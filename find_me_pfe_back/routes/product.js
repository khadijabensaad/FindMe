var express = require('express');
var router = express.Router();
const prod = require('../controllers/productController');
const upload = require('../middlewares/uploadFile');
const {verifyToken}= require('../middlewares/verifyToken');

// Get All products
router.get('/getAllProducts', verifyToken, prod.getAllProducts);

// Get Product By id
router.get('/getProduct/:id', verifyToken, prod.getProductById);

// Get Product By name
router.get('/getProductByName', prod.getProductByName);

// Get Product By barcode
router.get('/getProductByBarCode', verifyToken, prod.getProductByBarCode);

// Get Products By color
router.get('/getProductsByColor', prod.getProductsByColor);

// Tri croissant prix
router.get('/sortByPrice',prod.sortByPrice);

// Tri decroissant prix
router.get('/sortByPriceDec',prod.sortByPriceDec);

// Tri croissant rating
router.get('/sortByRating',prod.sortByRating);

// Tri decroissant rating
router.get('/sortByRatingDec',prod.sortByRatingDec);

// Most Searched Products
router.get('/mostSearcheProducts', prod.mostSearchedProducts);

//Search With Filter
router.post('/searchProductsWithFilter', verifyToken, prod.searchProductsWithFilter);

// get total informations
router.get('/getTotalInformations', prod.getTotalInformations);
 
// Create new product
router.post('/addProduct', upload.fields([{ name: 'thumbnail', maxCount: 1 }, { name: 'images', maxCount: 5 }]),prod.addProduct);

// Delete Product
router.delete('/deleteProduct/:id', prod.deleteProduct);

// Update Product
router.put('/updateProduct/:id', prod.updateProduct);

router.get("/getcategoryPourcentage",prod.getcategoryPourcentage)

module.exports = router;