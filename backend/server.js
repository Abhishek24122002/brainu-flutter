const express = require("express");
const cors = require("cors");
const upload = require("./upload"); // Import upload.js

const app = express();
app.use(cors()); // Allow requests from any origin
app.use(express.json());

// Test API
app.get("/test", (req, res) => {
  res.json({ message: "Server is working!" });
});

// ✅ Add the missing /upload route
app.post("/upload", upload.single("image"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "File upload failed" });
  }
  res.json({ imageUrl: req.file.location });
});
// Upload audio to S3
// app.post("/upload-audio", upload.single("audio"), (req, res) => {
//   if (!req.file) {
//     return res.status(400).json({ error: "Audio upload failed" });
//   }
//   res.json({ audioUrl: req.file.location }); // Return S3 URL
// });

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, "0.0.0.0", () => console.log(`Server running on port ${PORT}`));


