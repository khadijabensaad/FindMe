const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/interactionController');
const { optionalAuth } = require('../middlewares/optionalAuth');

router.post('/', optionalAuth, ctrl.track);

module.exports = router;
