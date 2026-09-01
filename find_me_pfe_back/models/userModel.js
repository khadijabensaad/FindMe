const mongoose = require("mongoose");
const product = require('./productModel');

const userSchema = new mongoose.Schema({
    username: {
        type: String
    },
    email: {
        type: String
    },
    password: {
        type: String
    },
    activated: {
        type: Boolean,
        default: false
    },
    image: {
        type: String
    },
    role: {
        type: String,
        enum: ['Admin', 'Client'],
        default: 'Client'
    },
    favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: "Product" }]
},{timestamps:true} 
);

const User = mongoose.model("User", userSchema);
module.exports = User;