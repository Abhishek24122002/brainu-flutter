const express = require("express");
const cors = require("cors");
const { upload, uploadAudio } = require("./upload");

const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

// 🔧 Setup AWS S3 client
const s3 = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

// 🔐 Function to generate signed URL
async function getSignedAudioUrl(key) {
  const command = new GetObjectCommand({
    Bucket: process.env.AWS_S3_BUCKET_NAME,
    Key: key,
  });

  try {
    const signedUrl = await getSignedUrl(s3, command, { expiresIn: 3600 }); // 1 hour
    return signedUrl;
  } catch (err) {
    console.error("Error generating signed URL:", err);
    return null;
  }
}

// 📦 Upload Image to S3
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

// 🎵 Upload Audio to S3
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

// 🔗 Generate Signed URL for audio access
app.get("/get-audio-url", async (req, res) => {
  const { key } = req.query;
  if (!key) {
    return res.status(400).json({ error: "Missing 'key' query parameter" });
  }

  const url = await getSignedAudioUrl(key);
  if (!url) {
    return res.status(500).json({ error: "Failed to generate signed URL" });
  }

  res.json({ signedUrl: url });
});

// ❗ Global Error Handling Middleware
app.use((err, req, res, next) => {
  console.error("Error:", err);
  res.status(err.status || 500).json({
    error: err.message || "Internal Server Error",
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
