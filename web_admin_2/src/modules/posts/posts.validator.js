function normalizePostListQuery(query = {}) {
  // Chuẩn hóa query để service chỉ làm việc với kiểu dữ liệu sạch.
  const page = Math.max(1, Number(query.page) || 1);
  const pageSize = Math.min(50, Math.max(1, Number(query.pageSize) || 20));

  const search = String(query.search || '').trim();
  const provinceCode34 = String(query.provinceCode34 || '').trim();
  const moderationStatus = String(query.moderationStatus || '').trim();
  const postType = String(query.postType || '').trim();
  const mediaKind = String(query.mediaKind || '').trim();
  const sortBy = String(query.sortBy || 'newest').trim();

  return {
    page,
    pageSize,
    search,
    provinceCode34,
    moderationStatus,
    postType,
    mediaKind,
    sortBy,
  };
}

function normalizePostUpdatePayload(payload = {}) {
  const title = String(payload.title || '').trim();
  const text = String(payload.text || '').trim();
  const postType = String(payload.postType || 'story').trim();
  const visibility = String(payload.visibility || 'public').trim();
  const moderationStatus = String(payload.moderationStatus || 'published').trim();
  const placeName = String(payload.placeName || '').trim();
  const provinceCode34 = String(payload.provinceCode34 || '').trim();
  const provinceName34 = String(payload.provinceName34 || '').trim();
  const regionCode = String(payload.regionCode || '').trim();

  let media = [];
  const mediaRaw = String(payload.mediaJson || '').trim();
  if (mediaRaw) {
    media = JSON.parse(mediaRaw);
    if (!Array.isArray(media)) {
      throw new Error('mediaJson phai la mang JSON hop le');
    }
  }

  const normalizedMedia = media
    .map((item) => ({
      url: String(item?.url || '').trim(),
      type: String(item?.type || 'image').trim().toLowerCase(),
      w: item?.w ?? null,
      h: item?.h ?? null,
    }))
    .filter((item) => item.url);

  return {
    title,
    text,
    postType,
    visibility,
    moderationStatus,
    placeName,
    provinceCode34,
    provinceName34,
    regionCode,
    media: normalizedMedia,
    mediaCount: normalizedMedia.length,
    hasMedia: normalizedMedia.length > 0,
  };
}

function normalizePostIds(ids = []) {
  return Array.from(new Set(
    (Array.isArray(ids) ? ids : [])
      .map((id) => String(id || '').trim())
      .filter(Boolean),
  ));
}

function normalizeModerationStatusInput(value = '') {
  const normalized = String(value || '').trim().toLowerCase();
  const allowed = ['pending', 'published', 'hidden', 'rejected'];

  if (!allowed.includes(normalized)) {
    throw new Error('moderationStatus khong hop le');
  }

  return normalized;
}

module.exports = {
  normalizePostListQuery,
  normalizePostUpdatePayload,
  normalizePostIds,
  normalizeModerationStatusInput,
};
