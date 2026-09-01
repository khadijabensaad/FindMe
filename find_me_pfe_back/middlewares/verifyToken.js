const jwt = require("jsonwebtoken");
exports.verifyToken = async (req, res, next) => {
    try {
        let token = req.header("Authorization");
        if (!token) {
            return res.status(403).json("Access Denied")
        }
        if (token.startsWith("Bearer")) {
            token = token.slice(7, token.length).trimLeft()
        }
        const decoded = jwt.verify(token, process.env.NET_SECRET)

        req.userId = decoded.id
        req.userRole = decoded.role
        next()
    } catch (err) {
        res.status(500).json({ status: false, message: err.message })
    }
};