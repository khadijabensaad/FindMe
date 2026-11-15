const { createRecommendationService } = require("../services/recommendationService");
const repo = require("../services/catalogRepository");
const geo = require("../services/geoService");
const parser = require("../services/criteriaParser");

const reco = createRecommendationService({ repo });
const langOf = (req) => (String(req.query.lang || "en").startsWith("fr") ? "fr" : "en");
const list = (v) => (v == null || v === "" ? [] : String(v).split(",").map((s) => s.trim()).filter(Boolean));
const num = (v) => (v == null || v === "" || !Number.isFinite(Number(v)) ? null : Number(v));

const wrap = (fn) => async (req, res) => {
  try {
    const out = await fn(req, res);
    if (out === null) return res.status(404).json({ message: "Product not found" });
    if (out !== undefined) res.status(200).json(out);
  } catch (err) {
    console.error("[recommendations]", err);
    res.status(500).json({ message: err.message });
  }
};

// GET /recommendations/home
module.exports.home = wrap((req) => reco.home(req.userId, { lang: langOf(req) }));

// GET /recommendations/for-you?limit=10
module.exports.forYou = wrap((req) => reco.forYou(req.userId, { limit: Math.min(50, num(req.query.limit) || 10), lang: langOf(req) }));

// GET /recommendations/similar/:productId
module.exports.similar = wrap((req) => reco.similar(req.params.productId, { userId: req.userId, limit: Math.min(30, num(req.query.limit) || 8), lang: langOf(req) }));

// GET /recommendations/trending?days=14
module.exports.trending = wrap((req) => reco.trending({ days: Math.min(90, num(req.query.days) || 14), limit: Math.min(50, num(req.query.limit) || 10), userId: req.userId, lang: langOf(req) }));

// GET /recommendations/budget?max=100&types=dress,shoes
module.exports.budget = wrap(async (req, res) => {
  const max = num(req.query.max);
  if (!max) { res.status(400).json({ message: "max is required" }); return undefined; }
  return reco.budgetPicks({ max, types: list(req.query.types), userId: req.userId, limit: Math.min(50, num(req.query.limit) || 10), lang: langOf(req) });
});

// GET /recommendations/complete-look/:productId
module.exports.completeLook = wrap((req) => reco.completeTheLook(req.params.productId, { userId: req.userId, lang: langOf(req) }));

// GET /recommendations/discover?query=&types=&colors=&styles=&sizes=&brands=&gender=&minPrice=&maxPrice=&sort=match&page=1
module.exports.discover = wrap((req) => reco.discover({
  userId: req.userId,
  lang: langOf(req),
  sort: req.query.sort || "match",
  page: num(req.query.page) || 1,
  limit: Math.min(50, num(req.query.limit) || 20),
  filters: {
    query: req.query.query || "",
    types: list(req.query.types),
    colors: list(req.query.colors).map((c) => c.toLowerCase()),
    styles: list(req.query.styles),
    sizes: list(req.query.sizes).map((s) => s.toUpperCase()),
    brands: list(req.query.brands),
    gender: req.query.gender || null,
    minPrice: num(req.query.minPrice),
    maxPrice: num(req.query.maxPrice),
  },
}));

// GET /recommendations/explain/:productId
module.exports.explain = wrap((req) => reco.explain(req.params.productId, { userId: req.userId, lang: langOf(req) }));

// GET /recommendations/nearby-shops/:productId?lat=&lng=&radiusKm=
module.exports.nearbyShops = wrap((req) => reco.nearbyShops(req.params.productId, { lat: num(req.query.lat), lng: num(req.query.lng), radiusKm: num(req.query.radiusKm) }));

// GET /recommendations/nearby-products?lat=&lng=&place=&radiusKm=&query=&types=&colors=&sizes=&maxPrice=&productIds=
// Products available in shops around a GPS position or a named place (Tunis, Sousse…).
module.exports.nearbyProducts = wrap(async (req) => {
  const shops = await repo.getAllShops();
  let origin = null;
  if (geo.validCoord(num(req.query.lat), num(req.query.lng))) origin = { lat: num(req.query.lat), lng: num(req.query.lng), source: "gps", label: req.query.label || null };
  const place = req.query.place ? geo.detectPlace(String(req.query.place), shops) : null;
  if (place) origin = { lat: place.lat, lng: place.lng, label: place.name, source: "place" };
  let criteria = parser.emptyCriteria();
  if (req.query.query) criteria = parser.mergeCriteria(criteria, parser.parseMessage(String(req.query.query), await repo.getVocabulary()));
  const set = parser.sanitizeSet({ types: list(req.query.types), colors: list(req.query.colors), sizes: list(req.query.sizes), maxPrice: num(req.query.maxPrice) });
  criteria = parser.mergeCriteria(criteria, { set });
  const productIds = list(req.query.productIds);
  return reco.nearbyProducts({
    criteria,
    productIds: productIds.length ? productIds : null,
    origin,
    radiusKm: Math.min(500, num(req.query.radiusKm) || 25),
    userId: req.userId,
    lang: langOf(req),
    limit: Math.min(30, num(req.query.limit) || 12),
  });
});

// GET /recommendations/stores?lat=&lng=  — every shop with valid coordinates, nearest first
module.exports.stores = wrap(async (req) => {
  const origin = geo.validCoord(num(req.query.lat), num(req.query.lng)) ? { lat: num(req.query.lat), lng: num(req.query.lng) } : null;
  const shops = await repo.getAllShops();
  const cards = shops.map((s) => ({ ...geo.shopCard(s, origin), productCount: (s.products || []).length })).filter((s) => s.coordinates);
  if (origin) cards.sort((a, b) => a.distanceKm - b.distanceKm);
  return { origin, stores: cards, skipped: shops.length - cards.length };
});

// GET /recommendations/places — cities for the manual location picker
module.exports.places = wrap(async () => ({ places: geo.PLACES.map(({ name, lat, lng }) => ({ name, lat, lng })) }));

// POST /recommendations/feedback { productId, value: like|dislike, reason?, context? }
module.exports.feedback = wrap(async (req, res) => {
  const { productId, value, reason, context } = req.body;
  if (!productId || !["like", "dislike"].includes(value)) { res.status(400).json({ message: "productId and value (like|dislike) are required" }); return undefined; }
  await repo.saveFeedback({ userId: req.userId, productId, value, reason, context });
  if (req.userId) await repo.logInteraction({ userId: req.userId, productId, type: value, meta: { reason, context } });
  return { status: true };
});

module.exports.service = reco;
