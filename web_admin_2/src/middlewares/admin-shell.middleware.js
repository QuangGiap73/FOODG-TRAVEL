function adminShell(req, res, next) {
  const currentPath = req.path || '/';

  res.locals.currentPath = currentPath;
  res.locals.pageTitle = 'Dashboard';
  res.locals.layout = 'layouts/admin';
  res.locals.user = res.locals.user || {
    displayName: 'Admin Demo',
    role: 'guest',
  };
  res.locals.navItems = [
    { label: 'Dashboard', href: '/admin', key: '/admin', icon: 'home' },
    { label: 'Người dùng', href: '/admin/users', key: '/admin/users', icon: 'users' },
    { label: 'Tỉnh thành', href: '/admin/provinces', key: '/admin/provinces', icon: 'map' },
    { label: 'Món ăn', href: '/admin/dishes', key: '/admin/dishes', icon: 'dish' },
    { label: 'Bài viết', href: '/admin/posts', key: '/admin/posts', icon: 'post' },
    { label: 'Bài viết hệ thống', href: '/admin/system-posts', key: '/admin/system-posts', icon: 'post' },
  ];

  next();
}

module.exports = { adminShell };
