// Profile endpoints (GET /auth/me, PUT /auth/updateProfile, PUT /auth/changePassword)
// and the auth middleware, tested with in-memory fakes (no MongoDB, no Cloudinary).
const test = require('node:test');
const assert = require('node:assert');
const Module = require('module');

// --- fakes -----------------------------------------------------------------
const users = new Map();
const hash = (p) => `hashed:${p}`;
function doc(u) {
  return { ...u, save: async function () { users.set(this._id, { ...this }); } };
}
function query(value) {
  // mimics mongoose: .select().lean() chain or direct await
  const q = {
    select(fields) {
      if (fields === '-password' && value) { const { password, ...rest } = value; value = rest; }
      return q;
    },
    lean() { return q; },
    then(res, rej) { return Promise.resolve(value).then(res, rej); },
  };
  return q;
}
const fakeUserModel = {
  findById: (id) => {
    const u = users.get(String(id));
    return query(u ? doc(u) : null);
  },
  findByIdAndUpdate: (id, { $set }) => {
    const u = users.get(String(id));
    if (!u) return query(null);
    Object.assign(u, $set);
    return query({ ...u });
  },
};
const uploads = [];
const fakes = {
  '../models/userModel': fakeUserModel,
  '../models/productModel': {},
  '../models/userOTPVerification': {},
  '../models/discountModel': {},
  cloudinary: { v2: { config() {}, uploader: { upload: async (path) => { uploads.push(path); return { secure_url: `https://cdn.test/${path}` }; } } } },
  bcrypt: { compare: async (p, h) => hash(p) === h, genSalt: async () => 'salt', hash: async (p) => hash(p) },
  jsonwebtoken: {
    sign: () => 'token',
    verify: (t) => {
      if (t === 'expired') { const e = new Error('jwt expired'); e.name = 'TokenExpiredError'; throw e; }
      if (t !== 'good') throw new Error('invalid signature');
      return { id: 'u1', role: 'Client' };
    },
  },
  nodemailer: { createTransport: () => ({ sendMail: async () => ({}) }) },
  dotenv: { config() {} },
};
const realLoad = Module._load;
Module._load = function (request, ...rest) {
  if (Object.prototype.hasOwnProperty.call(fakes, request)) return fakes[request];
  return realLoad.call(this, request, ...rest);
};
const auth = require('../controllers/authController');
const { verifyToken } = require('../middlewares/verifyToken');
Module._load = realLoad;

function res() {
  const r = { code: 200, body: null };
  r.status = (c) => { r.code = c; return r; };
  r.json = (b) => { r.body = b; return r; };
  return r;
}
function reset() {
  users.clear();
  users.set('u1', { _id: 'u1', username: 'Khadija', email: 'k@test.tn', image: '', role: 'Client', password: hash('oldpass123') });
}

// --- tests -----------------------------------------------------------------
test('GET /auth/me returns the user without the password hash', async () => {
  reset();
  const r = res();
  await auth.getMe({ userId: 'u1' }, r);
  assert.equal(r.code, 200);
  assert.equal(r.body.user.username, 'Khadija');
  assert.equal(r.body.user.password, undefined);
});

test('updateProfile saves the new username and the uploaded photo', async () => {
  reset();
  const r = res();
  await auth.updateProfile({ userId: 'u1', body: { username: '  Khadija B ' }, file: { path: '/tmp/p.jpg' } }, r);
  assert.equal(r.code, 200);
  assert.equal(r.body.user.username, 'Khadija B');
  assert.equal(r.body.user.image, 'https://cdn.test//tmp/p.jpg');
  assert.equal(users.get('u1').username, 'Khadija B', 'persisted');
  assert.equal(r.body.user.password, undefined);
});

test('updateProfile rejects an empty or too short update', async () => {
  reset();
  const r1 = res();
  await auth.updateProfile({ userId: 'u1', body: {} }, r1);
  assert.equal(r1.code, 400);
  const r2 = res();
  await auth.updateProfile({ userId: 'u1', body: { username: 'K' } }, r2);
  assert.equal(r2.code, 400);
  assert.equal(users.get('u1').username, 'Khadija');
});

test('changePassword checks the current password and hashes the new one', async () => {
  reset();
  const bad = res();
  await auth.changePassword({ userId: 'u1', body: { currentPassword: 'wrong', newPassword: 'newpass123' } }, bad);
  assert.equal(bad.code, 400);
  const short = res();
  await auth.changePassword({ userId: 'u1', body: { currentPassword: 'oldpass123', newPassword: 'short' } }, short);
  assert.equal(short.code, 400);
  const ok = res();
  await auth.changePassword({ userId: 'u1', body: { currentPassword: 'oldpass123', newPassword: 'newpass123' } }, ok);
  assert.equal(ok.code, 200);
  assert.equal(users.get('u1').password, hash('newpass123'));
});

test('verifyToken: 401 for expired or invalid tokens, next() for a valid one', async () => {
  const r1 = res();
  await verifyToken({ header: () => 'Bearer expired' }, r1, () => assert.fail('next called'));
  assert.equal(r1.code, 401);
  assert.match(r1.body.message, /expired/i);
  const r2 = res();
  await verifyToken({ header: () => 'Bearer nope' }, r2, () => assert.fail('next called'));
  assert.equal(r2.code, 401);
  const req = { header: () => 'Bearer good' };
  let called = false;
  await verifyToken(req, res(), () => { called = true; });
  assert.ok(called);
  assert.equal(req.userId, 'u1');
});
