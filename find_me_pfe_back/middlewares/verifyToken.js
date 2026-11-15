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
<<<<<<< HEAD
        // expired / invalid token is an authentication problem, not a server error
        const expired = err && err.name === 'TokenExpiredError'
        res.status(401).json({ status: false, message: expired ? 'Session expired, please log in again' : 'Invalid token' })
=======
        res.status(500).json({ status: false, message: err.message })
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
    }
};