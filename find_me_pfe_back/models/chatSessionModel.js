const mongoose = require("mongoose");

const chatMessageSchema = new mongoose.Schema(
  {
    role: { type: String, enum: ["user", "assistant"], required: true },
    text: String,
    products: [{ type: mongoose.Schema.Types.ObjectId, ref: "Product" }],
    intent: String,
  },
  { _id: false, timestamps: { createdAt: true, updatedAt: false } }
);

// Conversation memory of the AI Stylist (criteria are remembered between messages)
const chatSessionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    criteria: { type: mongoose.Schema.Types.Mixed, default: {} },
    shownProductIds: [String],
    lastProductIds: [String],
    language: { type: String, default: "en" },
    geo: { type: mongoose.Schema.Types.Mixed, default: null }, // active "near me" search: origin, radius, products
    messages: [chatMessageSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model("ChatSession", chatSessionSchema);
