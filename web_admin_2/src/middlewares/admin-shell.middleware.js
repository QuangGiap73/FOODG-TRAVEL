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
    { label: 'Dashboard', href: '/admin', key: '/admin' },
    { label: 'Nguoi dung', href: '/admin/users', key: '/admin/users' },
    { label: 'Tinh thanh', href: '/admin/provinces', key: '/admin/provinces' },
    { label: 'Mon an', href: '/admin/dishes', key: '/admin/dishes' },
    { label: 'Bai viet', href: '/admin/posts', key: '/admin/posts' },
  ];

  next();
}

module.exports = { adminShell };
