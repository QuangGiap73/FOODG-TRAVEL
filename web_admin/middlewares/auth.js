const { admin } = require('../firebase/config');

// Extract ID token from Authorization header "Bearer <token>" or cookie "idToken"
function getTokenFromRequest(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (authHeader && typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
    return authHeader.replace('Bearer ', '').trim();
  }
  const rawCookie = req.headers.cookie;
  if (rawCookie) {
    const cookies = parseCookieHeader(rawCookie);
    if (cookies.idToken) {
      return cookies.idToken;
    }
  }
  return null;
}

function getRoleFromClaims(decoded) {
  return decoded.role || (decoded.admin ? 'admin' : undefined);
}

function redirectOrJson(res, statusCode, payload, wantsHtml) {
  if (wantsHtml) {
    res.redirect('/login');
  } else {
    res.status(statusCode).json(payload);
  }
}

async function verifyRequestToken(req, res) {
  const token = getTokenFromRequest(req);
  const wantsHtml = req.accepts('html');

  if (!token) {
    redirectOrJson(res, 401, { error: 'Missing Firebase ID token' }, wantsHtml);
    return null;
  }
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;
    res.locals.user = decoded;
    return decoded;
  } catch (error) {
    console.error('verifyIdToken error:', error.message);
    redirectOrJson(res, 401, { error: 'Invalid or expired Firebase ID token' }, wantsHtml);
    return null;
  }
}

async function requireAuth(req, res, next) {
  const decoded = await verifyRequestToken(req, res);
  if (decoded) {
    next();
  }
}

function requireRole(roles, options = { allowAdmin: true }) {
  const allowed = Array.isArray(roles) ? roles : [roles];
  return async (req, res, next) => {
    const decoded = await verifyRequestToken(req, res);
    if (!decoded) return;

    const role = getRoleFromClaims(decoded);
    const wantsHtml = req.accepts('html');

    const isAllowed =
      allowed.includes(role) ||
      (options.allowAdmin && role === 'admin');

    if (isAllowed) {
      next();
    } else {
      redirectOrJson(res, 403, { error: `Forbidden: role ${allowed.join(', ')} required` }, wantsHtml);
    }
  };
}

const requireAdmin = requireRole('admin', { allowAdmin: true });
const requireUser = requireRole('user', { allowAdmin: true }); // admin cũng được phép, user app chắc chắn được

module.exports = { requireAuth, requireAdmin, requireUser, requireRole, getRoleFromClaims };

function parseCookieHeader(header) {
  return header.split(';').reduce((acc, part) => {
    const [key, ...rest] = part.trim().split('=');
    acc[key] = rest.join('=');
    return acc;
  }, {});
}
