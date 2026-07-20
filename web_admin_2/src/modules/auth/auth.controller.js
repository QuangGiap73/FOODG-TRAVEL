const { env } = require('../../config/env');
const { getFirebaseClientConfig } = require('../../config/firebase-client');
const { getFirebaseAdmin } = require('../../config/firebase-admin');

function renderLoginPage(_req, res) {
  res.render('pages/auth/login', {
    layout: 'layouts/auth',
    pageTitle: 'Dang nhap',
    firebaseConfig: getFirebaseClientConfig(),
    sessionCookieName: env.sessionCookieName,
  });
}

async function createSession(req, res) {
  const admin = getFirebaseAdmin();
  if (!admin) {
    return res.status(500).json({
      success: false,
      message: 'Firebase Admin is not configured',
    });
  }

  const idToken = String(req.body?.idToken || '').trim();
  const rememberLogin = req.body?.rememberLogin === true;
  if (!idToken) {
    return res.status(400).json({
      success: false,
      message: 'Missing Firebase ID token',
    });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    const role = decoded.role || (decoded.admin ? 'admin' : null);
    if (role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Tai khoan khong co quyen admin.',
      });
    }

    const expiresIn = rememberLogin
      ? 14 * 24 * 60 * 60 * 1000
      : 12 * 60 * 60 * 1000;
    const sessionCookie = await admin.auth().createSessionCookie(idToken, {
      expiresIn,
    });

    res.cookie(env.sessionCookieName, sessionCookie, {
      maxAge: expiresIn,
      httpOnly: true,
      sameSite: 'lax',
      secure: env.nodeEnv === 'production',
      path: '/',
    });

    return res.json({
      success: true,
      message: 'Session created',
    });
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: error.message || 'Khong the tao session dang nhap',
    });
  }
}

function logout(_req, res) {
  res.clearCookie(env.sessionCookieName, {
    path: '/',
    sameSite: 'lax',
  });

  return res.redirect('/login');
}

module.exports = { renderLoginPage, createSession, logout };
