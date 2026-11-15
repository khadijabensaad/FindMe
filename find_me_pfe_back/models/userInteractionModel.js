const mongoose = require("mongoose");

// Implicit feedback used by Style DNA, "For You" and the trend engine
const userInteractionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    product: { type: mongoose.Schema.Types.ObjectId, ref: "Product", index: true },
    type: {
      type: String,
      enum: ["view", "click", "favorite", "search", "chat_click", "like", "dislike", "outfit_save"],
      required: true,
    },
    meta: { type: mongoose.Schema.Types.Mixed },
  },
  { timestamps: true }
);
userInteractionSchema.index({ createdAt: -1 });
userInteractionSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model("UserInteraction", userInteractionSchema);
