/**
 * FINDME — AI Fashion Stylist (hybrid architecture).
 *
 *   message ─► 1. Understanding  (LLM → JSON criteria, validated; rule-based fallback)
 *           ─► 2. Context merge   (criteria remembered across turns + refinements)
 *           ─► 3. Retrieval       (MongoDB catalogue → hard filters → relaxation → ranking)
 *           ─► 4. Response        (LLM phrasing grounded on real products + guardrail; template fallback)
 *           ─► 5. Memory & signals (chat session + interaction log for Style DNA)
 *
 * The LLM never invents products, prices or availability: it only receives products
 * that were retrieved from the database, and any answer quoting an unknown price is rejected.
 */
const parser = require('./criteriaParser');
const tx = require('./taxonomy');
const geo = require('./geoService');

// ---------------------------------------------------------------------------
// i18n helpers for templates & quick replies
// ---------------------------------------------------------------------------
const TYPE_LABELS = {
  en: { dress: 'dresses', skirt: 'skirts', shirt: 'shirts', tshirt: 't-shirts', jacket: 'jackets', pants: 'pants', jeans: 'jeans', shorts: 'shorts', sportswear: 'sportswear', shoes: 'shoes', bag: 'bags', necklace: 'necklaces', bracelet: 'bracelets', ring: 'rings', earrings: 'earrings', watch: 'watches', accessory: 'accessories', cosmetics: 'beauty products', other: 'items' },
  fr: { dress: 'robes', skirt: 'jupes', shirt: 'chemises', tshirt: 't-shirts', jacket: 'vestes', pants: 'pantalons', jeans: 'jeans', shorts: 'shorts', sportswear: 'tenues de sport', shoes: 'chaussures', bag: 'sacs', necklace: 'colliers', bracelet: 'bracelets', ring: 'bagues', earrings: "boucles d'oreilles", watch: 'montres', accessory: 'accessoires', cosmetics: 'produits beauté', other: 'articles' },
};
const COLOR_LABELS_FR = { black: 'noir', white: 'blanc', grey: 'gris', cream: 'crème', beige: 'beige', brown: 'marron', red: 'rouge', pink: 'rose', blue: 'bleu', 'light blue': 'bleu clair', green: 'vert', yellow: 'jaune', orange: 'orange', purple: 'violet', gold: 'doré', silver: 'argenté', bronze: 'bronze' };
const STYLE_LABELS = {
  en: { minimalist: 'minimalist', elegant: 'classy', casual: 'casual', sporty: 'sporty', trendy: 'modern' },
  fr: { minimalist: 'minimaliste', elegant: 'chic', casual: 'décontracté', sporty: 'sportif', trendy: 'moderne' },
};
const OCCASION_LABELS = {
  en: { party: 'party', wedding: 'wedding', work: 'work', sport: 'sport', everyday: 'everyday', beach: 'beach' },
  fr: { party: 'soirée', wedding: 'mariage', work: 'bureau', sport: 'sport', everyday: 'quotidien', beach: 'plage' },
};
const SLOT_LABELS = {
  en: { shoes: 'shoes', bag: 'a bag', jewelry: 'jewelry', top: 'a top', bottom: 'a bottom', outer: 'a jacket', accessory: 'an accessory', outfit: 'an outfit base' },
  fr: { shoes: 'chaussures', bag: 'un sac', jewelry: 'un bijou', top: 'un haut', bottom: 'un bas', outer: 'une veste', accessory: 'un accessoire', outfit: 'une pièce principale' },
};

const L = (lang) => (lang === 'fr' || lang === 'tn' ? 'fr' : 'en');
const fmt = (n) => (Number.isInteger(n) ? String(n) : Number(n).toFixed(2).replace(/\.00$/, ''));

function colorLabel(c, lang) {
  return L(lang) === 'fr' ? (COLOR_LABELS_FR[c] || c) : c;
}

function criteriaSummary(c, lang) {
  const l = L(lang);
  const parts = [];
  parts.push(c.types && c.types.length ? c.types.map((t) => TYPE_LABELS[l][t] || t).join(' & ') : (l === 'fr' ? 'articles' : 'items'));
  if (c.colors && c.colors.length) parts.push(c.colors.map((x) => colorLabel(x, lang)).join('/'));
  if (c.styles && c.styles.length) parts.push(c.styles.map((s) => STYLE_LABELS[l][s] || s).join('/'));
  if (c.occasion) parts.push(OCCASION_LABELS[l][c.occasion] || c.occasion);
  if (c.brands && c.brands.length) parts.push(c.brands.join(', '));
  if (c.maxPrice) parts.push(l === 'fr' ? `moins de ${fmt(c.maxPrice)} TND` : `under ${fmt(c.maxPrice)} TND`);
  if (c.minPrice && !c.maxPrice) parts.push(l === 'fr' ? `plus de ${fmt(c.minPrice)} TND` : `over ${fmt(c.minPrice)} TND`);
  if (c.sizes && c.sizes.length) parts.push(`${l === 'fr' ? 'taille' : 'size'} ${c.sizes.join('/')}`);
  return parts.join(' · ');
}

/** Chips displayed above the chat ("Black ✕", "Dress ✕", "≤ 150 TND ✕"). */
function criteriaChips(c, lang) {
  const l = L(lang);
  const chips = [];
  (c.types || []).forEach((v) => chips.push({ field: 'types', value: v, label: TYPE_LABELS[l][v] || v }));
  (c.colors || []).forEach((v) => chips.push({ field: 'colors', value: v, label: colorLabel(v, lang) }));
  (c.excludeColors || []).forEach((v) => chips.push({ field: 'excludeColors', value: v, label: `${l === 'fr' ? 'pas' : 'no'} ${colorLabel(v, lang)}` }));
  (c.styles || []).forEach((v) => chips.push({ field: 'styles', value: v, label: STYLE_LABELS[l][v] || v }));
  (c.brands || []).forEach((v) => chips.push({ field: 'brands', value: v, label: v }));
  (c.sizes || []).forEach((v) => chips.push({ field: 'sizes', value: v, label: `${l === 'fr' ? 'Taille' : 'Size'} ${v}` }));
  if (c.gender) chips.push({ field: 'gender', value: c.gender, label: { men: l === 'fr' ? 'Homme' : 'Men', women: l === 'fr' ? 'Femme' : 'Women', kids: l === 'fr' ? 'Enfant' : 'Kids' }[c.gender] });
  if (c.occasion) chips.push({ field: 'occasion', value: c.occasion, label: OCCASION_LABELS[l][c.occasion] || c.occasion });
  if (c.maxPrice) chips.push({ field: 'maxPrice', value: c.maxPrice, label: `≤ ${fmt(c.maxPrice)} TND` });
  if (c.minPrice) chips.push({ field: 'minPrice', value: c.minPrice, label: `≥ ${fmt(c.minPrice)} TND` });
  return chips;
}

/** What should the stylist ask next to refine? */
function nextQuestionTopic(c, products) {
  if (!c.types.length) return 'type';
  if (!c.styles.length && products.length > 1) return 'style';
  if (!c.maxPrice && products.length > 1) return 'budget';
  if (!c.sizes.length && products.length > 0 && !['bag', 'necklace', 'bracelet', 'earrings', 'watch', 'accessory', 'cosmetics'].includes(c.types[0])) return 'size';
  return products.length ? 'next' : 'relax';
}

const QUESTIONS = {
  en: {
    type: 'What are you looking for today: a dress, shoes, a bag…?',
    style: 'Do you prefer a classy, modern or minimalist look?',
    budget: "What's your budget?",
    size: 'What size do you wear?',
    next: 'Want a cheaper option, another colour, or should I complete the look?',
    relax: 'Shall I widen the budget or try another colour?',
  },
  fr: {
    type: "Qu'est-ce que tu cherches aujourd'hui : une robe, des chaussures, un sac… ?",
    style: 'Tu préfères un look chic, moderne ou minimaliste ?',
    budget: 'Quel est ton budget ?',
    size: 'Quelle taille fais-tu ?',
    next: "Tu veux moins cher, une autre couleur, ou que je complète le look ?",
    relax: "Je peux élargir le budget ou essayer une autre couleur ?",
  },
};

function quickRepliesFor(topic, lang, { hasProducts, hasLocation } = {}) {
  const fr = L(lang) === 'fr';
  const map = {
    type: fr ? ['Une robe', 'Des chaussures', 'Un sac', 'Une tenue complète'] : ['A dress', 'Shoes', 'A bag', 'A full outfit'],
    style: fr ? ['Chic', 'Moderne', 'Minimaliste', 'Décontracté'] : ['Classy', 'Modern', 'Minimalist', 'Casual'],
    budget: fr ? ['Moins de 50 TND', 'Moins de 100 TND', 'Moins de 200 TND'] : ['Under 50 TND', 'Under 100 TND', 'Under 200 TND'],
    size: ['Size S', 'Size M', 'Size L', 'Size XL'].map((s) => (fr ? s.replace('Size', 'Taille') : s)),
    next: fr ? ['Moins cher', 'Une autre couleur', 'Complète le look', 'Boutiques proches'] : ['Cheaper', 'Another colour', 'Complete the look', 'Shops near me'],
    relax: fr ? ['Élargir le budget', 'Une autre couleur', 'Recommencer'] : ['Widen the budget', 'Another colour', 'Start over'],
  };
  let q = map[topic] || map.next;
  if (topic !== 'next' && hasProducts) q = [...q.slice(0, 3), fr ? 'Complète le look' : 'Complete the look'];
  return q;
}

// ---------------------------------------------------------------------------
// Templates (used when no LLM is configured, or as a guardrail fallback)
// ---------------------------------------------------------------------------
function nearbyTemplate(n, criteria, lang) {
  const fr = L(lang) === 'fr';
  const where = n.origin && n.origin.label ? (fr ? ` de ${n.origin.label}` : ` of ${n.origin.label}`) : (n.origin ? (fr ? ' de toi' : ' of you') : '');
  const sizeNote = criteria.sizes && criteria.sizes.length
    ? (fr ? ` La taille ${criteria.sizes.join('/')} existe pour ces articles (le stock par boutique n’est pas suivi).` : ` Size ${criteria.sizes.join('/')} exists for these items (per-shop stock is not tracked).`)
    : '';
  if (!n.results.length) {
    if (n.nearestOutside) {
      const o = n.nearestOutside;
      return fr
        ? `Aucune boutique à moins de ${fmt(n.radiusKm)} km${where}. La plus proche est ${o.shop} (${o.city}) à ${fmt(o.distanceKm)} km, avec « ${o.product} ». Je peux élargir la recherche.`
        : `No shop within ${fmt(n.radiusKm)} km${where}. The closest is ${o.shop} (${o.city}), ${fmt(o.distanceKm)} km away, with "${o.product}". I can widen the search.`;
    }
    return fr ? 'Je ne trouve aucun article correspondant référencé en boutique pour le moment.' : 'I can’t find a matching item listed in a shop right now.';
  }
  const first = n.results[0];
  const s = first.stores[0];
  const verified = s.verified ? '' : (fr ? ' (disponibilité à confirmer)' : ' (availability to confirm)');
  if (n.needsLocation) {
    return fr
      ? `« ${first.product.name} » est vendu chez ${first.stores.map((x) => x.name).slice(0, 3).join(', ')}. Partage ta position ou choisis une ville pour voir les distances. 📍${sizeNote}`
      : `"${first.product.name}" is sold at ${first.stores.map((x) => x.name).slice(0, 3).join(', ')}. Share your location or pick a city to see distances. 📍${sizeNote}`;
  }
  const count = n.results.length;
  return fr
    ? `J'ai trouvé ${count} article${count > 1 ? 's' : ''} dans ${n.stores.length} boutique${n.stores.length > 1 ? 's' : ''} à moins de ${fmt(n.radiusKm)} km${where}. Le plus proche : « ${first.product.name} » chez ${s.name}, à ${fmt(s.distanceKm)} km${verified}. 📍${sizeNote}`
    : `I found ${count} item${count > 1 ? 's' : ''} in ${n.stores.length} shop${n.stores.length > 1 ? 's' : ''} within ${fmt(n.radiusKm)} km${where}. Closest: "${first.product.name}" at ${s.name}, ${fmt(s.distanceKm)} km away${verified}. 📍${sizeNote}`;
}

function templateReply({ intent, lang, criteria, search, outfit, shops, nearby, topic, product, similarTo }) {
  const fr = L(lang) === 'fr';
  switch (intent) {
    case 'greeting':
      return fr
        ? "Salut ! ✨ Je suis ton styliste FINDME. Dis-moi ce que tu cherches, par exemple « une robe noire pour une soirée à moins de 150 TND »."
        : "Hi! ✨ I'm your FINDME stylist. Tell me what you're looking for, e.g. \"a black dress for a party under 150 TND\".";
    case 'thanks':
      return fr ? 'Avec plaisir ! Je reste là si tu veux compléter ton look. 🖤' : "My pleasure! I'm here if you want to complete your look. 🖤";
    case 'bye':
      return fr ? 'À bientôt, et bon shopping ! 🛍️' : 'See you soon, happy shopping! 🛍️';
    case 'about':
      return fr
        ? "Je suis le styliste IA de FINDME : je trouve des articles dans le catalogue selon ta couleur, ton budget, ta taille et ton style, je compose des tenues et je t'indique les boutiques proches."
        : "I'm FINDME's AI stylist: I find items in the catalogue by colour, budget, size and style, build complete outfits and show you the nearest shops.";
    case 'outfit': {
      if (!outfit) return fr ? 'Montre-moi d’abord un article, et je compose une tenue autour. 👗' : 'Show me an item first and I’ll build an outfit around it. 👗';
      if (!outfit.items.length) return fr ? `Je n'ai pas encore de pièces à associer avec « ${outfit.anchor.name} » dans le catalogue.` : `I don't have matching pieces for "${outfit.anchor.name}" in the catalogue yet.`;
      const parts = outfit.items.map((it) => `${it.product.name} (${fmt(it.product.effectivePrice)} TND)`);
      return fr
        ? `Voici un look complet autour de « ${outfit.anchor.name} » : ${parts.join(', ')}. Total : ${fmt(outfit.totalPrice)} TND. ✨`
        : `Here's a complete look around "${outfit.anchor.name}": ${parts.join(', ')}. Total: ${fmt(outfit.totalPrice)} TND. ✨`;
    }
    case 'nearby': {
      if (nearby) return nearbyTemplate(nearby, criteria, lang);
      if (!shops) return fr ? 'Dis-moi d’abord quel article t’intéresse. 📍' : 'Tell me which item you like first. 📍';
      if (!shops.shops.length) return fr ? `Aucune boutique n'est encore référencée pour « ${shops.productName} ».` : `No shop is listed yet for "${shops.productName}".`;
      const list = shops.shops.slice(0, 3).map((s) => (s.distanceKm != null ? `${s.name} (${s.city}, ${fmt(s.distanceKm)} km)` : `${s.name} (${s.city})`)).join(', ');
      return fr ? `« ${shops.productName} » est disponible chez : ${list}. 📍` : `"${shops.productName}" is available at: ${list}. 📍`;
    }
    case 'similar':
      if (!search || !search.products.length) return fr ? 'Montre-moi d’abord un article, et je te trouve des alternatives.' : 'Show me an item first and I’ll find alternatives.';
      return fr
        ? `Voici des articles similaires à « ${similarTo || search.products[0].name} » : même style, couleurs proches et prix comparables. ✨`
        : `Here are items similar to "${similarTo || search.products[0].name}": same style, close colours and comparable prices. ✨`;
    case 'smalltalk':
      return fr
        ? "Je suis là pour t'aider à trouver la pièce parfaite ✨ Dis-moi ce que tu cherches : un type d'article, une couleur, une occasion ou un budget."
        : "I'm here to help you find the perfect piece ✨ Tell me what you're looking for: an item, a colour, an occasion or a budget.";
    default: {
      if (!parser.hasAnyCriteria(criteria)) return QUESTIONS[L(lang)].type;
      const products = (search && search.products) || [];
      const summary = criteriaSummary(criteria, lang);
      if (!products.length) {
        return fr ? `Je n'ai rien trouvé pour « ${summary} » pour le moment. ${QUESTIONS.fr.relax}` : `I couldn't find anything for "${summary}" right now. ${QUESTIONS.en.relax}`;
      }
      const top = products[0];
      const map = fr ? { sizes: 'la taille', brands: 'la marque', colors: 'la couleur', budget: 'le budget', types: "le type d'article" } : { sizes: 'size', brands: 'brand', colors: 'colour', budget: 'budget', types: 'item type' };
      const relaxedTxt = (search.relaxed || []).map((r) => map[r]).join(', ');
      const exact = search.exactCount != null ? search.exactCount : products.length;
      const alt = search.alternativeCount || 0;
      const opener = intent === 'refine' ? (fr ? 'Voilà !' : 'Here you go!') : (fr ? 'Super choix ! 🖤' : 'Great choice! 🖤');
      let text;
      if (exact > 0) {
        text = fr
          ? `${opener} J'ai trouvé ${exact} ${exact > 1 ? 'articles' : 'article'} pour « ${summary} ». Mon meilleur choix : ${top.name} à ${fmt(top.effectivePrice)} TND.`
          : `${opener} I found ${exact} ${exact > 1 ? 'matches' : 'match'} for "${summary}". My best pick: ${top.name} at ${fmt(top.effectivePrice)} TND.`;
        if (alt) text += fr ? ` J'ajoute ${alt} alternative${alt > 1 ? 's' : ''} proche${alt > 1 ? 's' : ''} en assouplissant ${relaxedTxt}.` : ` Plus ${alt} close alternative${alt > 1 ? 's' : ''} (relaxed ${relaxedTxt}).`;
      } else {
        text = fr
          ? `Pas de correspondance exacte pour « ${summary} », alors j'ai assoupli ${relaxedTxt}. Le plus proche : ${top.name} à ${fmt(top.effectivePrice)} TND.`
          : `No exact match for "${summary}", so I relaxed the ${relaxedTxt}. Closest option: ${top.name} at ${fmt(top.effectivePrice)} TND.`;
      }
      if (search.exhausted) text += fr ? ' Tu as déjà vu toutes les options correspondantes.' : " You've already seen every matching option.";
      return `${text} ${QUESTIONS[L(lang)][topic] || ''}`.trim();
    }
  }
}

// ---------------------------------------------------------------------------
// LLM prompts
// ---------------------------------------------------------------------------
function understandingPrompt(vocab) {
  return `You are the language-understanding module of FINDME, a Tunisian fashion shopping app.
Read the conversation and extract the shopping criteria of the user's LAST message.
The user may write in French, English, Tunisian Arabic (Darija, also in Latin letters like "nheb", "9addech") or mix them.

Return ONLY this JSON:
{
  "intent": "search" | "refine" | "outfit" | "advice" | "nearby" | "similar" | "greeting" | "thanks" | "bye" | "about" | "smalltalk",
  "location": city or area named by the user (e.g. "Tunis", "La Marsa") or null,
  "radiusKm": search radius in km if the user gives one, else null,
  "productRef": null | "first" | "second" | "third" | "this"   (when the user refers to a product already shown),
  "language": "fr" | "en" | "tn" | "ar",
  "set": { only the criteria mentioned in the last message:
    "types": [${require('./taxonomy').TYPE_KEYS.map((t) => `"${t}"`).join(', ')}],
    "colors": [${tx.COLOR_KEYS.map((c) => `"${c}"`).join(', ')}],
    "excludeColors": [same colour values],
    "styles": ["minimalist", "elegant", "casual", "sporty", "trendy"],
    "occasion": "party" | "wedding" | "work" | "sport" | "everyday" | "beach",
    "gender": "women" | "men" | "kids",
    "sizes": ["XS","S","M","L","XL","XXL" or shoe sizes like "38"],
    "brands": [${(vocab.brands || []).slice(0, 60).map((b) => JSON.stringify(b)).join(', ')}],
    "minPrice": number, "maxPrice": number   (prices in TND / dinars)
  },
  "clear": [criteria field names the user wants to remove, or "all" to start over],
  "refinement": null | "cheaper" | "pricier" | "more_elegant" | "more_casual" | "other_color" | "more" | "reset"
}
Rules:
- Map synonyms to the allowed values ("robe" -> "dress", "baskets" -> "shoes", "chic"/"classy" -> "elegant", "moderne" -> "trendy", "noir" -> "black").
- "intent":"outfit" when the user wants items that go with a product already shown; "nearby" when they ask where to buy / closest shop.
- "intent":"nearby" when the user asks where to buy/find something, which shop/store has it, stores near them or in a city, availability in shops, or a search radius.
- "intent":"similar" when they want products similar to one already shown.
- "intent":"advice" for open fashion questions or inspiration: outfit ideas for an occasion, what to wear, how to style or match something, colour combinations, trends, style tips.
- "refine" when they adjust the previous results ("cheaper", "another colour", "show more", "plus chic").
- Never invent brands that are not in the list. Omit fields that were not mentioned.`;
}

function replyPrompt(lang) {
  const langName = { fr: 'French', en: 'English', tn: 'Tunisian Darija written in Latin letters (mixed with French is fine)', ar: 'Arabic' }[lang] || 'the language of the user';
  return `You are "FINDME Stylist", a warm, modern and concise personal fashion stylist inside a Tunisian shopping app.
Reply in ${langName}.
STRICT RULES:
- Only talk about products listed in PRODUCTS / OUTFIT / SHOPS. Never invent products, brands, prices, stock, discounts or shops.
- Quote prices exactly as given, in TND.
- 2 to 3 short sentences maximum, at most one emoji. The product cards are shown under your message, so do not list every product.
- Mention the best pick and briefly why it fits (use the "why" hints).
- If exact_matches is 0 and "relaxed" is not empty, say honestly that there was no exact match and what was relaxed.
- If there are exact matches AND close_alternatives, you may mention that a few close alternatives were added.
- If there are no products, say so honestly and suggest relaxing a criterion.
- End with ONE short question about NEXT_QUESTION_TOPIC when it is not "next" (style, budget, size or type), otherwise invite to refine (cheaper, other colour, complete the look).
Return JSON: {"reply": "..."}`;
}

function compactProduct(p) {
  return {
    name: p.name,
    brand: p.brand,
    price: p.effectivePrice,
    oldPrice: p.discountPrice > 0 && p.discountPrice < p.price ? p.price : undefined,
    colors: p.colors,
    match: p.matchPercent,
    why: (p.reasons || []).slice(0, 3).map((r) => r.label),
  };
}

/** Reject answers that quote a price we did not provide (anti-hallucination guardrail). */
function priceGuardrail(text, allowedNumbers) {
  const re = /(\d+(?:[.,]\d+)?)\s*(?:tnd|dt|dinars?|d\b)/gi;
  let m;
  while ((m = re.exec(text))) {
    const n = Number(m[1].replace(',', '.'));
    if (!allowedNumbers.some((a) => Math.abs(a - n) < 0.51)) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Creative stylist: free fashion knowledge, then matched to the real catalogue
// ---------------------------------------------------------------------------
function looksPrompt(lang) {
  const langName = { fr: 'French', en: 'English', tn: 'Tunisian Darija written in Latin letters (mixed with French is fine)', ar: 'Arabic' }[lang] || 'the language of the user';
  return `You are "FINDME Stylist", an expert personal fashion stylist in a Tunisian shopping app.
Use your own fashion knowledge freely: trends, colour harmony, body-friendly cuts, fabrics, occasions, seasons,
Tunisian climate and culture (weddings, henna nights, Ramadan evenings, summer heat, office, university).
Answer the user's request in ${langName}.

Return ONLY this JSON:
{
  "reply": "2 to 4 warm sentences answering the question or presenting the looks. At most one emoji.",
  "looks": [
    {
      "title": "short name of the look",
      "occasion": "when to wear it",
      "tip": "one practical styling tip",
      "pieces": [
        { "type": one of [${tx.TYPE_KEYS.map((t) => `"${t}"`).join(', ')}],
          "color": one of [${tx.COLOR_KEYS.map((c) => `"${c}"`).join(', ')}] or null,
          "style": "minimalist" | "elegant" | "casual" | "sporty" | "trendy" | null,
          "description": "short description of the piece, e.g. flowy satin midi dress" }
      ]
    }
  ]
}
Rules:
- 0 to 3 looks, 3 to 5 pieces each. For a pure question (e.g. which colours go with khaki) you may return 0 or 1 look that illustrates the answer.
- Respect the user's constraints (gender, budget, style DNA, occasion) when given.
- NEVER mention prices, stock, shops or brands: the app itself matches each piece to real products from the catalogue.
- Only fashion and style topics; politely bring other topics back to fashion.`;
}

function clip(v, n) {
  return String(v == null ? '' : v).replace(/\s+/g, ' ').trim().slice(0, n);
}

function sanitizeLooks(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.slice(0, 3).map((l) => ({
    title: clip(l && l.title, 60) || 'Look',
    occasion: clip(l && l.occasion, 80),
    tip: clip(l && l.tip, 220),
    pieces: (Array.isArray(l && l.pieces) ? l.pieces : []).slice(0, 5).map((p) => {
      const set = parser.sanitizeSet({ types: p && p.type ? [p.type] : [], colors: p && p.color ? [p.color] : [], styles: p && p.style ? [p.style] : [] });
      return { type: set.types[0] || null, color: set.colors[0] || null, style: set.styles[0] || null, description: clip(p && p.description, 90) };
    }).filter((p) => p.description || p.type),
  })).filter((l) => l.pieces.length);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------
function createChatService({ repo, llm, reco, logger = console } = {}) {
  if (!repo) repo = require('./catalogRepository');
  if (!llm) llm = require('./llmClient');
  if (!reco) reco = require('./recommendationService').createRecommendationService({ repo });

  async function understand(message, session, vocab) {
    const rules = parser.parseMessage(message, vocab);
    if (!llm.isEnabled()) return { ...rules, source: 'rules' };
    try {
      const history = (session.messages || []).slice(-8).map((m) => ({ role: m.role, content: m.text || '' }));
      const raw = await llm.completeJson({
        system: understandingPrompt(vocab),
        messages: [
          ...history,
          { role: 'user', content: `CURRENT_CRITERIA: ${JSON.stringify(session.criteria || {})}\nLAST_MESSAGE: ${message}` },
        ],
        temperature: 0,
        maxTokens: 400,
      });
      const u = parser.sanitizeUnderstanding(raw, vocab);
      u.location = typeof raw.location === 'string' ? raw.location.slice(0, 60) : null;
      u.radiusKm = Number(raw.radiusKm) > 0 && Number(raw.radiusKm) <= 1000 ? Number(raw.radiusKm) : null;
      u.productRef = { first: 0, second: 1, third: 2, this: 0 }[raw.productRef] ?? null;
      // safety net: unambiguous values found by the rules but missed by the LLM
      for (const f of ['maxPrice', 'minPrice', 'sizes']) {
        if (u.set[f] === undefined && rules.set[f] !== undefined) u.set[f] = rules.set[f];
      }
      if (!u.refinement && rules.refinement) u.refinement = rules.refinement;
      return { ...u, source: 'llm' };
    } catch (err) {
      logger.warn && logger.warn(`[chat] LLM understanding failed, using rules: ${err.message}`);
      return { ...rules, source: 'rules' };
    }
  }

  async function phrase(payload, fallbackText, allowedNumbers) {
    if (!llm.isEnabled()) return { text: fallbackText, source: 'template' };
    try {
      const out = await llm.completeJson({
        system: replyPrompt(payload.language),
        messages: [{ role: 'user', content: JSON.stringify(payload) }],
        temperature: 0.6,
        maxTokens: 300,
      });
      const text = String(out.reply || '').trim();
      if (!text || text.length > 700) throw new Error('empty or too long reply');
      if (!priceGuardrail(text, allowedNumbers)) throw new Error('reply quoted an unknown price');
      return { text, source: 'llm' };
    } catch (err) {
      logger.warn && logger.warn(`[chat] LLM reply rejected, using template: ${err.message}`);
      return { text: fallbackText, source: 'template' };
    }
  }

  /** LLM imagines looks from fashion knowledge; each piece is then matched to a real product (or stays an idea). */
  async function generateLooks({ message, criteria, lang, userId, session }) {
    const vocabLang = L(lang);
    let ctx = null;
    try {
      ctx = await reco.userContext(userId, await repo.getAllProducts());
    } catch (_) { ctx = null; }
    const persona = ctx && ctx.dna && ctx.dna.signals ? ctx.dna.persona : null;
    const history = (session.messages || []).slice(-6).map((m) => ({ role: m.role, content: m.text || '' }));
    const raw = await llm.completeJson({
      system: looksPrompt(lang),
      messages: [...history, {
        role: 'user',
        content: JSON.stringify({
          user_message: message,
          current_criteria: parser.hasAnyCriteria(criteria) ? criteriaSummary(criteria, lang) : null,
          gender: criteria.gender || null,
          budget_per_item_tnd: criteria.maxPrice || null,
          style_dna: persona,
        }),
      }],
      temperature: 0.8,
      maxTokens: 1100,
    });
    const looks = sanitizeLooks(raw.looks);
    const used = [];
    for (const look of looks) {
      for (const piece of look.pieces) {
        piece.product = null;
        if (!piece.type) continue;
        const set = { types: [piece.type] };
        if (piece.color) set.colors = [piece.color];
        if (piece.style) set.styles = [piece.style];
        if (criteria.gender) set.gender = criteria.gender;
        if (criteria.maxPrice) set.maxPrice = criteria.maxPrice;
        const c = parser.mergeCriteria({}, { set });
        try {
          const r = await reco.search(c, { userId, lang: vocabLang, limit: 1, minResults: 1, excludeIds: used, keep: ['types'], ctx: ctx || undefined });
          const prod = r.products[0];
          if (prod) {
            piece.product = prod;
            piece.exact = r.relaxed.length === 0;
            used.push(String(prod._id));
          }
        } catch (_) { /* keep as an idea */ }
      }
    }
    return { reply: clip(raw.reply, 900), looks };
  }

  /** Without an LLM: one look built from the catalogue (search + complete the look). */
  async function catalogueLook({ criteria, lang, userId }) {
    const vocabLang = L(lang);
    let anchor = null;
    if (parser.hasAnyCriteria(criteria)) {
      const s = await reco.search(criteria, { userId, lang: vocabLang, limit: 1 });
      anchor = s.products[0];
    }
    if (!anchor) {
      const fy = await reco.forYou(userId, { limit: 1, lang: vocabLang });
      anchor = fy.products[0];
    }
    if (!anchor) return [];
    const outfit = await reco.completeTheLook(anchor._id, { userId, lang: vocabLang });
    if (!outfit) return [];
    const all = [outfit.anchor, ...outfit.items.map((i) => i.product)];
    return [{
      title: L(lang) === 'fr' ? 'Look FINDME' : 'FINDME look',
      occasion: '',
      tip: '',
      pieces: all.map((p) => ({ type: p.type, color: (p.colors || [])[0] || null, style: null, description: p.name, product: p, exact: true })),
    }];
  }

  function applyRefinement(criteria, refinement, lastProducts) {
    const c = { ...criteria };
    const top = lastProducts[0] || null;
    const avg = lastProducts.length ? lastProducts.reduce((s, p) => s + (Number(p.effectivePrice) || Number(p.price) || 0), 0) / lastProducts.length : null;
    switch (refinement) {
      case 'cheaper': {
        // strictly cheaper than the pick currently recommended
        const ref = top ? Number(top.effectivePrice || top.price) : c.maxPrice;
        if (ref) c.maxPrice = Math.max(1, Math.floor(Math.min(c.maxPrice || Infinity, ref * 0.95)));
        c.minPrice = null;
        break;
      }
      case 'pricier': {
        const ref = avg || c.maxPrice || c.minPrice;
        if (ref) c.minPrice = Math.round(ref * 1.1);
        c.maxPrice = null;
        break;
      }
      case 'more_elegant': c.styles = ['elegant']; break;
      case 'more_casual': c.styles = ['casual']; break;
      case 'other_color': {
        const seen = new Set([...(c.colors || []), ...(top ? (top.colors || []).map((x) => tx.canonicalColor(x) || x) : [])]);
        c.excludeColors = [...new Set([...(c.excludeColors || []), ...seen])];
        c.colors = [];
        break;
      }
      default: break;
    }
    return c;
  }

  async function buildResponse({ session, userId, message, understanding, location }) {
    const lang = understanding.language || session.language || 'en'; // short messages ("Modern") keep the conversation language
    const vocabLang = L(lang);
    const lastProducts = await repo.getProductsByIds(session.lastProductIds || []).then((list) => {
      const byId = new Map(list.map((p) => [String(p._id), p]));
      return (session.lastProductIds || []).map((id) => byId.get(String(id))).filter(Boolean).map((p) => reco.toCard({ product: require('./scoring').enrich(p) }));
    });

    let criteria = parser.mergeCriteria(session.criteria, understanding);
    if (understanding.refinement && understanding.refinement !== 'reset') criteria = applyRefinement(criteria, understanding.refinement, lastProducts);

    let { intent } = understanding;
    const norm = tx.normalize(message || '');
    const shopsAll = repo.getAllShops ? await repo.getAllShops().catch(() => []) : [];
    const place = (message ? geo.detectPlace(message, shopsAll) : null) || (understanding.location ? geo.detectPlace(understanding.location, shopsAll) : null);
    const radius = (message ? geo.parseRadius(message) : null) || understanding.radiusKm || null;
    const prevGeo = session.geo && session.geo.active ? session.geo : null;
    // keep a "near me" conversation going: radius / city change or a filter follow-up ("what about size M?")
    if (prevGeo && ['search', 'refine', 'smalltalk'].includes(intent)) {
      const keys = Object.keys(understanding.set || {});
      const onlyFilters = keys.length > 0 && keys.every((k) => ['sizes', 'maxPrice', 'minPrice', 'colors', 'brands'].includes(k));
      if (radius || place || (onlyFilters && understanding.refinement !== 'more')) intent = 'nearby';
    }
    if (intent === 'refine' && !parser.hasAnyCriteria(criteria) && !lastProducts.length) intent = 'search';
    if (['greeting', 'smalltalk'].includes(intent) && understanding.set && Object.keys(understanding.set).length) intent = 'search';

    const result = { intent, language: lang, criteria, products: [], outfit: null, looks: null, shops: null, nearby: null, relaxed: [] };
    if (intent !== 'nearby' && session.geo) session.geo = { ...session.geo, active: false };
    let similarTo = null;
    let search = null;
    let topic = 'next';

    if (intent === 'search' || intent === 'refine') {
      if (parser.hasAnyCriteria(criteria)) {
        const excludeIds = understanding.refinement === 'more' ? (session.shownProductIds || []) : [];
        const keep = understanding.refinement === 'cheaper' ? ['budget'] : understanding.refinement === 'other_color' ? ['colors'] : [];
        search = await reco.search(criteria, { userId, lang: vocabLang, limit: 6, excludeIds, keep });
        result.products = search.products;
        result.relaxed = search.relaxed;
        topic = search.products.length ? nextQuestionTopic(criteria, search.products) : 'relax';
      } else {
        topic = 'type';
        const fy = await reco.forYou(userId, { limit: 4, lang: vocabLang });
        result.products = fy.products;
        result.inspiration = true;
      }
    } else if (intent === 'outfit') {
      let anchorId = understanding.productIds ? understanding.productIds[0] : null;
      if (!anchorId && understanding.set && understanding.set.types && understanding.set.types.length) {
        const s = await reco.search(criteria, { userId, lang: vocabLang, limit: 1 });
        anchorId = s.products[0] && s.products[0]._id;
      }
      if (!anchorId && lastProducts.length) anchorId = lastProducts[0]._id;
      if (!anchorId && parser.hasAnyCriteria(criteria)) {
        const s = await reco.search(criteria, { userId, lang: vocabLang, limit: 1 });
        anchorId = s.products[0] && s.products[0]._id;
      }
      if (anchorId) {
        result.outfit = await reco.completeTheLook(anchorId, { userId, lang: vocabLang });
        if (result.outfit) result.products = [result.outfit.anchor, ...result.outfit.items.map((i) => i.product)];
      } else {
        intent = 'advice'; // nothing to build around: let the stylist imagine complete looks
        result.intent = 'advice';
      }
    }

    if (intent === 'advice') {
      let creative = null;
      if (llm.isEnabled()) {
        try {
          creative = await generateLooks({ message, criteria, lang, userId, session });
        } catch (err) {
          logger.warn && logger.warn(`[chat] creative looks failed, using catalogue look: ${err.message}`);
        }
      }
      if (!creative) creative = { reply: '', looks: await catalogueLook({ criteria, lang, userId }) };
      result.looks = creative.looks;
      const seen = new Set();
      result.products = creative.looks.flatMap((l) => l.pieces.map((p) => p.product)).filter((p) => p && !seen.has(String(p._id)) && seen.add(String(p._id)));
      const allowed = result.products.flatMap((p) => [p.effectivePrice, p.price, p.discountPrice].filter((x) => Number(x) > 0).map(Number));
      const fr = L(lang) === 'fr';
      const fallbackText = creative.looks.length
        ? (fr ? `Voici ${creative.looks.length > 1 ? 'quelques idées de looks' : 'une idée de look'} ✨ Les pièces disponibles dans nos boutiques sont indiquées, les autres sont des idées pour t'inspirer.`
          : `Here ${creative.looks.length > 1 ? 'are a few look ideas' : 'is a look idea'} ✨ Pieces available in our shops are shown; the others are ideas to inspire you.`)
        : (fr ? 'Dis-moi l’occasion, la saison ou le style que tu vises, et je te propose des looks complets.' : 'Tell me the occasion, season or style you have in mind and I’ll suggest complete looks.');
      const text = creative.reply && priceGuardrail(creative.reply, allowed) ? creative.reply : fallbackText;
      const available = result.products.length;
      return {
        ...result,
        intent: 'advice',
        reply: text,
        quickReplies: fr
          ? [available ? 'Montre-moi des articles similaires' : 'Montre-moi des articles', 'Une autre idée', 'Plus chic', 'Pour le quotidien']
          : [available ? 'Show me similar items' : 'Show me items', 'Another idea', 'More elegant', 'For everyday'],
        criteriaChips: criteriaChips(criteria, lang),
        engine: { understanding: understanding.source, reply: creative.reply && text === creative.reply ? 'llm' : 'template', llm: llm.isEnabled() },
      };
    }

    if (intent === 'similar') {
      const refIdx = message ? geo.parseProductRef(message) : null;
      const anchor = understanding.productIds ? understanding.productIds[0]
        : lastProducts.length ? lastProducts[Math.min(refIdx || 0, lastProducts.length - 1)]._id : null;
      if (anchor) {
        const sim = await reco.similar(anchor, { userId, lang: vocabLang, limit: 6 });
        if (sim) {
          similarTo = sim.anchor.name;
          result.products = sim.products;
          search = { products: sim.products, total: sim.products.length, relaxed: [] };
        }
      }
      topic = 'next';
    }

    if (intent === 'nearby') {
      const set = understanding.set || {};
      const refIdx = message ? geo.parseProductRef(message) : null;
      const origin = place
        ? { lat: place.lat, lng: place.lng, label: place.name, source: 'place' }
        : location && geo.validCoord(location.lat, location.lng)
          ? { lat: Number(location.lat), lng: Number(location.lng), label: location.label || null, source: location.source || 'gps' }
          : prevGeo && prevGeo.origin ? prevGeo.origin : null;
      const newTypes = set.types && set.types.length ? set.types : null;
      // a new product search starts with the default radius unless one is given
      const radiusKm = radius || (!newTypes && prevGeo && prevGeo.radiusKm) || (place ? 15 : 25);
      let productIds = null;
      if (understanding.productIds) {
        productIds = understanding.productIds;
      } else if (/\b(similar|similaire|similaires|alternatives?|pareil)\b/.test(norm) && lastProducts.length) {
        const sim = await reco.similar(lastProducts[Math.min(refIdx || 0, lastProducts.length - 1)]._id, { userId, lang: vocabLang, limit: 10 });
        productIds = sim ? sim.products.map((p) => String(p._id)) : null;
      } else if (refIdx != null && lastProducts.length && (!newTypes || newTypes.includes(lastProducts[Math.min(refIdx, lastProducts.length - 1)].type))) {
        productIds = [String(lastProducts[Math.min(refIdx, lastProducts.length - 1)]._id)];
      } else if (!newTypes && prevGeo && prevGeo.productIds && prevGeo.productIds.length && !set.styles && !set.occasion) {
        productIds = prevGeo.productIds;
      } else if (!newTypes && !Object.keys(set).length && lastProducts.length) {
        // "shops near me" right after seeing products: the product the user is looking at
        productIds = [String(lastProducts[0]._id)];
      }
      const near = await reco.nearbyProducts({ criteria, productIds, origin, radiusKm, userId, lang: vocabLang, limit: 6 });
      result.nearby = near;
      result.products = near.results.map((r) => r.product);
      if (near.results.length === 1) result.shops = { productId: near.results[0].product._id, productName: near.results[0].product.name, shops: near.results[0].stores };
      session.geo = { active: true, radiusKm, origin: near.origin, productIds };
      topic = 'next';
    }

    // ---- phrasing -----------------------------------------------------------
    const fallback = templateReply({ intent, lang, criteria, search: search || { products: result.products, total: result.products.length, relaxed: [] }, outfit: result.outfit, shops: result.shops, nearby: result.nearby, topic, similarTo });
    const allowedNumbers = [
      ...result.products.flatMap((p) => [p.effectivePrice, p.price, p.discountPrice].filter((x) => Number(x) > 0).map(Number)),
      ...(result.outfit ? [result.outfit.totalPrice] : []),
      ...[criteria.maxPrice, criteria.minPrice].filter(Boolean),
      50, 100, 150, 200,
    ];
    const payload = {
      language: lang,
      intent,
      user_message: message,
      criteria: criteriaSummary(criteria, lang),
      relaxed: result.relaxed,
      exact_matches: search ? search.exactCount : undefined,
      close_alternatives: search ? search.alternativeCount : undefined,
      NEXT_QUESTION_TOPIC: topic,
      PRODUCTS: result.products.slice(0, 6).map(compactProduct),
      OUTFIT: result.outfit ? { anchor: result.outfit.anchor.name, items: result.outfit.items.map((i) => ({ slot: i.slot, name: i.product.name, price: i.product.effectivePrice })), total: result.outfit.totalPrice } : undefined,
      SHOPS: result.nearby
        ? result.nearby.stores.slice(0, 4).map((s) => ({ name: s.name, city: s.city, km: s.distanceKm, verified: s.verified }))
        : result.shops ? result.shops.shops.slice(0, 3).map((s) => ({ name: s.name, city: s.city, km: s.distanceKm })) : undefined,
      NEARBY: result.nearby ? {
        radius_km: result.nearby.radiusKm,
        around: result.nearby.origin ? result.nearby.origin.label || 'user location' : null,
        needs_location: result.nearby.needsLocation,
        results: result.nearby.results.slice(0, 4).map((r) => ({ product: r.product.name, price: r.product.effectivePrice, nearest_shop: r.stores[0].name, km: r.stores[0].distanceKm, verified: r.stores[0].verified })),
        nearest_outside_radius: result.nearby.nearestOutside,
        sizes_asked: criteria.sizes,
        note: 'per-shop size stock is not tracked; say so if sizes are asked',
      } : undefined,
      inspiration: result.inspiration || undefined,
    };
    const phrased = ['greeting', 'thanks', 'bye'].includes(intent) && !llm.isEnabled()
      ? { text: fallback, source: 'template' }
      : await phrase(payload, fallback, allowedNumbers);

    const hasLocation = !!(location && location.lat != null);
    let quickReplies = quickRepliesFor(intent === 'outfit' && result.outfit ? 'next' : topic, lang, { hasProducts: result.products.length > 0, hasLocation });
    if (intent === 'nearby' && result.nearby) {
      const fr = L(lang) === 'fr';
      const r2 = Math.min(200, Math.round(result.nearby.radiusKm * 2));
      quickReplies = result.nearby.needsLocation
        ? (fr ? ['Près de Tunis', 'Près de Sousse', 'Près de Sfax', 'Près de Monastir'] : ['Near Tunis', 'Near Sousse', 'Near Sfax', 'Near Monastir'])
        : (fr ? [`Élargir à ${r2} km`, 'Moins cher', 'Articles similaires près de moi', 'Recommencer'] : [`Search within ${r2} km`, 'Cheaper', 'Similar items near me', 'Start over'])
          .filter((q, i) => i > 0 || r2 > result.nearby.radiusKm);
    }
    if (intent === 'similar') quickReplies = L(lang) === 'fr' ? ['Moins cher', 'Où les trouver près de moi ?', 'Complète le look', 'Recommencer'] : ['Cheaper', 'Where to find them near me?', 'Complete the look', 'Start over'];
    if (intent === 'outfit' && result.outfit) quickReplies = L(lang) === 'fr' ? ['Moins cher', 'Plus chic', 'Boutiques proches', 'Recommencer'] : ['Cheaper', 'More elegant', 'Shops near me', 'Start over'];
    if (['greeting', 'about', 'smalltalk'].includes(intent) && !result.products.length) {
      quickReplies = L(lang) === 'fr'
        ? ['Robe noire pour une soirée', 'Baskets à moins de 150 TND', 'Une tenue pour le bureau', 'Quelles sont les tendances ?']
        : ['Black dress for a party', 'Sneakers under 150 TND', 'An outfit for work', "What's trending?"];
    }

    return {
      ...result,
      reply: phrased.text,
      quickReplies,
      criteriaChips: criteriaChips(criteria, lang),
      engine: { understanding: understanding.source, reply: phrased.source, llm: llm.isEnabled() },
    };
  }

  async function persist(session, { userId, message, response }) {
    const ids = response.products.map((p) => String(p._id));
    if (message) session.messages.push({ role: 'user', text: message, intent: response.intent });
    session.messages.push({ role: 'assistant', text: response.reply, products: ids, intent: response.intent });
    session.criteria = response.criteria;
    session.language = response.language;
    if (ids.length && !response.inspiration) {
      session.lastProductIds = ids;
      session.shownProductIds = [...new Set([...(session.shownProductIds || []), ...ids])];
    }
    await repo.saveChatSession(session);
    if (userId && parser.hasAnyCriteria(response.criteria) && ['search', 'refine'].includes(response.intent)) {
      repo.logInteraction({ userId, type: 'search', meta: { criteria: response.criteria, source: 'chatbot' } }).catch(() => {});
    }
  }

  /** Main entry point: POST /chatbot */
  async function handleMessage({ userId, sessionId, message, location, action }) {
    const session = await repo.getChatSession(sessionId, userId);
    const vocab = await repo.getVocabulary();
    let understanding;
    if (action && action.type && action.productId) {
      // buttons on product cards: no NLU needed, the product is known
      const map = { nearby: 'nearby', similar: 'similar', outfit: 'outfit', more: 'refine' };
      understanding = {
        intent: map[action.type] || 'search',
        language: session.language || 'en',
        set: {},
        clear: [],
        refinement: action.type === 'more' ? 'more' : null,
        productIds: [String(action.productId)],
        source: 'action',
      };
      if (!message) {
        const p = await repo.getProductById(action.productId);
        const name = p ? p.name : '';
        const fr = L(session.language) === 'fr';
        message = {
          nearby: fr ? `Où trouver « ${name} » près de moi ?` : `Where can I find "${name}" near me?`,
          similar: fr ? `Articles similaires à « ${name} »` : `Items similar to "${name}"`,
          outfit: fr ? `Complète le look avec « ${name} »` : `Complete the look with "${name}"`,
          more: fr ? 'Montre-moi plus' : 'Show me more',
        }[action.type] || name;
      }
    } else {
      understanding = await understand(message, session, vocab);
    }
    const response = await buildResponse({ session, userId, message, understanding, location });
    await persist(session, { userId, message, response });
    return { sessionId: String(session._id), chatbot: response.reply, ...response };
  }

  /** Remove one criterion chip and re-run the search: PATCH /chatbot/sessions/:id/criteria */
  async function removeCriterion({ userId, sessionId, field, value, location }) {
    const session = await repo.getChatSession(sessionId, userId);
    const c = parser.mergeCriteria(session.criteria, { set: {} });
    if (Array.isArray(c[field])) c[field] = c[field].filter((v) => String(v) !== String(value));
    else if (field in c) c[field] = null;
    session.criteria = c;
    const understanding = { intent: 'search', language: session.language || 'en', set: {}, clear: [], refinement: null, source: 'ui' };
    const response = await buildResponse({ session, userId, message: null, understanding, location });
    await persist(session, { userId, message: null, response });
    return { sessionId: String(session._id), chatbot: response.reply, ...response };
  }

  async function history({ userId, sessionId }) {
    const session = await repo.getChatSession(sessionId, userId);
    const allIds = [...new Set(session.messages.flatMap((m) => (m.products || []).map(String)))];
    const products = await repo.getProductsByIds(allIds);
    const byId = new Map(products.map((p) => [String(p._id), reco.toCard({ product: require('./scoring').enrich(p) })]));
    return {
      sessionId: String(session._id),
      criteria: session.criteria,
      criteriaChips: criteriaChips(parser.mergeCriteria(session.criteria, { set: {} }), session.language),
      messages: session.messages.map((m) => ({ role: m.role, text: m.text, intent: m.intent, products: (m.products || []).map((id) => byId.get(String(id))).filter(Boolean), createdAt: m.createdAt })),
    };
  }

  return { handleMessage, removeCriterion, history, understand, _internals: { templateReply, priceGuardrail, applyRefinement, criteriaChips, criteriaSummary, nextQuestionTopic } };
}

module.exports = { createChatService, priceGuardrail, criteriaSummary, criteriaChips };
