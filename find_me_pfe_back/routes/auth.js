var express = require('express');
var router = express.Router();
const auth = require('../controllers/authController');
const upload = require('../middlewares/uploadFile');
const {verifyToken}= require('../middlewares/verifyToken');

router.get('/getUser/:id', auth.getUserById);
router.get('/getFavorites', verifyToken, auth.getFavorites);
router.get('/getAllUsers', auth.getAllUsers);
router.get('/UserStats', auth.UserStats);
router.post('/signup', upload.single('file'), auth.create_account);
router.post('/otp', auth.otpVerification);
router.post('/resendOtp', auth.resendOtpVerification);
router.post('/login', auth.login);
router.post('/forgetPassword', auth.forgetPassword);
router.post("/resetPassword", auth.resetPassword);
router.put('/addToFavorites', verifyToken, auth.addToFavorites);
router.put('/deleteAllFavorites', verifyToken, auth.deleteAllFavorites);
router.put('/desactivateAccount/:id', auth.desactivateAccount);
router.delete('/deleteUser/:id', auth.deleteUser);

module.exports = router