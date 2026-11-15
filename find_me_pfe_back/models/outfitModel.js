const mongoose = require("mongoose");

const outfitSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    name: { type: String, required: true },
    occasion: String,
    items: [
      {
        _id: false,
        slot: String,
        product: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
      },
    ],
    plannedFor: Date,
    source: { type: String, enum: ["manual", "complete_look", "chatbot"], default: "manual" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Outfit", outfitSchema);
