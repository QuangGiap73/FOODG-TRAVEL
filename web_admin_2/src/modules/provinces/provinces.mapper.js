function toRegionViewModel(doc) {
  return {
    id: doc.id,
    code: doc.code || doc.id,
    name: doc.name || '',
    macro_region: doc.macro_region || '',
    number: doc.number ?? null,
  };
}

function toProvinceViewModel(doc) {
  return {
    id: doc.id,
    code: doc.code || doc.id,
    name: doc.name || '',
    regionsCode: doc.regionsCode || '',
    description: doc.description || '',
    imageUrl: doc.imageUrl || '',
    imageUrls: Array.isArray(doc.imageUrls) ? doc.imageUrls : [],
    slug: doc.slug || '',
    centerLat: Number(doc.centerLat) || 0,
    centerLng: Number(doc.centerLng) || 0,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
    dishesCount: Number(doc.dishesCount) || 0,
    checkinsCount: Number(doc.checkinsCount) || 0,
  };
}

module.exports = {
  toRegionViewModel,
  toProvinceViewModel,
};
