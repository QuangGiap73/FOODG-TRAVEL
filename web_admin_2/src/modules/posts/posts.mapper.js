function buildExcerpt(text = '', maxLength = 100) {
  const clean = String(text || '').replace(/\s+/g, ' ').trim();
  if (!clean) return '';
  if (clean.length <= maxLength) return clean;
  return `${clean.slice(0, maxLength).trim()}...`;
}

function formatPostDate(value) {
  if (!value) return null;

  if (typeof value.toDate === 'function') {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  return null;
}

function toPostViewModel(doc) {
  // Mapper gom mọi fallback để view không phải tự kiểm tra quá nhiều.
  const data = doc.data ? doc.data() : doc;

  const media = Array.isArray(data.media) ? data.media : [];
  const place = data.placeSnapshot || {};
  const normalizedMedia = media.map((item) => ({
    url: item?.url || '',
    type: String(item?.type || 'image').toLowerCase(),
    w: item?.w || null,
    h: item?.h || null,
  }));

  return {
    id: doc.id || data.id || '',
    authorId: data.authorId || '',
    authorName: data.authorName || 'Ẩn danh',
    authorPhoto: data.authorPhoto || '',
    authorUsername: data.authorUsername || '',
    text: data.text || '',
    excerpt: data.excerpt || buildExcerpt(data.text || '', 110),
    title: data.title || '',
    media: normalizedMedia,
    mediaCount: Number(data.mediaCount || normalizedMedia.length || 0),
    hasMedia: Boolean(
      typeof data.hasMedia === 'boolean' ? data.hasMedia : normalizedMedia.length > 0,
    ),
    coverImage: normalizedMedia[0]?.url || '',
    placeId: data.placeId || '',
    placeName: data.placeName || place.name || '',
    placeSnapshot: place,
    placeSource: data.placeSource || '',
    provinceCode34: data.provinceCode34 || '',
    provinceName34: data.provinceName34 || '',
    regionCode: data.regionCode || '',
    postType: data.postType || 'story',
    visibility: data.visibility || 'public',
    status: data.status || 'active',
    moderationStatus: data.moderationStatus || 'published',
    likeCount: Number(data.likeCount || 0),
    commentCount: Number(data.commentCount || 0),
    viewCount: Number(data.viewCount || 0),
    shareCount: Number(data.shareCount || 0),
    saveCount: Number(data.saveCount || 0),
    reportCount: Number(data.reportCount || 0),
    isEdited: Boolean(data.isEdited),
    createdAt: data.createdAt || null,
    updatedAt: data.updatedAt || null,
    lastInteractionAt: data.lastInteractionAt || null,
    createdAtDate: formatPostDate(data.createdAt),
    updatedAtDate: formatPostDate(data.updatedAt),
  };
}

function toPostCommentViewModel(doc) {
  const data = doc.data ? doc.data() : doc;

  return {
    id: doc.id || data.id || '',
    authorId: data.authorId || '',
    authorName: data.authorName || 'Ẩn danh',
    authorPhoto: data.authorPhoto || '',
    text: data.text || '',
    status: data.status || 'active',
    createdAt: data.createdAt || null,
    createdAtDate: formatPostDate(data.createdAt),
  };
}

function toPostLikeViewModel(doc) {
  const data = doc.data ? doc.data() : doc;

  return {
    id: doc.id || data.id || '',
    createdAt: data.createdAt || null,
    createdAtDate: formatPostDate(data.createdAt),
  };
}

module.exports = {
  toPostViewModel,
  toPostCommentViewModel,
  toPostLikeViewModel,
};
