const multer = require('multer');

// Use in-memory storage; limit size to avoid oversized uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

module.exports = upload;
