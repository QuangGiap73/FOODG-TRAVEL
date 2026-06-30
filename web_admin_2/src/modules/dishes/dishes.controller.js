const { asyncHandler } = require('../../core/errors/async-handler');
const {
  getDishListPage,
  getDishDetail,
  getDishCreateDefaults,
  exportDishesWorkbook,
  createDish,
  uploadDishImage,
  deleteDish,
} = require('./dishes.service');
const { listProvinces } = require('../provinces/provinces.service');
const {
  CANONICAL_PROVINCES_34,
  LEGACY_PROVINCES_63,
} = require('./dishes.constants');

function buildCreateFormValues(values = {}, defaults = {}) {
  return {
    id: values.id || '',
    slug: values.slug || '',
    stt: values.stt || defaults.stt || 1,
    nameVi: values.nameVi || '',
    nameEn: values.nameEn || '',
    provinceCode34: values.provinceCode34 || '',
    provinceName34: values.provinceName34 || '',
    legacyProvinceCode: values.legacyProvinceCode || '',
    provinceCode: values.provinceCode || '',
    regionCode: values.regionCode || '',
    categoryVi: values.categoryVi || '',
    categoryEn: values.categoryEn || '',
    tagsVi: values.tagsVi || '',
    tagsEn: values.tagsEn || '',
    bestTimeVi: values.bestTimeVi || '',
    bestTimeEn: values.bestTimeEn || '',
    bestSeasonVi: values.bestSeasonVi || '',
    bestSeasonEn: values.bestSeasonEn || '',
    descriptionVi: values.descriptionVi || '',
    descriptionEn: values.descriptionEn || '',
    ingredientsVi: values.ingredientsVi || '',
    ingredientsEn: values.ingredientsEn || '',
    instructionsVi: values.instructionsVi || '',
    instructionsEn: values.instructionsEn || '',
    originStoryVi: values.originStoryVi || '',
    originStoryEn: values.originStoryEn || '',
    priceRangeVi: values.priceRangeVi || '',
    priceRangeEn: values.priceRangeEn || '',
    imageUrl: values.imageUrl || '',
    imageUrls: values.imageUrls || '',
    spicyLevel: values.spicyLevel ?? defaults.spicyLevel ?? 0,
    satietyLevel: values.satietyLevel ?? defaults.satietyLevel ?? 0,
  };
}

async function renderCreatePage(res, options = {}) {
  const provinces = options.provinces || CANONICAL_PROVINCES_34;
  const defaults = options.defaults || (await getDishCreateDefaults());

  res.status(options.statusCode || 200).render('pages/dishes/create', {
    pageTitle: 'Them mon an',
    provinces,
    legacyProvinces: LEGACY_PROVINCES_63,
    defaults,
    successMessage: options.successMessage || '',
    errorMessage: options.errorMessage || '',
    formValues: buildCreateFormValues(options.formValues, defaults),
  });
}

async function getDishesPage(req, res) {
  const provinces = await listProvinces();
  const pageData = await getDishListPage({
    page: req.query.page,
    pageSize: req.query.pageSize,
    search: req.query.search,
    provinceCode34: req.query.provinceCode34,
    spicyLevel: req.query.spicyLevel,
    sortBy: req.query.sortBy,
  });

  res.render('pages/dishes/index', {
    pageTitle: 'Mon an',
    dishes: pageData.items,
    pagination: pageData.meta,
    formData: { provinces },
  });
}

async function getDishCreatePage(req, res) {
  await renderCreatePage(res, {
    successMessage: req.query.created ? 'Da tao mon an thanh cong.' : '',
  });
}

async function getDishDetailPage(req, res) {
  const dish = await getDishDetail(req.params.id);

  res.render('pages/dishes/detail', {
    pageTitle: dish.nameVi || 'Chi tiet mon an',
    dish,
  });
}

async function createDishPage(req, res) {
  try {
    const created = await createDish(req.body);
    return res.redirect(`/admin/dishes/add?created=1&id=${encodeURIComponent(created.id)}`);
  } catch (error) {
    return renderCreatePage(res, {
      statusCode: error.statusCode || 400,
      errorMessage: error.message || 'Khong the tao mon an',
      formValues: req.body,
    });
  }
}

const getDishesApi = asyncHandler(async (req, res) => {
  const pageData = await getDishListPage({
    page: req.query.page,
    pageSize: req.query.pageSize,
    search: req.query.search,
    provinceCode34: req.query.provinceCode34,
    spicyLevel: req.query.spicyLevel,
    sortBy: req.query.sortBy,
  });

  return res.json({
    success: true,
    message: 'OK',
    data: pageData,
  });
});

const exportDishesApi = asyncHandler(async (req, res) => {
  const workbook = await exportDishesWorkbook({
    search: req.query.search,
    provinceCode34: req.query.provinceCode34,
    spicyLevel: req.query.spicyLevel,
    sortBy: req.query.sortBy,
  });

  res.setHeader(
    'Content-Type',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  res.setHeader('Content-Disposition', 'attachment; filename=dishes.xlsx');
  await workbook.xlsx.write(res);
  res.end();
});

const deleteDishApi = asyncHandler(async (req, res) => {
  await deleteDish(req.params.id);
  return res.json({
    success: true,
    message: 'Deleted',
  });
});

const uploadDishImageApi = asyncHandler(async (req, res) => {
  const uploaded = await uploadDishImage(req.file);
  return res.json({
    success: true,
    message: 'Uploaded',
    data: uploaded,
  });
});

module.exports = {
  getDishesPage: asyncHandler(getDishesPage),
  getDishDetailPage: asyncHandler(getDishDetailPage),
  getDishCreatePage: asyncHandler(getDishCreatePage),
  createDishPage: asyncHandler(createDishPage),
  getDishesApi,
  exportDishesApi,
  uploadDishImageApi,
  deleteDishApi,
};
