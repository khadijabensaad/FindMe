const categoryModel = require('../models/categoryModel');
const Product = require('../models/productModel');
const userModel = require('../models/userModel');

module.exports.getAllCategories = async (req, res, next) => {
    try {
      const categoryList = await categoryModel.find();//.populate('products');// .populate('owner') tjiblek fi west postman cellule mta3 owner kemla moch ken id mte3ou
      if (!categoryList) {
        throw new Error("Category not found");
      }
      res.status(200).json(categoryList);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  };

  module.exports.getCategoryById = async (req, res, next) => { // 
    try {
        const { id } = req.params;
      const category = await categoryModel.findById(id);
      if (!category) {
        throw new Error("Category not found");
      }
      res.status(200).json(category);// tnajem tgetti val mta3 esm brand khw par expl res.status(200).json(brand.nom);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
}; 

module.exports.getCategoryProducts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const category = await categoryModel.findById(id).populate('products');

    if (!category) {
      throw new Error("Category not found");
    }

    // Extract the product details
    const products = category.products.map((product) => {
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
        discountPrice: product.discountPrice
      };
    });
    const userFavorites= await userModel.findById(req.userId).select('favorites');
      const productListWithFavorites = products.map(product => {
        const isFavorite = userFavorites.favorites.includes(product.id);
        return { ...product, isFavorite }; // Adding a property 'isFavorite' to each product
      });
    res.status(200).json({prods: productListWithFavorites});
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.getCategoryByName = async (req, res, next) => { //fil postman requete tkoun http://localhost:5000/products/getProductByName?name=necklace
    try {
        const {name} = req.query;
        if (!name) 
        {
            throw new Error("Please enter the category name to search");
        }
        const categoryList = await categoryModel.find(
            {
                name:{$regex: name,$options:"i"},
            }
        ); //await nista3mlouha kif nabda bech ne5thou donnees mel base de donnees
        if (!categoryList || categoryList.length===0 ) 
        {
            throw new Error("Category not found!");
        }
        res.status(200).json(categoryList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.addCategory = async (req, res, next) => {
    try{
        const {name, /*products*/} = req.body; //tnajem ta3mel const nom = req.body.nom;
        if (!name) {
            return res.status(200).json({message: "Name required"});//7attina 200 khater kif bech njiw bech na3mlou liaison bel front 7achetna bech yraje3 true
        }
        const category = new categoryModel({name, /*products*/});
        /*await Promise.all(products.map(async productId => {
            const product = await Product.findById(productId);
            if (product) {
                product.category.push(name);
                await product.save();
            }
        }));*/
        const addedCategory= await category.save();
        res.status(201).json(addedCategory);
      }catch(error){
        res.status(500).json({message: error.message});
      }
};

module.exports.deleteCategory = async (req, res, next) => {
    try {
      const { id } = req.params; //req.params acces fil postman http://localhost:5000/users/deleteUser/2234567887654
      const checkIfCategoryExists = await categoryModel.findById(id);
      if (!checkIfCategoryExists) {
        res.status(404).json({ message: "Category not found!" });
      }
      await Product.updateMany({ category: checkIfCategoryExists.name }, { $pull: { category: checkIfCategoryExists.name } }); //tfasakh tous les produits du brand supprime
      await categoryModel.findByIdAndDelete(id);
  
      res.status(200).json("Deleted Category!");
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
};

module.exports.updateCategoryName = async (req, res, next) => {
    try {
        const { id }= req.params;
        const {name} = req.body;
        const checkIfCategoryExists = await categoryModel.findById(id);
      if (!checkIfCategoryExists) {
        res.status(404).json({ message: "Category not found" });
      }
      updatedCategory = await categoryModel.findByIdAndUpdate(
        id,
        {
            $set : {name},
        },
        { new: true}
        );
        await Product.updateMany({"category": checkIfCategoryExists.name}, { $push: { "category": updatedCategory.name } });
        await Product.updateMany({"category": checkIfCategoryExists.name}, { $pull: { "category": checkIfCategoryExists.name } });
        res.status(200).json("Updated Category!");
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.addProductsToCategory = async (req, res, next) => {
    try {
        const { id }= req.params;
        const {products} = req.body;
        const checkIfCategoryExists = await categoryModel.findById(id);
      if (!checkIfCategoryExists) {
        throw new Error("Category not found");
      }
      updatedCategory = await categoryModel.findByIdAndUpdate(
        id,
        {
            $push : {products},
        },
        { new: true}
        );
        //await Product.updateMany({brand: checkIfBrandExists.name}, { $set: { brand: name } });
        await Promise.all(products.map(async productId => {
          const product = await Product.findById(productId);
          if (product) {
              product.category.push(updatedCategory.name);
              await product.save();
          }
      }));
        res.status(200).json("Added Products to the Category!");
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
  };

  module.exports.deleteProductsFromCategory = async (req, res, next) => {
    try {
        const { id }= req.params;
        const {products} = req.body;
        const checkIfCategoryExists = await categoryModel.findById(id);
      if (!checkIfCategoryExists) {
        res.status(404).json({ message: "Category not found" });
      }
      updatedCategory = await categoryModel.findByIdAndUpdate(
        id,
        {
          $pull: { products: { $in: products } }
        },
        { new: true}
        );
        //await Product.updateMany({brand: checkIfBrandExists.name}, { $set: { brand: name } });
        await Promise.all(products.map(async productId => {
          const product = await Product.findById(productId);
          if (product) {
              product.category.pull(updatedCategory.name);
              await product.save();
          }
      }));
        res.status(200).json("Deleted Products from the Category!");
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
  };