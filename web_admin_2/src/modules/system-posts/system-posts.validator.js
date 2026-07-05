const ALLOWED_STATUS = ['draft', 'published', 'hidden'];

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

function normalizeTags(value = '') {
  return normalizeText(value)
    .split(',')
    .map((item) => normalizeText(item))
    .filter(Boolean);
}

function validateSystemPostPayload(payload = {}) {
  const titleVi = normalizeText(payload.titleVi || payload.title);
  const titleEn = normalizeText(payload.titleEn);

  return {
    titleVi,
    titleEn,
    slug: slugify(payload.slug || titleVi || titleEn),
    summaryVi: normalizeText(payload.summaryVi || payload.summary),
    summaryEn: normalizeText(payload.summaryEn),
    contentVi: normalizeText(payload.contentVi || payload.content),
    contentEn: normalizeText(payload.contentEn),
    coverImage: normalizeText(payload.coverImage),
    categoryVi: normalizeText(payload.categoryVi || payload.category),
    categoryEn: normalizeText(payload.categoryEn),
    provinceCode34: normalizeText(payload.provinceCode34),
    provinceName34: normalizeText(payload.provinceName34),
    regionCode: normalizeText(payload.regionCode),
    seoTitle: normalizeText(payload.seoTitle),
    seoDescription: normalizeText(payload.seoDescription),
    status: ALLOWED_STATUS.includes(payload.status) ? payload.status : 'draft',
    featured: payload.featured === 'true' || payload.featured === true || payload.featured === 'on',
    pinned: payload.pinned === 'true' || payload.pinned === true || payload.pinned === 'on',
    tags: normalizeTags(payload.tags),
  };
}

function validateSystemPostListQuery(query = {}) {
  return {
    page: Math.max(1, Number(query.page || 1)),
    pageSize: Math.min(50, Math.max(1, Number(query.pageSize || 12))),
    search: normalizeText(query.search),
    status: ALLOWED_STATUS.includes(query.status) ? query.status : '',
  };
}

module.exports = {
  ALLOWED_STATUS,
  validateSystemPostPayload,
  validateSystemPostListQuery,
  slugify,
};
