const express = require('express');
const router = express.Router();
const bot = require('../controllers/chatbotController');
<<<<<<< HEAD
const { optionalAuth } = require('../middlewares/optionalAuth');

// AI Fashion Stylist (works for guests, personalized when a token is sent)
router.post('/', optionalAuth, bot.discuss);
router.get('/sessions/:id', optionalAuth, bot.history);
router.patch('/sessions/:id/criteria', optionalAuth, bot.removeCriterion);
router.delete('/sessions/:id', optionalAuth, bot.resetSession);

module.exports = router;
=======

router.post('/', bot.discuss);

module.exports = router;
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
