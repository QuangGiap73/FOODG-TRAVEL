const ExcelJS = require('exceljs');
const { AppError } = require('../../core/errors/app-error');
const { createUploadService } = require('../uploads/upload.service');
const {
  listAllDishesWithSearchFromRepository,
  listAllDishesFromRepository,
  getDishByIdFromRepository,
  getNextDishSttFromRepository,
  createDishInRepository,
  deleteDishFromRepository,
} = require('./dishes.repository');
const { toDishViewModel } = require('./dishes.mapper');
const { validateDishListQuery, validateDishCreatePayload } = require('./dishes.validator');

function normalizeText(value = '') {
  return String(value || '').trim();
}

function slugify(value = '') {
  return normalizeText(value)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\u0111/g, 'd')
    .replace(/\u0110/g, 'd')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function buildSearchKeywords(values = []) {
  const tokenSet = new Set();

  values.forEach((value) => {
    const normalized = slugify(value).replace(/-/g, ' ').trim();
    if (!normalized) return;

    normalized.split(/\s+/).forEach((token) => {
      if (token) tokenSet.add(token);
    });

    tokenSet.add(normalized.replace(/\s+/g, '-'));
    tokenSet.add(normalized.replace(/\s+/g, ''));
  });

  return Array.from(tokenSet);
}

function buildDishDocument(payload) {
  const imageList = [payload.imageUrl, ...payload.imageUrls].filter(Boolean);

  return {
    id: payload.id,
    slug: payload.slug,
    STT: payload.stt,
    Name: {
      vi: payload.nameVi,
      en: payload.nameEn,
    },
    category: {
      vi: payload.categoryVi,
      en: payload.categoryEn,
    },
    Tags: {
      vi: payload.tagsVi,
      en: payload.tagsEn,
    },
    Best_time: {
      vi: payload.bestTimeVi,
      en: payload.bestTimeEn,
    },
    Best_season: {
      vi: payload.bestSeasonVi,
      en: payload.bestSeasonEn,
    },
    description: {
      vi: payload.descriptionVi,
      en: payload.descriptionEn,
    },
    ingredients: {
      vi: payload.ingredientsVi,
      en: payload.ingredientsEn,
    },
    instructions: {
      vi: payload.instructionsVi,
      en: payload.instructionsEn,
    },
    origin_story: {
      vi: payload.originStoryVi,
      en: payload.originStoryEn,
    },
    price_range: {
      vi: payload.priceRangeVi,
      en: payload.priceRangeEn,
    },
    provinceCode34: payload.provinceCode34,
    provinceName34: payload.provinceName34,
    legacyProvinceCode: payload.legacyProvinceCode || payload.provinceName34,
    province_code: payload.provinceCode || payload.legacyProvinceCode || payload.provinceName34,
    region_code: payload.regionCode,
    Img: payload.imageUrl || imageList[0] || '',
    Images: imageList,
    spicy_level: payload.spicyLevel,
    satiety_level: payload.satietyLevel,
    nameSort: slugify(payload.nameVi || payload.nameEn),
    searchKeywords: buildSearchKeywords([
      payload.id,
      payload.slug,
      payload.nameVi,
      payload.nameEn,
      payload.provinceName34,
      payload.provinceCode34,
      payload.tagsVi,
      payload.tagsEn,
    ]),
  };
}

async function getDishListPage(payload = {}) {
  const query = validateDishListQuery(payload);
  const hasSearch = Boolean(query.search);

  if (hasSearch) {
    const dishes = await listAllDishesWithSearchFromRepository({
      search: query.search,
      provinceCode34: query.provinceCode34,
      spicyLevel: query.spicyLevel,
      sortBy: query.sortBy,
    });

    const total = dishes.length;
    const start = (query.page - 1) * query.pageSize;
    const pageItems = dishes.slice(start, start + query.pageSize);

    return {
      items: pageItems.map(toDishViewModel),
      meta: {
        page: query.page,
        pageSize: query.pageSize,
        total,
        totalPages: Math.max(1, Math.ceil(total / query.pageSize)),
        hasNextPage: start + query.pageSize < total,
        hasPrevPage: query.page > 1,
        search: query.search,
        provinceCode34: query.provinceCode34,
        spicyLevel: query.spicyLevel,
        sortBy: query.sortBy,
      },
    };
  }

  const dishes = await listAllDishesFromRepository(query);
  const total = dishes.length;
  const start = (query.page - 1) * query.pageSize;
  const pageItems = dishes.slice(start, start + query.pageSize);

  return {
    items: pageItems.map(toDishViewModel),
    meta: {
      page: query.page,
      pageSize: query.pageSize,
      total,
      totalPages: Math.max(1, Math.ceil(total / query.pageSize)),
      hasNextPage: start + query.pageSize < total,
      hasPrevPage: query.page > 1,
      search: query.search,
      provinceCode34: query.provinceCode34,
      spicyLevel: query.spicyLevel,
      sortBy: query.sortBy,
    },
  };
}

async function getDishCreateDefaults() {
  return {
    stt: await getNextDishSttFromRepository(),
    spicyLevel: 0,
    satietyLevel: 0,
  };
}

async function exportDishesWorkbook(filters = {}) {
  const query = validateDishListQuery({
    ...filters,
    page: 1,
    pageSize: 1000,
  });

  const dishes = (await listAllDishesWithSearchFromRepository(query)).map(toDishViewModel);

  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Mon an');

  worksheet.columns = [
    { header: 'STT', key: 'stt', width: 8 },
    { header: 'Ten mon VI', key: 'nameVi', width: 30 },
    { header: 'Ten mon EN', key: 'nameEn', width: 30 },
    { header: 'Tinh / Thanh', key: 'provinceName34', width: 20 },
    { header: 'Danh muc', key: 'categoryVi', width: 24 },
    { header: 'Do cay', key: 'spicyLevel', width: 10 },
    { header: 'Do no', key: 'satietyLevel', width: 10 },
    { header: 'Gia tham khao', key: 'priceRangeVi', width: 20 },
    { header: 'Slug', key: 'slug', width: 25 },
  ];

  dishes.forEach((dish) => {
    worksheet.addRow({
      stt: dish.stt,
      nameVi: dish.nameVi,
      nameEn: dish.nameEn,
      provinceName34: dish.provinceName34,
      categoryVi: dish.categoryVi,
      spicyLevel: dish.spicyLevel,
      satietyLevel: dish.satietyLevel,
      priceRangeVi: dish.priceRangeVi,
      slug: dish.slug,
    });
  });

  return workbook;
}

async function createDish(payload) {
  const data = validateDishCreatePayload(payload);

  if (!data.id) throw new AppError('ID la truong bat buoc', 400);
  if (!data.slug) throw new AppError('Slug la truong bat buoc', 400);
  if (!data.nameVi) throw new AppError('Ten mon tieng Viet la truong bat buoc', 400);
  if (!data.nameEn) throw new AppError('Ten mon tieng Anh la truong bat buoc', 400);
  if (!data.provinceCode34 || !data.provinceName34) {
    throw new AppError('Vui long chon tinh/thanh hien tai', 400);
  }

  if (!/^[a-z0-9_]+$/.test(data.id)) {
    throw new AppError('ID chi duoc gom chu thuong, so va dau gach duoi', 400);
  }

  if (!/^[a-z0-9-]+$/.test(data.slug)) {
    throw new AppError('Slug chi duoc gom chu thuong, so va dau gach ngang', 400);
  }

  if (data.spicyLevel < 0 || data.spicyLevel > 5) {
    throw new AppError('Do cay phai nam trong khoang 0 den 5', 400);
  }

  if (data.satietyLevel < 0 || data.satietyLevel > 5) {
    throw new AppError('Do no phai nam trong khoang 0 den 5', 400);
  }

  const existing = await getDishByIdFromRepository(data.id);
  if (existing) {
    throw new AppError('ID mon an da ton tai', 400);
  }

  const document = buildDishDocument(data);
  await createDishInRepository(data.id, document);

  return {
    id: data.id,
    slug: data.slug,
  };
}

async function uploadDishImage(file) {
  if (!file?.buffer) {
    throw new AppError('Chua chon anh de tai len', 400);
  }

  const uploadService = createUploadService();
  return uploadService.uploadImage(file, {
    folder: process.env.CLOUDINARY_FOLDER || 'food-travel/dishes',
  });
}

async function deleteDish(id) {
  if (!id) {
    throw new AppError('Thieu ma mon', 400);
  }

  await deleteDishFromRepository(id);
  return { id };
}

module.exports = {
  getDishListPage,
  getDishCreateDefaults,
  exportDishesWorkbook,
  createDish,
  uploadDishImage,
  deleteDish,
  slugify,
};
