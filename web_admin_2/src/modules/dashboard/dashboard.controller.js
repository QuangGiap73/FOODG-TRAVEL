const { getDashboardOverview } = require('./dashboard.service');

async function getDashboardPage(_req, res) {
  const overview = await getDashboardOverview();

  res.render('pages/dashboard/index', {
    pageTitle: 'Dashboard',
    overview,
    pageStyles: ['/public/css/pages/dashboard.css', '/public/css/pages/dashboard-map.css'],
    pageScripts: ['/public/vendor/d3/d3.min.js', '/public/js/modules/dashboard/index.js', '/public/js/modules/dashboard/dashboard-map.js'],
  });
}

module.exports = { getDashboardPage };
