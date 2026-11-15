var express = require('express');
var router = express.Router();
const discount = require('../controllers/discountController');
const {verifyToken}= require('../middlewares/verifyToken');

// Get All Discounts
router.get('/getAllDiscounts',discount.getAllDiscounts);

// Get Discount By id
router.get('/getDiscount/:id',discount.getDiscountById);

// Get Discount By Value
router.get('/getDiscountByValue/:value',discount.getDiscountByValue);

// Get Discounted Products
router.get('/getDiscountedProducts', verifyToken, discount.getDiscountedProducts);

// Get Specific Discount Products
router.get('/getSpecificDiscountProducts/:id', verifyToken, discount.getSpecificDiscountProducts);

// Add Discount
router.post('/addDiscount',discount.addDiscount);

// Empty Discount
router.put('/emptyDiscount/:id', discount.emptyDiscount);

//Delete Products from Discount
router.delete('/deleteDiscount', discount.deleteDiscount);

module.exports = router;