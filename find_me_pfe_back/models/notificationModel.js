const mongoose = require('mongoose')

const notificationSchema = new mongoose.Schema({
    content: {
        type: String,
        required: true
    },
    productId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true
    },
    productPic: {
        type: String
    },
},
    {
        timestamps: true
    },);


const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;