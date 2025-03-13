const { S3Client } = require("@aws-sdk/client-s3");
const multer = require("multer");
const multerS3 = require("multer-s3");
require("dotenv").config(); // Load environment variables

// Configure AWS S3 Client for v3
const s3 = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

// Configure Multer for S3
const upload = multer({
  storage: multerS3({
    s3: s3,
    bucket: process.env.AWS_S3_BUCKET_NAME,
    metadata: (req, file, cb) => {
      cb(null, { fieldName: file.fieldname });
    },
    key: (req, file, cb) => {
      const filename = `uploads/${Date.now()}_${file.originalname}`;
      console.log("Uploading file to S3:", filename); // ✅ Log filename
      cb(null, filename);
    },
  }),
});

// ✅ Debugging Middleware
upload.single("image"), (req, res, next) => {
  if (!req.file) {
    console.error("Multer failed to process file.");
    return res.status(500).json({ error: "Multer upload failed" });
  }
  next();
};

module.exports = upload;
