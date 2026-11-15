/**
 * FINDME — AI Style DNA (pure function).
 *
 * Builds a style profile from real user signals:
 *   - favorites (strong signal)
 *   - interactions: views, clicks, chat likes / dislikes, saved outfits (time-decayed)
 *   - the explicit Style Quiz answers (userPreferences)
 *
 * The output feeds both the recommendation engine (as `profile`) and the
 * Style DNA screen in the app.
 */
const tx = require('./taxonomy');
const { enrich } = require('./scoring');

const SIGNAL_WEIGHTS = {
  favorite: 3,
  outfit_save: 2.5,
  like: 2,
  click: 1.2,
  view: 1,
  chat_click: 1.5,
  search: 0.5,
  dislike: -2,
};
const HALF_LIFE_DAYS = 30;

const PERSONAS = {
  'elegant+minimalist': 'Minimalist Chic',
  'elegant+trendy': 'Modern Glam',
  'casual+sporty': 'Athleisure Lover',
  'casual+minimalist': 'Effortless Basics',
  'casual+elegant': 'Smart Casual',
  'sporty+trendy': 'Street Sport',
  'casual+trendy': 'Urban Trendsetter',
  'minimalist+sporty': 'Clean Athletic',
  'elegant+sporty': 'Sport Chic',
  'minimalist+trendy': 'Modern Minimalist',
  elegant: 'Timeless Elegance',
  minimalist: 'Pure Minimalist',
  casual: 'Easygoing Casual',
  sporty: 'Active Spirit',
  trendy: 'Trend Hunter',
};

function decay(dateLike, now) {
  if (!dateLike) return 1;
  const ageDays = (now - new Date(dateLike).getTime()) / (24 * 3600 * 1000);
  return Math.pow(0.5, Math.max(0, ageDays) / HALF_LIFE_DAYS);
}

function add(map, key, w) {
  if (!key) return;
  map[key] = (map[key] || 0) + w;
}

function normalizeByMax(map) {
  const vals = Object.values(map).filter((v) => v > 0);
  const max = vals.length ? Math.max(...vals) : 0;
  const out = {};
  for (const [k, v] of Object.entries(map)) if (v > 0 && max > 0) out[k] = Number((v / max).toFixed(3));
  return out;
}

function topN(map, n) {
  return Object.entries(map).filter(([, v]) => v > 0).sort((a, b) => b[1] - a[1]).slice(0, n).map(([k]) => k);
}

function weightedMedian(pairs) {
  const sorted = pairs.filter(([, w]) => w > 0).sort((a, b) => a[0] - b[0]);
  const total = sorted.reduce((s, [, w]) => s + w, 0);
  let acc = 0;
  for (const [v, w] of sorted) {
    acc += w;
    if (acc >= total / 2) return v;
  }
  return null;
}

/**
 * @param {object} input
 *   favorites: Product[]
 *   interactions: [{ type, product: Product, createdAt }]
 *   preferences: { styles:[], colors:[], brands:[], types:[], budgetMin, budgetMax, occasions:[] } | null
 */
function computeStyleDna({ favorites = [], interactions = [], preferences = null } = {}, now = Date.now()) {
  const styles = {};
  const colors = {};
  const brands = {};
  const types = {};
  const prices = [];
  let signals = 0;

  const absorb = (rawProduct, w) => {
    if (!rawProduct) return;
    const p = enrich(rawProduct, now);
    for (const s of tx.STYLE_KEYS) add(styles, s, w * (p._styles[s] || 0));
    p._colors.forEach((c) => add(colors, c, w / Math.max(1, p._colors.length)));
    add(brands, tx.normalize(p.brand), w);
    add(types, p._type, w);
    if (w > 0 && p._price > 0) prices.push([p._price, w]);
  };

  favorites.forEach((p) => {
    absorb(p, SIGNAL_WEIGHTS.favorite);
    signals += 1;
  });
  interactions.forEach((it) => {
    const base = SIGNAL_WEIGHTS[it.type];
    if (base === undefined) return;
    const w = base * decay(it.createdAt, now);
    absorb(it.product, w);
    if (it.type === 'search' && it.meta && it.meta.criteria) {
      const c = it.meta.criteria;
      (c.styles || []).forEach((s) => add(styles, s, 0.6 * decay(it.createdAt, now)));
      (c.colors || []).forEach((col) => add(colors, col, 0.5 * decay(it.createdAt, now)));
      (c.types || []).forEach((t) => add(types, t, 0.5 * decay(it.createdAt, now)));
      if (c.maxPrice) prices.push([c.maxPrice * 0.8, 0.5]);
    }
    signals += 1;
  });

  if (preferences) {
    (preferences.styles || []).forEach((s) => add(styles, s, 3));
    (preferences.colors || []).forEach((c) => add(colors, c, 2));
    (preferences.brands || []).forEach((b) => add(brands, tx.normalize(b), 2));
    (preferences.types || []).forEach((t) => add(types, t, 1.5));
    if (preferences.budgetMax) {
      prices.push([(Number(preferences.budgetMin || 0) + Number(preferences.budgetMax)) / 2, 4]);
    }
    if ((preferences.styles || []).length) signals += 5;
  }

  // Style shares sum to 100% → easy to read ("38% minimalist")
  const positiveStyles = {};
  tx.STYLE_KEYS.forEach((s) => { positiveStyles[s] = Math.max(0, styles[s] || 0); });
  const totalStyle = Object.values(positiveStyles).reduce((a, b) => a + b, 0);
  const stylePercents = {};
  tx.STYLE_KEYS.forEach((s) => {
    stylePercents[s] = totalStyle > 0 ? Math.round((positiveStyles[s] / totalStyle) * 100) : 0;
  });

  const rankedStyles = tx.STYLE_KEYS.filter((s) => stylePercents[s] > 0).sort((a, b) => stylePercents[b] - stylePercents[a]);
  let persona = 'Style Explorer';
  if (rankedStyles.length) {
    const [a, b] = rankedStyles;
    const pairKey = b && stylePercents[b] >= stylePercents[a] * 0.55 ? [a, b].sort().join('+') : a;
    persona = PERSONAS[pairKey] || PERSONAS[a] || persona;
  }

  // Budget: weighted median ± spread
  let budget = null;
  if (preferences && preferences.budgetMax) {
    budget = { min: Number(preferences.budgetMin || 0), max: Number(preferences.budgetMax) };
  } else if (prices.length) {
    const median = weightedMedian(prices);
    budget = { min: Math.round(median * 0.6), max: Math.round(median * 1.4) };
  }
  if (budget) budget.median = Math.round((budget.min + budget.max) / 2);

  const confidence = Number(Math.min(1, signals / 15).toFixed(2));

  return {
    persona,
    styles: stylePercents,
    topStyles: rankedStyles.slice(0, 3),
    topColors: topN(colors, 5),
    topBrands: topN(brands, 5),
    topTypes: topN(types, 5),
    budget,
    confidence,
    signals,
    // used by the ranking engine
    profile: signals === 0 ? null : {
      styleVector: normalizeByMax(styles),
      colorAffinity: normalizeByMax(colors),
      brandAffinity: normalizeByMax(brands),
      typeAffinity: normalizeByMax(types),
      budget,
    },
  };
}

module.exports = { computeStyleDna, SIGNAL_WEIGHTS, PERSONAS };
