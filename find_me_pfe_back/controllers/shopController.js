const shopModel = require('../models/shopModel');
const Product = require('../models/productModel');
const userModel = require('../models/userModel');

module.exports.getAllShops = async (req, res, next) => {
    try {
      const shopList = await shopModel.find();//.populate('products');// .populate('owner') tjiblek fi west postman cellule mta3 owner kemla moch ken id mte3ou
      if (!shopList) {
        throw new Error("Shop not found");
      }
      res.status(200).json(shopList);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  };

  module.exports.getShopById = async (req, res, next) => { // 
    try {
      const { id } = req.params;
      const shop = await shopModel.findById(id).populate('products');
      if (!shop) {
        throw new Error("Shop not found");
      }
      res.status(200).json(shop);// tnajem tgetti val mta3 esm brand khw par expl res.status(200).json(brand.nom);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
}; 

module.exports.getShopProducts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const shop = await shopModel.findById(id).populate('products');

    if (!shop) {
      throw new Error("Shop not found");
    }

    // Extract the product details
    const products = shop.products.map((product) => {
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
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports.getShopByName = async (req, res, next) => { //fil postman requete tkoun http://localhost:5000/products/getProductByName?name=necklace
    try {
        const {name} = req.query;
        if (!name) 
        {
            throw new Error("Please enter the shop name to search");
        }
        const shopList = await shopModel.find(
            {
                name:{$regex: name,$options:"i"},
            }
        );//.populate('products'); //await nista3mlouha kif nabda bech ne5thou donnees mel base de donnees
        if (!shopList) 
        {
            throw new Error("Shop not found!");
        }
        res.status(200).json(shopList);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

  module.exports.addShop = async (req, res, next) => {
    try{
        const {name, city, region,coordinates, /*products*/} = req.body; //tnajem ta3mel const nom = req.body.nom;
        if (!name) {
            return res.status(200).json({message: "Name required"});//7attina 200 khater kif bech njiw bech na3mlou liaison bel front 7achetna bech yraje3 true
        }
        if (!city) {
          return res.status(200).json({message: "City required"});//7attina 200 khater kif bech njiw bech na3mlou liaison bel front 7achetna bech yraje3 true
        }
        if (!region) {
        return res.status(200).json({message: "Region required"});//7attina 200 khater kif bech njiw bech na3mlou liaison bel front 7achetna bech yraje3 true
        }
        if (!coordinates) {
            return res.status(200).json({message: "coordinates required"});//7attina 200 khater kif bech njiw bech na3mlou liaison bel front 7achetna bech yraje3 true
        }
        
        const shop = new shopModel({name, city, region, coordinates, /*products*/});
        const addedShop= await shop.save();
        // nzidou fazet shop fil shops mta3 product
        /*await Promise.all(products.map(async productId => {
          const product = await Product.findById(productId);
          if (product) {
              product.shops.push(addedShop.name);
              await product.save();
          }
      }));*/
        res.status(201).json(addedShop);
      }catch(error){
        res.status(500).json({message: error.message});
      }
};

module.exports.deleteShop = async (req, res, next) => {
    try {
      const { id } = req.params; //req.params acces fil postman http://localhost:5000/users/deleteUser/2234567887654
      const checkIfShopExists = await shopModel.findById(id);
      if (!checkIfShopExists) {
        throw new Error("Shop not found");
      }
      //await Product.deleteMany({ brand: checkIfBrandExists.name }) tfasakh tous les produits du brand supprime
      await shopModel.findByIdAndDelete(id);
      await Product.updateMany(
        { shops: checkIfShopExists.name },
        { $pull: { shops: checkIfShopExists.name } }
    );
      res.status(200).json("Deleted Shop!");
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
};

module.exports.updateShop = async (req, res, next) => {
    try {
        const { id }= req.params;
        const {name, city, region, coordinates} = req.body;
        const checkIfShopExists = await shopModel.findById(id);
      if (!checkIfShopExists) {
        throw new Error("Shop not found");
      }
      updatedShop = await shopModel.findByIdAndUpdate(
        id,
        {
            $set : {name, city, region, coordinates},
        },
        { new: true}
        );
        await Product.updateMany({ "shops": checkIfShopExists.name },{ $push: { "shops": updatedShop.name } });
        await Product.updateMany({ "shops": checkIfShopExists.name },{ $pull: { "shops": checkIfShopExists.name } });
        //await Product.updateMany({brand: checkIfBrandExists.name}, { $set: { brand: name } });
        res.status(200).json("Updated Shop!");
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports.getShopsByCity = async (req, res, next) => {
  try {
      const { city } = req.query;
      if (!city) {
          throw new Error("Please provide a city to search for");
      }
      const shopList = await shopModel.find({ city: { $regex: new RegExp(city, 'i') } });
      if (!shopList || shopList.length === 0) {
          throw new Error("No shops found with the specified city");
      }
      res.status(200).json(shopList);
  } catch (error) {
      res.status(500).json({ message: error.message });
  }
};

module.exports.getShopsByRegion = async (req, res, next) => {
  try {
      const { region } = req.query;
      if (!region) {
          throw new Error("Please provide a region to search for");
      }
      const shopList = await shopModel.find({ region: { $regex: new RegExp(region, 'i') } });
      if (!shopList || shopList.length === 0) {
          throw new Error("No shops found with the specified region");
      }
      res.status(200).json(shopList);
  } catch (error) {
      res.status(500).json({ message: error.message });
  }
};

module.exports.addProductsToShop = async (req, res, next) => {
  try {
      const { id }= req.params;
      const {products} = req.body;
      const checkIfShopExists = await shopModel.findById(id);
    if (!checkIfShopExists) {
      throw new Error("Shop not found");
    }
    const parsedProducts = Array.isArray(products) ? products : JSON.parse(products);
    updatedShop = await shopModel.findByIdAndUpdate(
      id,
      {
         $push: { products: { $each: parsedProducts } } ,
      },
      { new: true}
      );
      //await Product.updateMany({brand: checkIfBrandExists.name}, { $set: { brand: name } });
      await Promise.all(parsedProducts.map(async productId => {
        const product = await Product.findById(productId);
        if (product) {
            product.shops.push(updatedShop.name);
            await product.save();
        }
    }));
      res.status(200).json("Added Products to the Shop!");
  } catch (error) {
      res.status(500).json({ message: error.message });
  }
};

module.exports.deleteProductsFromShop = async (req, res, next) => {
  try {
      const { id }= req.params;
      const {products} = req.body;
      const checkIfShopExists = await shopModel.findById(id);
    if (!checkIfShopExists) {
      res.status(404).json({ message: "Shop not found" });
    }
    updatedShop = await shopModel.findByIdAndUpdate(
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
            product.shops.pull(updatedShop.name);
            await product.save();
        }
    }));
      res.status(200).json("Deleted Products from the Shop!");
  } catch (error) {
      res.status(500).json({ message: error.message });
  }
};

module.exports.CalculateDistance = async (req, res, next) => {
  try {
    const { lat, long } = req.body; // Assuming you pass lat and long of user's location in the request body

    if (!lat || !long) {
      return res.status(400).json({ message: "Latitude and Longitude are required." });
    }

    const shops = await shopModel.find(); // Retrieve all shops

    if (!shops || shops.length === 0) {
      return res.status(404).json({ message: "No shops found." });
    }

    // Calculate distances for each shop
    const shopsWithDistance = shops.map((shop) => {
      const shopLat = shop.coordinates.latitude;
      const shopLong = shop.coordinates.longitude;

      // Using Haversine formula to calculate distance between two points on Earth
      const R = 6371; // Radius of Earth in kilometers
      const dLat = (shopLat - lat) * (Math.PI / 180);
      const dLon = (shopLong - long) * (Math.PI / 180);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat * (Math.PI / 180)) *
          Math.cos(shopLat * (Math.PI / 180)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const distance = R * c; // Distance in kilometers

      return {
        _id: shop._id,
        name: shop.name,
        city: shop.city,
        region: shop.region,
        distance: distance.toFixed(2), // Round distance to 2 decimal places
        coordinates: {
          latitude: shopLat,
          longitude: shopLong,
        },
      };
    });
    shopsWithDistance.sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));
    res.status(200).json({ shops: shopsWithDistance });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};