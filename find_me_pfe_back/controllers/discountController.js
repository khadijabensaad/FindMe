const discountModel = require('../models/discountModel');
const productModel = require('../models/productModel');
const userModel = require('../models/userModel');
const Notification = require('../models/notificationModel');


module.exports.getAllDiscounts = async (req, res, next) => {
    try {
      const discountList = await discountModel.find();//.populate('sale_products');// .populate('owner') tjiblek fi west postman cellule mta3 owner kemla moch ken id mte3ou
      if (!discountList) {
        throw new Error("Discounts not found");
      }
      res.status(200).json(discountList);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  };

  module.exports.getDiscountById = async (req, res, next) => { // 
    try {
      const { id } = req.params;
      const discount = await discountModel.findById(id);
      if (!discount) {
        throw new Error("Discount not found");
      }
      res.status(200).json(discount);// tnajem tgetti val mta3 esm brand khw par expl res.status(200).json(brand.nom);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
}; 

module.exports.getDiscountByValue = async (req, res, next) => { // 
    try {
        const { value } = req.params;
      const discount = await discountModel.findOne({value})
      if (!discount) {
        throw new Error("Discount not found");
      }
      res.status(200).json(discount);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
}; 

module.exports.addDiscount = async (req, res, next) => {
  try {
    const { value, sale_products } = req.body;

    // Check if a discount with the provided value already exists
    const existingDiscount = await discountModel.findOne({ value });

    await discountModel.updateMany(
      { sale_products: { $in: sale_products } },
      { $pull: { sale_products: { $in: sale_products } } }
    );

    if (existingDiscount) {
      // If the discount exists, add the product IDs to the existing sale_products
      sale_products.forEach(productId => {
        existingDiscount.sale_products.push(productId);
      });
      await existingDiscount.save();
    } else {
      // If the discount doesn't exist, create a new one
      const newDiscount = new discountModel({ value, sale_products });
      const addedDiscount = await newDiscount.save();
    }

    //update discountPrice in productModel
    console.log("value: ", value);
    const prods = await productModel.find({ _id: { $in: sale_products } });

    for (const product of prods) {
      const discountedPrice = product.price - (product.price * value / 100);
      product.discountPrice = discountedPrice;
      await product.save();

      // Create a notification for the discounted product
      const notification = new Notification({
        content: `Product ${product.name} is now available at a ${value}% discount!`,
        productId: product._id,
        productPic: product.thumbnail // Adjust the field name as necessary
      });
      await notification.save();
    }

    const newDiscount = await discountModel.findOne({ value });
    res.status(200).json({ message: "Products are now discounted!", discount: newDiscount });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports.deleteDiscount = async (req, res, next) => {
  try {
    const {prods} = req.body;

    if (!prods) {
      throw new Error("Products not found");
    }

    await discountModel.updateMany(
      { sale_products: { $in: prods } },
      { $pull: { sale_products: { $in: prods } } }
  );
  const products= await productModel.find({ _id: { $in: prods } });
  for (const product of products) {
    product.discountPrice = -1;
    await product.save();
}
    res.status(200).json({message:"Products are removed from Discount"});
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.getDiscountedProducts = async (req, res) => {
  try {
    const discountedProducts = await productModel.find({ discountPrice: { $ne: -1 } });
    if (!discountedProducts.length) {
      return res.status(404).json({ message: "No discounted products found" });
    }

    const userFavorites = await userModel.findById(req.userId).select('favorites');
    const discountedProductsWithFavorites = discountedProducts.map(product => {
      const isFavorite = userFavorites.favorites.includes(product._id.toString());
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
        discountPrice: product.discountPrice,
        searched: product.searched,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
        isFavorite: isFavorite
      };
    });

    res.status(200).json({ message: "Discounted Products", products: discountedProductsWithFavorites });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};


module.exports.emptyDiscount = async (req, res, next) => {
  try {
    const {id} = req.params;
    const discount = await discountModel.findById(id);
    if (!discount) {
      res.status(500).json({ message: "Discount not found" });
    }
    discountedProducts = discount.sale_products;

    await discountModel.updateMany(
      { sale_products: { $in: discountedProducts } },
      { $pull: { sale_products: { $in: discountedProducts } } }
  );
  const products= await productModel.find({ _id: { $in: discountedProducts } });
  console.log(products);
  for (const product of products) {
    product.discountPrice = -1;
    await product.save();
}
    res.status(200).json({message:"Products are removed from Discount"});
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.getSpecificDiscountProducts = async (req, res) => {
  try {
    const {id} = req.params;
    const discount = await discountModel.findById(id).populate('sale_products');
    if(!discount){
      return res.status(404).json({ message: "Discount not found" });
    }
    
    const products = discount.sale_products.map((product) => {
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
    const userFavorites= await userModel.findById(req.userId).select('favorites');
      const productListWithFavorites = products.map(product => {
        const isFavorite = userFavorites.favorites.includes(product.id);
        return { ...product, isFavorite }; // Adding a property 'isFavorite' to each product
      });
    res.status(200).json({prods: productListWithFavorites});
    /*const discountedProducts = await productModel.find({ discountPrice: { $ne: -1 } });
    if (!discountedProducts.length) {
      return res.status(404).json({ message: "No discounted products found" });
    }

    const userFavorites = await userModel.findById(req.userId).select('favorites');
    const discountedProductsWithFavorites = discountedProducts.map(product => {
      const isFavorite = userFavorites.favorites.includes(product._id.toString());
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
        discountPrice: product.discountPrice,
        searched: product.searched,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
        isFavorite: isFavorite
      };
    });

    res.status(200).json({ message: "Discounted Products", products: discountedProductsWithFavorites });*/
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};