const test = require('node:test');
const assert = require('node:assert/strict');
const geo = require('../services/geoService');
const { createChatService } = require('../services/chatService');
const { createRecommendationService } = require('../services/recommendationService');
const { makeRepo, NOW, byName, shops } = require('./fixtures');

const SOUSSE = { lat: 35.8300, lng: 10.6000, source: 'gps' };
const quiet = { warn() {} };
function setup() {
  const repo = makeRepo();
  const reco = createRecommendationService({ repo, now: () => NOW });
  return { repo, reco, chat: createChatService({ repo, llm: { isEnabled: () => false }, reco, logger: quiet }) };
}

test('haversine: Sousse → Tunis ≈ 115 km', () => {
  const d = geo.haversineKm(35.8256, 10.6084, 36.8065, 10.1815);
  assert.ok(d > 110 && d < 120, String(d));
});

test('places, radius and product references', () => {
  assert.equal(geo.detectPlace('stores in Tunis please').name, 'Tunis');
  assert.equal(geo.detectPlace('près de La Marsa').name, 'La Marsa');
  assert.equal(geo.detectPlace('une robe noire'), null);
  assert.equal(geo.detectPlace('in Nowhere', shops), null); // invalid (0,0) coordinates are ignored
  assert.equal(geo.parseRadius('within 10 km'), 10);
  assert.equal(geo.parseRadius('dans un rayon de 5,5 km'), 5.5);
  assert.equal(geo.parseProductRef('Where can I find the first one near me?'), 0);
  assert.equal(geo.parseProductRef('le deuxième'), 1);
});

test('availability distinguishes verified (both sides) from declared (one side)', () => {
  const avail = geo.availability(byName('Floral Summer Dress'), shops);
  assert.equal(avail.length, 1);
  assert.equal(avail[0].verified, false);
  assert.equal(avail[0].declaredBy, 'product');
  assert.equal(geo.availability(byName('Modern Party Dress'), shops)[0].verified, true);
});

test('nearbyProducts: radius filter, distance sort, invalid coordinates skipped', async () => {
  const { reco } = setup();
  const r = await reco.nearbyProducts({ criteria: { types: ['shoes'] }, origin: SOUSSE, radiusKm: 10 });
  assert.ok(r.results.length >= 2);
  const d = r.results.map((x) => x.stores[0].distanceKm);
  assert.deepEqual(d, [...d].sort((a, b) => a - b));
  assert.ok(r.stores.every((s) => s.name !== 'Ghost Shop' && s.distanceKm <= 10));
  assert.ok(r.results.find((x) => x.product.name === 'White Leather Sneakers').stores.length === 2);
});

test('the spec conversation: dress → budget → first one near me → size M', async () => {
  const { chat } = setup();
  const sid = 'spec';
  let r = await chat.handleMessage({ sessionId: sid, message: 'Find me a black dress' });
  assert.equal(r.intent, 'search');
  r = await chat.handleMessage({ sessionId: sid, message: 'Under 150 TND' });
  assert.equal(r.criteria.maxPrice, 150);
  const first = r.products[0];
  r = await chat.handleMessage({ sessionId: sid, message: 'Where can I find the first one near me?', location: SOUSSE });
  assert.equal(r.intent, 'nearby');
  assert.equal(r.nearby.results.length, 1);
  assert.equal(r.nearby.results[0].product._id, first._id); // the product was not forgotten
  assert.equal(r.nearby.results[0].stores[0].name, 'Zara Sousse');
  assert.ok(r.nearby.results[0].stores[0].distanceKm < 2);
  assert.match(r.reply, /Zara Sousse/);
  r = await chat.handleMessage({ sessionId: sid, message: 'What about size M?' });
  assert.equal(r.intent, 'nearby'); // still the same product, same place
  assert.equal(r.nearby.results[0].product._id, first._id);
  assert.match(r.reply, /Size M/);
});

test('city search with an honest answer when nothing is inside the radius, then widen', async () => {
  const { chat } = setup();
  await chat.handleMessage({ sessionId: 'city', message: 'black dress under 150 TND' });
  let r = await chat.handleMessage({ sessionId: 'city', message: 'Show me stores selling this product in Tunis.' });
  assert.equal(r.intent, 'nearby');
  assert.equal(r.nearby.origin.label, 'Tunis');
  assert.equal(r.nearby.results.length, 0);
  assert.equal(r.nearby.nearestOutside.shop, 'Zara Sousse');
  assert.match(r.reply, /No shop within 15 km/);
  assert.ok(r.quickReplies.some((q) => /within 30 km/.test(q)));
  r = await chat.handleMessage({ sessionId: 'city', message: 'Search within 200 km' });
  assert.equal(r.nearby.radiusKm, 200);
  assert.equal(r.nearby.results[0].stores[0].name, 'Zara Sousse');
});

test('category search near a place, verified vs to-confirm availability', async () => {
  const { chat } = setup();
  const r = await chat.handleMessage({ sessionId: 'cat', message: 'Show me nearby stores with dresses in Tunis' });
  assert.equal(r.intent, 'nearby');
  const names = r.nearby.results.map((x) => x.product.name);
  assert.ok(names.includes('Modern Party Dress') && names.includes('Floral Summer Dress'));
  const floral = r.nearby.results.find((x) => x.product.name === 'Floral Summer Dress');
  assert.equal(floral.stores[0].verified, false);
});

test('no location: stores listed without distances and the user is asked for a place', async () => {
  const { chat } = setup();
  const r = await chat.handleMessage({ sessionId: 'noloc', message: 'Find black sneakers available in nearby stores.' });
  assert.equal(r.intent, 'nearby');
  assert.equal(r.nearby.needsLocation, true);
  assert.ok(r.quickReplies.includes('Near Tunis'));
});

test('product-card actions: nearby and similar without any NLU', async () => {
  const { chat } = setup();
  const id = byName('White Leather Sneakers')._id;
  let r = await chat.handleMessage({ sessionId: 'act', action: { type: 'nearby', productId: id }, location: SOUSSE });
  assert.equal(r.intent, 'nearby');
  assert.equal(r.nearby.results[0].product._id, id);
  assert.equal(r.nearby.results[0].stores.length, 2);
  r = await chat.handleMessage({ sessionId: 'act', action: { type: 'similar', productId: byName('Elegant Black Midi Dress')._id } });
  assert.equal(r.intent, 'similar');
  assert.ok(r.products.length > 0);
  assert.ok(r.products.every((p) => p.type === 'dress'));
});
