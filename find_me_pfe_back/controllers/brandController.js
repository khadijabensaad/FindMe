const brandModel = require('../models/brandModel');
const Product = require('../models/productModel');

module.exports.getAllBrands = async (req, res, next) => {
    try {
      const brandList = await brandModel.find().populate('products');// .populate('owner') tjiblek fi west postman cellule mta3 owner kemla moch ken id mte3ou
      if (!brandList) {
        throw new Error("Brand not found");
      }
      res.status(200).json(brandList);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  };

  module.exports.getBrandById = async (req, res, next) => { // 
    try {
        const { id } = req.params;
      const brand = await brandModel.findById(id).populate("products");
      if (!brand) {
        throw new Error("Brand not found");
      }
      res.status(200).json(brand);// tnajem tgetti val mta3 esm brand khw par expl res.status(200).json(brand.nom);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
};

module.exports.getBrandProducts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const brand = await brandModel.findById(id).populate('products');
    if (!brand) {
      return res.status(404).json({ message: "Brand not found" });
    }

    // Extract the product details
    const products = brand.products.map((product) => {
      return {
        id: product._id,
        name: product.name,
        price: product.price,
        rating: product.rating,
        barcode: product.barcode,
        thumbnail: product.thumbnail,
        images: product.images,
        colors: product.colors,
        description: product.description,
        size: product.size,
        brand: product.brand,
        category: product.category,
        discountPrice: product.discountPrice
      };
    });

    res.status(200).json({ prods: products });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.getBrandByName = async (req, res, next) => { //fil postman requete tkoun http://localhost:5000/products/getProductByName?name=necklace
    try {
        const {name} = req.query;
        if (!name) 
        {
            throw new Error("Please enter the brand name to search");
        }
        const brandList = await brandModel.find(
            {
                name:{$regex: name,$options:"i"},
            }
        ); //await nista3mlouha kif nabda bech ne5thou donnees mel base de donnees
        if (!brandList) 
        {
            throw new Error("Brand not found!");
        }
        res.status(200).json(brandList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.addBrand = async (req, res, next) => {
    try{
        const {name} = req.body; //tnajem ta3mel const nom = req.body.nom;
        if (!name) {
            return res.status(200).json({message: "Name required"});//7attina 200 khater kif bech njiw bech na3mlou liaison bel front 7achetna bech yraje3 true
        }
        const brand = new brandModel({name});
        const addedBrand= await brand.save();
        res.status(201).json(addedBrand);
      }catch(error){
        res.status(500).json({message: error.message});
      }
};

module.exports.deleteBrand = async (req, res, next) => {
    try {
      const { id } = req.params; //req.params acces fil postman http://localhost:5000/users/deleteUser/2234567887654
      const checkIfBrandExists = await brandModel.findById(id);
      if (!checkIfBrandExists) {
        throw new Error("Brand not found");
      }
      await Product.deleteMany({ brand: checkIfBrandExists.name }) //tfasakh tous les produits du brand supprime
      await brandModel.findByIdAndDelete(id);
  
      res.status(200).json("Deleted Brand!");
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
};

module.exports.updateBrand = async (req, res, next) => {
    try {
        const { id }= req.params;
        const {name} = req.body;
        const checkIfBrandExists = await brandModel.findById(id);
      if (!checkIfBrandExists) {
        res.status(404).json({ message: "Brand not found" });
      }
      updatedBrand = await brandModel.findByIdAndUpdate(
        id,
        {
            $set : {name},
        },
        { new: true}
        );
        await Product.updateMany({brand: checkIfBrandExists.name}, { $set: { brand: name } });
        res.status(200).json("Updated Brand!");
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};