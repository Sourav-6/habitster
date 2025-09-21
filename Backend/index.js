const express = require("express");
const app = express();
const PORT = 3000;

app.use(express.json());

app.get("/", (req, res) => {
  res.send("Habitster backend is running!");
});

// --- API Endpoints ---

// Registration Endpoint
app.post("/api/auth/register", (req, res) => {
  const { email, password } = req.body;
  console.log("Received registration request for:");
  console.log("Email:", email);
  console.log("Password:", password);
  res.json({ message: "User registered successfully!" });
});

// Login Endpoint
app.post("/api/auth/login", (req, res) => {
  const { email, password } = req.body;
  console.log("Received login request for:");
  console.log("Email:", email);
  console.log("Password:", password);
  res.json({
    message: "User logged in successfully!",
    token: "dummy-auth-token-for-now",
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
