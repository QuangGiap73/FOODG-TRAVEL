const express = require('express');
const multer = require('multer');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const {
  getDishesPage,
  getDishDetailPage,
  getDishCreatePage,
  createDishPage,
  getDishesApi,
  exportDishesApi,
  uploadDishImageApi,
  deleteDishApi,
} = require('./dishes.controller');

const router = express.Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 4 * 1024 * 1024 },
});

router.get('/', requireAdmin, getDishesPage);
router.get('/add', requireAdmin, getDishCreatePage);
router.post('/add', requireAdmin, createDishPage);
router.get('/:id', requireAdmin, getDishDetailPage);
router.get('/api/list', requireAdmin, getDishesApi);
router.get('/api/export', requireAdmin, exportDishesApi);
router.post('/api/upload-image', requireAdmin, upload.single('image'), uploadDishImageApi);
router.delete('/api/list/:id', requireAdmin, deleteDishApi);

module.exports = router;
