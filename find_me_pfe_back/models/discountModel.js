const mongoose = require("mongoose");
const product = require('./productModel');

const discountSchema = new mongoose.Schema(
    {
     value: {type: Number, required: true, unique: true},
     sale_products: [{ type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true }],
    },{timestamps:true} //kif t7ot timestamps: true tala3lek fil base mongo created at w updated at, dima n7otouha mel mosta7sen
);

const Discount = mongoose.model("Discount", discountSchema);
module.exports = Discount;