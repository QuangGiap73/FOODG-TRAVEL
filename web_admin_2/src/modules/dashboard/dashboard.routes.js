const express = require('express');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const { asyncHandler } = require('../../core/errors/async-handler');
const { getDashboardPage } = require('./dashboard.controller');

const router = express.Router();

router.get('/', requireAdmin, asyncHandler(getDashboardPage));

module.exports = router;
