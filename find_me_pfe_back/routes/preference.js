const express = require('express');
const router = express.Router();
const pref = require('../controllers/preferenceController');
const { verifyToken } = require('../middlewares/verifyToken');

router.get('/', verifyToken, pref.getPreferences);
router.put('/', verifyToken, pref.savePreferences);
router.get('/style-dna', verifyToken, pref.styleDna);

module.exports = router;
