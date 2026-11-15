/**
 * FINDME — Geolocation helpers (pure functions).
 *
 * - Haversine distance.
 * - Tunisian places (governorates + main cities) so the user can search "in Tunis"
 *   or pick a city manually when GPS is unavailable. These are city centres,
 *   never the user's own coordinates.
 * - Radius parsing ("within 10 km", "dans un rayon de 5 km").
 * - Product ↔ shop availability, with a VERIFIED flag when both sides of the
 *   relationship agree (product.shops lists the shop AND shop.products lists the product).
 */
const tx = require('./taxonomy');

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function validCoord(lat, lng) {
  const la = Number(lat);
  const lo = Number(lng);
  return Number.isFinite(la) && Number.isFinite(lo) && Math.abs(la) <= 90 && Math.abs(lo) <= 180 && !(la === 0 && lo === 0);
}

/** Governorates and main cities of Tunisia (city centres). */
const PLACES = [
  ['Tunis', 36.8065, 10.1815, ['tunis', 'tunes', 'centre ville']],
  ['Ariana', 36.8625, 10.1956, ['ariana', 'aryana']],
  ['Ben Arous', 36.7531, 10.2189, ['ben arous']],
  ['La Manouba', 36.8101, 10.0956, ['manouba', 'la manouba']],
  ['La Marsa', 36.8782, 10.3247, ['la marsa', 'marsa']],
  ['Lac', 36.8380, 10.2400, ['lac 1', 'lac 2', 'berges du lac', 'les berges du lac']],
  ['Nabeul', 36.4561, 10.7376, ['nabeul']],
  ['Hammamet', 36.4000, 10.6167, ['hammamet']],
  ['Zaghouan', 36.4029, 10.1429, ['zaghouan']],
  ['Bizerte', 37.2744, 9.8739, ['bizerte', 'binzart']],
  ['Béja', 36.7256, 9.1817, ['beja']],
  ['Jendouba', 36.5011, 8.7802, ['jendouba']],
  ['Le Kef', 36.1826, 8.7149, ['le kef', 'kef']],
  ['Siliana', 36.0849, 9.3708, ['siliana']],
  ['Sousse', 35.8256, 10.6084, ['sousse', 'soussa']],
  ['Hammam Sousse', 35.8608, 10.5947, ['hammam sousse']],
  ['Msaken', 35.7333, 10.5833, ['msaken']],
  ['Monastir', 35.7643, 10.8113, ['monastir']],
  ['Mahdia', 35.5047, 11.0622, ['mahdia']],
  ['Sfax', 34.7406, 10.7603, ['sfax', 'sfakes']],
  ['Kairouan', 35.6781, 10.0963, ['kairouan', 'qairawan']],
  ['Kasserine', 35.1676, 8.8365, ['kasserine']],
  ['Sidi Bouzid', 35.0382, 9.4858, ['sidi bouzid']],
  ['Gafsa', 34.4250, 8.7842, ['gafsa']],
  ['Tozeur', 33.9197, 8.1335, ['tozeur']],
  ['Kébili', 33.7044, 8.9690, ['kebili']],
  ['Gabès', 33.8815, 10.0982, ['gabes']],
  ['Médenine', 33.3549, 10.5055, ['medenine']],
  ['Djerba', 33.8756, 10.8575, ['djerba', 'jerba', 'houmt souk']],
  ['Zarzis', 33.5000, 11.1167, ['zarzis']],
  ['Tataouine', 32.9297, 10.4518, ['tataouine']],
].map(([name, lat, lng, words]) => ({ name, lat, lng, words }));

/**
 * Find a place mentioned in free text. Shops' own cities/regions are checked first,
 * so a shop city that is not in the static list still works.
 */
function detectPlace(text, shops = []) {
  const t = tx.normalize(text);
  if (!t) return null;
  // shop cities / regions (centre = mean of their coordinates)
  const byCity = {};
  for (const s of shops) {
    if (!s || !s.coordinates || !validCoord(s.coordinates.latitude, s.coordinates.longitude)) continue;
    for (const key of [s.city, s.region]) {
      if (!key) continue;
      const k = tx.normalize(key);
      (byCity[k] = byCity[k] || { name: key, pts: [] }).pts.push([s.coordinates.latitude, s.coordinates.longitude]);
    }
  }
  const cityKeys = Object.keys(byCity).sort((a, b) => b.length - a.length);
  for (const k of cityKeys) {
    if (k.length >= 3 && tx.hasWord(t, k)) {
      const pts = byCity[k].pts;
      return {
        name: byCity[k].name,
        lat: pts.reduce((s, p) => s + p[0], 0) / pts.length,
        lng: pts.reduce((s, p) => s + p[1], 0) / pts.length,
        source: 'place',
      };
    }
  }
  const sorted = [...PLACES].sort((a, b) => Math.max(...b.words.map((w) => w.length)) - Math.max(...a.words.map((w) => w.length)));
  for (const p of sorted) {
    if (p.words.some((w) => tx.hasWord(t, w))) return { name: p.name, lat: p.lat, lng: p.lng, source: 'place' };
  }
  return null;
}

/** "within 10 km", "dans un rayon de 5 km", "à moins de 3 km", "10km" */
function parseRadius(text) {
  const t = tx.normalize(text);
  const m = t.match(/(\d+(?:[.,]\d+)?)\s*(?:km|kilometres?|kilometers?|kms)\b/);
  if (!m) return null;
  const v = Number(m[1].replace(',', '.'));
  return v > 0 && v <= 1000 ? v : null;
}

/** Which ordinal product the user refers to: "the first one", "le deuxième", "this dress". */
function parseProductRef(text) {
  const t = tx.normalize(text);
  if (/\b(first|1st|premier|premiere|le 1er|la 1ere|loul|lowel)\b/.test(t)) return 0;
  if (/\b(second|2nd|deuxieme|2eme|seconde|thani)\b/.test(t)) return 1;
  if (/\b(third|3rd|troisieme|3eme|thaleth)\b/.test(t)) return 2;
  if (/\b(this|that|it|this one|that one|ce|cet|cette|celui|celle|ca|cela|le meme|la meme|same)\b/.test(t)) return 0;
  return null;
}

/**
 * Availability of a product in shops.
 * @returns [{ shop, verified, declaredBy: 'both'|'product'|'shop' }]
 */
function availability(product, shops) {
  const pid = String(product._id);
  const names = new Set((product.shops || []).map((n) => tx.normalize(n)));
  const out = [];
  for (const s of shops) {
    const inProduct = names.has(tx.normalize(s.name));
    const inShop = (s.products || []).some((id) => String(id) === pid);
    if (!inProduct && !inShop) continue;
    out.push({ shop: s, verified: inProduct && inShop, declaredBy: inProduct && inShop ? 'both' : inProduct ? 'product' : 'shop' });
  }
  return out;
}

function shopCard(shop, origin) {
  const c = shop.coordinates || {};
  const hasCoords = validCoord(c.latitude, c.longitude);
  const d = origin && hasCoords ? haversineKm(origin.lat, origin.lng, c.latitude, c.longitude) : null;
  return {
    _id: String(shop._id),
    name: shop.name,
    city: shop.city || '',
    region: shop.region || '',
    coordinates: hasCoords ? { latitude: Number(c.latitude), longitude: Number(c.longitude) } : null,
    distanceKm: d == null ? null : Number(d.toFixed(2)),
  };
}

module.exports = { haversineKm, validCoord, PLACES, detectPlace, parseRadius, parseProductRef, availability, shopCard };
