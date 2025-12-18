const express = require('express');
const { requireAdmin } = require('../middlewares/auth');
const { renderUserManager, listUsers, deleteUser, createUser, updateUser, exportUsersExcel } = require('../controllers/userController');

const router = express.Router();

router.get('/', requireAdmin, renderUserManager);
router.get('/api/users', requireAdmin, listUsers);
router.post('/api/users', requireAdmin, createUser);
router.delete('/api/users/:id', requireAdmin, deleteUser);
router.put('/api/users/:id', requireAdmin, updateUser);
router.get('/api/users/export', requireAdmin, exportUsersExcel);

module.exports = router;
