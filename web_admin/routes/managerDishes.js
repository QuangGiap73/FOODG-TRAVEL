const express = require('express');
const { requireAdmin } = require('../middlewares/auth');
const { renderDishesPage, listDishes, updateDish, deleteDish, createDish, uploadDishImage } = require('../controllers/dishesController');
const upload = require('../middlewares/upload');

const router = express.Router();

router.get('/', requireAdmin, renderDishesPage);
router.get('/api/dishes', requireAdmin, listDishes);
router.put('/api/dishes/:id', requireAdmin, updateDish);
router.delete('/api/dishes/:id', requireAdmin, deleteDish);
router.post('/api/dishes',requireAdmin, createDish);
router.post('/api/dishes/upload-image', requireAdmin, upload.array('images', 10), uploadDishImage);
module.exports = router;
