const express = require('express');
const { requireAdmin } = require('../middlewares/auth');
const { renderDishesPage, listDishes, updateDish, deleteDish } = require('../controllers/dishesController');

const router = express.Router();

router.get('/', requireAdmin, renderDishesPage);
router.get('/api/dishes', requireAdmin, listDishes);
router.put('/api/dishes/:id', requireAdmin, updateDish);
router.delete('api/dishes/:id', requireAdmin, deleteDish);

module.exports = router;
