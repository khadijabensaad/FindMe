const mongoose = require("mongoose");

// Explicit style preferences (Style Quiz) — one document per user
const userPreferenceSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },
    styles: [{ type: String, enum: ["minimalist", "elegant", "casual", "sporty", "trendy"] }],
    colors: [String],
    brands: [String],
    types: [String],
    occasions: [String],
    sizes: [String],
    gender: { type: String, enum: ["men", "women", "kids", null], default: null },
    budgetMin: { type: Number, default: 0 },
    budgetMax: { type: Number, default: null },
    quizCompletedAt: Date,
  },
  { timestamps: true }
);

module.exports = mongoose.model("UserPreference", userPreferenceSchema);
