const express = require('express');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const { getPostsPage } = require('./posts.controller');

const router = express.Router();

router.get('/', requireAdmin, getPostsPage);

module.exports = router;
