const { getDashboardCollections } = require('./dashboard.repository');
const canonicalProvinces = require('./data/canonical-provinces-34.json');
const provinceMergeMap = require('./data/province-merge-map.json');
const { remember } = require('../../core/cache/memory-cache');

const DAY_MS = 24 * 60 * 60 * 1000;

function timestampToDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value._seconds) return new Date(value._seconds * 1000);
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function getCreatedAt(item) {
  return timestampToDate(item.createdAt || item.publishedAt || item.updatedAt);
}

function getText(value) {
  if (typeof value === 'string') return value;
  if (value && typeof value === 'object') return value.vi || value.en || '';
  return '';
}

function normalizeKey(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function formatNumber(value) {
  return new Intl.NumberFormat('vi-VN').format(value);
}

function countToday(items, now) {
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return items.filter((item) => (getCreatedAt(item)?.getTime() || 0) >= start.getTime()).length;
}

function buildSevenDaySeries(posts, now) {
  return Array.from({ length: 7 }, (_, index) => {
    const date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (6 - index));
    const nextDate = new Date(date.getTime() + DAY_MS);
    const value = posts.filter((post) => {
      const createdAt = getCreatedAt(post);
      return createdAt && createdAt >= date && createdAt < nextDate;
    }).length;
    return {
      label: date.toLocaleDateString('vi-VN', { weekday: 'short' }),
      date: date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
      value,
    };
  });
}

function buildProvinceMap(provinces, dishes, posts) {
  const activity = new Map();
  const canonicalize = (value) => {
    const key = normalizeKey(value).replace(/^(tinh|tp|thanh_pho)_/, '');
    if (key === 'ho_chi_minh') return 'thanh_pho_ho_chi_minh';
    return provinceMergeMap[key] || key;
  };
  const add = (item, type) => {
    const rawKey = item.provinceCode34 || item.provinceCode || item.province_code || item.provinceName34 || item.provinceName || item.province;
    const key = canonicalize(rawKey);
    if (!key) return;
    const current = activity.get(key) || { dishes: 0, posts: 0 };
    current[type] += 1;
    activity.set(key, current);
  };
  dishes.forEach((item) => add(item, 'dishes'));
  posts.forEach((item) => add(item, 'posts'));

  const coordinateGroups = new Map();
  provinces.forEach((province) => {
    const rawKey = province.code || province.provinceCode34 || province.slug || getText(province.name) || province.id;
    const key = canonicalize(rawKey);
    const lat = Number(province.centerLat || province.latitude || province.lat);
    const lng = Number(province.centerLng || province.longitude || province.lng);
    if (!key || !Number.isFinite(lat) || !Number.isFinite(lng)) return;
    const group = coordinateGroups.get(key) || [];
    group.push({ lat, lng, isCanonical: normalizeKey(rawKey) === key });
    coordinateGroups.set(key, group);
  });

  return canonicalProvinces
    .map((province) => {
      const stats = activity.get(province.code) || { dishes: 0, posts: 0 };
      const coordinates = coordinateGroups.get(province.code) || [];
      const preferred = coordinates.find((item) => item.isCanonical);
      const lat = preferred?.lat ?? (coordinates.length ? coordinates.reduce((sum, item) => sum + item.lat, 0) / coordinates.length : NaN);
      const lng = preferred?.lng ?? (coordinates.length ? coordinates.reduce((sum, item) => sum + item.lng, 0) / coordinates.length : NaN);
      return {
        id: province.code,
        name: province.name,
        lat,
        lng,
        dishes: stats.dishes,
        posts: stats.posts,
        total: stats.dishes + stats.posts,
      };
    })
    .filter((province) => Number.isFinite(province.lat) && Number.isFinite(province.lng))
    .sort((left, right) => right.total - left.total);
}

function buildRecentActivity(users, posts, systemPosts) {
  const activities = [
    ...users.map((item) => ({
      type: 'user',
      title: getText(item.fullName) || item.displayName || item.email || 'Người dùng mới',
      description: 'Đã tham gia cộng đồng',
      date: getCreatedAt(item),
      href: `/admin/users/${item.id}`,
    })),
    ...posts.map((item) => ({
      type: 'post',
      title: getText(item.title) || getText(item.caption) || 'Bài viết cộng đồng',
      description: item.moderationStatus === 'pending' ? 'Đang chờ kiểm duyệt' : 'Hoạt động mới từ cộng đồng',
      date: getCreatedAt(item),
      href: `/admin/posts/${item.id}`,
    })),
    ...systemPosts.map((item) => ({
      type: 'system',
      title: getText(item.title) || 'Nội dung hệ thống',
      description: item.status === 'published' ? 'Đã xuất bản' : 'Đã cập nhật nội dung',
      date: getCreatedAt(item),
      href: `/admin/system-posts/${item.id}`,
    })),
  ];

  return activities
    .filter((item) => item.date)
    .sort((left, right) => right.date - left.date)
    .slice(0, 6)
    .map((item) => ({
      ...item,
      time: item.date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }),
    }));
}

async function buildDashboardOverview() {
  const data = await getDashboardCollections();
  const now = new Date();
  const pendingPosts = data.posts.filter((post) => ['pending', 'review', 'waiting'].includes(String(post.moderationStatus || '').toLowerCase()));
  const activePosts = data.posts.filter((post) => String(post.status || 'active').toLowerCase() !== 'deleted');
  const mapPoints = buildProvinceMap(data.provinces, data.dishes, activePosts);

  return {
    generatedAt: now.toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric' }),
    stats: [
      { key: 'users', label: 'Người dùng', value: formatNumber(data.users.length), hint: `+${countToday(data.users, now)} hôm nay`, href: '/admin/users' },
      { key: 'dishes', label: 'Món ăn', value: formatNumber(data.dishes.length), hint: `${formatNumber(mapPoints.filter((item) => item.dishes > 0).length)} tỉnh có dữ liệu`, href: '/admin/dishes' },
      { key: 'posts', label: 'Bài viết', value: formatNumber(activePosts.length), hint: `+${countToday(activePosts, now)} hôm nay`, href: '/admin/posts' },
      { key: 'pending', label: 'Chờ kiểm duyệt', value: formatNumber(pendingPosts.length), hint: pendingPosts.length ? 'Cần xử lý sớm' : 'Đã xử lý hết', href: '/admin/posts?moderationStatus=pending' },
    ],
    weeklyPosts: buildSevenDaySeries(activePosts, now),
    mapPoints,
    topProvinces: mapPoints.filter((item) => item.total > 0).slice(0, 5),
    recentActivity: buildRecentActivity(data.users, activePosts, data.systemPosts),
    coverage: {
      provinces: canonicalProvinces.length,
      mapped: mapPoints.length,
      active: mapPoints.filter((item) => item.total > 0).length,
    },
  };
}

async function getDashboardOverview() {
  return remember('dashboard:overview', 45 * 1000, buildDashboardOverview);
}

module.exports = { getDashboardOverview };
