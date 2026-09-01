const Notification = require('../models/notificationModel')


module.exports.getAllNotiifications = async (req, res, next) => {
    try {
        let notifications = await Notification.find().sort({ createdAt: -1 });
        if (!notifications || notifications.length === 0) {
            return res.status(201).json({
                status: true,
                message: "No notifications found"
            });
        }

        res.status(200).json({ data: notifications, status: true });


    } catch (error) {
        return res.status(500).json({
            status: false,
            message: error.message
        });
    }
};