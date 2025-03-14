const express = require("express");
const cors = require("cors");
const { upload, uploadAudio } = require("./upload");

const app = express();
app.use(cors());
app.use(express.json());

// Upload Image to S3
app.post("/upload", (req, res, next) => {
  upload.single("image")(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded or invalid file type." });
    }
    res.json({ imageUrl: req.file.location });
  });
});

// Upload Audio to S3
app.post("/upload-audio", (req, res, next) => {
  uploadAudio.single("audio")(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded or invalid file type." });
    }
    res.json({ audioUrl: req.file.location });
  });
});

// Global Error Handling Middleware
app.use((err, req, res, next) => {
  console.error("Error:", err);
  res.status(err.status || 500).json({
    error: err.message || "Internal Server Error",
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));