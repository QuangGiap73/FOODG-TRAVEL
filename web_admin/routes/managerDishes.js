const express = require('express');
const { requireAdmin} = require('../middlewares/auth');
const { renderDishesPage, listDishes} = require('../controllers/dishesController');

const router = express.Router();
router.get('/', requireAdmin, (req, res) => {
    res.render('manager_dishes/manager_dishes', { pageTitle: 'Quan ly mon an'});
})
router.get('/', requireAdmin, renderDishesPage);
router.get('/api/dishes', requireAdmin, listDishes);
module.exports = router;