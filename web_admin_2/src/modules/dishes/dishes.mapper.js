function toDishViewModel(dish) {
  const name = dish.Name || dish.name || {};
  const region = dish.region_code || dish.regionCode || '';
  const provinceCode34 = dish.provinceCode34 || '';
  const priceRange = dish.price_range || {};
  const updatedAt = dish.updatedAt || dish.updated_at || null;

  return {
    id: dish.id || '',
    stt: Number(dish.STT || dish.stt || 0),
    slug: dish.slug || '',
    nameVi: typeof name === 'object' ? String(name.vi || '').trim() : String(name || '').trim(),
    nameEn: typeof name === 'object' ? String(name.en || '').trim() : '',
    provinceCode34,
    provinceName34: dish.provinceName34 || '',
    regionCode: region,
    categoryVi:
      typeof dish.category === 'object' ? String(dish.category.vi || '').trim() : String(dish.category || '').trim(),
    priceRangeVi:
      typeof priceRange === 'object' ? String(priceRange.vi || '').trim() : String(priceRange || '').trim(),
    imageUrl: dish.Img || dish.img || dish.imageUrl || (Array.isArray(dish.Images) ? dish.Images[0] : '') || '',
    spicyLevel: Number(dish.spicy_level || 0),
    satietyLevel: Number(dish.satiety_level || 0),
    updatedAtLabel: updatedAt ? new Date(updatedAt).toLocaleString('vi-VN') : '-',
  };
}

function normalizeLocalizedValue(value) {
  if (!value) return '';

  if (typeof value === 'object') {
    return String(value.vi || value.en || value.name || '').trim();
  }

  return String(value).trim();
}

function formatTimestamp(value) {
  if (!value) return '-';

  if (typeof value.toDate === 'function') {
    return value.toDate().toLocaleString('vi-VN');
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('vi-VN');
}

function toDishDetailViewModel(dish) {
  const name = dish.Name || dish.name || {};
  const description = dish.description || {};
  const ingredients = dish.ingredients || {};
  const instructions = dish.instructions || {};
  const originStory = dish.origin_story || {};
  const tags = dish.Tags || {};
  const category = dish.category || {};
  const bestTime = dish.Best_time || {};
  const bestSeason = dish.Best_season || {};
  const priceRange = dish.price_range || {};
  const images = Array.isArray(dish.Images) ? dish.Images.filter(Boolean) : [];
  const imageUrl = dish.Img || dish.img || dish.imageUrl || images[0] || '';

  const tagsVi = typeof tags === 'object' ? String(tags.vi || '').trim() : String(tags || '').trim();
  const ingredientTokens = typeof ingredients === 'object'
    ? String(ingredients.vi || '').split(',').map((item) => item.trim()).filter(Boolean)
    : [];
  const instructionSteps = typeof instructions === 'object'
    ? String(instructions.vi || '').split('.').map((item) => item.trim()).filter(Boolean)
    : [];

  return {
    id: dish.id || '',
    slug: dish.slug || '',
    stt: Number(dish.STT || dish.stt || 0),
    nameVi: typeof name === 'object' ? String(name.vi || '').trim() : String(name || '').trim(),
    nameEn: typeof name === 'object' ? String(name.en || '').trim() : '',
    descriptionVi: typeof description === 'object' ? String(description.vi || '').trim() : String(description || '').trim(),
    descriptionEn: typeof description === 'object' ? String(description.en || '').trim() : '',
    provinceCode34: String(dish.provinceCode34 || '').trim(),
    provinceName34: String(dish.provinceName34 || '').trim(),
    legacyProvinceCode: String(dish.legacyProvinceCode || '').trim(),
    provinceCode: String(dish.province_code || '').trim(),
    regionCode: normalizeLocalizedValue(dish.region_code || dish.regionCode),
    categoryVi: typeof category === 'object' ? String(category.vi || '').trim() : String(category || '').trim(),
    categoryEn: typeof category === 'object' ? String(category.en || '').trim() : '',
    tagsVi,
    tagsEn: typeof tags === 'object' ? String(tags.en || '').trim() : '',
    tagList: tagsVi.split(',').map((item) => item.trim()).filter(Boolean),
    ingredientList: ingredientTokens,
    ingredientsVi: typeof ingredients === 'object' ? String(ingredients.vi || '').trim() : '',
    ingredientsEn: typeof ingredients === 'object' ? String(ingredients.en || '').trim() : '',
    instructionSteps: instructionSteps.length ? instructionSteps : [String(instructions.vi || '').trim()].filter(Boolean),
    instructionsVi: typeof instructions === 'object' ? String(instructions.vi || '').trim() : '',
    instructionsEn: typeof instructions === 'object' ? String(instructions.en || '').trim() : '',
    originStoryVi: typeof originStory === 'object' ? String(originStory.vi || '').trim() : '',
    originStoryEn: typeof originStory === 'object' ? String(originStory.en || '').trim() : '',
    bestTimeVi: typeof bestTime === 'object' ? String(bestTime.vi || '').trim() : String(bestTime || '').trim(),
    bestTimeEn: typeof bestTime === 'object' ? String(bestTime.en || '').trim() : '',
    bestSeasonVi: typeof bestSeason === 'object' ? String(bestSeason.vi || '').trim() : String(bestSeason || '').trim(),
    bestSeasonEn: typeof bestSeason === 'object' ? String(bestSeason.en || '').trim() : '',
    priceRangeVi: typeof priceRange === 'object' ? String(priceRange.vi || '').trim() : String(priceRange || '').trim(),
    priceRangeEn: typeof priceRange === 'object' ? String(priceRange.en || '').trim() : '',
    imageUrl,
    images,
    spicyLevel: Number(dish.spicy_level || 0),
    satietyLevel: Number(dish.satiety_level || 0),
    updatedAtLabel: formatTimestamp(dish.updatedAt || dish.updated_at),
    createdAtLabel: formatTimestamp(dish.createdAt || dish.created_at),
  };
}

module.exports = { toDishViewModel, toDishDetailViewModel };
