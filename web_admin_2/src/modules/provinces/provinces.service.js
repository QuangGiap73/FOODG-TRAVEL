const { AppError } = require('../../core/errors/app-error');
const { createUploadService } = require('../uploads/upload.service');
const {
  listRegionsFromRepository,
  listProvincesFromRepository,
  getRegionByCodeFromRepository,
  getProvinceByCodeFromRepository,
  createRegionInRepository,
  deleteRegionInRepository,
  createProvinceInRepository,
  updateProvinceInRepository,
  deleteProvinceInRepository,
  hasProvinceInRegionFromRepository,
  buildProvinceStatsMapFromRepository,
  normalizeProvinceKey,
} = require('./provinces.repository');
const {
  validateRegionPayload,
  validateProvincePayload,
} = require('./provinces.validator');
const {
  toRegionViewModel,
  toProvinceViewModel,
} = require('./provinces.mapper');

async function listRegions() {
  const items = await listRegionsFromRepository();
  return items.map(toRegionViewModel);
}

async function listProvinces(regionCode) {
  const [items, statsMap] = await Promise.all([
    listProvincesFromRepository(regionCode),
    buildProvinceStatsMapFromRepository(),
  ]);

  return items.map((item) => {
    const normalizedCode = normalizeProvinceKey(item.code || item.id);
    const normalizedName = normalizeProvinceKey(item.name);
    const stats =
      statsMap.get(normalizedCode) ||
      statsMap.get(normalizedName) ||
      { dishesCount: 0, checkinsCount: 0 };

    return toProvinceViewModel({
      ...item,
      dishesCount: stats.dishesCount,
      checkinsCount: stats.checkinsCount,
    });
  });
}

async function createRegion(payload) {
  const data = validateRegionPayload(payload);

  if (!data.code || !data.name) {
    throw new AppError('Vui long nhap ma va ten mien', 400);
  }

  const allowedMacro = ['bac', 'trung', 'nam'];
  const macroRaw = data.macro_region.toLowerCase();
  if (!allowedMacro.includes(macroRaw)) {
    throw new AppError('macro_region phai la mot trong: bac, trung, nam', 400);
  }

  const existing = await getRegionByCodeFromRepository(data.code);
  if (existing) {
    throw new AppError('Ma mien da ton tai', 400);
  }

  const macroRegion =
    macroRaw === 'bac' ? 'Bac' : macroRaw === 'trung' ? 'Trung' : 'Nam';
  const number = Number.isFinite(Number(data.number)) ? Number(data.number) : null;

  await createRegionInRepository({
    code: data.code,
    name: data.name,
    macro_region: macroRegion,
    number,
  });

  return {
    code: data.code,
    name: data.name,
    macro_region: macroRegion,
    number,
  };
}

async function removeRegion(code) {
  if (!code) throw new AppError('Thieu ma mien', 400);

  const hasProvince = await hasProvinceInRegionFromRepository(code);
  if (hasProvince) {
    throw new AppError('Khong the xoa: con tinh thanh thuoc mien nay', 400);
  }

  await deleteRegionInRepository(code);
  return { code };
}

async function createProvince(payload) {
  const data = validateProvincePayload(payload);

  if (!data.code || !data.name || !data.regionsCode) {
    throw new AppError('Ma tinh, ten tinh va ma mien la bat buoc', 400);
  }

  const region = await getRegionByCodeFromRepository(data.regionsCode);
  if (!region) {
    throw new AppError('Ma mien khong ton tai', 400);
  }

  const existing = await getProvinceByCodeFromRepository(data.code);
  if (existing) {
    throw new AppError('Ma tinh da ton tai', 400);
  }

  await createProvinceInRepository(data);

  return {
    code: data.code,
    name: data.name,
    regionsCode: data.regionsCode,
  };
}

async function updateProvince(code, payload) {
  const data = validateProvincePayload({ ...payload, code });

  if (!data.code || !data.name || !data.regionsCode) {
    throw new AppError('Ma tinh, ten tinh va ma mien la bat buoc', 400);
  }

  const existing = await getProvinceByCodeFromRepository(data.code);
  if (!existing) {
    throw new AppError('Tinh thanh khong ton tai', 404);
  }

  const region = await getRegionByCodeFromRepository(data.regionsCode);
  if (!region) {
    throw new AppError('Ma mien khong ton tai', 400);
  }

  await updateProvinceInRepository(data.code, data);

  return {
    code: data.code,
    name: data.name,
    regionsCode: data.regionsCode,
  };
}

async function removeProvince(code) {
  if (!code) throw new AppError('Thieu ma tinh', 400);

  const existing = await getProvinceByCodeFromRepository(code);
  if (!existing) {
    throw new AppError('Tinh thanh khong ton tai', 404);
  }

  await deleteProvinceInRepository(code);
  return { code };
}

async function uploadProvinceImage(file) {
  if (!file?.buffer) {
    throw new AppError('Chưa chọn file ảnh', 400);
  }

  const uploadService = createUploadService();
  return uploadService.uploadImage(file, {
    folder: process.env.CLOUDINARY_FOLDER || 'food-travel/provinces',
  });
}

module.exports = {
  listRegions,
  listProvinces,
  createRegion,
  removeRegion,
  createProvince,
  updateProvince,
  removeProvince,
  uploadProvinceImage,
};
