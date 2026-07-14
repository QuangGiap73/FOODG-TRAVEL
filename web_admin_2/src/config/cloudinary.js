const cloudinary = require('cloudinary').v2;

let configured = false;

function getCloudinary() {
  if (!configured) {
    const cloudinaryUrl = process.env.CLOUDINARY_URL;

    if (cloudinaryUrl) {
      cloudinary.config({ cloudinary_url: cloudinaryUrl });
    } else {
      cloudinary.config({
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME || '',
        api_key: process.env.CLOUDINARY_API_KEY || '',
        api_secret: process.env.CLOUDINARY_API_SECRET || '',
      });
    }

    configured = true;
  }

  return cloudinary;
}

module.exports = { getCloudinary };
