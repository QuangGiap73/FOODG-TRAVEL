const express = require('express');
const multer = require('multer');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const {
  getUsersPage,
  getUserDetailPage,
  getUserEditPage,
  getUsersApi,
  createUserApi,
  updateUserApi,
  deleteUserApi,
  deleteUsersApi,
  uploadUserAvatarApi,
  exportUsersApi,
} = require('./users.controller');

const router = express.Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
});

router.get('/', requireAdmin, getUsersPage);
router.get('/api/list', requireAdmin, getUsersApi);
router.post('/api/list', requireAdmin, createUserApi);
router.put('/api/list/:id', requireAdmin, updateUserApi);
router.delete('/api/list', requireAdmin, deleteUsersApi);
router.delete('/api/list/:id', requireAdmin, deleteUserApi);
router.post('/api/list/:id/avatar', requireAdmin, upload.single('avatar'), uploadUserAvatarApi);
router.get('/api/export', requireAdmin, exportUsersApi);
router.get('/:id/edit', requireAdmin, getUserEditPage);
router.get('/:id', requireAdmin, getUserDetailPage);

module.exports = router;
