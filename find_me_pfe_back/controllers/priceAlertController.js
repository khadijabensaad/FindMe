const PriceAlert = require("../models/priceAlertModel");
const repo = require("../services/catalogRepository");
const { toCard } = require("../services/recommendationService");
const { enrich } = require("../services/scoring");
const tx = require("../services/taxonomy");

/**
 * Smart Wishlist. Alerts are evaluated lazily against the CURRENT price
 * (discountPrice included), so they are always correct even when prices are
 * changed directly in the database or through the discount module.
 */
async function evaluate(alerts) {
  const products = await repo.getProductsByIds(alerts.map((a) => String(a.product)));
  const byId = new Map(products.map((p) => [String(p._id), p]));
  const out = [];
  for (const a of alerts) {
    const p = byId.get(String(a.product));
    if (!p) continue;
    const current = tx.effectivePrice(p);
    const reached = current <= a.targetPrice;
    if (reached && !a.triggeredAt) {
      a.triggeredAt = new Date();
      await PriceAlert.updateOne({ _id: a._id }, { $set: { triggeredAt: a.triggeredAt } });
    }
    out.push({
      _id: String(a._id),
      targetPrice: a.targetPrice,
      priceAtCreation: a.priceAtCreation,
      currentPrice: current,
      reached,
      triggeredAt: a.triggeredAt || null,
      unseen: reached && !a.seenAt,
      dropPercent: a.priceAtCreation ? Math.max(0, Math.round((1 - current / a.priceAtCreation) * 100)) : 0,
      product: toCard({ product: enrich(p) }),
    });
  }
  return out;
}

// GET /alerts
module.exports.list = async (req, res) => {
  try {
    const alerts = await PriceAlert.find({ user: req.userId, active: true }).sort({ createdAt: -1 }).lean();
    const evaluated = await evaluate(alerts);
    res.status(200).json({ unseenCount: evaluated.filter((a) => a.unseen).length, alerts: evaluated });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// POST /alerts { productId, targetPrice? }  (default target: 10% below current price)
module.exports.create = async (req, res) => {
  try {
    const p = await repo.getProductById(req.body.productId);
    if (!p) return res.status(404).json({ message: "Product not found" });
    const current = tx.effectivePrice(p);
    const target = Number(req.body.targetPrice) > 0 ? Number(req.body.targetPrice) : Math.round(current * 0.9 * 100) / 100;
    const alert = await PriceAlert.findOneAndUpdate(
      { user: req.userId, product: p._id },
      { $set: { targetPrice: target, priceAtCreation: current, active: true, triggeredAt: null, seenAt: null } },
      { upsert: true, new: true }
    ).lean();
    const [evaluated] = await evaluate([alert]);
    res.status(201).json(evaluated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// PUT /alerts/seen  → mark triggered alerts as seen
module.exports.markSeen = async (req, res) => {
  try {
    await PriceAlert.updateMany({ user: req.userId, triggeredAt: { $ne: null }, seenAt: null }, { $set: { seenAt: new Date() } });
    res.status(200).json({ status: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// DELETE /alerts/:id
module.exports.remove = async (req, res) => {
  try {
    await PriceAlert.deleteOne({ _id: req.params.id, user: req.userId });
    res.status(200).json({ status: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
