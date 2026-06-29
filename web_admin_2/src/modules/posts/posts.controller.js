function getPostsPage(_req, res) {
  res.render('pages/posts/index', {
    pageTitle: 'Bai viet',
  });
}

module.exports = { getPostsPage };
