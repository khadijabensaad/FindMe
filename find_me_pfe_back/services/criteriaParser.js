/**
 * FINDME — Rule-based criteria extraction (FR / EN / a bit of Tunisian Darija).
 *
 * Used in two ways:
 *  1. Fallback NLU when no LLM is configured or the LLM call fails.
 *  2. Safety net: whatever the LLM returns is sanitized against the same vocabulary.
 */
const tx = require('./taxonomy');

const EMPTY_CRITERIA = Object.freeze({
  types: [],
  colors: [],
  excludeColors: [],
  styles: [],
  occasion: null,
  gender: null,
  sizes: [],
  brands: [],
  minPrice: null,
  maxPrice: null,
});

function emptyCriteria() {
  return JSON.parse(JSON.stringify(EMPTY_CRITERIA));
}

const NUM = '(\\d+(?:[.,]\\d+)?)';
const CURRENCY = '(?:\\s*(?:tnd|dt|dinars?|dinar|d|tunisian dinars?))?';

function toNumber(s) {
  return Number(String(s).replace(',', '.'));
}

/** Extract { minPrice, maxPrice } from text. */
function parseBudget(text) {
  const t = tx.normalize(text);
  let m;
  m = t.match(new RegExp(`(?:between|entre|from|de)\\s+${NUM}${CURRENCY}\\s*(?:and|et|to|a|-)\\s*${NUM}`));
  if (m) {
    const a = toNumber(m[1]);
    const b = toNumber(m[2]);
    return { minPrice: Math.min(a, b), maxPrice: Math.max(a, b) };
  }
  m = t.match(new RegExp(`(?:under|below|less than|max(?:imum)?|up to|no more than|moins de|en dessous de|au maximum|pas plus de|jusqu'a|inferieur a|<|a moins de|9al min|a9al min)\\s*(?:de\\s+)?${NUM}`));
  if (m) return { minPrice: null, maxPrice: toNumber(m[1]) };
  m = t.match(new RegExp(`(?:over|above|more than|at least|min(?:imum)?|plus de|au moins|superieur a|>)\\s*(?:de\\s+)?${NUM}`));
  if (m) return { minPrice: toNumber(m[1]), maxPrice: null };
  m = t.match(new RegExp(`budget\\s*(?:de|of|is|est|:)?\\s*${NUM}`));
  if (m) return { minPrice: null, maxPrice: toNumber(m[1]) };
  m = t.match(new RegExp(`${NUM}\\s*(?:tnd|dt|dinars?)\\b`));
  if (m) return { minPrice: null, maxPrice: toNumber(m[1]) };
  return { minPrice: null, maxPrice: null };
}

/** Extract clothing / shoe sizes. Single letters (S, M, L) only count after "size"/"taille". */
function parseSizes(original) {
  const sizes = new Set();
  const t = String(original || '');
  const re = /(?:size|taille|pointure|taile|ta9is)\s*:?\s*(xxs|xs|s|m|l|xl|xxl|xxxl|\d{2})\b/gi;
  let m;
  while ((m = re.exec(t))) sizes.add(m[1].toUpperCase());
  const standalone = /\b(XXS|XS|XL|XXL|XXXL)\b/g;
  while ((m = standalone.exec(t))) sizes.add(m[1]);
  return [...sizes];
}

function parseBrands(text, brandVocab = []) {
  const t = tx.normalize(text);
  return brandVocab.filter((b) => b && tx.hasWord(t, b));
}

const REFINEMENTS = [
  ['reset', ['start over', 'reset', 'new search', 'recommencer', 'on recommence', 'nouvelle recherche', 'from scratch', 'zero']],
  ['cheaper', ['cheaper', 'less expensive', 'lower price', 'moins cher', 'moins chere', 'moins chers', 'plus abordable', 'pas cher', 'pas chere', 'arkhes', 'ar5es', 'budget serre']],
  ['pricier', ['more expensive', 'higher end', 'plus cher', 'plus chere', 'haut de gamme', 'premium']],
  ['more_elegant', ['more elegant', 'more chic', 'classier', 'more classy', 'plus chic', 'plus elegant', 'plus elegante', 'plus classe', 'plus habille']],
  ['more_casual', ['more casual', 'more relaxed', 'plus decontracte', 'plus decontractee', 'plus casual', 'plus cool']],
  ['other_color', ['another color', 'another colour', 'other color', 'other colour', 'different color', 'different colour', 'autre couleur', 'autres couleurs', 'une autre couleur', 'couleur differente', 'lawn ekher']],
  ['more', ['show more', 'more options', 'other options', "d'autres", 'autres options', 'autres choix', 'montre plus', 'encore', 'something else', 'autre chose', 'others', 'more please', 'ghirou', 'okhrin']],
];

const INTENT_PATTERNS = {
  greeting: /^(hi|hello|hey|hii+|salut|bonjour|bonsoir|coucou|cc|ahla|aslema|salam|slt|yo|good (morning|evening|afternoon))\b/,
  thanks: /\b(thanks?|thank you|thx|merci|choukran|chokran|yaatik saha|ya3tik sa7a|y3aychek|parfait merci)\b/,
  bye: /\b(bye|goodbye|au revoir|a plus|a bientot|bslama|see you|ciao|tchao)\b/,
  about: /\b(who are you|what are you|qui es[- ]tu|t'es qui|what can you do|que (peux|sais)[- ]tu faire|tu fais quoi|chnowa enti|help me use|comment ca marche)\b/,
  similar: /\b(similar|similaire|similaires|alternatives?|ressemblant|ressemblante|pareil|pareille|comme celui|comme celle|like this one|like that one)\b/,
  // open fashion questions / inspiration: answered by the LLM with its own fashion knowledge
  advice: /\b(ideas?|idees?|inspiration|inspire[- ]moi|inspire me|what (should i|to|can i) wear|que (dois-je |je peux )?porter|quoi porter|qu'est-ce que je (peux )?porte|how to (wear|style|match)|comment (porter|associer|assortir)|tendances?|trends?|trending|tips|astuces?|conseils? (mode|de style)|style advice|fashion advice|which colou?rs? (go|goes|match)|quelles? couleurs? (va|vont)|colou?rs? (that|qui) (go|vont))\b/,
  adviceWeak: /\b(advice|conseil|conseils|help me (choose|pick|style)|aide[- ]moi a (choisir|m'habiller))\b/,
  outfit: /\b(outfit|outfits|tenue|tenues|look|complete the look|completer|complete|assortir|assorti|match with|matches|goes with|aller avec|va avec|ensemble|associer|coordonner|style me|habille[- ]moi)\b/,
  nearby: /\b(near me|nearby|nearest|closest|close to me|close to my|near my|around me|autour de moi|pres de ma position|stores? (selling|with|that|in|near)|shops? (selling|with|that|in|near)|boutiques? (qui|avec|a|en|de|pres)|magasins? (qui|avec|a|de|pres)|available (in|at|near) (stores?|shops?|a shop|a store)|disponibles? (en|dans les|pres)( boutiques?| magasins?)?|in (nearby )?stores|en boutique|within \d+ ?km|dans un rayon|shops? near|stores? near|pres de (moi|chez moi)|proches?|a cote|boutiques? (la |les )?plus proches?|magasins? (le |les )?plus proches?|where can i buy|where to buy|where is it sold|ou acheter|ou le trouver|ou la trouver|which shops?|quelles? boutiques?|quels? magasins?|disponible ou|available where|9rib|qrib)\b/,
  search: /\b(looking for|look for|i want|i need|show me|find me|find|search|cherche|je veux|j'ai besoin|besoin d'|montre[- ]moi|trouve[- ]moi|propose|suggest|recommend|recommande|conseille|nheb|n7eb|nlawej)\b/,
};

/** Returns 'fr' | 'en' | 'tn', or null when the message carries no language evidence ("Modern", "OK"). */
function detectLanguage(text) {
  const t = tx.normalize(text);
  const fr = (t.match(/\b(je|j'|cherche|une|un|des|le|la|les|du|pour|moins|robe|robes|veux|avec|est|pas|bonjour|merci|salut|tenue|chaussures|couleur|prix|taille|soiree|plus|quoi|ou|mon|ma|mes|vous|tu|moi|complete|boutiques?|magasins?|proches?|autre|cher|chere|elegante|moderne|decontracte|minimaliste|oui|non|stp|svp|elargir|rayon|trouver|acheter|taille|baskets|chaussures|premiere?|similaires?)\b/g) || []).length;
  const en = (t.match(/\b(i|i'm|looking|for|an|the|want|need|with|under|show|me|my|dress|shoes|color|colour|price|size|party|please|what|where|hello|thanks|thank|cheaper|another|more|near|shops?|complete|yes|no|classy|casual|minimalist|modern|elegant)\b/g) || []).length;
  const darija = (t.match(/\b(nheb|n7eb|chnowa|9addech|qaddech|barcha|behi|mte3|fama|famma|ya3tik|aslema|ahla|zeda|bech|kifech|choukran|chokran)\b/g) || []).length;
  if (darija >= 1 && darija >= fr / 2) return 'tn';
  if (fr === en) return null;
  return fr > en ? 'fr' : 'en';
}

/**
 * Parse a user message.
 * @returns {{intent:string, language:string, set:object, refinement:string|null, clear:string[]}}
 *   `set` only contains the criteria actually found in this message.
 */
function parseMessage(text, vocab = {}) {
  const t = tx.normalize(text);
  const set = {};

  const types = tx.detectTypes(t);
  if (types.length) set.types = types;

  const colors = tx.detectColors(t);
  const negColor = t.match(/\b(?:not|no|pas de|pas en|sans|except|sauf)\s+(?:in\s+|en\s+)?([a-z ]{3,20})/);
  if (negColor) {
    const excluded = tx.detectColors(negColor[1]);
    if (excluded.length) {
      set.excludeColors = excluded;
      excluded.forEach((c) => {
        const i = colors.indexOf(c);
        if (i >= 0) colors.splice(i, 1);
      });
    }
  }
  if (colors.length) set.colors = colors;

  const styles = tx.detectStyles(t);
  if (styles.length) set.styles = styles;

  const occasion = tx.detectOccasion(t);
  if (occasion) {
    set.occasion = occasion;
    if (!set.styles) set.styles = [...tx.OCCASIONS[occasion].styles];
  }

  const gender = tx.detectGender(t);
  if (gender) set.gender = gender;

  const sizes = parseSizes(text);
  if (sizes.length) set.sizes = sizes;

  const brands = parseBrands(text, vocab.brands || []);
  if (brands.length) set.brands = brands;

  const budget = parseBudget(text);
  if (budget.maxPrice != null) set.maxPrice = budget.maxPrice;
  if (budget.minPrice != null) set.minPrice = budget.minPrice;

  let refinement = null;
  for (const [key, words] of REFINEMENTS) {
    if (words.some((w) => tx.hasWord(t, w))) {
      refinement = key;
      break;
    }
  }
  // "more chic" etc. should not also be read as a fresh style request
  if (refinement === 'more_elegant' || refinement === 'more_casual') delete set.styles;

  const hasCriteria = Object.keys(set).length > 0;
  let intent = 'smalltalk';
  if (INTENT_PATTERNS.nearby.test(t)) intent = 'nearby';
  else if (INTENT_PATTERNS.similar.test(t) && !types.length) intent = 'similar';
  else if (INTENT_PATTERNS.advice.test(t) || (INTENT_PATTERNS.adviceWeak.test(t) && !types.length)) intent = 'advice';
  else if (INTENT_PATTERNS.outfit.test(t) && !(INTENT_PATTERNS.search.test(t) && types.length && !/tenue|outfit|look/.test(t))) intent = 'outfit';
  else if (refinement) intent = 'refine';
  else if (hasCriteria || INTENT_PATTERNS.search.test(t)) intent = 'search';
  else if (INTENT_PATTERNS.thanks.test(t)) intent = 'thanks';
  else if (INTENT_PATTERNS.bye.test(t)) intent = 'bye';
  else if (INTENT_PATTERNS.about.test(t)) intent = 'about';
  else if (INTENT_PATTERNS.greeting.test(t)) intent = 'greeting';

  // "Hi, I want a black dress" → still a search
  if (intent === 'greeting' && hasCriteria) intent = 'search';

  return { intent, language: detectLanguage(text), set, refinement, clear: refinement === 'reset' ? ['all'] : [] };
}

// ---------------------------------------------------------------------------
// Sanitizing (also applied to LLM output)
// ---------------------------------------------------------------------------
const ALLOWED_INTENTS = ['greeting', 'thanks', 'bye', 'about', 'search', 'refine', 'outfit', 'advice', 'nearby', 'similar', 'smalltalk'];
const ALLOWED_REFINEMENTS = ['reset', 'cheaper', 'pricier', 'more_elegant', 'more_casual', 'other_color', 'more'];
const ALLOWED_FIELDS = Object.keys(EMPTY_CRITERIA);

function asArray(v) {
  if (v == null) return [];
  return Array.isArray(v) ? v : [v];
}

function positiveNumberOrNull(v) {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? n : null;
}

/** Keep only values the catalogue understands. */
function sanitizeSet(set = {}, vocab = {}) {
  const out = {};
  if (set.types !== undefined) {
    out.types = [...new Set(asArray(set.types).map((x) => tx.normalize(x).replace(/[- ]/g, '')).map((x) => (x === 'tshirt' ? 'tshirt' : x))
      .map((x) => (tx.TYPE_KEYS.includes(x) ? x : (tx.detectTypes(x)[0] || null))).filter(Boolean))];
  }
  for (const field of ['colors', 'excludeColors']) {
    if (set[field] !== undefined) out[field] = [...new Set(asArray(set[field]).map(tx.canonicalColor).filter(Boolean))];
  }
  if (set.styles !== undefined) {
    out.styles = [...new Set(asArray(set.styles).map((s) => tx.normalize(s))
      .map((s) => (tx.STYLE_KEYS.includes(s) ? s : tx.detectStyles(s)[0])).filter(Boolean))];
  }
  if (set.occasion !== undefined) {
    const o = tx.normalize(set.occasion);
    out.occasion = tx.OCCASIONS[o] ? o : tx.detectOccasion(o);
  }
  if (set.gender !== undefined) {
    const g = tx.normalize(set.gender);
    out.gender = ['men', 'women', 'kids'].includes(g) ? g : tx.detectGender(g);
  }
  if (set.sizes !== undefined) {
    out.sizes = [...new Set(asArray(set.sizes).map((s) => String(s).toUpperCase().trim()).filter((s) => /^(XXS|XS|S|M|L|XL|XXL|XXXL|\d{2})$/.test(s)))];
  }
  if (set.brands !== undefined) {
    const known = (vocab.brands || []);
    out.brands = [...new Set(asArray(set.brands).map((b) => known.find((k) => tx.normalize(k) === tx.normalize(b))).filter(Boolean))];
  }
  if (set.minPrice !== undefined) out.minPrice = positiveNumberOrNull(set.minPrice);
  if (set.maxPrice !== undefined) out.maxPrice = positiveNumberOrNull(set.maxPrice);
  if (out.minPrice && out.maxPrice && out.minPrice > out.maxPrice) {
    [out.minPrice, out.maxPrice] = [out.maxPrice, out.minPrice];
  }
  return out;
}

function sanitizeUnderstanding(u = {}, vocab = {}) {
  const intent = ALLOWED_INTENTS.includes(u.intent) ? u.intent : 'search';
  const refinement = ALLOWED_REFINEMENTS.includes(u.refinement) ? u.refinement : null;
  const clear = asArray(u.clear).filter((f) => f === 'all' || ALLOWED_FIELDS.includes(f));
  const language = typeof u.language === 'string' && u.language.length <= 5 ? u.language.toLowerCase() : 'en';
  return { intent, language, set: sanitizeSet(u.set || {}, vocab), refinement, clear };
}

/** Apply a new understanding on top of the current conversation criteria. */
function mergeCriteria(current, understanding) {
  let c = { ...emptyCriteria(), ...(current || {}) };
  const { set = {}, clear = [], refinement } = understanding;
  if (refinement === 'reset' || clear.includes('all')) c = emptyCriteria();
  clear.forEach((f) => {
    if (f !== 'all' && f in c) c[f] = Array.isArray(EMPTY_CRITERIA[f]) ? [] : null;
  });
  // A different product type starts a new need: forget the old context (budget, colours,
  // style, size…) unless the same message restates it. Gender is kept.
  if (set.types && set.types.length && c.types.length && !set.types.some((x) => c.types.includes(x))) {
    c = { ...emptyCriteria(), gender: c.gender };
  }
  for (const [k, v] of Object.entries(set)) {
    if (Array.isArray(v) ? v.length === 0 : v == null) continue;
    c[k] = v;
  }
  if (c.colors.length && c.excludeColors.length) {
    c.excludeColors = c.excludeColors.filter((x) => !c.colors.includes(x));
  }
  return c;
}

function hasAnyCriteria(c) {
  return !!c && Object.entries(c).some(([, v]) => (Array.isArray(v) ? v.length > 0 : v != null));
}

module.exports = {
  emptyCriteria,
  parseBudget,
  parseSizes,
  parseBrands,
  parseMessage,
  detectLanguage,
  sanitizeSet,
  sanitizeUnderstanding,
  mergeCriteria,
  hasAnyCriteria,
  ALLOWED_INTENTS,
  ALLOWED_REFINEMENTS,
};
