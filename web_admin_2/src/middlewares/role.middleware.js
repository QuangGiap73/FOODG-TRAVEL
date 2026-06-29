function requireRole(_role) {
  return function roleGuard(_req, _res, next) {
    next();
  };
}

module.exports = { requireRole };
