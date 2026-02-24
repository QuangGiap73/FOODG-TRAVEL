const express = require('express');
const { requireAdmin } = require('../middlewares/auth');
const {
  renderPostsPage,
  listPosts,
  updatePostStatus,
} = require('../controllers/postsController');

const router = express.Router();

router.get('/', requireAdmin, renderPostsPage);
router.get('/api/posts', requireAdmin, listPosts);
router.put('/api/posts/:id/status', requireAdmin, updatePostStatus);

module.exports = router;
