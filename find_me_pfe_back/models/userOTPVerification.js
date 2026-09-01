const mongoose = require('mongoose');

const UserOTPVerificaticationSchema = new mongoose.Schema({
    userId: {
        type: String,
        required: true
    },
    otp: {
        type: String,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now()
    },
    expiredAt: {
        type: Date,
        expires:"5m",
    }
});
const UserOTPVerificatication = mongoose.model("UserOTPVerificatication", UserOTPVerificaticationSchema)

module.exports = UserOTPVerificatication