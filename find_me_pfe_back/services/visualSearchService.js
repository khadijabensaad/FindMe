/**
 * FINDME — Visual Fashion Search ("Find Similar" from a photo).
 *
 * Pipeline: photo ─► vision LLM ─► structured attributes (type, colours, style, gender)
 *                 ─► validated against the taxonomy ─► recommendationService.search()
 *
 * The vision model only *describes* the garment; products always come from MongoDB.
 * (A possible extension for the report: CLIP image embeddings stored per product
 *  for pixel-level similarity.)
 */
const fs = require('fs');
const tx = require('./taxonomy');
const parser = require('./criteriaParser');

const VISION_SYSTEM = `You are a fashion vision expert for a shopping app.
Describe the MAIN clothing item or accessory visible in the photo.
Return ONLY JSON:
{
  "is_fashion": true|false,
  "type": one of [${tx.TYPE_KEYS.map((t) => `"${t}"`).join(', ')}],
  "colors": up to 2 of [${tx.COLOR_KEYS.map((c) => `"${c}"`).join(', ')}],
  "styles": up to 2 of ["minimalist","elegant","casual","sporty","trendy"],
  "gender": "women" | "men" | "kids" | null,
  "pattern": "plain" | "striped" | "floral" | "printed" | "checked" | "other",
  "description_en": "one short sentence",
  "description_fr": "une phrase courte"
}`;

function createVisualSearchService({ llm, reco } = {}) {
  if (!llm) llm = require('./llmClient');
  if (!reco) reco = require('./recommendationService').createRecommendationService();

  async function searchByImage({ filePath, buffer, mimeType = 'image/jpeg', userId, lang = 'en', limit = 8 }) {
    if (!llm.isEnabled()) {
      const err = new Error('Visual search needs a vision-capable LLM: set LLM_PROVIDER / LLM_API_KEY / LLM_MODEL (or LLM_VISION_MODEL) in .env');
      err.status = 503;
      throw err;
    }
    const data = buffer || fs.readFileSync(filePath);
    if (data.length > 8 * 1024 * 1024) {
      const err = new Error('Image too large (max 8 MB)');
      err.status = 413;
      throw err;
    }
    const raw = await llm.describeImageJson({
      system: VISION_SYSTEM,
      prompt: 'Describe the main fashion item in this photo.',
      base64: data.toString('base64'),
      mimeType,
    });
    if (raw.is_fashion === false) {
      return { detected: { isFashion: false }, products: [], criteria: null };
    }
    const set = parser.sanitizeSet({ types: raw.type ? [raw.type] : [], colors: raw.colors || [], styles: raw.styles || [], gender: raw.gender || undefined });
    const criteria = parser.mergeCriteria({}, { set });
    const result = await reco.search(criteria, { userId, lang, limit, minResults: 4 });
    return {
      detected: {
        isFashion: true,
        type: set.types[0] || null,
        colors: set.colors,
        styles: set.styles,
        gender: set.gender || null,
        pattern: raw.pattern || null,
        description: lang === 'fr' ? raw.description_fr || raw.description_en : raw.description_en || raw.description_fr,
      },
      criteria,
      relaxed: result.relaxed,
      products: result.products,
    };
  }

  return { searchByImage };
}

module.exports = { createVisualSearchService };
