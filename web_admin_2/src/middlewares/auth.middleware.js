const { env } = require('../config/env');
const { getFirebaseAdmin } = require('../config/firebase-admin');

function parseCookieHeader(header = '') {
  return header.split(';').reduce((acc, part) => {
    const [key, ...rest] = part.trim().split('=');
    if (!key) return acc;
    acc[key] = rest.join('=');
    return acc;
  }, {});
}

function getTokenFromRequest(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (authHeader && typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
    return authHeader.replace('Bearer ', '').trim();
  }

  const cookies = parseCookieHeader(req.headers.cookie || '');
  return cookies[env.sessionCookieName] || null;
}

function getRoleFromClaims(decoded) {
  return decoded.role || (decoded.admin ? 'admin' : 'user');
}

function redirectOrJson(req, res, statusCode, message) {
  if (req.accepts('html')) {
    return res.redirect('/login');
  }

  return res.status(statusCode).json({
    success: false,
    message,
  });
}

async function verifyRequestToken(req, res) {
  const token = getTokenFromRequest(req);
  if (!token) {
    redirectOrJson(req, res, 401, 'Missing Firebase ID token');
    return null;
  }

  const admin = getFirebaseAdmin();
  if (!admin) {
    redirectOrJson(req, res, 500, 'Firebase Admin is not configured');
    return null;
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;
    res.locals.user = {
      displayName: decoded.name || decoded.email || decoded.uid,
      email: decoded.email || '',
      role: getRoleFromClaims(decoded),
      uid: decoded.uid,
    };
    res.locals.isAuthenticated = true;
    return decoded;
  } catch (error) {
    console.error('[auth] verifyIdToken error:', error.message);
    redirectOrJson(req, res, 401, 'Invalid or expired Firebase ID token');
    return null;
  }
}

async function requireAuth(req, res, next) {
  const decoded = await verifyRequestToken(req, res);
  if (decoded) next();
}

function requireRole(roles, options = { allowAdmin: true }) {
  const allowedRoles = Array.isArray(roles) ? roles : [roles];

  return async function roleGuard(req, res, next) {
    const decoded = await verifyRequestToken(req, res);
    if (!decoded) return;

    const role = getRoleFromClaims(decoded);
    const isAllowed = allowedRoles.includes(role) || (options.allowAdmin && role === 'admin');

    if (!isAllowed) {
      redirectOrJson(req, res, 403, `Forbidden: requires ${allowedRoles.join(', ')}`);
      return;
    }

    next();
  };
}

const requireAdmin = requireRole('admin', { allowAdmin: true });

module.exports = {
  requireAuth,
  requireAdmin,
  requireRole,
  getRoleFromClaims,
  getTokenFromRequest,
};
