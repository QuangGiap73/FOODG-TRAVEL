function notFoundMiddleware(req, res) {
  if (req.originalUrl.startsWith('/api/')) {
    return res.status(404).json({
      success: false,
      message: 'Resource not found',
    });
  }

  return res.status(404).render('pages/errors/error', {
    layout: 'layouts/auth',
    pageTitle: 'Khong tim thay trang',
    error: {
      statusCode: 404,
      message: 'Trang ban tim khong ton tai.',
    },
  });
}

module.exports = { notFoundMiddleware };
