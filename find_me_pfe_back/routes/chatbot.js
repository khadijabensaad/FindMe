const express = require('express');
const router = express.Router();
const bot = require('../controllers/chatbotController');

router.post('/', bot.discuss);

module.exports = router;