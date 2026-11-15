const express = require('express');
const router = express.Router();
const reco = require('../controllers/recommendationController');
const { optionalAuth } = require('../middlewares/optionalAuth');

router.get('/home', optionalAuth, reco.home);
router.get('/for-you', optionalAuth, reco.forYou);
router.get('/similar/:productId', optionalAuth, reco.similar);
router.get('/trending', optionalAuth, reco.trending);
router.get('/budget', optionalAuth, reco.budget);
router.get('/complete-look/:productId', optionalAuth, reco.completeLook);
router.get('/discover', optionalAuth, reco.discover);
router.get('/explain/:productId', optionalAuth, reco.explain);
router.get('/nearby-shops/:productId', optionalAuth, reco.nearbyShops);
router.get('/nearby-products', optionalAuth, reco.nearbyProducts);
router.get('/stores', optionalAuth, reco.stores);
router.get('/places', reco.places);
router.post('/feedback', optionalAuth, reco.feedback);

module.exports = router;
