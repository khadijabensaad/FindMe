const repo = require("../services/catalogRepository");

const ALLOWED = ["view", "click", "favorite", "search", "chat_click", "like", "dislike", "outfit_save"];

// POST /interactions { productId?, type, meta? }
module.exports.track = async (req, res) => {
  const { productId, type, meta } = req.body || {};
  if (!ALLOWED.includes(type)) return res.status(400).json({ message: `type must be one of ${ALLOWED.join(", ")}` });
  try {
    await repo.logInteraction({ userId: req.userId, productId, type, meta });
    res.status(201).json({ status: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
