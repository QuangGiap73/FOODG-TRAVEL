const { env } = require('../../config/env');
const { getFirebaseClientConfig } = require('../../config/firebase-client');

function renderLoginPage(_req, res) {
  res.render('pages/auth/login', {
    layout: 'layouts/auth',
    pageTitle: 'Dang nhap',
    firebaseConfig: getFirebaseClientConfig(),
    sessionCookieName: env.sessionCookieName,
  });
}

module.exports = { renderLoginPage };
