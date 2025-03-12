const express = require("express");
const upload = require("./upload");
const cors = require("cors");

const app = express();
app.use(cors()); // Allow CORS for Flutter
app.use(express.json());

// Upload image to S3
app.post("/upload", upload.single("image"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "File upload failed" });
  }
  res.json({ imageUrl: req.file.location }); // Return the S3 URL
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
