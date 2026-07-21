function normalizeImageUrls(imageUrlsInput, imageUrlInput) {
  const result = [];
  const seen = new Set();

  function pushUrl(value) {
    if (!value && value !== 0) return;
    const text = String(value).trim();
    if (!text || seen.has(text)) return;
    seen.add(text);
    result.push(text);
  }

  if (imageUrlInput) pushUrl(imageUrlInput);

  if (Array.isArray(imageUrlsInput)) {
    imageUrlsInput.forEach((item) => pushUrl(item));
  } else if (typeof imageUrlsInput === 'string') {
    imageUrlsInput.split(/\r?\n/).forEach((item) => pushUrl(item));
  }

  return result;
}

function validateRegionPayload(payload = {}) {
  return {
    code: String(payload.code || '').trim(),
    name: String(payload.name || '').trim(),
    macro_region: String(payload.macro_region || '').trim(),
    number: payload.number,
  };
}

function validateProvincePayload(payload = {}) {
  const imageUrl = String(payload.imageUrl || '').trim();
  const imageUrls = normalizeImageUrls(payload.imageUrls, imageUrl);
  const places = Array.isArray(payload.places)
    ? payload.places
        .map((place) => ({
          nameVi: String(place?.nameVi || '').trim(),
          nameEn: String(place?.nameEn || '').trim(),
          imageUrl: String(place?.imageUrl || '').trim(),
          slug: String(place?.slug || '').trim(),
        }))
        .filter((place) => place.nameVi || place.nameEn || place.imageUrl || place.slug)
    : [];

  return {
    code: String(payload.code || '').trim(),
    name: String(payload.name || '').trim(),
    regionsCode: String(payload.regionsCode || '').trim(),
    descriptionEn: String(payload.descriptionEn || '').trim(),
    population: String(payload.population || '').trim(),
    areaKm2: String(payload.areaKm2 || '').trim(),
    establishedDate: String(payload.establishedDate || '').trim(),
    vehiclePlateCode: String(payload.vehiclePlateCode || '').trim(),
    provinceCodeLabel: String(payload.provinceCodeLabel || payload.code || '').trim(),
    description: String(payload.description || '').trim(),
    slug: String(payload.slug || '').trim(),
    centerLat: Number(payload.centerLat) || 0,
    centerLng: Number(payload.centerLng) || 0,
    imageUrl: imageUrls[0] || '',
    imageUrls,
    places,
  };
}

module.exports = {
  normalizeImageUrls,
  validateRegionPayload,
  validateProvincePayload,
};
