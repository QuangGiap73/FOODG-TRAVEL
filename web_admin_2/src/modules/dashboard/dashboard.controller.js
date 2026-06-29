const { getDashboardOverview } = require('./dashboard.service');

function getDashboardPage(_req, res) {
  const overview = getDashboardOverview();

  res.render('pages/dashboard/index', {
    pageTitle: 'Dashboard',
    overview,
  });
}

module.exports = { getDashboardPage };
