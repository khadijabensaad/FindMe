const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/visualSearchController');
const upload = require('../middlewares/uploadFile');
const { optionalAuth } = require('../middlewares/optionalAuth');

router.post('/visual', optionalAuth, upload.single('image'), ctrl.visualSearch);

module.exports = router;
