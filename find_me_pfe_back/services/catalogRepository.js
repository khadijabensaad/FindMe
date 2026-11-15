/**
 * FINDME — Data access for the AI services.
 *
 * All MongoDB access of the recommendation / chat services goes through this object,
 * so services can be unit-tested with an in-memory fake (see tests/).
 *
 * The catalogue is cached in memory for CATALOG_CACHE_MS (default 60 s): a PFE-sized
 * catalogue (hundreds/thousands of products) is ranked in a few milliseconds in JS.
 * For a very large catalogue, replace getAllProducts() by a pre-filtered Mongo query.
 */
const mongoose = require('mongoose');

const models = () => ({
  Product: require('../models/productModel'),
  User: require('../models/userModel'),
  Shop: require('../models/shopModel'),
  Brand: require('../models/brandModel'),
  Category: require('../models/categoryModel'),
  UserInteraction: require('../models/userInteractionModel'),
  UserPreference: require('../models/userPreferenceModel'),
  ChatSession: require('../models/chatSessionModel'),
  RecommendationFeedback: require('../models/recommendationFeedbackModel'),
});

const CACHE_MS = Number(process.env.CATALOG_CACHE_MS || 60000);
let productCache = { at: 0, data: null };
let vocabCache = { at: 0, data: null };
let shopCache = { at: 0, data: null };

function isValidId(id) {
  return mongoose.Types.ObjectId.isValid(String(id || ''));
}

const repo = {
  invalidate() {
    productCache = { at: 0, data: null };
    vocabCache = { at: 0, data: null };
    shopCache = { at: 0, data: null };
  },

  async getAllProducts() {
    if (productCache.data && Date.now() - productCache.at < CACHE_MS) return productCache.data;
    const data = await models().Product.find().lean();
    productCache = { at: Date.now(), data };
    return data;
  },

  async getProductById(id) {
    if (!isValidId(id)) return null;
    const all = await repo.getAllProducts();
    const hit = all.find((p) => String(p._id) === String(id));
    return hit || models().Product.findById(id).lean();
  },

  async getProductsByIds(ids = []) {
    const all = await repo.getAllProducts();
    const set = new Set(ids.map(String));
    return all.filter((p) => set.has(String(p._id)));
  },

  /** Vocabulary the NLU is allowed to use (brands and categories that really exist). */
  async getVocabulary() {
    if (vocabCache.data && Date.now() - vocabCache.at < CACHE_MS) return vocabCache.data;
    const products = await repo.getAllProducts();
    const brands = [...new Set(products.map((p) => p.brand).filter(Boolean))];
    const categories = [...new Set(products.flatMap((p) => p.category || []).filter(Boolean))];
    const colors = [...new Set(products.flatMap((p) => p.colors || []).map((c) => String(c).toLowerCase()))];
    const prices = products.map((p) => Number(p.price) || 0).filter((x) => x > 0);
    const data = {
      brands,
      categories,
      colors,
      priceRange: prices.length ? { min: Math.min(...prices), max: Math.max(...prices) } : null,
    };
    vocabCache = { at: Date.now(), data };
    return data;
  },

  async getUserFavorites(userId) {
    if (!isValidId(userId)) return [];
    const user = await models().User.findById(userId).select('favorites').lean();
    return user ? (user.favorites || []).map(String) : [];
  },

  async getUserBasic(userId) {
    if (!isValidId(userId)) return null;
    return models().User.findById(userId).select('username image').lean();
  },

  async getPreferences(userId) {
    if (!isValidId(userId)) return null;
    return models().UserPreference.findOne({ user: userId }).lean();
  },

  async savePreferences(userId, prefs) {
    return models().UserPreference.findOneAndUpdate(
      { user: userId },
      { $set: { ...prefs, user: userId, quizCompletedAt: new Date() } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    ).lean();
  },

  async getInteractions(userId, { sinceDays = 120, limit = 400 } = {}) {
    if (!isValidId(userId)) return [];
    const since = new Date(Date.now() - sinceDays * 24 * 3600 * 1000);
    return models().UserInteraction.find({ user: userId, createdAt: { $gte: since } })
      .sort({ createdAt: -1 }).limit(limit).lean();
  },

  async logInteraction({ userId, productId, type, meta }) {
    const doc = { type, meta };
    if (isValidId(userId)) doc.user = userId;
    if (isValidId(productId)) doc.product = productId;
    return models().UserInteraction.create(doc);
  },

  /** Weighted interaction counts per product over the last `days` (trend window). */
  async getRecentProductCounts(days = 14) {
    const since = new Date(Date.now() - days * 24 * 3600 * 1000);
    const rows = await models().UserInteraction.aggregate([
      { $match: { createdAt: { $gte: since }, product: { $ne: null }, type: { $ne: 'dislike' } } },
      {
        $group: {
          _id: '$product',
          count: {
            $sum: {
              $switch: {
                branches: [
                  { case: { $eq: ['$type', 'favorite'] }, then: 3 },
                  { case: { $eq: ['$type', 'outfit_save'] }, then: 2 },
                  { case: { $eq: ['$type', 'like'] }, then: 2 },
                  { case: { $eq: ['$type', 'chat_click'] }, then: 1.5 },
                ],
                default: 1,
              },
            },
          },
        },
      },
    ]);
    const counts = {};
    rows.forEach((r) => { counts[String(r._id)] = r.count; });
    return counts;
  },

  async getDislikedProductIds(userId) {
    if (!isValidId(userId)) return [];
    const rows = await models().RecommendationFeedback.find({ user: userId, value: 'dislike' }).select('product').lean();
    return rows.map((r) => String(r.product));
  },

  async saveFeedback({ userId, productId, value, reason, context }) {
    return models().RecommendationFeedback.create({ user: isValidId(userId) ? userId : undefined, product: productId, value, reason: reason || null, context: context || 'other' });
  },

  /** Every shop with its coordinates and product ids (cached like the catalogue). */
  async getAllShops() {
    if (shopCache.data && Date.now() - shopCache.at < CACHE_MS) return shopCache.data;
    const data = await models().Shop.find().select('name city region coordinates products').lean();
    shopCache = { at: Date.now(), data };
    return data;
  },

  async getShopsByNames(names = []) {
    if (!names.length) return [];
    return models().Shop.find({ name: { $in: names } }).select('name city region coordinates').lean();
  },

  // ---- chat sessions -------------------------------------------------------
  async getChatSession(sessionId, userId) {
    const { ChatSession } = models();
    if (isValidId(sessionId)) {
      const s = await ChatSession.findById(sessionId);
      if (s && (!s.user || !userId || String(s.user) === String(userId))) return s;
    }
    return ChatSession.create({ user: isValidId(userId) ? userId : undefined, criteria: {}, messages: [] });
  },

  async saveChatSession(session) {
    session.markModified('criteria');
    session.markModified('geo');
    if (session.messages.length > 40) session.messages = session.messages.slice(-40);
    if (session.shownProductIds.length > 200) session.shownProductIds = session.shownProductIds.slice(-200);
    return session.save();
  },

  async deleteChatSession(sessionId, userId) {
    if (!isValidId(sessionId)) return null;
    const filter = { _id: sessionId };
    if (isValidId(userId)) filter.user = userId;
    return models().ChatSession.deleteOne(filter);
  },
};

module.exports = repo;
