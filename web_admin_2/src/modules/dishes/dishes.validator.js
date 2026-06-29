function validateDishListQuery(query = {}) {
  return {
    page: Math.max(1, Number(query.page) || 1),
    pageSize: Math.max(1, Math.min(100, Number(query.pageSize) || 50)),
    search: String(query.search || '').trim(),
    provinceCode34: String(query.provinceCode34 || '').trim(),
    spicyLevel: query.spicyLevel === '' || query.spicyLevel === undefined ? '' : Number(query.spicyLevel),
    sortBy: String(query.sortBy || 'stt_asc').trim(),
  };
}

function cleanText(value = '') {
  return String(value || '').trim();
}

function cleanNumber(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function cleanMultilineList(value = '') {
  return String(value || '')
    .split(/\r?\n/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function validateDishCreatePayload(payload = {}) {
  return {
    id: cleanText(payload.id),
    slug: cleanText(payload.slug),
    stt: cleanNumber(payload.stt, 0),
    nameVi: cleanText(payload.nameVi),
    nameEn: cleanText(payload.nameEn),
    provinceCode34: cleanText(payload.provinceCode34),
    provinceName34: cleanText(payload.provinceName34),
    legacyProvinceCode: cleanText(payload.legacyProvinceCode),
    provinceCode: cleanText(payload.provinceCode),
    regionCode: cleanText(payload.regionCode),
    categoryVi: cleanText(payload.categoryVi),
    categoryEn: cleanText(payload.categoryEn),
    tagsVi: cleanText(payload.tagsVi),
    tagsEn: cleanText(payload.tagsEn),
    bestTimeVi: cleanText(payload.bestTimeVi),
    bestTimeEn: cleanText(payload.bestTimeEn),
    bestSeasonVi: cleanText(payload.bestSeasonVi),
    bestSeasonEn: cleanText(payload.bestSeasonEn),
    descriptionVi: cleanText(payload.descriptionVi),
    descriptionEn: cleanText(payload.descriptionEn),
    ingredientsVi: cleanText(payload.ingredientsVi),
    ingredientsEn: cleanText(payload.ingredientsEn),
    instructionsVi: cleanText(payload.instructionsVi),
    instructionsEn: cleanText(payload.instructionsEn),
    originStoryVi: cleanText(payload.originStoryVi),
    originStoryEn: cleanText(payload.originStoryEn),
    priceRangeVi: cleanText(payload.priceRangeVi),
    priceRangeEn: cleanText(payload.priceRangeEn),
    imageUrl: cleanText(payload.imageUrl),
    imageUrls: cleanMultilineList(payload.imageUrls),
    spicyLevel: cleanNumber(payload.spicyLevel, 0),
    satietyLevel: cleanNumber(payload.satietyLevel, 0),
  };
}

module.exports = {
  validateDishListQuery,
  validateDishCreatePayload,
};
