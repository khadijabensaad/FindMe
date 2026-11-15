const fs = require("fs");
const { createVisualSearchService } = require("../services/visualSearchService");
const { service: reco } = require("./recommendationController");

const visual = createVisualSearchService({ reco });

// POST /search/visual  multipart field "image"
module.exports.visualSearch = async (req, res) => {
  const file = req.file;
  if (!file) return res.status(400).json({ message: "image file is required (field name: image)" });
  try {
    const lang = String(req.query.lang || req.body.lang || "en").startsWith("fr") ? "fr" : "en";
    // Flutter's MultipartFile sends application/octet-stream by default: infer the image type
    const ext = String(file.originalname || "").split(".").pop().toLowerCase();
    const byExt = { png: "image/png", webp: "image/webp", gif: "image/gif", jpg: "image/jpeg", jpeg: "image/jpeg", heic: "image/jpeg" };
    const mimeType = String(file.mimetype || "").startsWith("image/") ? file.mimetype : byExt[ext] || "image/jpeg";
    const result = await visual.searchByImage({ filePath: file.path, mimeType, userId: req.userId, lang });
    res.status(200).json(result);
  } catch (err) {
    console.error("[visual-search]", err.message);
    res.status(err.status || 500).json({ message: err.message });
  } finally {
    fs.unlink(file.path, () => {});
  }
};
