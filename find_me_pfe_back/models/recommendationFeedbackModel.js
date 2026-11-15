const mongoose = require("mongoose");

// Explicit like / dislike on a recommendation, with an optional reason
const recommendationFeedbackSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    product: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
    value: { type: String, enum: ["like", "dislike"], required: true },
    reason: { type: String, enum: ["too_expensive", "not_my_style", "wrong_color", "wrong_size", "already_have", "other", null], default: null },
    context: { type: String, enum: ["for_you", "similar", "chatbot", "complete_look", "trending", "discover", "visual_search", "other"], default: "other" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("RecommendationFeedback", recommendationFeedbackSchema);
