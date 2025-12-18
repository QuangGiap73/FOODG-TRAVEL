const express = require('express');
const { requireAdmin } = require('../middlewares/auth');
const {
  renderProvincesPage,
  listRegions,
  listProvinces,
  addRegion,
  deleteRegion,
  addProvince,
  uploadProvinceImage,
} = require('../controllers/provincesController');
const upload = require('../middlewares/upload');

const router = express.Router();

router.get('/', requireAdmin, renderProvincesPage);
router.get('/api/regions', requireAdmin, listRegions);
router.get('/api/provinces', requireAdmin, listProvinces);
router.post('/api/regions', requireAdmin, addRegion);
router.delete('/api/regions/:code', requireAdmin, deleteRegion);
router.post('/api/provinces', requireAdmin, addProvince);
router.post(
  '/api/provinces/upload-image',
  requireAdmin,
  upload.single('image'),
  uploadProvinceImage,
);

module.exports = router;
