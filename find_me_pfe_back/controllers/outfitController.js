const mongoose = require("mongoose");
const Outfit = require("../models/outfitModel");
const repo = require("../services/catalogRepository");
const { toCard } = require("../services/recommendationService");
const { enrich } = require("../services/scoring");

async function hydrate(outfits, userId) {
  const ids = [...new Set(outfits.flatMap((o) => o.items.map((i) => String(i.product))))];
  const [products, favs] = await Promise.all([repo.getProductsByIds(ids), repo.getUserFavorites(userId)]);
  const favSet = new Set(favs);
  const byId = new Map(products.map((p) => [String(p._id), toCard({ product: enrich(p) }, 0, favSet)]));
  return outfits.map((o) => {
    const items = o.items.map((i) => ({ slot: i.slot, product: byId.get(String(i.product)) })).filter((i) => i.product);
    return { ...o, _id: String(o._id), items, totalPrice: Math.round(items.reduce((s, i) => s + i.product.effectivePrice, 0) * 100) / 100 };
  });
}

// GET /outfits
module.exports.list = async (req, res) => {
  try {
    const outfits = await Outfit.find({ user: req.userId }).sort({ plannedFor: 1, createdAt: -1 }).lean();
    res.status(200).json(await hydrate(outfits, req.userId));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// POST /outfits { name, occasion?, plannedFor?, source?, items:[{slot, productId}] }
module.exports.create = async (req, res) => {
  try {
    const { name, occasion, plannedFor, source } = req.body;
    const items = (req.body.items || [])
      .filter((i) => mongoose.Types.ObjectId.isValid(i.productId))
      .slice(0, 8)
      .map((i) => ({ slot: i.slot || "item", product: i.productId }));
    if (!name || !items.length) return res.status(400).json({ message: "name and at least one item are required" });
    const outfit = await Outfit.create({ user: req.userId, name: String(name).slice(0, 60), occasion, plannedFor: plannedFor ? new Date(plannedFor) : undefined, source: source || "manual", items });
    items.forEach((i) => repo.logInteraction({ userId: req.userId, productId: i.product, type: "outfit_save" }).catch(() => {}));
    const [hydrated] = await hydrate([outfit.toObject()], req.userId);
    res.status(201).json(hydrated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// DELETE /outfits/:id
module.exports.remove = async (req, res) => {
  try {
    await Outfit.deleteOne({ _id: req.params.id, user: req.userId });
    res.status(200).json({ status: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
