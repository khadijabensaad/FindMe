const jwt = require("jsonwebtoken");

// Like verifyToken, but never blocks: guests can use the AI stylist and the
// recommendations, logged-in users get personalized results.
exports.optionalAuth = (req, res, next) => {
  try {
    let token = req.header("Authorization");
    if (token && token.startsWith("Bearer")) token = token.slice(7).trim();
    if (token && token !== "null" && token !== "undefined") {
      const decoded = jwt.verify(token, process.env.NET_SECRET);
      req.userId = decoded.id;
      req.userRole = decoded.role;
    }
  } catch (_) {
    // invalid / expired token → continue as guest
  }
  next();
};
