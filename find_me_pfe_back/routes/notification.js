const router = require('express').Router();
const { getAllNotiifications } = require('../controllers/notificationController');


router.get('/',getAllNotiifications)


module.exports=router