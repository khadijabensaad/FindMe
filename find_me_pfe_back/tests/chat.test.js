const test = require('node:test');
const assert = require('node:assert/strict');
const { createChatService, priceGuardrail } = require('../services/chatService');
const { createRecommendationService } = require('../services/recommendationService');
const { makeRepo, NOW } = require('./fixtures');

const quiet = { warn() {} };
const noLLM = { isEnabled: () => false };

function setup(llm = noLLM) {
  const repo = makeRepo();
  const reco = createRecommendationService({ repo, now: () => NOW });
  return { repo, chat: createChatService({ repo, llm, reco, logger: quiet }) };
}

test('multi-turn conversation without LLM (rules + templates)', async () => {
  const { chat } = setup();
  const sid = 's1';
  let r = await chat.handleMessage({ sessionId: sid, message: 'I need a black dress for a birthday party, under 150 TND.' });
  assert.equal(r.intent, 'search');
  assert.ok(r.products.length >= 1);
  assert.ok(r.products.every((p) => p.type === 'dress' && p.effectivePrice <= 150));
  assert.equal(r.products[0].name, 'Elegant Black Midi Dress');
  assert.match(r.reply, /Elegant Black Midi Dress/);
  assert.ok(r.criteriaChips.some((c) => c.field === 'maxPrice'));
  assert.ok(r.quickReplies.length >= 3);
  assert.equal(r.chatbot, r.reply); // backward compatible field

  // context is remembered: only the style changes
  r = await chat.handleMessage({ sessionId: sid, message: 'Modern' });
  assert.deepEqual(r.criteria.types, ['dress']);
  assert.deepEqual(r.criteria.styles, ['trendy']);
  assert.equal(r.products[0].name, 'Modern Party Dress');

  // refinement: cheaper
  r = await chat.handleMessage({ sessionId: sid, message: 'cheaper please' });
  assert.ok(r.criteria.maxPrice < 145);
  assert.ok(r.products.every((p) => p.effectivePrice <= r.criteria.maxPrice), 'cheaper never shows pricier items');

  // outfit around the last best product
  r = await chat.handleMessage({ sessionId: sid, message: 'Complete the look' });
  assert.equal(r.intent, 'outfit');
  assert.ok(r.outfit && r.outfit.items.length >= 2);
  assert.match(r.reply, /Total/);

  // nearby shops with the user location
  r = await chat.handleMessage({ sessionId: sid, message: 'Shops near me', location: { lat: 35.83, lng: 10.6 } });
  assert.equal(r.intent, 'nearby');
  assert.ok(r.shops.shops.length >= 1);
  assert.ok(r.shops.shops[0].distanceKm != null);
});

test('French conversation gets French replies and chips', async () => {
  const { chat } = setup();
  const r = await chat.handleMessage({ sessionId: 'fr', message: 'Je cherche des chaussures noires à moins de 130 dinars' });
  assert.equal(r.language, 'fr');
  assert.match(r.reply, /J'ai trouvé|meilleur choix/);
  assert.ok(r.products.every((p) => p.type === 'shoes'));
  assert.ok(r.criteriaChips.some((c) => c.label === 'noir'));
});

test('greeting shows suggestions, no products', async () => {
  const { chat } = setup();
  const r = await chat.handleMessage({ sessionId: 'g', message: 'Salut' });
  assert.equal(r.intent, 'greeting');
  assert.equal(r.products.length, 0);
  assert.ok(r.quickReplies.length === 4);
});

test('removing a criterion chip re-runs the search', async () => {
  const { chat } = setup();
  await chat.handleMessage({ sessionId: 'chip', message: 'a green dress under 100 TND' });
  const r = await chat.removeCriterion({ sessionId: 'chip', field: 'colors', value: 'green' });
  assert.deepEqual(r.criteria.colors, []);
  assert.ok(r.products.length >= 1);
});

test('LLM mode: understanding JSON is sanitized and the reply is grounded', async () => {
  const calls = [];
  const llm = {
    isEnabled: () => true,
    async completeJson({ system }) {
      calls.push(system.slice(0, 40));
      if (system.includes('language-understanding')) {
        return { intent: 'search', language: 'tn', set: { types: ['robe'], colors: ['ak7el'], maxPrice: '150', brands: ['Gucci'] } };
      }
      return { reply: 'Lgit lik Elegant Black Midi Dress b 129 TND, tji mezyena 3lik 🖤 T7eb chic wala moderne?' };
    },
  };
  const { chat } = setup(llm);
  const r = await chat.handleMessage({ sessionId: 'llm', message: 'nheb robe k7al b 150 dinar' });
  assert.equal(r.engine.understanding, 'llm');
  assert.equal(r.engine.reply, 'llm');
  assert.deepEqual(r.criteria.types, ['dress']);
  assert.deepEqual(r.criteria.colors, ['black']);
  assert.deepEqual(r.criteria.brands, []); // unknown brand dropped
  assert.equal(r.criteria.maxPrice, 150);
  assert.match(r.reply, /129 TND/);
  assert.equal(calls.length, 2);
});

test('LLM mode: a hallucinated price is rejected → template', async () => {
  const llm = {
    isEnabled: () => true,
    async completeJson({ system }) {
      if (system.includes('language-understanding')) return { intent: 'search', language: 'en', set: { types: ['dress'], colors: ['black'] } };
      return { reply: 'The Elegant Black Midi Dress is only 59 TND today!' };
    },
  };
  const { chat } = setup(llm);
  const r = await chat.handleMessage({ sessionId: 'h', message: 'black dress' });
  assert.equal(r.engine.reply, 'template');
  assert.doesNotMatch(r.reply, /59 TND/);
});

test('LLM down → rule-based understanding still works', async () => {
  const llm = { isEnabled: () => true, async completeJson() { throw new Error('timeout'); } };
  const { chat } = setup(llm);
  const r = await chat.handleMessage({ sessionId: 'down', message: 'white sneakers size 39' });
  assert.equal(r.engine.understanding, 'rules');
  assert.equal(r.products[0].name, 'White Leather Sneakers');
});

test('price guardrail', () => {
  assert.equal(priceGuardrail('Only 129 TND', [129]), true);
  assert.equal(priceGuardrail('Only 99 dt', [129]), false);
  assert.equal(priceGuardrail('No price here', []), true);
});

test('search interactions are logged for Style DNA', async () => {
  const { chat, repo } = setup();
  await chat.handleMessage({ userId: 'cccccccccccccccccccccccc', sessionId: 'log', message: 'black dress under 150 TND' });
  await new Promise((r) => setImmediate(r));
  assert.ok(repo.logged.some((l) => l.type === 'search' && l.meta.criteria.types[0] === 'dress'));
});

// ---------------------------------------------------------------------------
// Creative stylist: LLM fashion knowledge + catalogue matching
// ---------------------------------------------------------------------------
function creativeLLM(reply) {
  return {
    isEnabled: () => true,
    async completeJson({ system }) {
      if (system.includes('language-understanding')) return { intent: 'advice', language: 'fr', set: { occasion: 'wedding' } };
      return {
        reply,
        looks: [{
          title: 'Soirée de mariage chic',
          occasion: 'Mariage en été',
          tip: 'Ajoute une pochette dorée pour illuminer le noir.',
          pieces: [
            { type: 'dress', color: 'black', style: 'elegant', description: 'Robe midi en satin noir' },
            { type: 'shoes', color: 'black', style: 'elegant', description: 'Escarpins noirs' },
            { type: 'jacket', color: 'green', style: 'elegant', description: 'Blazer kaki structuré' },
            { type: 'spaceship', color: 'ultraviolet', description: '' },
          ],
        }],
      };
    },
  };
}

test('advice: the LLM imagines looks, pieces are matched to real products or kept as ideas', async () => {
  const { chat } = setup(creativeLLM('Pour un mariage en été, mise sur le noir élégant ✨'));
  const r = await chat.handleMessage({ sessionId: 'adv', message: 'Des idées de tenues pour un mariage en été ?' });
  assert.equal(r.intent, 'advice');
  assert.equal(r.engine.reply, 'llm');
  assert.equal(r.looks.length, 1);
  const pieces = r.looks[0].pieces;
  assert.equal(pieces.length, 3); // invalid piece dropped
  assert.equal(pieces[0].product.name, 'Elegant Black Midi Dress');
  assert.equal(pieces[1].product.name, 'Black Heels');
  assert.equal(pieces[2].product, null); // no jacket in the catalogue → stays an idea
  assert.deepEqual(r.products.map((p) => p.name), ['Elegant Black Midi Dress', 'Black Heels']);
});

test('advice: an invented price in the creative reply is rejected', async () => {
  const { chat } = setup(creativeLLM('Cette robe ne coûte que 49 TND !'));
  const r = await chat.handleMessage({ sessionId: 'adv2', message: 'Des idées de tenues pour un mariage ?' });
  assert.equal(r.engine.reply, 'template');
  assert.doesNotMatch(r.reply, /49 TND/);
  assert.equal(r.looks.length, 1);
});

test('advice without LLM: a look built from the catalogue', async () => {
  const { chat } = setup();
  const r = await chat.handleMessage({ sessionId: 'adv3', message: 'Des idées de tenues pour une soirée ?' });
  assert.equal(r.intent, 'advice');
  assert.equal(r.looks.length, 1);
  assert.ok(r.looks[0].pieces.length >= 2);
  assert.ok(r.looks[0].pieces.every((p) => p.product));
});
