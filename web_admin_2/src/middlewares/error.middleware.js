function errorMiddleware(error, _req, res, _next) {
  const statusCode = error.statusCode || 500;

  if (_req.originalUrl.includes('/api/')) {
    return res.status(statusCode).json({
      success: false,
      message: error.message || 'Internal server error',
      details: error.details || null,
    });
  }

  return res.status(statusCode).render('pages/errors/error', {
    layout: 'layouts/auth',
    pageTitle: 'Co loi xay ra',
    error,
  });
}

module.exports = { errorMiddleware };
