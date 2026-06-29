const express = require('express');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const { getDashboardPage } = require('./dashboard.controller');

const router = express.Router();

router.get('/', requireAdmin, getDashboardPage);

module.exports = router;
