const express = require('express');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const {
  getPostsPage,
  getPostDetailPage,
  getPostEditPage,
  updatePostPage,
  deletePostPage,
  deletePostsApi,
  updatePostModerationApi,
  updatePostsModerationApi,
} = require('./posts.controller');

const router = express.Router();

router.get('/', requireAdmin, getPostsPage);
router.delete('/api/list', requireAdmin, deletePostsApi);
router.patch('/api/list/moderation', requireAdmin, updatePostsModerationApi);
router.patch('/api/list/:id/moderation', requireAdmin, updatePostModerationApi);
router.get('/:id/edit', requireAdmin, getPostEditPage);
router.post('/:id/edit', requireAdmin, updatePostPage);
router.post('/:id/delete', requireAdmin, deletePostPage);
router.get('/:id', requireAdmin, getPostDetailPage);

module.exports = router;
