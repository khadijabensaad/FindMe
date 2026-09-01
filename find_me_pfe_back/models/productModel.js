const mongoose = require("mongoose");
const brand = require('./brandModel');

const productSchema = new mongoose.Schema(
    {
     name: {type: String, required: true},
     price: {type: Number, required: true},
     rating: {type: Number, default:0},
     barcode: {type: Number, unique: true},
     thumbnail: {type:String,required: true},
     images: {type:[String], required: true},
     colors: [String],
     description: String,
     size: [String],
     brand: {type: mongoose.Schema.Types.String,ref:'Brand', required: true},
     shops: [{type: mongoose.Schema.Types.String,ref:'Shop'}],
     category: [{type: mongoose.Schema.Types.String,ref:'Category'}],
     discountPrice: {type: Number, default:-1},
     searched: {type: Number, default:0},
    },{timestamps:true} //kif t7ot timestamps: true tala3lek fil base mongo created at w updated at, dima n7otouha mel mosta7sen
);

const Product = mongoose.model("Product", productSchema);
module.exports = Product;