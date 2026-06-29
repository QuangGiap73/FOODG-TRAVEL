function getDishesPage(_req, res) {
  res.render('pages/dishes/index', {
    pageTitle: 'Mon an',
  });
}

module.exports = { getDishesPage };
