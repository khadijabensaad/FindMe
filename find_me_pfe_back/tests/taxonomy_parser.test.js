const test = require('node:test');
const assert = require('node:assert/strict');
const tx = require('../services/taxonomy');
const parser = require('../services/criteriaParser');

test('detectTypes handles FR/EN synonyms and t-shirt vs shirt', () => {
  assert.deepEqual(tx.detectTypes('Je cherche une robe noire'), ['dress']);
  assert.deepEqual(tx.detectTypes('a white t-shirt'), ['tshirt']);
  assert.deepEqual(tx.detectTypes('a shirt and a t-shirt'), ['shirt', 'tshirt']);
  assert.deepEqual(tx.detectTypes('des baskets blanches'), ['shoes']);
  assert.deepEqual(tx.detectTypes('short dress'), ['dress']);
  assert.deepEqual(tx.detectTypes("boucles d'oreilles dorées"), ['earrings']);
  assert.deepEqual(tx.detectTypes('montre-moi plus de robes'), ['dress']);
  assert.deepEqual(tx.detectTypes('montre plus'), []);
  assert.deepEqual(tx.detectTypes('une montre dorée'), ['watch']);
});

test('colours: French forms, multi-word and canonical', () => {
  assert.deepEqual(tx.detectColors('robe noire'), ['black']);
  assert.deepEqual(tx.detectColors('chemise bleu clair'), ['light blue']);
  assert.deepEqual(tx.detectColors('or et argent').sort(), ['silver']); // "or" is ambiguous in French
  assert.equal(tx.canonicalColor('Gris'), 'grey');
});

test('budget parsing', () => {
  assert.deepEqual(parser.parseBudget('under 150 TND'), { minPrice: null, maxPrice: 150 });
  assert.deepEqual(parser.parseBudget('à moins de 100 dinars'), { minPrice: null, maxPrice: 100 });
  assert.deepEqual(parser.parseBudget('entre 50 et 120 dt'), { minPrice: 50, maxPrice: 120 });
  assert.deepEqual(parser.parseBudget('budget 80'), { minPrice: null, maxPrice: 80 });
  assert.deepEqual(parser.parseBudget('size 38 please'), { minPrice: null, maxPrice: null });
});

test('sizes: single letters only after "size"/"taille"', () => {
  assert.deepEqual(parser.parseSizes("I'm looking for a dress"), []);
  assert.deepEqual(parser.parseSizes('taille M'), ['M']);
  assert.deepEqual(parser.parseSizes('do you have it in XL'), ['XL']);
  assert.deepEqual(parser.parseSizes('pointure 38'), ['38']);
});

test('parseMessage: the reference scenario', () => {
  const u = parser.parseMessage('I need a black dress for a birthday party, under 150 TND.', { brands: ['Zara'] });
  assert.equal(u.intent, 'search');
  assert.equal(u.language, 'en');
  assert.deepEqual(u.set.types, ['dress']);
  assert.deepEqual(u.set.colors, ['black']);
  assert.equal(u.set.maxPrice, 150);
  assert.equal(u.set.occasion, 'party');
  assert.ok(u.set.styles.includes('elegant'));
});

test('parseMessage: French, refinements, intents', () => {
  const fr = parser.parseMessage('Je cherche une robe rouge pour une soirée à moins de 100 dinars');
  assert.equal(fr.language, 'fr');
  assert.deepEqual(fr.set.colors, ['red']);
  assert.equal(fr.set.maxPrice, 100);
  assert.equal(parser.parseMessage('moins cher').refinement, 'cheaper');
  assert.equal(parser.parseMessage('plus chic stp').refinement, 'more_elegant');
  assert.equal(parser.parseMessage('dans une autre couleur').refinement, 'other_color');
  assert.equal(parser.parseMessage('Complète le look').intent, 'outfit');
  assert.equal(parser.parseMessage('où acheter ça près de moi ?').intent, 'nearby');
  assert.equal(parser.parseMessage('Salut !').intent, 'greeting');
  assert.equal(parser.parseMessage('Bonjour, je veux des baskets').intent, 'search');
  assert.equal(parser.parseMessage('merci beaucoup').intent, 'thanks');
  assert.deepEqual(parser.parseMessage('une robe, pas en noir').set.excludeColors, ['black']);
});

test('sanitize rejects values outside the vocabulary (LLM output safety net)', () => {
  const u = parser.sanitizeUnderstanding({
    intent: 'hack', language: 'fr',
    set: { types: ['robe', 'spaceship'], colors: ['noir', 'ultraviolet'], brands: ['Gucci', 'zara'], maxPrice: -5, styles: ['chic'], sizes: ['m', 'XXXXL'] },
    clear: ['password', 'colors'],
  }, { brands: ['Zara'] });
  assert.equal(u.intent, 'search');
  assert.deepEqual(u.set.types, ['dress']);
  assert.deepEqual(u.set.colors, ['black']);
  assert.deepEqual(u.set.brands, ['Zara']);
  assert.equal(u.set.maxPrice, null);
  assert.deepEqual(u.set.styles, ['elegant']);
  assert.deepEqual(u.set.sizes, ['M']);
  assert.deepEqual(u.clear, ['colors']);
});

test('mergeCriteria keeps context between turns', () => {
  let c = parser.mergeCriteria({}, { set: { types: ['dress'], colors: ['black'], maxPrice: 150 } });
  c = parser.mergeCriteria(c, { set: { styles: ['elegant'] } });
  assert.deepEqual(c.types, ['dress']);
  assert.deepEqual(c.colors, ['black']);
  assert.equal(c.maxPrice, 150);
  assert.deepEqual(c.styles, ['elegant']);
  c = parser.mergeCriteria(c, { set: {}, refinement: 'reset', clear: ['all'] });
  assert.equal(parser.hasAnyCriteria(c), false);
});
