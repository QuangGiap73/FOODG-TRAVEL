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

module.exports = { toDishViewModel };
