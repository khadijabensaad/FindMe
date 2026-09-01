const productModel = require('../models/productModel');
const Brand = require('../models/brandModel');
const Shop = require('../models/shopModel');
const Category = require('../models/categoryModel');
const userModel = require('../models/userModel');
const discountModel = require('../models/discountModel');
const cloudinary = require('cloudinary').v2;
const { validationResult } = require('express-validator');
const dotenv = require('dotenv')
dotenv.config()

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_API_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

module.exports.getAllProducts = async (req, res, next) => {
    try {
      const productList = await productModel.find();// .populate('owner') tjiblek fi west postman cellule mta3 owner kemla moch ken id mte3ou
      if (!productList) {
        throw new Error("Product not found");
      }
      const userFavorites= await userModel.findById(req.userId).select('favorites');
      const productListWithFavorites = productList.map(product => {
        const isFavorite = userFavorites.favorites.includes(product._id);
        return { ...product._doc, isFavorite }; // Adding a property 'isFavorite' to each product
      });
      res.status(200).json(productListWithFavorites);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  };

  module.exports.getProductById = async (req, res, next) => {
    try {
      const { id } = req.params;
      const product = await productModel.findById(id);
  
      if (!product) {
        return res.status(404).json({ message: "Product not found" });
      }
  
      // Increment the 'searched' count for the product
      product.searched += 1;
      await product.save();
  
      // Retrieve user's favorites and check if the current product is in favorites
      const user = await userModel.findById(req.userId).select('favorites');
      const isFavorite = user.favorites.includes(product._id);
  
      // Return product data along with 'isFavorite' flag
      const prodData = { ...product._doc, isFavorite };
      return res.status(200).json(prodData);
    } catch (err) {
      console.error(err);
      return res.status(500).json({ message: "Internal server error" });
    }
  };
  

module.exports.getProductByName = async (req, res, next) => { //fil postman requete tkoun http://localhost:5000/products/getProductByName?name=necklace
    try {
        const {name} = req.query;
        /*if (!name) 
        {
            throw new Error("Please enter the product name to search");
        }*/
        const productList = await productModel.find(
            {
                name:{$regex: name,$options:"i"},
            }
        ); //await nista3mlouha kif nabda bech ne5thou donnees mel base de donnees
        if (!productList) 
        {
            throw new Error("Product not found!");
        }
        //console.log(productList.length);
        res.status(200).json(productList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.getProductByBarCode = async (req, res, next) => { // 
    try {
        const { barcode } = req.query;
      const product = await productModel.findOne({barcode})
      if (!product ) {
        throw new Error("Product not found");
      }
      product.searched +=1;
      await product.save();
      
      const user = await userModel.findById(req.userId).select('favorites');
      const isFavorite = user.favorites.includes(product._id);
  
      // Return product data along with 'isFavorite' flag
      const prodData = { ...product._doc, isFavorite };
      
      return res.status(200).json(prodData);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
}; 

module.exports.getProductsByColor = async (req, res, next) => {
    try {
        const { color } = req.query;
        if (!color) {
            throw new Error("Please provide a color to search for");
        }
        const productList = await productModel.find({ colors: { $regex: new RegExp(color, 'i') } });
        if (!productList || productList.length === 0) {
            throw new Error("No products found with the specified color");
        }
        res.status(200).json(productList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.addProduct = async (req, res, next) => {
    try{
        
        const {name, price, rating, barcode, colors, description, size, brand_id, /*shops_id*/} = req.body; //tnajem ta3mel const nom = req.body.nom;
        
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        // Handle image upload
        let thumbnail;
        if (req.files['thumbnail'][0]) {
            thumbnail = await cloudinary.uploader.upload(req.files['thumbnail'][0].path);
        }
        let images = [];
        // Handle multiple image uploads
        if (req.files['images']) {
            const imagesFiles = req.files['images'].map(file => file.path);

            if (imagesFiles && imagesFiles.length > 0) {
                for (const file of imagesFiles) {
                    const uploadedImage = await cloudinary.uploader.upload(file);
                    images.push(uploadedImage.secure_url);
                }
            }

        }
        const brand_name = await Brand.findById(brand_id);
        const parsedColors = JSON.parse(colors);
        const parsedSize = JSON.parse(size);

        const product = new productModel({
          name,
          price,
          rating,
          barcode,
          colors: parsedColors,
          description,
          size: parsedSize,
          thumbnail: thumbnail ? thumbnail.secure_url : null,
          images: images.length > 0 ? images : null,
          brand:brand_name.name
        });
        const addedProduct= await product.save();
        await Brand.findByIdAndUpdate(brand_id, { $push: { products: product._id } });
        res.status(201).json(addedProduct);
      }catch(error){
        res.status(500).json({message: error.message});
      }
};

module.exports.deleteProduct = async (req, res, next) => {
    try {
      const { id } = req.params; //req.params acces fil postman http://localhost:5000/users/deleteUser/2234567887654
      const checkIfProductExists = await productModel.findById(id);
      if (!checkIfProductExists) {
        throw new Error("Product not found");
      }
      await productModel.findByIdAndDelete(id);
      await Brand.updateMany({}, { $pull: { products: checkIfProductExists._id } });
      await Shop.updateMany({}, { $pull : { products: checkIfProductExists._id } });
      await Category.updateMany({}, { $pull : { products: checkIfProductExists._id } });
      res.status(200).json("Deleted Product!");
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
};

module.exports.updateProduct = async (req, res, next) => { //ne9sa modifications fil tsawer
    try {
        const { id }= req.params;
        const {name, price ,rating, barcode, colors, description, size} = req.body;
        //const thumbnail = req.files['thumbnail'][0].filename;
        //const images = req.files['images'].map(file => file.filename);

        const checkIfProductExists = await productModel.findById(id);
      if (!checkIfProductExists) {
        throw new Error("Product not found");
      }
      const parsedColors = JSON.parse(colors);
      const parsedSize = JSON.parse(size);
      updatedProduct = await productModel.findByIdAndUpdate(
        id,
        {
            $set : {name, price ,rating, barcode, colors: parsedColors, description, size: parsedSize/*, thumbnail, images*/},
        },
        { new: true}
        );

        res.status(200).json("Updated Product!");
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.sortByPrice = async (req, res, next) => {
    try {
        const productList = await productModel.find().sort({price : 1}); // ken 7atit price:1 raw tri croissant ken price -1 raw decroissant
        if (!productList) // !productList kima t9oul null
        {
            throw new Error("Products not found!");
        }
        //console.log(userList);
        res.status(200).json(productList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.sortByPriceDec = async (req, res, next) => {
    try {
        const productList = await productModel.find().sort({price : -1}); // ken 7atit price:1 raw tri croissant ken price -1 raw decroissant
        if (!productList) // !productList kima t9oul null
        {
            throw new Error("Products not found!");
        }
        //console.log(userList);
        res.status(200).json(productList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.sortByRating = async (req, res, next) => {
    try {
        const productList = await productModel.find().sort({rating : 1}); // ken 7atit price:1 raw tri croissant ken price -1 raw decroissant
        if (!productList) // !productList kima t9oul null
        {
            throw new Error("Products not found!");
        }
        //console.log(userList);
        res.status(200).json(productList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.sortByRatingDec = async (req, res, next) => {
    try {
        const productList = await productModel.find().sort({rating : -1}); // ken 7atit price:1 raw tri croissant ken price -1 raw decroissant
        if (!productList) // !productList kima t9oul null
        {
            throw new Error("Products not found!");
        }
        //console.log(userList);
        res.status(200).json(productList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.searchProductsWithFilter = async (req, res, next) =>{
    try{
        let query = {};
        //Filter
        if(req.body.region){
            const shopList = await Shop.find({ region: req.body.region }); // Retrieve shops in the specified region
            const shopNames = shopList.map(shop => shop.name); // Extract shop names
            query.shops = { $in: shopNames }; // Filter products based on shop IDs in the specified region
        }
        if(req.body.colors){
            query.colors= { $in: req.body.colors };
        }
        if(req.body.size){
            if( JSON.stringify(req.body.size) === JSON.stringify([])){
                
            }else{
                query.size= { $in: req.body.size };
            }
        }
        //Sort
        let sortCriteria = {};
        if (req.body.sortBy) {
            sortCriteria[req.body.sortBy] = req.body.sortOrder === 'desc' ? -1 : 1;
        }
        //search
        if (req.body.name) {
            query.name =  { $regex: req.body.name, $options: "i" } ;
        }
        //Fetching Products
        const productList = await productModel.find(query)
            .sort(sortCriteria)
            //.populate('shops') //tnajamch t7otha khater .populate tekhou fil paramtere ken type id
            console.log(productList.length);
            const userFavorites= await userModel.findById(req.userId).select('favorites');
      const productListWithFavorites = productList.map(product => {
        const isFavorite = userFavorites.favorites.includes(product._id);
        return { ...product._doc, isFavorite }; // Adding a property 'isFavorite' to each product
      });
        res.status(200).json(productListWithFavorites);
    }catch(error){
        res.status(500).json({ message: error.message });
    }
};

module.exports.mostSearchedProducts = async (req, res) => {
    try {
        // Fetch all products and sort by 'searched' attribute in descending order
        const products = await productModel.find().sort({ searched: -1 }).exec();

        // Calculate the total number of searches
        const totalSearches = products.reduce((sum, product) => sum + product.searched, 0);
        console.log(totalSearches);
        // Format the response to include the 'searched' value and its percentage
        const formattedProducts = products.map(product => {
            const percentage = totalSearches > 0 ? (product.searched / totalSearches) * 100 : 0;
            return {
                product: product,
                searched: product.searched,
                percentage: percentage.toFixed(2) // Format percentage to 2 decimal places
            };
        });

        res.status(200).json({total: totalSearches, products: formattedProducts});
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.getTotalInformations = async (req,res) =>{
    try {
        const totalProducts = await productModel.countDocuments();
        const totalShops = await Shop.countDocuments();
        const totalBrands = await Brand.countDocuments();
        const totalUsers= await userModel.countDocuments();
        const totalCategories= await Category.countDocuments();
        const discountProducts = await discountModel.aggregate([
            { $unwind: '$sale_products' },
            { $group: { _id: null, total: { $sum: 1 } } },
          ]);
          const totalDiscounts = discountProducts.length > 0 ? discountProducts[0].total : 0;
        res.status(200).json({ status: true, products: totalProducts, shops: totalShops, brands: totalBrands, users: totalUsers, categories: totalCategories, discounts: totalDiscounts });
      } catch (error) {
        res.status(500).json({ message: 'Error fetching total Informations', status: false });
      }
};


module.exports.getcategoryPourcentage = async (req, res) => {
    try {
        const totalProducts = await productModel.countDocuments();

        const categories = await Category.aggregate([
            {
                $lookup: {
                    from: "products", // The collection name for products
                    localField: "name",
                    foreignField: "category",
                    as: "products"
                }
            },
            {
                $project: {
                    _id: 1,
                    name: 1,
                    count: { $size: "$products" },
                    percentage: {
                        $cond: {
                            if: { $eq: [totalProducts, 0] },
                            then: 0,
                            else: { $multiply: [{ $divide: [{ $size: "$products" }, totalProducts] }, 100] }
                        }
                    }
                }
            }
        ]);

        console.log("Category Percentages:", categories);
        res.status(200).json({ status: true, categories: categories });
    } catch (error) {
        console.error("Error calculating category percentages:", error);
        res.status(500).json({ status: false, error: error.message });
    }
};