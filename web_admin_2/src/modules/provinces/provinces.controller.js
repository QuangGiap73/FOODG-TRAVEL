const { ok } = require('../../core/http/response');
const { asyncHandler } = require('../../core/errors/async-handler');
const {
  listRegions,
  listProvinces,
  createRegion,
  removeRegion,
  createProvince,
  updateProvince,
  removeProvince,
  uploadProvinceImage,
} = require('./provinces.service');

async function getProvincesPage(_req, res) {
  const [regions, provinces] = await Promise.all([
    listRegions(),
    listProvinces(),
  ]);

  res.render('pages/provinces/index', {
    pageTitle: 'Tinh thanh',
    initialRegions: regions,
    initialProvinces: provinces,
  });
}

const getRegionsApi = asyncHandler(async (_req, res) => {
  return ok(res, await listRegions());
});

const getProvincesApi = asyncHandler(async (req, res) => {
  return ok(res, await listProvinces(req.query.regionCode || ''));
});

const createRegionApi = asyncHandler(async (req, res) => {
  return ok(res, await createRegion(req.body), 'Created', 201);
});

const deleteRegionApi = asyncHandler(async (req, res) => {
  return ok(res, await removeRegion(req.params.code), 'Deleted');
});

const createProvinceApi = asyncHandler(async (req, res) => {
  return ok(res, await createProvince(req.body), 'Created', 201);
});

const updateProvinceApi = asyncHandler(async (req, res) => {
  return ok(res, await updateProvince(req.params.code, req.body), 'Updated');
});

const deleteProvinceApi = asyncHandler(async (req, res) => {
  return ok(res, await removeProvince(req.params.code), 'Deleted');
});

const uploadProvinceImageApi = asyncHandler(async (req, res) => {
  return ok(res, await uploadProvinceImage(req.file), 'Image uploaded');
});

module.exports = {
  getProvincesPage: asyncHandler(getProvincesPage),
  getRegionsApi,
  getProvincesApi,
  createRegionApi,
  deleteRegionApi,
  createProvinceApi,
  updateProvinceApi,
  deleteProvinceApi,
  uploadProvinceImageApi,
};
