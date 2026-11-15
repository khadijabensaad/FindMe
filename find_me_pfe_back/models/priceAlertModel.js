const mongoose = require("mongoose");

// Smart wishlist: notify when the effective price drops to the target
const priceAlertSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    product: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
    targetPrice: { type: Number, required: true },
    priceAtCreation: Number,
    active: { type: Boolean, default: true },
    triggeredAt: Date,
    seenAt: Date,
  },
  { timestamps: true }
);
priceAlertSchema.index({ user: 1, product: 1 }, { unique: true });

module.exports = mongoose.model("PriceAlert", priceAlertSchema);
