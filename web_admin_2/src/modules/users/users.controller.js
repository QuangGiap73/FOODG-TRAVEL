const { ok } = require('../../core/http/response');
const { asyncHandler } = require('../../core/errors/async-handler');
const {
  listUsers,
  getUserDetail,
  createUser,
  updateUser,
  deleteUser,
  deleteUsers,
  uploadUserAvatar,
  buildUsersWorkbook,
} = require('./users.service');

function buildPlaceholderAvatar(name, email) {
  const initials = String(name || email || 'U')
    .trim()
    .split(/\s+/)
    .map((part) => part[0] || '')
    .join('')
    .slice(0, 2)
    .toUpperCase() || 'U';

  return `data:image/svg+xml;utf8,${encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect width="100%" height="100%" rx="48" fill="#fff0dd"/><text x="50%" y="54%" dominant-baseline="middle" text-anchor="middle" font-family="Segoe UI, Arial" font-size="34" font-weight="700" fill="#dc5f00">${initials}</text></svg>`,
  )}`;
}

function mapUsersForDashboard(users) {
  return users.map((user) => {
    const created = user.createdAt?._seconds
      ? new Date(user.createdAt._seconds * 1000)
      : user.createdAt
      ? new Date(user.createdAt)
      : null;
    const updated = user.updatedAt?._seconds
      ? new Date(user.updatedAt._seconds * 1000)
      : user.updatedAt
      ? new Date(user.updatedAt)
      : null;
    const role = String(user.role || 'user').toLowerCase();
    const provinceName =
      user.preferences?.provinceName34 ||
      user.preferences?.provinceName ||
      user.preferences?.provinceCode34 ||
      user.preferences?.provinceCode ||
      '-';
    const journeySummary = user.journeySummary || null;
    const statusKey = user.onboardingCompleted ? 'active' : 'pending';
    const statusLabel = user.onboardingCompleted ? 'Hoạt động' : 'Chưa onboarding';
    const levelNumber = Number(journeySummary?.level || 0) || 0;
    const totalPointsValue = Number(journeySummary?.totalPoints || 0) || 0;
    const totalCheckinsValue = Number(journeySummary?.totalCheckins || 0) || 0;
    const uniqueProvincesCount = Number(journeySummary?.uniqueProvincesCount || 0) || 0;
    const currentStreak = Number(journeySummary?.currentStreak || 0) || 0;

    return {
      ...user,
      avatar: user.photoUrl || buildPlaceholderAvatar(user.fullName, user.email),
      username: String((user.email || user.id).split('@')[0] || '').toLowerCase(),
      provinceName,
      statusLabel,
      statusKey,
      genderLabel: user.gender || '-',
      joinDate: created ? created.toLocaleDateString('vi-VN') : '-',
      joinTime: created ? created.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : '-',
      updatedDate: updated ? updated.toLocaleDateString('vi-VN') : '-',
      updatedTime: updated ? updated.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : '-',
      level: levelNumber ? `Lv.${levelNumber}` : '-',
      levelColor: levelNumber >= 10 ? 'orange' : levelNumber >= 5 ? 'green' : 'blue',
      totalPoints: totalPointsValue.toLocaleString('vi-VN'),
      totalPointsValue,
      totalCheckins: totalCheckinsValue.toLocaleString('vi-VN'),
      totalCheckinsValue,
      uniqueProvincesCount,
      currentStreak,
      roleBadge: role || 'user',
    };
  });
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value === 'object' && value._seconds) return new Date(value._seconds * 1000);
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function formatDate(value, options = {}) {
  const date = toDate(value);
  if (!date) return '-';
  return date.toLocaleDateString('vi-VN', options);
}

function formatDateInput(value) {
  const date = toDate(value);
  if (!date) return '';
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

function formatTime(value) {
  const date = toDate(value);
  if (!date) return '-';
  return date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
}

function formatDateTimeLabel(value) {
  const date = toDate(value);
  if (!date) return 'Chua co du lieu';
  return `${formatDate(date)} , ${formatTime(date)}`;
}

function formatNumber(value) {
  return Number(value || 0).toLocaleString('vi-VN');
}

function mapUserDetailForPage(user) {
  const journeySummary = user.journeySummary || {};
  const provinceName =
    user.preferences?.provinceName34 ||
    user.preferences?.provinceName ||
    user.preferences?.provinceCode34 ||
    user.preferences?.provinceCode ||
    'Chua cap nhat';
  const levelNumber = Number(journeySummary.level || 0) || 0;
  const totalPointsValue = Number(journeySummary.totalPoints || 0) || 0;
  const totalCheckinsValue = Number(journeySummary.totalCheckins || 0) || 0;
  const uniqueProvincesCount = Number(journeySummary.uniqueProvincesCount || 0) || 0;
  const uniquePlacesCount = Number(journeySummary.uniquePlacesCount || 0) || 0;
  const currentStreak = Number(journeySummary.currentStreak || 0) || 0;
  const longestStreak = Number(journeySummary.longestStreak || 0) || 0;
  const badgeCount = Array.isArray(user.badges) ? user.badges.length : 0;
  const postsCount = Array.isArray(user.recentPosts) ? user.recentPosts.length : 0;
  const progressPercent = Math.max(8, Math.min(100, Math.round((uniqueProvincesCount / 34) * 100) || 8));

  const recentActivity = [
    ...(user.recentCheckins || []).slice(0, 4).map((item) => ({
      type: 'checkin',
      icon: '📍',
      colorClass: 'orange',
      title: `Check-in tai "${item.placeName || 'Dia diem'}"`,
      subtitle: item.placeAddress || item.provinceName || 'Không rõ địa điểm',
      sortValue: toDate(item.createdAt)?.getTime() || 0,
      time: formatDateTimeLabel(item.createdAt),
    })),
    ...(user.recentPosts || []).slice(0, 3).map((item) => ({
      type: 'post',
      icon: '📝',
      colorClass: 'blue',
      title: 'Đăng bài viết cộng đồng',
      subtitle: item.text || item.placeSnapshot?.name || 'Không có nội dung',
      sortValue: toDate(item.createdAt)?.getTime() || 0,
      time: formatDateTimeLabel(item.createdAt),
    })),
    ...(user.badges || []).slice(0, 3).map((item) => ({
      type: 'badge',
      icon: '🏅',
      colorClass: 'green',
      title: `Cập nhật huy hiệu "${item.title || 'Huy hiệu'}"`,
      subtitle: item.description || 'Tiến độ huy hiệu',
      sortValue: toDate(item.updatedAt || item.unlockedAt)?.getTime() || 0,
      time: formatDateTimeLabel(item.updatedAt || item.unlockedAt),
    })),
  ]
    .sort((left, right) => right.sortValue - left.sortValue);

  return {
    ...user,
    avatar: user.photoUrl || buildPlaceholderAvatar(user.fullName, user.email),
    username: String((user.email || user.id).split('@')[0] || '').toLowerCase(),
    provinceName,
    fullName: user.fullName || 'Người dùng',
    phone: user.phone || 'Chưa cập nhật',
    email: user.email || 'Chưa cập nhật',
    genderLabel: user.gender === 'male' ? 'Nam' : user.gender === 'female' ? 'Nữ' : user.gender || 'Chưa cập nhật',
    birthDateLabel: formatDate(user.dateOfBirth),
    createdAtLabel: formatDate(user.createdAt),
    createdAtTimeLabel: formatTime(user.createdAt),
    updatedAtLabel: formatDate(user.updatedAt),
    levelBadge: levelNumber ? `Lv.${levelNumber}` : 'Lv.0',
    statusLabel: user.onboardingCompleted ? 'Hoạt động' : 'Chưa onboarding',
    statusClass: user.onboardingCompleted ? 'active' : 'pending',
    stats: [
      { icon: '⭐', label: 'Tổng điểm', value: formatNumber(totalPointsValue) },
      { icon: '📍', label: 'Tổng check-in', value: formatNumber(totalCheckinsValue) },
      { icon: '🗺️', label: 'Tỉnh đã khám phá', value: `${formatNumber(uniqueProvincesCount)} / 34` },
      { icon: '🔥', label: 'Streak', value: `${formatNumber(currentStreak)} ngay` },
      { icon: '🏅', label: 'Huy hiệu', value: formatNumber(badgeCount) },
      { icon: '📝', label: 'Bài đăng cộng đồng', value: formatNumber(postsCount) },
    ],
    accountSummary: [
      { icon: '💚', label: 'Trạng thái tài khoản', value: user.onboardingCompleted ? 'Hoạt động bình thường' : 'Cần hoàn tất onboarding', colorClass: 'green' },
      { icon: '🕒', label: 'Hoạt động gần nhất', value: formatDateTimeLabel(journeySummary.lastActiveAt || user.updatedAt), colorClass: 'blue' },
      { icon: '🛡️', label: 'Xác minh tài khoản', value: user.email ? 'Đã có email đăng nhập' : 'Chưa có email', colorClass: 'green' },
      { icon: '📱', label: 'Nền tảng', value: 'Dữ liệu hiện tại chưa lưu thiết bị', colorClass: 'purple' },
    ],
    overviewProfile: [
      { label: 'Họ tên', value: user.fullName || '-' },
      { label: 'Email', value: user.email || '-' },
      { label: 'Số điện thoại', value: user.phone || '-' },
      { label: 'Ngày sinh', value: formatDate(user.dateOfBirth) },
      { label: 'Giới tính', value: user.gender === 'male' ? 'Nam' : user.gender === 'female' ? 'Nữ' : user.gender || '-' },
      { label: 'Thành phố hiện tại', value: provinceName },
    ],
    journeyCard: {
      progressPercent,
      progressLabel: `${progressPercent}%`,
      provinceValue: provinceName,
      placeValue: `${formatNumber(uniquePlacesCount)} dia diem`,
      favoriteCategory: `Mức cay ${Number(user.preferences?.spicyLevel || 0)}/5`,
    },
    achievementStats: [
      { label: 'Streak hiện tại', value: `${formatNumber(currentStreak)} ngày`, hint: 'Chuỗi hiện tại' },
      { label: 'Streak dài nhất', value: `${formatNumber(longestStreak)} ngày`, hint: 'Kỷ lục cá nhân' },
      { label: 'Tổng check-in', value: formatNumber(totalCheckinsValue), hint: 'Đã hoàn thành' },
      { label: 'Quán đã lưu', value: formatNumber(uniquePlacesCount), hint: 'Tổng số địa điểm' },
    ],
    featuredBadges: (user.badges || []).slice(0, 5).map((badge, index) => ({
      id: badge.id || badge.badgeId || `badge-${index}`,
      title: badge.title || 'Huy hiệu',
      description: badge.description || 'Đang cập nhật',
      progressText: `${Math.round(Number(badge.progress || 0) * 100)}%`,
      accentClass: ['orange', 'green', 'blue', 'red', 'yellow'][index % 5],
    })),
    recentPlaces: (user.recentCheckins || []).slice(0, 3).map((item) => ({
      id: item.id,
      title: item.placeName || 'Địa điểm check-in',
      subtitle: item.placeAddress || item.provinceName || 'Không rõ địa điểm',
      image: item.photoUrl || item.placeImageUrl || user.photoUrl || buildPlaceholderAvatar(item.placeName, user.email),
      rating: Number(item.pointsEarned || 0) / 10 + 3.5,
    })),
    recentPosts: (user.recentPosts || []).slice(0, 1).map((item) => ({
      id: item.id,
      title: item.placeSnapshot?.name || 'Bài đăng cộng đồng',
      content: item.text || 'Không có nội dung',
      image: item.media?.[0]?.url || item.placeSnapshot?.photoUrl || user.photoUrl || buildPlaceholderAvatar(user.fullName, user.email),
      meta: `${formatDate(item.createdAt)}  •  ❤ ${formatNumber(item.likeCount || 0)}  •  💬 ${formatNumber(item.commentCount || 0)}`,
    })),
    moderationNote: user.onboardingCompleted
      ? 'Người dùng hoạt động ổn định, dữ liệu journey đang đồng bộ bình thường.'
      : 'Tài khoản chưa hoàn tất onboarding, cần theo dõi thêm.',
    moderationStatuses: [
      { label: 'Hoạt động bình thường', className: 'good' },
      { label: 'Chờ xác minh', className: 'warn' },
      { label: 'Cảnh báo', className: 'danger' },
    ],
    recentActivity: recentActivity.slice(0, 5),
  };
}

async function getUsersPage(_req, res) {
  const rawUsers = await listUsers({ sort: 'created-desc' });
  const users = mapUsersForDashboard(rawUsers);
  const activeUsers = users.filter((user) => user.statusKey === 'active').length;
  const usersWithJourney = users.filter((user) => user.journeySummary).length;
  const totalPoints = users.reduce((sum, user) => sum + user.totalPointsValue, 0);
  const totalCheckins = users.reduce((sum, user) => sum + user.totalCheckinsValue, 0);
  const provinceSet = new Set(users.map((user) => user.provinceName).filter((value) => value && value !== '-'));

  res.render('pages/users/index', {
    pageTitle: 'Người dùng',
    users,
    stats: [
      { label: 'Tổng người dùng', value: users.length.toLocaleString('vi-VN'), icon: '👥', colorClass: 'orange' },
      { label: 'Người dùng hoạt động', value: activeUsers.toLocaleString('vi-VN'), icon: '🟢', colorClass: 'green' },
      { label: 'Tổng lượt check-in', value: totalCheckins.toLocaleString('vi-VN'), icon: '📍', colorClass: 'yellow' },
      { label: 'Tổng điểm thưởng', value: totalPoints.toLocaleString('vi-VN'), icon: '🎖', colorClass: 'purple' },
    ],
    filters: {
      roles: ['Tất cả', 'admin', 'user'],
      statuses: ['Tất cả', 'Hoạt động', 'Chưa onboarding'],
      provinces: ['Tất cả', ...Array.from(provinceSet).sort((a, b) => a.localeCompare(b, 'vi'))],
      sorts: ['Ngày tham gia mới nhất', 'Ngày cập nhật mới nhất', 'Tên A-Z'],
    },
    pagination: {
      from: users.length ? 1 : 0,
      to: users.length,
      total: users.length,
      page: 1,
      totalPages: 1,
      pageSize: 10,
    },
  });
}

async function getUserDetailPage(req, res) {
  const user = mapUserDetailForPage(await getUserDetail(req.params.id));

  res.render('pages/users/detail', {
    pageTitle: 'Chi tiết người dùng',
    detailUser: user,
  });
}

async function getUserEditPage(req, res) {
  const user = mapUserDetailForPage(await getUserDetail(req.params.id));

  res.render('pages/users/edit', {
    pageTitle: 'Chỉnh sửa người dùng',
    editUser: {
      ...user,
      dateOfBirthInput: formatDateInput(user.dateOfBirth),
    },
  });
}

async function getUsersApi(req, res) {
  return ok(res, await listUsers({ sort: req.query.sort }));
}

const createUserApi = asyncHandler(async (req, res) => {
  return ok(res, await createUser(req.body), 'Created', 201);
});

const updateUserApi = asyncHandler(async (req, res) => {
  return ok(res, await updateUser(req.params.id, req.body), 'Updated');
});

const deleteUserApi = asyncHandler(async (req, res) => {
  return ok(res, await deleteUser(req.params.id), 'Deleted');
});

const deleteUsersApi = asyncHandler(async (req, res) => {
  return ok(res, await deleteUsers(req.body?.ids), 'Deleted');
});

const uploadUserAvatarApi = asyncHandler(async (req, res) => {
  return ok(res, await uploadUserAvatar(req.params.id, req.file), 'Avatar uploaded');
});

const exportUsersApi = asyncHandler(async (req, res) => {
  const workbook = await buildUsersWorkbook({ sort: req.query.sort });
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename=users.xlsx');
  await workbook.xlsx.write(res);
  res.end();
});

module.exports = {
  getUsersPage: asyncHandler(getUsersPage),
  getUserDetailPage: asyncHandler(getUserDetailPage),
  getUserEditPage: asyncHandler(getUserEditPage),
  getUsersApi: asyncHandler(getUsersApi),
  createUserApi,
  updateUserApi,
  deleteUserApi,
  deleteUsersApi,
  uploadUserAvatarApi,
  exportUsersApi,
};
