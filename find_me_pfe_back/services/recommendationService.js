/**
 * FINDME — Recommendation engine.
 *
 * Modules (see the PFE plan):
 *   1. Personalized "For You"        → forYou()
 *   2. Similar Product Finder        → similar()
 *   3. Smart Budget Recommendations  → budgetPicks()
 *   4. Trending Products (time window) → trending()
 *   5. Complete the Look             → completeTheLook()
 *   + search() used by the AI Stylist (hard filters + progressive relaxation + ranking)
 *   + discover(), nearbyShops(), explain(), home(), styleDna()
 */
const tx = require('./taxonomy');
const { enrich, scoreProduct, rankProducts, badgesFor } = require('./scoring');
const { computeStyleDna } = require('./styleDna');
const { emptyCriteria } = require('./criteriaParser');
const geo = require('./geoService');

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function cosineStyles(a, b) {
  let dot = 0; let na = 0; let nb = 0;
  for (const s of tx.STYLE_KEYS) {
    dot += (a[s] || 0) * (b[s] || 0);
    na += (a[s] || 0) ** 2;
    nb += (b[s] || 0) ** 2;
  }
  return na && nb ? dot / Math.sqrt(na * nb) : 0.5;
}

/** Public JSON shape of a product (keeps every original field so old Flutter models still parse). */
function toCard(result, index = 0, favoriteIds = new Set(), now = Date.now()) {
  const p = result.product || result;
  const out = {};
  for (const [k, v] of Object.entries(p)) if (!k.startsWith('_') || k === '_id' || k === '__v') out[k] = v;
  out._id = String(p._id);
  out.isFavorite = favoriteIds.has(String(p._id));
  out.type = p._type;
  out.gender = p._gender;
  out.effectivePrice = p._price;
  out.styleVector = p._styles;
  if (result.breakdown) {
    out.score = result.score;
    out.matchPercent = result.matchPercent;
    out.breakdown = result.breakdown;
    out.reasons = result.reasons;
    out.badges = badgesFor(result, index, now);
  } else {
    out.badges = [];
    out.reasons = [];
  }
  return out;
}

function createRecommendationService({ repo, now = () => Date.now() } = {}) {
  if (!repo) repo = require('./catalogRepository');

  async function catalog() {
    const raw = await repo.getAllProducts();
    const t = now();
    return raw.map((p) => enrich(p, t));
  }

  async function trendStats(products) {
    let recentCounts = {};
    try { recentCounts = await repo.getRecentProductCounts(14); } catch (_) { recentCounts = {}; }
    return {
      maxSearched: Math.max(1, ...products.map((p) => Number(p.searched) || 0)),
      recentCounts,
      maxRecent: Math.max(1, ...Object.values(recentCounts)),
    };
  }

  /** Everything we know about a user, computed once per request. */
  async function userContext(userId, products) {
    if (!userId) return { profile: null, dna: null, favoriteIds: new Set(), disliked: new Set() };
    const [favIds, interactions, prefs, disliked] = await Promise.all([
      repo.getUserFavorites(userId).catch(() => []),
      repo.getInteractions(userId).catch(() => []),
      repo.getPreferences(userId).catch(() => null),
      repo.getDislikedProductIds(userId).catch(() => []),
    ]);
    const byId = new Map(products.map((p) => [String(p._id), p]));
    const favorites = favIds.map((id) => byId.get(String(id))).filter(Boolean);
    const inter = interactions.map((it) => ({ ...it, product: it.product ? byId.get(String(it.product)) : null }));
    const dna = computeStyleDna({ favorites, interactions: inter, preferences: prefs }, now());
    return { profile: dna.profile, dna, favoriteIds: new Set(favIds.map(String)), disliked: new Set(disliked), preferences: prefs };
  }

  // ---------------------------------------------------------------------------
  // Hard filters used by the stylist search
  // ---------------------------------------------------------------------------
  function passes(p, c) {
    if (c.types.length && !c.types.includes(p._type)) return false;
    if (c._typeGroups && c._typeGroups.length && !c._typeGroups.includes(p._group)) return false;
    if (c.gender && p._gender && p._gender !== c.gender) return false;
    if (c.colors.length && !c.colors.some((col) => p._colors.includes(col))) return false;
    if (c.excludeColors.length && p._colors.length && p._colors.every((col) => c.excludeColors.includes(col))) return false;
    if (c.maxPrice && p._price > c.maxPrice) return false;
    if (c.minPrice && p._price < c.minPrice) return false;
    if (c.sizes.length && (p.size || []).length) {
      const sizes = p.size.map((s) => String(s).toUpperCase());
      if (!c.sizes.some((s) => sizes.includes(s))) return false;
    }
    if (c.brands.length && !c.brands.some((b) => tx.normalize(b) === tx.normalize(p.brand))) return false;
    return true;
  }

  const RELAX_STEPS = [
    ['sizes', (c) => ({ ...c, sizes: [] })],
    ['brands', (c) => ({ ...c, brands: [] })],
    ['colors', (c) => ({ ...c, colors: [] })],
    ['budget', (c) => ({ ...c, maxPrice: c.maxPrice ? Math.round(c.maxPrice * 1.25) : null, minPrice: null })],
    ['types', (c) => ({ ...c, _typeGroups: [...new Set(c.types.map(tx.typeGroup))], types: [] })],
  ];

  /**
   * Search used by the AI stylist and visual search.
   * @returns {{ products:Card[], relaxed:string[], total:number, criteriaUsed:object }}
   */
  async function search(criteria, { userId, lang = 'en', limit = 6, excludeIds = [], minResults = 3, relax = true, keep = [], ctx: givenCtx } = {}) {
    const products = await catalog();
    const ctx = givenCtx || (await userContext(userId, products));
    const stats = await trendStats(products);
    const base = { ...emptyCriteria(), ...criteria };
    const exclude = new Set(excludeIds.map(String));

    const pool = products.filter((p) => !ctx.disliked.has(String(p._id)));
    const exact = pool.filter((p) => passes(p, base));
    let freshExact = exact.filter((p) => !exclude.has(String(p._id)));
    const exhausted = freshExact.length === 0 && exact.length > 0;

    // Not enough exact matches → look for close alternatives by relaxing criteria one by one.
    let c = base;
    let extras = [];
    let relaxed = [];
    if (relax && freshExact.length < minResults) {
      const exactIds = new Set(exact.map((p) => String(p._id)));
      for (const [field, fn] of RELAX_STEPS) {
        if (field === 'types' && freshExact.length > 0) break; // never change the item type if we have exact matches
        if (keep.includes(field)) continue; // e.g. "cheaper" must never relax the budget
        const active = field === 'budget' ? (c.maxPrice || c.minPrice) : (c[field] && c[field].length);
        if (!active) continue;
        c = fn(c);
        relaxed.push(field);
        extras = pool.filter((p) => passes(p, c) && !exactIds.has(String(p._id)) && !exclude.has(String(p._id)));
        if (freshExact.length + extras.length >= minResults) break;
      }
      if (!extras.length) relaxed = [];
    }
    if (exhausted && !extras.length) freshExact = exact; // everything was already shown: show again rather than nothing

    // rank with the ORIGINAL criteria so alternatives are still ordered by closeness
    const rankCtx = { criteria: base, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, now: now() };
    const rankedExact = rankProducts(freshExact, rankCtx, { limit });
    const rankedExtras = rankProducts(extras, rankCtx, { limit: Math.max(0, limit - rankedExact.length) });
    const cards = [
      ...rankedExact.map((r, i) => toCard(r, i, ctx.favoriteIds, now())),
      ...rankedExtras.map((r, i) => ({ ...toCard(r, rankedExact.length + i + 1, ctx.favoriteIds, now()), alternative: true })),
    ];
    return {
      products: cards,
      exactCount: rankedExact.length,
      alternativeCount: rankedExtras.length,
      relaxed: rankedExtras.length ? relaxed : [],
      total: exact.length,
      exhausted: exhausted && !extras.length,
      criteriaUsed: c,
    };
  }

  async function forYou(userId, { limit = 10, lang = 'en', ctx: givenCtx, products: given } = {}) {
    const products = given || (await catalog());
    const ctx = givenCtx || (await userContext(userId, products));
    const stats = await trendStats(products);
    let pool = products.filter((p) => !ctx.disliked.has(String(p._id)));
    const notFav = pool.filter((p) => !ctx.favoriteIds.has(String(p._id)));
    if (notFav.length >= limit) pool = notFav;
    const coldStart = !ctx.profile;
    const weights = coldStart ? { category: 0.1, style: 0.1, budget: 0.1, preference: 0.1, rating: 0.3, trend: 0.3 } : undefined;
    const ranked = rankProducts(pool, { criteria: {}, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, weights, now: now() }, { limit });
    return { coldStart, products: ranked.map((r, i) => toCard(r, i, ctx.favoriteIds, now())) };
  }

  async function similar(productId, { userId, limit = 8, lang = 'en' } = {}) {
    const products = await catalog();
    const anchor = products.find((p) => String(p._id) === String(productId));
    if (!anchor) return null;
    const ctx = await userContext(userId, products);
    const stats = await trendStats(products);
    const topStyles = Object.entries(anchor._styles).sort((a, b) => b[1] - a[1]).slice(0, 2).map(([s]) => s);
    const criteria = { types: anchor._type !== 'other' ? [anchor._type] : [], colors: anchor._colors.slice(0, 2), styles: topStyles, gender: anchor._gender, maxPrice: Math.round(anchor._price * 1.3) };
    const pool = products.filter((p) => String(p._id) !== String(anchor._id) && p._group === anchor._group && (!anchor._gender || !p._gender || p._gender === anchor._gender));
    const ranked = pool.map((p) => {
      const r = scoreProduct(p, { criteria, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, now: now() });
      // add a direct similarity term (style cosine + price proximity + same brand)
      const priceProx = 1 - Math.min(1, Math.abs(p._price - anchor._price) / Math.max(anchor._price, 1));
      const sim = 0.5 * cosineStyles(anchor._styles, p._styles) + 0.3 * priceProx + 0.2 * (p.brand === anchor.brand ? 1 : 0);
      r.score = Number((0.6 * r.score + 0.4 * sim).toFixed(4));
      r.matchPercent = Math.round(r.score * 100);
      return r;
    }).sort((a, b) => b.score - a.score).slice(0, limit);
    return { anchor: toCard({ product: anchor }, 0, ctx.favoriteIds), products: ranked.map((r, i) => toCard(r, i + 1, ctx.favoriteIds, now())) };
  }

  async function trending({ days = 14, limit = 10, userId, lang = 'en', products: given, ctx: givenCtx } = {}) {
    const products = given || (await catalog());
    let recent = {};
    try { recent = await repo.getRecentProductCounts(days); } catch (_) { recent = {}; }
    const favoriteIds = givenCtx ? givenCtx.favoriteIds : new Set(userId ? await repo.getUserFavorites(userId).catch(() => []) : []);
    const maxRecent = Math.max(1, ...Object.values(recent));
    const maxSearched = Math.max(1, ...products.map((p) => Number(p.searched) || 0));
    const ranked = products.map((p) => {
      const r = Math.log1p(recent[String(p._id)] || 0) / Math.log1p(maxRecent);
      const s = Math.log1p(Number(p.searched) || 0) / Math.log1p(maxSearched);
      const rating = (Number(p.rating) || 0) / 5;
      const trendScore = 0.5 * r + 0.3 * s + 0.2 * rating;
      return { product: p, score: trendScore, trendScore, recentInteractions: recent[String(p._id)] || 0 };
    }).sort((a, b) => b.score - a.score).slice(0, limit);
    return {
      windowDays: days,
      products: ranked.map((r, i) => ({
        ...toCard({ product: r.product }, i, favoriteIds),
        trendScore: Number(r.trendScore.toFixed(3)),
        recentInteractions: r.recentInteractions,
        badges: ['Trending', ...(tx.hasDiscount(r.product) ? ['Discount'] : [])],
        reasons: [{ code: 'trending', label: lang === 'fr' ? `Populaire ces ${days} derniers jours` : `Popular over the last ${days} days` }],
      })),
    };
  }

  async function budgetPicks({ max, types = [], userId, limit = 10, lang = 'en', ctx: givenCtx, products: given } = {}) {
    const products = given || (await catalog());
    const ctx = givenCtx || (await userContext(userId, products));
    const stats = await trendStats(products);
    const criteria = { ...emptyCriteria(), maxPrice: Number(max), types };
    const pool = products.filter((p) => passes(p, criteria) && !ctx.disliked.has(String(p._id)));
    const ranked = pool.map((p) => {
      const r = scoreProduct(p, { criteria, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, now: now() });
      const value = tx.hasDiscount(p) ? 0.1 : 0;
      r.score = Number(Math.min(1, r.score + value).toFixed(4));
      r.matchPercent = Math.round(r.score * 100);
      return r;
    }).sort((a, b) => b.score - a.score).slice(0, limit);
    return { max: Number(max), products: ranked.map((r, i) => toCard(r, i, ctx.favoriteIds, now())) };
  }

  async function completeTheLook(productId, { userId, lang = 'en', alternatives = 2 } = {}) {
    const products = await catalog();
    const anchor = products.find((p) => String(p._id) === String(productId));
    if (!anchor) return null;
    const ctx = await userContext(userId, products);
    const rules = tx.OUTFIT_RULES[anchor._type] || tx.OUTFIT_RULES.other;
    const used = new Set([String(anchor._id)]);
    const items = [];
    for (const rule of rules) {
      const cands = products.filter((p) => !used.has(String(p._id)) && rule.types.includes(p._type)
        && (!anchor._gender || !p._gender || p._gender === anchor._gender || p._gender === null) && !ctx.disliked.has(String(p._id)));
      if (!cands.length) continue;
      const scored = cands.map((p) => {
        const harmony = tx.colorHarmony(anchor._colors, p._colors);
        const styleFit = cosineStyles(anchor._styles, p._styles);
        const pref = ctx.profile ? scoreProduct(p, { criteria: {}, profile: ctx.profile, favoriteIds: ctx.favoriteIds, lang }).breakdown.preference : 0.5;
        const score = 0.45 * harmony + 0.35 * styleFit + 0.2 * pref;
        const reasons = [];
        if (harmony >= 0.8) reasons.push({ code: 'color_harmony', label: lang === 'fr' ? 'Couleurs harmonieuses' : 'Colours go well together' });
        if (styleFit >= 0.6) reasons.push({ code: 'style_harmony', label: lang === 'fr' ? 'Même univers de style' : 'Same style universe' });
        return { product: p, score: Number(score.toFixed(4)), matchPercent: Math.round(score * 100), reasons, breakdown: { harmony, styleFit, preference: pref } };
      }).sort((a, b) => b.score - a.score);
      const [best, ...rest] = scored;
      used.add(String(best.product._id));
      items.push({
        slot: rule.slot,
        product: { ...toCard({ product: best.product }, 0, ctx.favoriteIds), matchPercent: best.matchPercent, reasons: best.reasons },
        alternatives: rest.slice(0, alternatives).map((r) => ({ ...toCard({ product: r.product }, 0, ctx.favoriteIds), matchPercent: r.matchPercent, reasons: r.reasons })),
      });
    }
    const totalPrice = items.reduce((s, it) => s + it.product.effectivePrice, anchor._price);
    return { anchor: toCard({ product: anchor }, 0, ctx.favoriteIds), items, totalPrice: Math.round(totalPrice * 100) / 100 };
  }

  const SORTS = {
    match: (a, b) => b.score - a.score,
    price_asc: (a, b) => a.product._price - b.product._price,
    price_desc: (a, b) => b.product._price - a.product._price,
    rating: (a, b) => (Number(b.product.rating) || 0) - (Number(a.product.rating) || 0),
    new: (a, b) => new Date(b.product.createdAt || 0) - new Date(a.product.createdAt || 0),
    popular: (a, b) => (Number(b.product.searched) || 0) - (Number(a.product.searched) || 0),
  };

  async function discover({ userId, filters = {}, sort = 'match', page = 1, limit = 20, lang = 'en' } = {}) {
    const products = await catalog();
    const ctx = await userContext(userId, products);
    const stats = await trendStats(products);
    const criteria = { ...emptyCriteria(), ...filters };
    let pool = products.filter((p) => passes(p, criteria) && !ctx.disliked.has(String(p._id)));
    if (filters.query) {
      const q = tx.normalize(filters.query);
      pool = pool.filter((p) => tx.normalize(`${p.name} ${p.brand} ${p.description} ${(p.category || []).join(' ')}`).includes(q));
    }
    const scored = pool.map((p) => scoreProduct(p, { criteria, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, now: now() }));
    scored.sort(SORTS[sort] || SORTS.match);
    const start = (Math.max(1, page) - 1) * limit;
    return {
      total: scored.length,
      page: Math.max(1, page),
      hasMore: start + limit < scored.length,
      products: scored.slice(start, start + limit).map((r, i) => toCard(r, start + i, ctx.favoriteIds, now())),
    };
  }

  async function allShops() {
    if (repo.getAllShops) return repo.getAllShops();
    return repo.getShopsByNames ? repo.getShopsByNames([]) : [];
  }

  /** Shops selling one product, verified or declared, nearest first. */
  async function nearbyShops(productId, { lat, lng, radiusKm = null } = {}) {
    const product = await repo.getProductById(productId);
    if (!product) return null;
    const origin = geo.validCoord(lat, lng) ? { lat: Number(lat), lng: Number(lng) } : null;
    const shops = await allShops();
    let out = geo.availability(product, shops).map((a) => ({ ...geo.shopCard(a.shop, origin), verified: a.verified }));
    if (origin) {
      out.sort((a, b) => (a.distanceKm == null ? 1e9 : a.distanceKm) - (b.distanceKm == null ? 1e9 : b.distanceKm));
      if (radiusKm) out = out.filter((s) => s.distanceKm != null && s.distanceKm <= radiusKm);
    }
    return { productId: String(product._id), productName: product.name, shops: out };
  }

  /**
   * Geolocated product search: real product↔shop relations, Haversine distance,
   * radius filter, ranking by distance then relevance.
   * @param opts { criteria, productIds, origin:{lat,lng,label,source}, radiusKm, userId, lang, limit }
   */
  async function nearbyProducts({ criteria = {}, productIds = null, origin = null, radiusKm = 25, userId, lang = 'en', limit = 6 } = {}) {
    const products = await catalog();
    const ctx = await userContext(userId, products);
    const shops = await allShops();
    const hasOrigin = origin && geo.validCoord(origin.lat, origin.lng);
    const o = hasOrigin ? { lat: Number(origin.lat), lng: Number(origin.lng) } : null;

    // 1. candidate products (catalogue search, or the products the user is talking about)
    let candidates;
    if (productIds && productIds.length) {
      const set = new Set(productIds.map(String));
      const base = { ...emptyCriteria(), ...criteria };
      candidates = products.filter((p) => set.has(String(p._id)))
        .map((p) => scoreProduct(p, { criteria: base, profile: ctx.profile, favoriteIds: ctx.favoriteIds, lang, now: now() }));
      // follow-up filters ("what about size M?") apply to the same products
      if (base.sizes.length) candidates = candidates.filter((r) => !(r.product.size || []).length || base.sizes.some((sz) => r.product.size.map((x) => String(x).toUpperCase()).includes(sz)));
      if (base.maxPrice) candidates = candidates.filter((r) => r.product._price <= base.maxPrice);
      if (base.colors.length) candidates = candidates.filter((r) => base.colors.some((c) => r.product._colors.includes(c)));
    } else {
      const base = { ...emptyCriteria(), ...criteria };
      const pool = products.filter((p) => passes(p, base) && !ctx.disliked.has(String(p._id)));
      const stats = await trendStats(products);
      candidates = rankProducts(pool, { criteria: base, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, now: now() }, { limit: 40, diversify: false });
    }

    // 2. store availability + distance
    let withoutStores = 0;
    let missingCoords = 0;
    let nearestOutside = null;
    const results = [];
    for (const r of candidates) {
      const avail = geo.availability(r.product, shops);
      if (!avail.length) { withoutStores += 1; continue; }
      let stores = avail.map((a) => ({ ...geo.shopCard(a.shop, o), verified: a.verified }));
      missingCoords += stores.filter((s) => !s.coordinates).length;
      stores = stores.filter((s) => s.coordinates);
      if (o) {
        stores.sort((a, b) => a.distanceKm - b.distanceKm);
        const inside = stores.filter((s) => s.distanceKm <= radiusKm);
        if (!inside.length) {
          const best = stores[0];
          if (best && (!nearestOutside || best.distanceKm < nearestOutside.distanceKm)) nearestOutside = { shop: best.name, city: best.city, distanceKm: best.distanceKm, product: r.product.name };
          continue;
        }
        stores = inside;
      }
      if (!stores.length) continue;
      results.push({ r, stores });
    }
    results.sort((a, b) => (o ? a.stores[0].distanceKm - b.stores[0].distanceKm : 0) || b.r.score - a.r.score);
    const top = results.slice(0, limit);

    // 3. unique stores for the map, with how many of the results they sell
    const storeMap = new Map();
    top.forEach(({ r, stores }) => stores.forEach((s) => {
      const cur = storeMap.get(s._id) || { ...s, productIds: [], verified: false };
      cur.productIds.push(String(r.product._id));
      cur.verified = cur.verified || s.verified;
      storeMap.set(s._id, cur);
    }));
    const mapStores = [...storeMap.values()].sort((a, b) => (a.distanceKm == null ? 0 : a.distanceKm) - (b.distanceKm == null ? 0 : b.distanceKm));

    return {
      origin: hasOrigin ? { lat: o.lat, lng: o.lng, label: origin.label || null, source: origin.source || 'gps' } : null,
      needsLocation: !hasOrigin,
      radiusKm,
      results: top.map(({ r, stores }, i) => ({ product: toCard(r, i, ctx.favoriteIds, now()), stores })),
      stores: mapStores,
      totalCandidates: candidates.length,
      withoutStores,
      missingCoords,
      nearestOutside: top.length ? null : nearestOutside,
    };
  }

  async function explain(productId, { userId, lang = 'en', criteria = {} } = {}) {
    const products = await catalog();
    const p = products.find((x) => String(x._id) === String(productId));
    if (!p) return null;
    const ctx = await userContext(userId, products);
    const stats = await trendStats(products);
    const r = scoreProduct(p, { criteria, profile: ctx.profile, stats, favoriteIds: ctx.favoriteIds, lang, now: now() });
    return { productId: String(p._id), score: r.score, matchPercent: r.matchPercent, breakdown: r.breakdown, reasons: r.reasons, weights: require('./scoring').WEIGHTS, persona: ctx.dna ? ctx.dna.persona : null };
  }

  async function styleDna(userId) {
    const products = await catalog();
    const ctx = await userContext(userId, products);
    const dna = ctx.dna || computeStyleDna({});
    const { profile, ...publicDna } = dna;
    return { ...publicDna, hasQuiz: !!(ctx.preferences && ctx.preferences.quizCompletedAt), preferences: ctx.preferences || null };
  }

  /** One call for the Smart Home screen. */
  async function home(userId, { lang = 'en' } = {}) {
    const products = await catalog();
    const ctx = await userContext(userId, products);
    const budgetMax = (ctx.dna && ctx.dna.budget && ctx.dna.budget.max) || 100;
    const [fy, tr, bp] = await Promise.all([
      forYou(userId, { limit: 10, lang, ctx, products }),
      trending({ limit: 10, lang, ctx, products }),
      budgetPicks({ max: budgetMax, limit: 10, lang, ctx, products }),
    ]);
    const deals = products.filter((p) => tx.hasDiscount(p))
      .sort((a, b) => (1 - b._price / b.price) - (1 - a._price / a.price)).slice(0, 10)
      .map((p) => toCard({ product: p }, 0, ctx.favoriteIds));
    deals.forEach((d) => { d.badges = ['Discount']; });
    const newIn = [...products].sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0)).slice(0, 10)
      .map((p) => toCard({ product: p }, 0, ctx.favoriteIds));
    return {
      styleDna: ctx.dna ? { persona: ctx.dna.persona, topStyles: ctx.dna.topStyles, confidence: ctx.dna.confidence } : null,
      forYou: fy,
      trending: tr.products,
      budget: { max: budgetMax, products: bp.products },
      deals,
      newIn,
    };
  }

  return { search, forYou, similar, trending, budgetPicks, completeTheLook, discover, nearbyShops, nearbyProducts, explain, styleDna, home, userContext, toCard, haversineKm };
}

module.exports = { createRecommendationService, toCard, haversineKm };
