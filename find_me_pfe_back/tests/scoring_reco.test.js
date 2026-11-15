const test = require('node:test');
const assert = require('node:assert/strict');
const { scoreProduct, WEIGHTS } = require('../services/scoring');
const { computeStyleDna } = require('../services/styleDna');
const { createRecommendationService } = require('../services/recommendationService');
const { products, makeRepo, NOW } = require('./fixtures');

const byName = (n) => products.find((p) => p.name === n);

test('weights follow the PFE formula and sum to 1', () => {
  assert.deepEqual(WEIGHTS, { category: 0.3, style: 0.2, budget: 0.15, preference: 0.15, rating: 0.1, trend: 0.1 });
  assert.equal(Object.values(WEIGHTS).reduce((a, b) => a + b, 0).toFixed(5), '1.00000');
});

test('scoreProduct is normalized and explainable', () => {
  const criteria = { types: ['dress'], colors: ['black'], styles: ['elegant'], maxPrice: 150 };
  const good = scoreProduct(byName('Elegant Black Midi Dress'), { criteria, now: NOW, stats: { maxSearched: 80 } });
  const bad = scoreProduct(byName('Red Satin Gown'), { criteria, now: NOW, stats: { maxSearched: 80 } });
  assert.ok(good.score > bad.score);
  assert.ok(good.score <= 1 && good.score >= 0);
  Object.values(good.breakdown).forEach((v) => assert.ok(v >= 0 && v <= 1));
  const codes = good.reasons.map((r) => r.code);
  ['type_match', 'color_match', 'in_budget'].forEach((c) => assert.ok(codes.includes(c), c));
  assert.equal(good.breakdown.category, 1);
  assert.equal(good.breakdown.budget, 1);
});

test('gender mismatch is strongly penalized', () => {
  const ctx = { criteria: { types: ['pants'], gender: 'women' }, now: NOW };
  assert.ok(scoreProduct(byName('Black Chino Pants'), ctx).score < 0.4);
});

test('Style DNA from favorites + quiz', () => {
  const dna = computeStyleDna({
    favorites: [byName('Elegant Black Midi Dress'), byName('Black Heels'), byName('Gold Necklace')],
    preferences: { styles: ['minimalist'], colors: ['black'], budgetMin: 50, budgetMax: 150 },
  }, NOW);
  assert.equal(Object.values(dna.styles).reduce((a, b) => a + b, 0) >= 98, true); // shares ≈ 100%
  assert.equal(dna.topStyles[0], 'elegant');
  assert.ok(['Minimalist Chic', 'Timeless Elegance', 'Modern Glam'].includes(dna.persona), dna.persona);
  assert.equal(dna.topColors[0], 'black');
  assert.deepEqual(dna.budget, { min: 50, max: 150, median: 100 });
  assert.ok(dna.profile.typeAffinity.dress > 0);
});

test('empty Style DNA for a new user (cold start)', () => {
  const dna = computeStyleDna({});
  assert.equal(dna.profile, null);
  assert.equal(dna.persona, 'Style Explorer');
});

test('search: strict filters + ranking', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const r = await reco.search({ types: ['dress'], colors: ['black'], maxPrice: 150 }, { minResults: 1 });
  assert.equal(r.relaxed.length, 0);
  assert.deepEqual(r.products.map((p) => p.name), ['Elegant Black Midi Dress', 'Modern Party Dress']);
  assert.ok(r.products[0].badges.includes('Best Match'));
  assert.ok(r.products[0].matchPercent >= 70);
  // old Flutter ProductModel fields are preserved
  ['_id', 'name', 'price', 'thumbnail', 'images', 'colors', 'size', 'brand', 'shops', 'category', 'createdAt', 'isFavorite', 'discountPrice'].forEach((k) => assert.ok(k in r.products[0], k));
});

test('search: progressive relaxation when nothing matches exactly', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const r = await reco.search({ types: ['dress'], colors: ['green'], maxPrice: 100 }, { minResults: 1 });
  assert.ok(r.relaxed.includes('colors'));
  assert.ok(r.products.length >= 1);
  assert.ok(r.products.every((p) => p.type === 'dress'));
});

test('search: "more" excludes what was already shown', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const first = await reco.search({ types: ['dress'] }, { limit: 2, minResults: 1 });
  const more = await reco.search({ types: ['dress'] }, { limit: 2, minResults: 1, excludeIds: first.products.map((p) => p._id) });
  const ids = new Set(first.products.map((p) => p._id));
  assert.ok(more.products.every((p) => !ids.has(p._id)));
});

test('completeTheLook for a dress: shoes + bag + jewelry, colour-coherent', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const look = await reco.completeTheLook(byName('Elegant Black Midi Dress')._id);
  assert.deepEqual(look.items.map((i) => i.slot), ['shoes', 'bag', 'jewelry']);
  assert.equal(look.items[0].product.name, 'Black Heels');
  assert.equal(look.totalPrice, 129 + look.items.reduce((s, i) => s + i.product.effectivePrice, 0));
});

test('similar products stay in the same family and exclude the anchor', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const anchor = byName('Elegant Black Midi Dress');
  const r = await reco.similar(anchor._id);
  assert.ok(r.products.length > 0);
  assert.ok(r.products.every((p) => p._id !== anchor._id && p.type === 'dress'));
  assert.equal(r.products[0].name, 'Modern Party Dress');
});

test('trending uses the time window counts', async () => {
  const recent = { [byName('Beige Tote Bag')._id]: 30 };
  const reco = createRecommendationService({ repo: makeRepo({ recent }), now: () => NOW });
  const r = await reco.trending({ days: 7 });
  assert.equal(r.products[0].name, 'Beige Tote Bag');
});

test('budget picks never exceed the budget', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const r = await reco.budgetPicks({ max: 100 });
  assert.ok(r.products.length > 0);
  assert.ok(r.products.every((p) => p.effectivePrice <= 100));
});

test('For You is personalized once the user has signals', async () => {
  const favorites = [byName('Sport Tracksuit')._id, byName('Running Shoes')._id];
  const reco = createRecommendationService({ repo: makeRepo({ favorites }), now: () => NOW });
  const r = await reco.forYou('cccccccccccccccccccccccc', { limit: 3 });
  assert.equal(r.coldStart, false);
  assert.ok(r.products.every((p) => !favorites.includes(p._id)));
  // the sporty profile gets the sport-brand sneakers first
  assert.equal(r.products[0].name, 'White Leather Sneakers');
  assert.ok(r.products[0].reasons.some((x) => x.code === 'dna_match'));
});

test('nearby shops sorted by distance', async () => {
  const reco = createRecommendationService({ repo: makeRepo(), now: () => NOW });
  const p = { ...byName('Elegant Black Midi Dress') };
  const r = await reco.nearbyShops(p._id, { lat: 35.83, lng: 10.6 });
  assert.equal(r.shops[0].name, 'Zara Sousse');
  assert.ok(r.shops[0].distanceKm < 2);
});
