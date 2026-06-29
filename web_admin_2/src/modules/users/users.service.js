const ExcelJS = require('exceljs');
const { AppError } = require('../../core/errors/app-error');
const {
  listUsersFromRepository,
  getUserDetailByIdFromRepository,
  createUserInRepository,
  updateUserInRepository,
  updateUserAvatarInRepository,
  deleteUserInRepository,
} = require('./users.repository');
const { validateUserPayload } = require('./users.validator');
const { toUserViewModel } = require('./users.mapper');
const { createUploadService } = require('../uploads/upload.service');

function getTime(val) {
  if (!val) return 0;
  if (typeof val === 'object' && val._seconds) return val._seconds * 1000;
  const time = new Date(val).getTime();
  return Number.isNaN(time) ? 0 : time;
}

function sortUsers(items, sort = '') {
  const normalized = String(sort || '').toLowerCase();
  const list = [...items];

  if (normalized === 'name-asc' || normalized === 'name-desc') {
    const asc = normalized === 'name-asc';
    const getLastName = (value) => {
      const parts = String(value.fullName || '').trim().toLowerCase().split(/\s+/);
      return parts.length ? parts[parts.length - 1] : '';
    };

    list.sort((a, b) => {
      const left = getLastName(a);
      const right = getLastName(b);
      if (left < right) return asc ? -1 : 1;
      if (left > right) return asc ? 1 : -1;
      return 0;
    });
  }

  if (normalized === 'created-asc' || normalized === 'created-desc') {
    const asc = normalized === 'created-asc';
    list.sort((a, b) => (asc ? getTime(a.createdAt) - getTime(b.createdAt) : getTime(b.createdAt) - getTime(a.createdAt)));
  }

  return list;
}

async function listUsers(options = {}) {
  const items = await listUsersFromRepository();
  return sortUsers(items.map(toUserViewModel), options.sort);
}

async function createUser(payload) {
  const data = validateUserPayload(payload);
  if (!data.email || !data.password) {
    throw new AppError('Missing email or password', 400);
  }
  if (data.password.length < 6) {
    throw new AppError('auth/invalid-password', 400);
  }

  try {
    const id = await createUserInRepository(data);
    return { id };
  } catch (error) {
    const badRequestCodes = ['auth/email-already-exists', 'auth/invalid-password', 'auth/invalid-email'];
    if (badRequestCodes.includes(error?.code)) {
      throw new AppError(error.code, 400);
    }
    throw error;
  }
}

async function getUserDetail(id) {
  if (!id) throw new AppError('Missing id', 400);
  const item = await getUserDetailByIdFromRepository(id);
  if (!item) throw new AppError('User not found', 404);
  return toUserViewModel(item);
}

async function updateUser(id, payload) {
  const data = validateUserPayload(payload);
  if (!id) throw new AppError('Missing id', 400);
  if (!data.email) throw new AppError('Missing email', 400);
  if (data.password && data.password.trim() && data.password.trim().length < 6) {
    throw new AppError('auth/invalid-password', 400);
  }
  data.password = data.password ? data.password.trim() : '';

  try {
    const updated = await updateUserInRepository(id, data);
    if (!updated) throw new AppError('User not found', 404);
    return { id, authUpdated: updated.authUpdated };
  } catch (error) {
    const badCodes = ['auth/email-already-exists', 'auth/invalid-email', 'auth/invalid-password'];
    if (badCodes.includes(error?.code)) {
      throw new AppError(error.code, 400);
    }
    throw error;
  }
}

async function deleteUser(id) {
  if (!id) throw new AppError('Missing id', 400);
  const deleted = await deleteUserInRepository(id);
  if (!deleted) throw new AppError('User not found', 404);
  return { id };
}

async function deleteUsers(ids = []) {
  const normalizedIds = Array.from(new Set(
    (Array.isArray(ids) ? ids : [])
      .map((id) => String(id || '').trim())
      .filter(Boolean),
  ));

  if (!normalizedIds.length) throw new AppError('Missing user ids', 400);

  const results = [];
  for (const id of normalizedIds) {
    const deleted = await deleteUserInRepository(id);
    results.push({ id, deleted: Boolean(deleted) });
  }

  return {
    deleted: results.filter((item) => item.deleted).map((item) => item.id),
    notFound: results.filter((item) => !item.deleted).map((item) => item.id),
  };
}

async function uploadUserAvatar(id, file) {
  if (!id) throw new AppError('Missing id', 400);
  if (!file) throw new AppError('Missing avatar file', 400);

  const uploadService = createUploadService();
  const uploaded = await uploadService.uploadImage(file, {
    folder: 'food-travel/users/avatars',
    publicId: `user-${id}-avatar`,
  });

  const updated = await updateUserAvatarInRepository(id, uploaded.url);
  if (!updated) throw new AppError('User not found', 404);
  return updated;
}

async function buildUsersWorkbook(options = {}) {
  const users = await listUsers(options);
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Users');
  worksheet.columns = [
    { header: 'Ho ten', key: 'fullName', width: 28 },
    { header: 'Email', key: 'email', width: 30 },
    { header: 'Phone', key: 'phone', width: 18 },
    { header: 'Vai tro', key: 'role', width: 14 },
    { header: 'Ngay tao', key: 'createdAt', width: 24 },
  ];

  users.forEach((user) => {
    worksheet.addRow({
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      createdAt: user.createdAt?._seconds
        ? new Date(user.createdAt._seconds * 1000).toLocaleString('vi-VN')
        : '',
    });
  });

  return workbook;
}

module.exports = {
  listUsers,
  getUserDetail,
  createUser,
  updateUser,
  deleteUser,
  deleteUsers,
  uploadUserAvatar,
  buildUsersWorkbook,
};
