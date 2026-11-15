/**
 * AI Fashion Stylist endpoints.
 * The previous node-nlp intent bot is kept in controllers/legacy/ for reference (not loaded).
 */
const { createChatService } = require("../services/chatService");
const repo = require("../services/catalogRepository");

const chat = createChatService({ repo });

const langOf = (req) => (String(req.query.lang || req.body.lang || "en").startsWith("fr") ? "fr" : "en");

function parseLocation(body) {
  const loc = body.location || {};
  const lat = Number(loc.lat ?? loc.latitude);
  const lng = Number(loc.lng ?? loc.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { lat, lng, label: typeof loc.label === "string" ? loc.label.slice(0, 60) : null, source: loc.source === "manual" ? "manual" : "gps" };
}

// POST /chatbot  { message?, sessionId?, location?:{lat,lng,label,source}, action?:{type:'nearby'|'similar'|'outfit'|'more', productId} }
module.exports.discuss = async (req, res) => {
  const message = String(req.body.message || "").trim();
  const action = req.body.action && typeof req.body.action === "object" ? { type: String(req.body.action.type || ""), productId: String(req.body.action.productId || "") } : null;
  if (!message && !(action && action.type && action.productId)) return res.status(400).json({ error: "Message is required" });
  if (message.length > 1000) return res.status(400).json({ error: "Message is too long" });
  try {
    const response = await chat.handleMessage({
      userId: req.userId,
      sessionId: req.body.sessionId,
      message: message || null,
      action,
      location: parseLocation(req.body),
    });
    res.status(200).json(response);
  } catch (err) {
    console.error("[chatbot] error:", err);
    res.status(500).json({ error: "Internal Server Error", chatbot: "Sorry, something went wrong. Please try again." });
  }
};

// GET /chatbot/sessions/:id
module.exports.history = async (req, res) => {
  try {
    res.status(200).json(await chat.history({ userId: req.userId, sessionId: req.params.id }));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// PATCH /chatbot/sessions/:id/criteria  { field, value }
module.exports.removeCriterion = async (req, res) => {
  const { field, value } = req.body;
  if (!field) return res.status(400).json({ error: "field is required" });
  try {
    res.status(200).json(await chat.removeCriterion({ userId: req.userId, sessionId: req.params.id, field, value, location: parseLocation(req.body) }));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// DELETE /chatbot/sessions/:id
module.exports.resetSession = async (req, res) => {
  try {
    await repo.deleteChatSession(req.params.id, req.userId);
    res.status(200).json({ status: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports._langOf = langOf;
