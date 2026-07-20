const { asyncHandler } = require('../../core/errors/async-handler');
const {
  getDishListPage,
  getDishDetail,
  getDishCreateDefaults,
  getDishEditData,
  exportDishesWorkbook,
  createDish,
  updateDish,
  uploadDishImage,
  deleteDish,
} = require('./dishes.service');
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
    dishTypeCodes: values.dishTypeCodes || '',
    mealTimeTags: values.mealTimeTags || '',
    ingredientsListNormalized: values.ingredientsListNormalized || '',
    suitableForSeason: values.suitableForSeason || '',
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
  const provinces = CANONICAL_PROVINCES_34;
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
// helper render trang edit 
async function renderEditPage(res, options = {}) {
  const defaults = options.formValues || {};
  const {
    CANONICAL_PROVINCES_34,
    LEGACY_PROVINCES_63,
  } = require('./dishes.constants');

  res.status(options.statusCode || 200).render('pages/dishes/edits', {
    pageTitle: 'Chinh sua mon an',
    provinces: CANONICAL_PROVINCES_34,
    legacyProvinces: LEGACY_PROVINCES_63,
    successMessage: options.successMessage || '',
    errorMessage: options.errorMessage || '',
    formValues: defaults,
    dishId: options.dishId || '',
  });
}
// get trang edit
async function getDishEditPage(req, res) {
  const formValues = await getDishEditData(req.params.id);

  await renderEditPage(res, {
    dishId: req.params.id,
    formValues,
    successMessage: req.query.updated ? 'Da cap nhat mon an thanh cong.' : '',
  });
}
// post update
async function updateDishPage(req, res) {
  try {
    await updateDish(req.params.id, req.body);

    return res.redirect(`/admin/dishes/${encodeURIComponent(req.params.id)}/edit?updated=1`);
  } catch (error) {
    await renderEditPage(res, {
      statusCode: error.statusCode || 400,
      dishId: req.params.id,
      errorMessage: error.message || 'Khong the cap nhat mon an',
      formValues: {
        ...req.body,
        id: req.params.id,
      },
    });
  }
}
module.exports = {
  getDishesPage: asyncHandler(getDishesPage),
  getDishDetailPage: asyncHandler(getDishDetailPage),
  getDishCreatePage: asyncHandler(getDishCreatePage),
  createDishPage: asyncHandler(createDishPage),
  getDishEditPage: asyncHandler(getDishEditPage),
  updateDishPage: asyncHandler(updateDishPage),
  getDishesApi,
  exportDishesApi,
  uploadDishImageApi,
  deleteDishApi,
};
