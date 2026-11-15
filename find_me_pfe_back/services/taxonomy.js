/**
 * FINDME — Fashion taxonomy (pure functions, no DB access).
 *
 * The product schema stores brand / category / shops as plain strings and has no
 * "type" field (dress, shirt, shoes…). This module infers product type, gender,
 * style vector and colour family from the existing fields, so the recommendation
 * engine and the AI stylist work on the current MongoDB data without migration.
 */

// ---------------------------------------------------------------------------
// Text helpers
// ---------------------------------------------------------------------------
function normalize(text) {
  return String(text || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '') // strip accents (é -> e)
    .replace(/[’']/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** true if `keyword` appears in `text` as a whole word/phrase (text must be normalized). */
function hasWord(text, keyword) {
  const k = escapeRegex(normalize(keyword));
  return new RegExp(`(^|[^a-z0-9])${k}([^a-z0-9]|$)`).test(text);
}

// ---------------------------------------------------------------------------
// Product types
// ---------------------------------------------------------------------------
const TYPES = {
  dress: { group: 'onepiece', keywords: ['dress', 'dresses', 'robe', 'robes', 'gown', 'jumpsuit', 'combinaison'] },
  skirt: { group: 'bottom', keywords: ['skirt', 'skirts', 'jupe', 'jupes'] },
  shirt: { group: 'top', keywords: ['shirt', 'shirts', 'chemise', 'chemises', 'blouse', 'blouses', 'polo'] },
  tshirt: { group: 'top', keywords: ['t-shirt', 't-shirts', 'tshirt', 'tshirts', 't shirt', 'tee', 'top', 'tops', 'debardeur', 'tank top', 'crop top'] },
  jacket: { group: 'outer', keywords: ['jacket', 'jackets', 'veste', 'vestes', 'blazer', 'blazers', 'coat', 'manteau', 'hoodie', 'sweat', 'sweatshirt', 'pull', 'sweater', 'cardigan', 'gilet', 'trench'] },
  pants: { group: 'bottom', keywords: ['pants', 'pant', 'pantalon', 'pantalons', 'trousers', 'chino', 'chinos', 'jogger', 'joggers', 'cargo'] },
  jeans: { group: 'bottom', keywords: ['jeans', 'jean', 'denim'] },
  shorts: { group: 'bottom', keywords: ['shorts', 'short', 'bermuda'] },
  sportswear: { group: 'sport', keywords: ['sportswear', 'sportwear', 'sport wear', 'tracksuit', 'survetement', 'legging', 'leggings', 'jogging', 'activewear', 'brassiere de sport'] },
  shoes: { group: 'footwear', keywords: ['shoes', 'shoe', 'chaussure', 'chaussures', 'sneakers', 'sneaker', 'baskets', 'basket', 'heels', 'talons', 'escarpins', 'sandals', 'sandales', 'boots', 'bottes', 'bottines', 'mocassins', 'loafers', 'ballerines', 'trainers', 'pointure'] },
  bag: { group: 'bag', keywords: ['bag', 'bags', 'sac', 'sacs', 'handbag', 'pochette', 'clutch', 'backpack', 'sac a dos', 'tote'] },
  necklace: { group: 'jewelry', keywords: ['necklace', 'necklaces', 'collier', 'colliers', 'pendant', 'pendentif', 'chain', 'chaine'] },
  bracelet: { group: 'jewelry', keywords: ['bracelet', 'bracelets', 'bangle', 'jonc'] },
  ring: { group: 'jewelry', keywords: ['ring', 'rings', 'bague', 'bagues'] },
  earrings: { group: 'jewelry', keywords: ['earrings', 'earring', 'boucles d\'oreilles', 'boucle d\'oreille', 'boucles'] },
  watch: { group: 'jewelry', keywords: ['watch', 'watches', 'montre', 'montres'] },
  accessory: { group: 'accessory', keywords: ['accessory', 'accessories', 'accessoire', 'accessoires', 'belt', 'ceinture', 'scarf', 'foulard', 'echarpe', 'sunglasses', 'lunettes', 'hat', 'chapeau', 'cap', 'casquette', 'wallet', 'portefeuille'] },
  cosmetics: { group: 'beauty', keywords: ['cosmetics', 'cosmetic', 'cosmetique', 'cosmetiques', 'perfume', 'parfum', 'lipstick', 'rouge a levres', 'makeup', 'maquillage', 'mascara', 'lotion', 'moisturizer', 'soin'] },
};
const TYPE_KEYS = Object.keys(TYPES);

const JEWELRY_TYPES = ['necklace', 'bracelet', 'ring', 'earrings', 'watch'];
const TOP_TYPES = ['shirt', 'tshirt'];
const BOTTOM_TYPES = ['pants', 'jeans', 'shorts', 'skirt'];

/** Find every product type mentioned in a piece of free text. */
function detectTypes(text) {
  // "montre-moi", "montre plus", "tu me montres" are the verb "to show", not a watch
  const t = normalize(text)
    .replace(/\bmontres?[- ]?(moi|nous|plus|d'autres|encore|les|des|ce|ca|toi|un|une)\b/g, ' ')
    .replace(/\b(me|nous|tu|peux|peut|pourrais) (me )?montres?\b/g, ' ');
  const found = [];
  for (const key of TYPE_KEYS) {
    if (TYPES[key].keywords.some((k) => hasWord(t, k))) found.push(key);
  }
  // "t-shirt" also contains the word "shirt": only keep "shirt" if it appears on its own.
  if (found.includes('shirt')) {
    const stripped = t.replace(/t[- ]?shirts?/g, ' ');
    if (!TYPES.shirt.keywords.some((k) => hasWord(stripped, k))) found.splice(found.indexOf('shirt'), 1);
  }
  // "short" in "short dress" / "robe courte" is an adjective
  if (found.includes('shorts') && (found.includes('dress') || found.includes('skirt'))) found.splice(found.indexOf('shorts'), 1);
  return found;
}

/** Infer the single best type of a product from its name, then description, then categories. */
function inferType(product) {
  const fromName = detectTypes(product.name);
  if (fromName.length) return fromName[0];
  const fromCat = detectTypes((product.category || []).join(' '));
  const fromDesc = detectTypes(product.description);
  if (fromDesc.length) return fromDesc[0];
  if (fromCat.length) return fromCat[0];
  const cat = normalize((product.category || []).join(' '));
  if (/jewel|bijou/.test(cat)) return 'necklace';
  if (/sport/.test(cat)) return 'sportswear';
  return 'other';
}

function typeGroup(type) {
  return (TYPES[type] && TYPES[type].group) || 'other';
}

// ---------------------------------------------------------------------------
// Gender (from categories such as "Men", "Women", "Kids")
// ---------------------------------------------------------------------------
const GENDER_WORDS = {
  women: ['women', 'woman', 'femme', 'femmes', 'female', 'ladies', 'girl', 'girls', 'fille', 'filles', 'her'],
  men: ['men', 'man', 'homme', 'hommes', 'male', 'boy', 'boys', 'garcon', 'garcons', 'him'],
  kids: ['kids', 'kid', 'enfant', 'enfants', 'child', 'children', 'baby', 'bebe'],
};

function detectGender(text) {
  const t = normalize(text);
  for (const g of ['kids', 'women', 'men']) {
    if (GENDER_WORDS[g].some((w) => hasWord(t, w))) return g;
  }
  return null;
}

function inferGender(product) {
  return detectGender((product.category || []).join(' ')) || detectGender(product.name) || null;
}

// ---------------------------------------------------------------------------
// Colours (catalogue colours are stored in English, e.g. "black", "light blue")
// ---------------------------------------------------------------------------
const COLORS = {
  black: ['black', 'noir', 'noire', 'noirs', 'noires', 'ak7el', 'k7al'],
  white: ['white', 'blanc', 'blanche', 'blancs', 'blanches', 'abyedh', 'byadh'],
  grey: ['grey', 'gray', 'gris', 'grise', 'grises', 'anthracite'],
  cream: ['cream', 'creme', 'ivory', 'ivoire', 'ecru'],
  beige: ['beige', 'beiges', 'nude', 'sable', 'camel', 'taupe'],
  brown: ['brown', 'marron', 'brun', 'brune', 'chocolat', 'cognac'],
  red: ['red', 'rouge', 'rouges', 'bordeaux', 'burgundy', 'ahmar', 'a7mer'],
  pink: ['pink', 'rose', 'roses', 'fuchsia', 'blush'],
  blue: ['blue', 'bleu', 'bleue', 'bleus', 'bleues', 'navy', 'marine', 'azraq', 'zra9'],
  'light blue': ['light blue', 'bleu clair', 'sky blue', 'bleu ciel', 'baby blue'],
  green: ['green', 'vert', 'verte', 'verts', 'vertes', 'khaki', 'kaki', 'olive', 'akhdhar'],
  yellow: ['yellow', 'jaune', 'jaunes', 'moutarde', 'mustard'],
  orange: ['orange', 'oranges', 'corail', 'coral'],
  purple: ['purple', 'violet', 'violette', 'mauve', 'lilas', 'lilac', 'lavande', 'lavender'],
  gold: ['gold', 'golden', 'dore', 'doree', 'or'],
  silver: ['silver', 'argent', 'argente', 'argentee'],
  bronze: ['bronze', 'cuivre', 'copper'],
};
const COLOR_KEYS = Object.keys(COLORS);
const NEUTRAL_COLORS = ['black', 'white', 'grey', 'cream', 'beige', 'brown', 'silver', 'gold'];

/** Map any colour word (EN/FR/Darija) to its canonical English name, or null. */
function canonicalColor(word) {
  const w = normalize(word);
  if (COLORS[w]) return w;
  for (const key of COLOR_KEYS) {
    if (COLORS[key].some((k) => normalize(k) === w)) return key;
  }
  return null;
}

/** Find colours mentioned in free text. "bleu clair" wins over "bleu". */
function detectColors(text) {
  let t = normalize(text);
  const found = [];
  // check multi-word colours first and remove them from the text
  const ordered = [...COLOR_KEYS].sort((a, b) => b.length - a.length);
  for (const key of ordered) {
    const words = [...COLORS[key]].sort((a, b) => b.length - a.length);
    for (const k of words) {
      if (key === 'gold' && k === 'or') continue; // "or" is too ambiguous in French
      if (hasWord(t, k)) {
        if (!found.includes(key)) found.push(key);
        t = t.replace(new RegExp(escapeRegex(normalize(k)), 'g'), ' ');
      }
    }
  }
  return found;
}

function productColors(product) {
  return (product.colors || []).map((c) => canonicalColor(c) || normalize(c));
}

/** Outfit colour harmony between two colour lists (0..1). */
function colorHarmony(colorsA, colorsB) {
  if (!colorsA.length || !colorsB.length) return 0.6;
  let best = 0;
  for (const a of colorsA) {
    for (const b of colorsB) {
      let s;
      if (NEUTRAL_COLORS.includes(a) || NEUTRAL_COLORS.includes(b)) s = 1;
      else if (a === b) s = 0.8;
      else if ((a === 'blue' && b === 'light blue') || (a === 'light blue' && b === 'blue')) s = 0.85;
      else s = 0.45;
      best = Math.max(best, s);
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------
const STYLE_KEYS = ['minimalist', 'elegant', 'casual', 'sporty', 'trendy'];

const STYLE_WORDS = {
  minimalist: ['minimalist', 'minimaliste', 'minimal', 'simple', 'sobre', 'basic', 'basique', 'clean', 'epure', 'neutral', 'neutre'],
  elegant: ['elegant', 'elegante', 'classy', 'classe', 'chic', 'classic', 'classique', 'sophisticated', 'sophistique', 'formal', 'habille', 'luxe', 'luxury', 'glamour', 'raffine'],
  casual: ['casual', 'decontracte', 'decontractee', 'relax', 'cool', 'everyday', 'quotidien', 'confortable', 'comfortable', 'comfy'],
  sporty: ['sporty', 'sport', 'sportif', 'sportive', 'athletic', 'athleisure', 'gym', 'running', 'fitness', 'training'],
  trendy: ['trendy', 'tendance', 'modern', 'moderne', 'fashion', 'stylish', 'branche', 'streetwear', 'street', 'oversize', 'audacieux', 'bold', 'original'],
};

const OCCASIONS = {
  party: { words: ['party', 'soiree', 'fete', 'birthday', 'anniversaire', 'cocktail', 'night out', 'club', 'gala', 'prom', 'bal'], styles: ['elegant', 'trendy'] },
  wedding: { words: ['wedding', 'mariage', 'fiancailles', 'engagement', 'henna', 'outia', 'ceremonie', 'ceremony'], styles: ['elegant'] },
  work: { words: ['work', 'office', 'bureau', 'travail', 'interview', 'entretien', 'meeting', 'reunion', 'stage', 'internship', 'business'], styles: ['elegant', 'minimalist'] },
  sport: { words: ['gym', 'running', 'jogging', 'workout', 'entrainement', 'salle de sport', 'match', 'football', 'yoga', 'hiking', 'randonnee'], styles: ['sporty'] },
  everyday: { words: ['everyday', 'daily', 'quotidien', 'tous les jours', 'weekend', 'week-end', 'university', 'universite', 'fac', 'school', 'ecole', 'campus', 'shopping'], styles: ['casual'] },
  beach: { words: ['beach', 'plage', 'summer', 'ete', 'vacation', 'vacances', 'holiday', 'pool', 'piscine'], styles: ['casual', 'trendy'] },
};

function detectStyles(text) {
  const t = normalize(text);
  return STYLE_KEYS.filter((s) => STYLE_WORDS[s].some((w) => hasWord(t, w)));
}

function detectOccasion(text) {
  const t = normalize(text);
  for (const [key, def] of Object.entries(OCCASIONS)) {
    if (def.words.some((w) => hasWord(t, w))) return key;
  }
  return null;
}

const SPORT_BRANDS = ['nike', 'adidas', 'puma', 'decathlon', 'reebok', 'under armour', 'new balance', 'asics', 'kipsta', 'domyos'];

const PRODUCT_STYLE_HINTS = {
  elegant: ['elegant', 'evening', 'soiree', 'cocktail', 'satin', 'silk', 'soie', 'lace', 'dentelle', 'heels', 'talons', 'escarpins', 'blazer', 'chic', 'classy', 'pearl', 'perle', 'velvet', 'velours', 'gold', 'luxury', 'midi', 'maxi', 'wedding', 'party'],
  casual: ['jeans', 'denim', 't-shirt', 'tshirt', 'sneakers', 'baskets', 'cotton', 'coton', 'hoodie', 'sweat', 'shorts', 'casual', 'basic', 'everyday', 'canvas', 'linen', 'lin'],
  sporty: ['sport', 'running', 'training', 'gym', 'fitness', 'dry-fit', 'dri-fit', 'tracksuit', 'jogging', 'legging', 'athletic', 'football', 'yoga'],
  minimalist: ['basic', 'simple', 'minimal', 'plain', 'uni', 'essential', 'essentiel', 'clean', 'classic'],
  trendy: ['oversize', 'oversized', 'crop', 'trendy', 'modern', 'new collection', 'nouvelle collection', 'print', 'imprime', 'graphic', 'cargo', 'street', 'y2k', 'chunky', 'metallic'],
};

const TYPE_STYLE_PRIORS = {
  dress: { elegant: 0.45, trendy: 0.15 },
  skirt: { elegant: 0.25, trendy: 0.2 },
  shirt: { elegant: 0.3, minimalist: 0.2 },
  tshirt: { casual: 0.5, minimalist: 0.15 },
  jacket: { trendy: 0.25, elegant: 0.2 },
  pants: { elegant: 0.2, casual: 0.25 },
  jeans: { casual: 0.55, trendy: 0.15 },
  shorts: { casual: 0.5, sporty: 0.15 },
  sportswear: { sporty: 0.8 },
  shoes: { casual: 0.2, elegant: 0.15 },
  bag: { elegant: 0.3, trendy: 0.15 },
  necklace: { elegant: 0.5 },
  bracelet: { elegant: 0.4, trendy: 0.15 },
  ring: { elegant: 0.5 },
  earrings: { elegant: 0.5 },
  watch: { elegant: 0.4, minimalist: 0.2 },
  accessory: { trendy: 0.3 },
  cosmetics: { elegant: 0.2 },
};

/** Style vector of a product, each value in [0, 1]. */
function inferStyleVector(product, now = Date.now()) {
  const type = product._type || inferType(product);
  const text = normalize([product.name, product.description, (product.category || []).join(' '), product.brand].join(' '));
  const v = { minimalist: 0, elegant: 0, casual: 0, sporty: 0, trendy: 0 };

  Object.entries(TYPE_STYLE_PRIORS[type] || {}).forEach(([s, w]) => { v[s] += w; });
  for (const s of STYLE_KEYS) {
    const hits = PRODUCT_STYLE_HINTS[s].filter((w) => hasWord(text, w)).length;
    v[s] += Math.min(0.6, hits * 0.25);
  }
  if (SPORT_BRANDS.some((b) => hasWord(normalize(product.brand), b))) v.sporty += 0.45;
  if (/sport/.test(normalize((product.category || []).join(' ')))) v.sporty += 0.35;

  const cols = productColors(product);
  if (cols.length && cols.length <= 2 && cols.every((c) => NEUTRAL_COLORS.includes(c))) v.minimalist += 0.45;
  if (cols.length >= 4) v.trendy += 0.15;

  const created = product.createdAt ? new Date(product.createdAt).getTime() : 0;
  if (created && now - created < 30 * 24 * 3600 * 1000) v.trendy += 0.2;

  for (const s of STYLE_KEYS) v[s] = Math.min(1, Number(v[s].toFixed(3)));
  return v;
}

// ---------------------------------------------------------------------------
// Prices
// ---------------------------------------------------------------------------
function effectivePrice(product) {
  const p = Number(product.price) || 0;
  const d = Number(product.discountPrice);
  return d > 0 && d < p ? d : p;
}

function hasDiscount(product) {
  const d = Number(product.discountPrice);
  return d > 0 && d < Number(product.price);
}

// ---------------------------------------------------------------------------
// Complete the look
// ---------------------------------------------------------------------------
/** For an anchor product type, which slots complete the outfit (each slot = list of acceptable types). */
const OUTFIT_RULES = {
  dress: [{ slot: 'shoes', types: ['shoes'] }, { slot: 'bag', types: ['bag'] }, { slot: 'jewelry', types: ['necklace', 'earrings', 'bracelet'] }],
  skirt: [{ slot: 'top', types: TOP_TYPES }, { slot: 'shoes', types: ['shoes'] }, { slot: 'bag', types: ['bag'] }],
  shirt: [{ slot: 'bottom', types: BOTTOM_TYPES }, { slot: 'shoes', types: ['shoes'] }, { slot: 'accessory', types: ['watch', 'accessory', 'bracelet'] }],
  tshirt: [{ slot: 'bottom', types: ['jeans', 'shorts', 'pants', 'skirt'] }, { slot: 'shoes', types: ['shoes'] }, { slot: 'accessory', types: ['accessory', 'bag', 'watch'] }],
  jacket: [{ slot: 'top', types: TOP_TYPES }, { slot: 'bottom', types: BOTTOM_TYPES }, { slot: 'shoes', types: ['shoes'] }],
  pants: [{ slot: 'top', types: TOP_TYPES }, { slot: 'shoes', types: ['shoes'] }, { slot: 'accessory', types: ['watch', 'accessory', 'bag'] }],
  jeans: [{ slot: 'top', types: TOP_TYPES }, { slot: 'shoes', types: ['shoes'] }, { slot: 'outer', types: ['jacket'] }],
  shorts: [{ slot: 'top', types: ['tshirt', 'shirt'] }, { slot: 'shoes', types: ['shoes'] }, { slot: 'accessory', types: ['accessory', 'bag'] }],
  sportswear: [{ slot: 'shoes', types: ['shoes'] }, { slot: 'bag', types: ['bag'] }, { slot: 'accessory', types: ['watch', 'accessory'] }],
  shoes: [{ slot: 'outfit', types: ['dress', 'jeans', 'pants', 'skirt'] }, { slot: 'top', types: TOP_TYPES }, { slot: 'bag', types: ['bag'] }],
  bag: [{ slot: 'outfit', types: ['dress', 'skirt', 'pants', 'jeans'] }, { slot: 'shoes', types: ['shoes'] }, { slot: 'jewelry', types: JEWELRY_TYPES }],
  necklace: [{ slot: 'outfit', types: ['dress', 'shirt', 'tshirt'] }, { slot: 'jewelry', types: ['earrings', 'bracelet', 'ring'] }, { slot: 'bag', types: ['bag'] }],
  bracelet: [{ slot: 'jewelry', types: ['necklace', 'ring', 'watch'] }, { slot: 'outfit', types: ['dress', 'shirt'] }],
  ring: [{ slot: 'jewelry', types: ['necklace', 'bracelet', 'earrings'] }, { slot: 'outfit', types: ['dress'] }],
  earrings: [{ slot: 'jewelry', types: ['necklace', 'bracelet', 'ring'] }, { slot: 'outfit', types: ['dress'] }],
  watch: [{ slot: 'top', types: TOP_TYPES }, { slot: 'jewelry', types: ['bracelet', 'ring'] }],
  accessory: [{ slot: 'top', types: TOP_TYPES }, { slot: 'bottom', types: BOTTOM_TYPES }, { slot: 'shoes', types: ['shoes'] }],
  other: [{ slot: 'top', types: TOP_TYPES }, { slot: 'bottom', types: BOTTOM_TYPES }, { slot: 'shoes', types: ['shoes'] }],
};

module.exports = {
  normalize,
  hasWord,
  escapeRegex,
  TYPES,
  TYPE_KEYS,
  JEWELRY_TYPES,
  detectTypes,
  inferType,
  typeGroup,
  detectGender,
  inferGender,
  COLORS,
  COLOR_KEYS,
  NEUTRAL_COLORS,
  canonicalColor,
  detectColors,
  productColors,
  colorHarmony,
  STYLE_KEYS,
  STYLE_WORDS,
  OCCASIONS,
  detectStyles,
  detectOccasion,
  inferStyleVector,
  effectivePrice,
  hasDiscount,
  OUTFIT_RULES,
};
