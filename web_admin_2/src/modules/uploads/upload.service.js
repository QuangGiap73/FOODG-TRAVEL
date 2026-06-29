const { getCloudinary } = require('../../config/cloudinary');

function createUploadService() {
  return {
    async uploadImage(file, options = {}) {
      if (!file?.buffer) {
        throw new Error('Missing upload file');
      }

      const cloudinary = getCloudinary();

      return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            folder: options.folder || 'food-travel/users',
            public_id: options.publicId,
            resource_type: 'image',
            overwrite: true,
          },
          (error, result) => {
            if (error) return reject(error);
            resolve({
              url: result?.secure_url || '',
              publicId: result?.public_id || '',
            });
          },
        );

        stream.end(file.buffer);
      });
    },
  };
}

module.exports = { createUploadService };
