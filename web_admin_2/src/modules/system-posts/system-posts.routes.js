const express = require('express');
const multer = require('multer');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const {
  getSystemPostsPage,
  getSystemPostDetailPage,
  getSystemPostCreatePage,
  createSystemPostPage,
  getSystemPostEditPage,
  updateSystemPostPage,
  deleteSystemPostApi,
  uploadSystemPostImageApi,
} = require('./system-posts.controller');

const router = express.Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 4 * 1024 * 1024 },
});

router.get('/', requireAdmin, getSystemPostsPage);
router.get('/add', requireAdmin, getSystemPostCreatePage);
router.post('/add', requireAdmin, createSystemPostPage);
router.post('/api/upload-image', requireAdmin, upload.single('image'), uploadSystemPostImageApi);
router.get('/:id', requireAdmin, getSystemPostDetailPage);
router.get('/:id/edit', requireAdmin, getSystemPostEditPage);
router.post('/:id/edit', requireAdmin, updateSystemPostPage);
router.delete('/api/list/:id', requireAdmin, deleteSystemPostApi);

module.exports = router;
