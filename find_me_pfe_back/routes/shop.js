var express = require('express');
var router = express.Router();
const shop = require('../controllers/shopController');
const {verifyToken}= require('../middlewares/verifyToken');

// Get All Shops
router.get('/getAllShops',shop.getAllShops);

// Get Shop By id
router.get('/getShop/:id', shop.getShopById);

// Get Shop By name
router.get('/getShopByName', shop.getShopByName);

// Get Shop Products By id
router.get('/getShopProducts/:id', verifyToken, shop.getShopProducts);

// Get All Shops With Specified City
router.get('/getShopsByCity', shop.getShopsByCity);

// Get All Shops With Specified Region
router.get('/getShopsByRegion', shop.getShopsByRegion);

// Calculate Distance
router.post('/CalculateDistance',shop.CalculateDistance);

// Add Shop
router.post('/addShop',shop.addShop);

//Delete Shop
router.delete('/deleteShop/:id',shop.deleteShop);

// Update Shop
router.put('/updateShop/:id', shop.updateShop); 

// Add products to Shop
router.put('/addProductsToShop/:id', shop.addProductsToShop);

// Delete products from Shop
router.put('/deleteProductsFromShop/:id', shop.deleteProductsFromShop);

module.exports = router;