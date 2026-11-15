const repo = require("../services/catalogRepository");
const { service: reco } = require("./recommendationController");
const parser = require("../services/criteriaParser");

// GET /preferences
module.exports.getPreferences = async (req, res) => {
  try {
    res.status(200).json((await repo.getPreferences(req.userId)) || {});
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// PUT /preferences  (Style Quiz answers)
module.exports.savePreferences = async (req, res) => {
  try {
    const b = req.body || {};
    const clean = parser.sanitizeSet({ styles: b.styles || [], colors: b.colors || [], types: b.types || [], sizes: b.sizes || [] });
    const prefs = {
      styles: clean.styles,
      colors: clean.colors,
      types: clean.types,
      sizes: clean.sizes,
      brands: Array.isArray(b.brands) ? b.brands.slice(0, 10).map(String) : [],
      occasions: Array.isArray(b.occasions) ? b.occasions.slice(0, 6).map(String) : [],
      gender: ["men", "women", "kids"].includes(b.gender) ? b.gender : null,
      budgetMin: Number(b.budgetMin) > 0 ? Number(b.budgetMin) : 0,
      budgetMax: Number(b.budgetMax) > 0 ? Number(b.budgetMax) : null,
    };
    const saved = await repo.savePreferences(req.userId, prefs);
    const dna = await reco.styleDna(req.userId);
    res.status(200).json({ preferences: saved, styleDna: dna });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// GET /preferences/style-dna
module.exports.styleDna = async (req, res) => {
  try {
    res.status(200).json(await reco.styleDna(req.userId));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
