var express = require('express');
var router = express.Router();
const brand = require('../controllers/brandController');

// Get All Brands
router.get('/getAllBrands', brand.getAllBrands);

// Get Brand By id
router.get('/getBrand/:id', brand.getBrandById);

// Get Brand By id
router.get('/getBrandProducts/:id', brand.getBrandProducts);

// Get Brand By name
router.get('/getBrandByName', brand.getBrandByName);

// Add Brand
router.post('/addBrand',brand.addBrand);

//Delete Brand
router.delete('/deleteBrand/:id',brand.deleteBrand);

// Update Brand
router.put('/updateBrand/:id', brand.updateBrand); 

module.exports = router;