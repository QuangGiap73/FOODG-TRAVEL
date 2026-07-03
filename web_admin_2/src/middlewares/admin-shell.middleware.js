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
    { label: 'Nguoi dung', href: '/admin/users', key: '/admin/users', icon: 'users' },
    { label: 'Tinh thanh', href: '/admin/provinces', key: '/admin/provinces', icon: 'map' },
    { label: 'Mon an', href: '/admin/dishes', key: '/admin/dishes', icon: 'dish' },
    { label: 'Bai viet', href: '/admin/posts', key: '/admin/posts', icon: 'post' },
  ];

  next();
}

module.exports = { adminShell };
