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

function logout(_req, res) {
  res.clearCookie(env.sessionCookieName, {
    path: '/',
    sameSite: 'lax',
  });

  return res.redirect('/login');
}

module.exports = { renderLoginPage, logout };
