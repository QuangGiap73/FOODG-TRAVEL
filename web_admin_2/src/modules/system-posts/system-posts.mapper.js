function formatDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function normalizeTags(value) {
  if (Array.isArray(value)) return value.filter(Boolean);
  if (typeof value === 'string') {
    return value.split(',').map((item) => String(item || '').trim()).filter(Boolean);
  }
  return [];
}

function toSystemPostViewModel(doc) {
  const data = doc.data ? doc.data() : doc;
  const tags = normalizeTags(data.tags);

  return {
    id: doc.id || data.id || '',
    titleVi: data.title?.vi || data.titleVi || '',
    titleEn: data.title?.en || data.titleEn || '',
    title: data.title?.vi || data.titleVi || data.title?.en || data.titleEn || '',
    slug: data.slug || '',
    summaryVi: data.summary?.vi || data.summaryVi || '',
    summaryEn: data.summary?.en || data.summaryEn || '',
    summary: data.summary?.vi || data.summaryVi || '',
    contentVi: data.content?.vi || data.contentVi || '',
    contentEn: data.content?.en || data.contentEn || '',
    content: data.content?.vi || data.contentVi || '',
    coverImage: data.coverImage || '',
    categoryVi: data.category?.vi || data.categoryVi || '',
    categoryEn: data.category?.en || data.categoryEn || '',
    category: data.category?.vi || data.categoryVi || '',
    status: data.status || 'draft',
    featured: Boolean(data.featured),
    pinned: Boolean(data.pinned),
    provinceCode34: data.provinceCode34 || '',
    provinceName34: data.provinceName34 || '',
    regionCode: data.regionCode || '',
    tags,
    tagsText: tags.join(', '),
    seoTitle: data.seoTitle || '',
    seoDescription: data.seoDescription || '',
    updatedAtDate: formatDate(data.updatedAt),
  };
}

module.exports = { toSystemPostViewModel };
