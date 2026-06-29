const express = require('express');
const multer = require('multer');
const { requireAdmin } = require('../../middlewares/auth.middleware');
const {
  getProvincesPage,
  getRegionsApi,
  getProvincesApi,
  createRegionApi,
  deleteRegionApi,
  createProvinceApi,
  updateProvinceApi,
  deleteProvinceApi,
  uploadProvinceImageApi,
} = require('./provinces.controller');

const router = express.Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 4 * 1024 * 1024 },
});

router.get('/', requireAdmin, getProvincesPage);

router.get('/api/regions', requireAdmin, getRegionsApi);
router.post('/api/regions', requireAdmin, createRegionApi);
router.delete('/api/regions/:code', requireAdmin, deleteRegionApi);

router.get('/api/list', requireAdmin, getProvincesApi);
router.post('/api/list', requireAdmin, createProvinceApi);
router.put('/api/list/:code', requireAdmin, updateProvinceApi);
router.delete('/api/list/:code', requireAdmin, deleteProvinceApi);
router.post('/api/list/upload-image', requireAdmin, upload.single('image'), uploadProvinceImageApi);

module.exports = router;
