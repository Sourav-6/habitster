// middleware/authMiddleware.js
const jwt = require("jsonwebtoken");
require("dotenv").config(); // Make sure JWT_SECRET is loaded

const authMiddleware = (req, res, next) => {
  // 1. Get token from header
  const authHeader = req.headers.authorization;

  // 2. Check if token exists and has the correct format ('Bearer TOKEN')
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res
      .status(401)
      .json({ message: "Unauthorized: No token provided or invalid format" });
  }

  // 3. Extract the token
  const token = authHeader.split(" ")[1];

  try {
    // 4. Verify the token
    const decodedPayload = jwt.verify(token, process.env.JWT_SECRET);

    // 5. Attach user ID (or the whole payload) to the request object
    req.userId = decodedPayload.userId; // Make userId available to the next function

    // 6. Call 'next()' to pass control to the next middleware or the route handler
    next();
  } catch (error) {
    // 7. Handle invalid/expired tokens
    console.error("Token verification failed:", error.message);
    return res
      .status(401)
      .json({ message: "Unauthorized: Invalid or expired token" });
  }
};

module.exports = authMiddleware; // Export the function
