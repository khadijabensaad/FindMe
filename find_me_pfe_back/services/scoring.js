/**
 * FINDME — Explainable ranking (pure functions).
 *
 *   Score(p, u) = 0.30·C + 0.20·S + 0.15·B + 0.15·P + 0.10·R + 0.10·T
 *
 *   C  category / product-type match      S  style & colour match
 *   B  budget fit                         P  personal preferences (Style DNA, brands)
 *   R  rating                             T  popularity / trend (searches + recent interactions)
 *
 * Every component is normalized to [0, 1] and returned with human-readable reasons,
 * so the app can show *why* a product is recommended.
 */
const tx = require('./taxonomy');

const WEIGHTS = Object.freeze({ category: 0.3, style: 0.2, budget: 0.15, preference: 0.15, rating: 0.1, trend: 0.1 });

const LABELS = {
  en: {
    type_match: (t) => `It's the ${t} you asked for`,
    color_match: (c) => `Available in ${c}`,
    style_match: (s) => `Fits your ${s} style`,
    in_budget: (b) => `Within your ${b} TND budget`,
    near_budget: (b) => `Slightly above ${b} TND`,
    profile_budget: () => 'In your usual price range',
    brand_love: (b) => `From ${b}, a brand you like`,
    brand_match: (b) => `From ${b}, as requested`,
    dna_match: () => 'Matches your Style DNA',
    top_rated: (r) => `Rated ${r}/5`,
    trending: () => 'Trending right now',
    discount: (p) => `On sale: -${p}%`,
    size_ok: (s) => `Size ${s} available`,
    favorite: () => 'Already in your favorites',
  },
  fr: {
    type_match: (t) => `C'est le type d'article demandé (${t})`,
    color_match: (c) => `Disponible en ${c}`,
    style_match: (s) => `Correspond à ton style ${s}`,
    in_budget: (b) => `Dans ton budget de ${b} TND`,
    near_budget: (b) => `Légèrement au-dessus de ${b} TND`,
    profile_budget: () => 'Dans ta gamme de prix habituelle',
    brand_love: (b) => `De ${b}, une marque que tu aimes`,
    brand_match: (b) => `De ${b}, comme demandé`,
    dna_match: () => 'Correspond à ton Style DNA',
    top_rated: (r) => `Noté ${r}/5`,
    trending: () => 'Tendance en ce moment',
    discount: (p) => `En promo : -${p}%`,
    size_ok: (s) => `Taille ${s} disponible`,
    favorite: () => 'Déjà dans tes favoris',
  },
};

function label(lang, code, arg) {
  const dict = LABELS[lang] || LABELS.en;
  return dict[code] ? dict[code](arg) : code;
}

/** Enrich a raw product with inferred fields (memoized on the object). */
function enrich(product, now = Date.now()) {
  if (product._enriched) return product;
  const p = { ...product };
  p._type = tx.inferType(p);
  p._group = tx.typeGroup(p._type);
  p._gender = tx.inferGender(p);
  p._colors = tx.productColors(p);
  p._styles = tx.inferStyleVector(p, now);
  p._price = tx.effectivePrice(p);
  p._enriched = true;
  return p;
}

function clamp01(x) {
  return Math.max(0, Math.min(1, Number.isFinite(x) ? x : 0));
}

function topKey(map) {
  let best = null;
  let bestV = -Infinity;
  for (const [k, v] of Object.entries(map || {})) {
    if (v > bestV) { best = k; bestV = v; }
  }
  return best;
}

// --- Components -------------------------------------------------------------

function categoryScore(p, criteria, profile) {
  if (criteria.types && criteria.types.length) {
    if (criteria.types.includes(p._type)) return { v: 1, reason: ['type_match', p._type] };
    if (criteria.types.some((t) => tx.typeGroup(t) === p._group)) return { v: 0.5 };
    return { v: 0 };
  }
  if (profile && profile.typeAffinity && Object.keys(profile.typeAffinity).length) {
    const v = profile.typeAffinity[p._type] || 0;
    return { v: 0.3 + 0.7 * v };
  }
  return { v: 0.5 };
}

function styleScore(p, criteria, profile) {
  const parts = [];
  const reasons = [];
  // colours
  if (criteria.excludeColors && criteria.excludeColors.length && p._colors.some((c) => criteria.excludeColors.includes(c)) && !p._colors.some((c) => !criteria.excludeColors.includes(c))) {
    parts.push(0);
  } else if (criteria.colors && criteria.colors.length) {
    const hit = criteria.colors.find((c) => p._colors.includes(c));
    parts.push(hit ? 1 : 0);
    if (hit) reasons.push(['color_match', hit]);
  } else if (profile && profile.colorAffinity && Object.keys(profile.colorAffinity).length) {
    parts.push(Math.max(0.2, ...p._colors.map((c) => profile.colorAffinity[c] || 0)));
  }
  // styles
  if (criteria.styles && criteria.styles.length) {
    const best = Math.max(...criteria.styles.map((s) => p._styles[s] || 0));
    parts.push(best);
    if (best >= 0.45) reasons.push(['style_match', criteria.styles.find((s) => (p._styles[s] || 0) === best)]);
  } else if (profile && profile.styleVector && Object.keys(profile.styleVector).length) {
    let dot = 0;
    let norm = 0;
    for (const s of tx.STYLE_KEYS) {
      dot += (profile.styleVector[s] || 0) * (p._styles[s] || 0);
      norm += profile.styleVector[s] || 0;
    }
    const v = norm > 0 ? dot / norm : 0.5;
    parts.push(clamp01(v * 1.6));
    if (v >= 0.4) reasons.push(['dna_match']);
  }
  if (!parts.length) return { v: 0.5, reasons };
  return { v: parts.reduce((a, b) => a + b, 0) / parts.length, reasons };
}

function budgetScore(p, criteria, profile) {
  const price = p._price;
  if (criteria.maxPrice) {
    if (price <= criteria.maxPrice && (!criteria.minPrice || price >= criteria.minPrice)) return { v: 1, reason: ['in_budget', criteria.maxPrice] };
    if (price > criteria.maxPrice) {
      const over = (price - criteria.maxPrice) / criteria.maxPrice;
      const v = clamp01(0.6 * (1 - over * 2));
      return over <= 0.15 ? { v, reason: ['near_budget', criteria.maxPrice] } : { v };
    }
    return { v: 0.6 }; // below the minimum asked
  }
  if (criteria.minPrice) return { v: price >= criteria.minPrice ? 1 : 0.4 };
  if (profile && profile.budget && profile.budget.max) {
    const { min = 0, max } = profile.budget;
    if (price >= min * 0.8 && price <= max * 1.1) return { v: 1, reason: ['profile_budget'] };
    if (price < min * 0.8) return { v: 0.85 }; // cheaper than usual is never a problem
    return { v: clamp01(1 - (price - max) / max) * 0.7 };
  }
  return { v: 0.7 };
}

function preferenceScore(p, criteria, profile, favoriteIds) {
  const reasons = [];
  if (criteria.brands && criteria.brands.length) {
    const hit = criteria.brands.some((b) => tx.normalize(b) === tx.normalize(p.brand));
    if (hit) reasons.push(['brand_match', p.brand]);
    return { v: hit ? 1 : 0.15, reasons };
  }
  let v = 0.5;
  if (profile) {
    const brandAff = (profile.brandAffinity || {})[tx.normalize(p.brand)] || 0;
    const typeAff = (profile.typeAffinity || {})[p._type] || 0;
    const colorAff = Math.max(0, ...p._colors.map((c) => (profile.colorAffinity || {})[c] || 0));
    v = 0.25 + 0.4 * brandAff + 0.2 * typeAff + 0.15 * colorAff;
    if (brandAff >= 0.5) reasons.push(['brand_love', p.brand]);
  }
  if (favoriteIds && favoriteIds.has(String(p._id))) {
    v = Math.max(v, 0.9);
    reasons.push(['favorite']);
  }
  if (criteria.sizes && criteria.sizes.length) {
    const sizes = (p.size || []).map((s) => String(s).toUpperCase());
    const hit = criteria.sizes.find((s) => sizes.includes(s));
    if (hit) reasons.push(['size_ok', hit]);
    v = hit ? Math.min(1, v + 0.2) : v * 0.5;
  }
  return { v: clamp01(v), reasons };
}

function ratingScore(p) {
  const r = Number(p.rating) || 0;
  return { v: clamp01(r / 5), reason: r >= 4 ? ['top_rated', Number(r.toFixed(1))] : null };
}

function trendScore(p, stats) {
  const maxSearched = Math.max(1, stats.maxSearched || 1);
  const searched = Math.log1p(Number(p.searched) || 0) / Math.log1p(maxSearched);
  const recentMax = Math.max(1, stats.maxRecent || 1);
  const recent = (stats.recentCounts && stats.recentCounts[String(p._id)]) || 0;
  const recentNorm = Math.log1p(recent) / Math.log1p(recentMax);
  const v = clamp01(0.6 * searched + 0.4 * recentNorm);
  return { v, reason: v >= 0.65 ? ['trending'] : null };
}

/**
 * Score one product.
 * @param product raw or enriched product
 * @param ctx { criteria, profile, stats:{maxSearched,maxRecent,recentCounts}, favoriteIds:Set, lang, weights }
 */
function scoreProduct(product, ctx = {}) {
  const p = enrich(product, ctx.now);
  const criteria = ctx.criteria || {};
  const profile = ctx.profile || null;
  const stats = ctx.stats || {};
  const W = ctx.weights || WEIGHTS;
  const lang = ctx.lang === 'fr' || ctx.lang === 'tn' ? 'fr' : 'en';

  const c = categoryScore(p, criteria, profile);
  const s = styleScore(p, criteria, profile);
  const b = budgetScore(p, criteria, profile);
  const pr = preferenceScore(p, criteria, profile, ctx.favoriteIds);
  const r = ratingScore(p);
  const t = trendScore(p, stats);

  const breakdown = {
    category: Number(c.v.toFixed(3)),
    style: Number(s.v.toFixed(3)),
    budget: Number(b.v.toFixed(3)),
    preference: Number(pr.v.toFixed(3)),
    rating: Number(r.v.toFixed(3)),
    trend: Number(t.v.toFixed(3)),
  };
  let score = 0;
  for (const k of Object.keys(W)) score += W[k] * breakdown[k];

  // gender coherence: a men's product for a women's request is a hard mismatch
  if (criteria.gender && p._gender && p._gender !== criteria.gender) score *= 0.35;

  const rawReasons = [c.reason, ...(s.reasons || []), b.reason, ...(pr.reasons || []), r.reason, t.reason].filter(Boolean);
  if (tx.hasDiscount(p)) rawReasons.push(['discount', Math.round((1 - p._price / p.price) * 100)]);
  const reasons = rawReasons.map(([code, arg]) => ({ code, label: label(lang, code, arg) }));

  return { score: Number(score.toFixed(4)), matchPercent: Math.round(score * 100), breakdown, reasons, product: p };
}

/** Rank a list, optionally diversifying so the top results are not 5 near-identical items. */
function rankProducts(products, ctx = {}, { limit = 10, diversify = true } = {}) {
  const scored = products.map((p) => scoreProduct(p, ctx)).sort((a, b) => b.score - a.score);
  if (!diversify) return scored.slice(0, limit);
  // light MMR-style diversification on brand + type
  const out = [];
  const seen = {};
  const rest = [...scored];
  while (out.length < limit && rest.length) {
    let bestIdx = 0;
    let bestVal = -Infinity;
    for (let i = 0; i < Math.min(rest.length, 25); i++) {
      const key = `${rest[i].product.brand}|${rest[i].product._type}`;
      const penalty = (seen[key] || 0) * 0.04;
      const val = rest[i].score - penalty;
      if (val > bestVal) { bestVal = val; bestIdx = i; }
    }
    const [pick] = rest.splice(bestIdx, 1);
    const key = `${pick.product.brand}|${pick.product._type}`;
    seen[key] = (seen[key] || 0) + 1;
    out.push(pick);
  }
  return out;
}

/** Badges shown on product cards. */
function badgesFor(result, index, now = Date.now()) {
  const p = result.product;
  const badges = [];
  if (index === 0 && result.score >= 0.7) badges.push('Best Match');
  if (result.breakdown.trend >= 0.65) badges.push('Trending');
  if (tx.hasDiscount(p)) badges.push('Discount');
  const created = p.createdAt ? new Date(p.createdAt).getTime() : 0;
  if (created && now - created < 14 * 24 * 3600 * 1000) badges.push('New');
  return badges;
}

module.exports = {
  WEIGHTS,
  enrich,
  scoreProduct,
  rankProducts,
  badgesFor,
  topKey,
  label,
};
