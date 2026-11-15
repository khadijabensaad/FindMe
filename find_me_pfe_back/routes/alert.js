const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/priceAlertController');
const { verifyToken } = require('../middlewares/verifyToken');

router.get('/', verifyToken, ctrl.list);
router.post('/', verifyToken, ctrl.create);
router.put('/seen', verifyToken, ctrl.markSeen);
router.delete('/:id', verifyToken, ctrl.remove);

module.exports = router;
