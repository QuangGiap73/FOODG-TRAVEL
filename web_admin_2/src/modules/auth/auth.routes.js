const express = require('express');
const { renderLoginPage, logout } = require('./auth.controller');

const router = express.Router();

router.get('/', (_req, res) => res.redirect('/admin'));
router.get('/login', renderLoginPage);
router.post('/logout', logout);

module.exports = router;
