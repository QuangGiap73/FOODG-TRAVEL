const express = require('express');
const { renderLoginPage } = require('./auth.controller');

const router = express.Router();

router.get('/', (_req, res) => res.redirect('/admin'));
router.get('/login', renderLoginPage);

module.exports = router;
