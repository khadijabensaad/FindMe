const mongoose = require("mongoose");
const product = require('./productModel');

const brandSchema = new mongoose.Schema(
    {
     name: {type: String, required: true, unique: true},
     products: [{ type: mongoose.Schema.Types.ObjectId, ref: "Product" }],
    },{timestamps:true} //kif t7ot timestamps: true tala3lek fil base mongo created at w updated at, dima n7otouha mel mosta7sen
);

const Brand = mongoose.model("Brand", brandSchema);
module.exports = Brand;