const express = require('express');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const { getDishesPage } = require('./dishes.controller');

const router = express.Router();

router.get('/', requireAdmin, getDishesPage);

module.exports = router;
