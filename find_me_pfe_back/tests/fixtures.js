// In-memory fake catalogue + repository used by the unit tests (no MongoDB needed).
const DAY = 24 * 3600 * 1000;
const NOW = Date.UTC(2026, 10, 14);
let n = 0;
const id = () => (++n).toString(16).padStart(24, 'a');

function P(name, price, extra = {}) {
  return {
    _id: id(), name, price, rating: 4, barcode: n, thumbnail: `https://img/${n}.jpg`, images: [], colors: ['black'],
    description: '', size: ['S', 'M', 'L'], brand: 'Zara', shops: ['Zara Sousse'], category: ['Women'],
    discountPrice: -1, searched: 5, createdAt: new Date(NOW - 60 * DAY), updatedAt: new Date(NOW - 60 * DAY), __v: 0, ...extra,
  };
}

const products = [
  P('Elegant Black Midi Dress', 129, { description: 'Satin evening dress for cocktail parties', rating: 4.6, searched: 40 }),
  P('Modern Party Dress', 145, { colors: ['black', 'gold'], description: 'Trendy one shoulder party dress', brand: 'Bershka', shops: ['Bershka Tunis'], rating: 4.2 }),
  P('Red Satin Gown', 260, { colors: ['red'], description: 'Long evening gown', brand: 'Mango', rating: 4.8 }),
  P('Floral Summer Dress', 79, { colors: ['white', 'pink'], description: 'Light cotton dress for the beach', brand: 'Bershka', rating: 3.9 }),
  P('Basic White T-Shirt', 25, { colors: ['white'], category: ['Women'], description: 'Essential cotton t-shirt', size: ['XS', 'S', 'M'], searched: 80 }),
  P('Oversize Graphic Tee', 39, { colors: ['grey', 'black', 'red', 'blue'], brand: 'Pull&Bear', category: ['Men'], description: 'Oversize street print' }),
  P('Slim Blue Jeans', 99, { colors: ['blue'], brand: "Levi's", category: ['Women'], size: ['S', 'M'] }),
  P('Black Chino Pants', 89, { colors: ['black'], brand: 'Zara', category: ['Men'], size: ['M', 'L', 'XL'] }),
  P('White Leather Sneakers', 159, { colors: ['white'], brand: 'Nike', category: ['Shoes', 'Women'], size: ['38', '39', '40'], searched: 60 }),
  P('Black Heels', 119, { colors: ['black'], description: 'Elegant pointed heels', category: ['Shoes', 'Women'], size: ['37', '38'] }),
  P('Running Shoes', 210, { colors: ['blue', 'white'], brand: 'Adidas', category: ['Sport', 'Men'], size: ['42', '43'] }),
  P('Gold Necklace', 65, { colors: ['gold'], category: ['Jewelery'], description: 'Fine gold chain', size: [] }),
  P('Silver Bracelet', 45, { colors: ['silver'], category: ['Jewelery'], size: [] }),
  P('Black Leather Bag', 149, { colors: ['black'], brand: 'Mango', category: ['Accessories', 'Women'], size: [], discountPrice: 119 }),
  P('Beige Tote Bag', 95, { colors: ['beige'], category: ['Accessories'], size: [], createdAt: new Date(NOW - 3 * DAY) }),
  P('Sport Tracksuit', 130, { colors: ['black', 'white'], brand: 'Adidas', category: ['Sport', 'Men'] }),
  P('Classic White Shirt', 69, { colors: ['white'], brand: 'Zara', category: ['Men'], description: 'Formal cotton shirt' }),
  P('Nivea Soft Cream', 12, { colors: ['white'], brand: 'Nivea', category: ['Cosmetics'], description: 'Moisturizer', size: [] }),
];

const byName = (n) => products.find((p) => p.name === n);
// product side of the relation
byName('White Leather Sneakers').shops = ['Zara Sousse', 'Mall of Sousse'];
byName('Black Heels').shops = ['Zara Sousse', 'Mall of Sousse'];
byName('Floral Summer Dress').shops = ['Bershka Tunis'];
byName('Modern Party Dress').shops = ['Bershka Tunis'];
// shops: coordinates + product ids (both sides of the relation, like MongoDB)
const shops = [
  { _id: 's1', name: 'Zara Sousse', city: 'Sousse', region: 'Sousse', coordinates: { latitude: 35.8256, longitude: 10.6084 },
    products: products.filter((p) => p.shops.includes('Zara Sousse')).map((p) => p._id) },
  { _id: 's2', name: 'Bershka Tunis', city: 'Tunis', region: 'Tunis', coordinates: { latitude: 36.8065, longitude: 10.1815 },
    products: [byName('Modern Party Dress')._id] }, // Floral Summer Dress only declared on the product side
  { _id: 's3', name: 'Mall of Sousse', city: 'Sousse', region: 'Sousse', coordinates: { latitude: 35.8730, longitude: 10.5960 },
    products: [byName('White Leather Sneakers')._id, byName('Black Heels')._id] },
  { _id: 's4', name: 'Ghost Shop', city: 'Nowhere', region: 'Nowhere', coordinates: { latitude: 0, longitude: 0 }, products: [] },
];

function makeSession() {
  return { _id: 'bbbbbbbbbbbbbbbbbbbbbbbb', messages: [], criteria: {}, shownProductIds: [], lastProductIds: [], language: 'en' };
}

function makeRepo({ favorites = [], interactions = [], preferences = null, recent = {} } = {}) {
  const sessions = {};
  const logged = [];
  return {
    logged,
    sessions,
    async getAllProducts() { return products; },
    async getProductById(i) { return products.find((p) => p._id === String(i)) || null; },
    async getProductsByIds(ids) { const s = new Set(ids.map(String)); return products.filter((p) => s.has(p._id)); },
    async getVocabulary() { return { brands: [...new Set(products.map((p) => p.brand))], categories: [] }; },
    async getUserFavorites() { return favorites; },
    async getInteractions() { return interactions; },
    async getPreferences() { return preferences; },
    async getDislikedProductIds() { return []; },
    async getRecentProductCounts() { return recent; },
    async getShopsByNames(names) { return shops.filter((s) => names.includes(s.name)); },
    async getAllShops() { return shops; },
    async logInteraction(x) { logged.push(x); },
    async getChatSession(sid) { if (!sessions[sid || 'x']) sessions[sid || 'x'] = makeSession(); return sessions[sid || 'x']; },
    async saveChatSession(s) { return s; },
  };
}

module.exports = { products, shops, makeRepo, NOW, DAY, byName };
