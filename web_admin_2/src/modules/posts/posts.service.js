const {
  normalizePostListQuery,
  normalizePostUpdatePayload,
  normalizePostIds,
  normalizeModerationStatusInput,
} = require('./posts.validator');
const {
  getPostsFilteredDocsFromRepository,
  getPostDetailFromRepository,
  getCommentsForPostFromRepository,
  getLikesForPostFromRepository,
  softDeletePostInRepository,
  softDeletePostsInRepository,
  updatePostInRepository,
  updatePostModerationStatusInRepository,
  updatePostsModerationStatusInRepository,
  createPostModerationNotificationInRepository,
} = require('./posts.repository');
const {
  toPostViewModel,
  toPostCommentViewModel,
  toPostLikeViewModel,
} = require('./posts.mapper');
const { CANONICAL_PROVINCES_34 } = require('../dishes/dishes.constants');
const AppError = require('../../core/errors/app-error');

function applySearchInMemory(items, search) {
  // Tìm theo nội dung, tiêu đề, tác giả, địa điểm.
  if (!search) return items;

  const keyword = search.toLowerCase();

  return items.filter((item) => {
    const title = String(item.title || '').toLowerCase();
    const text = String(item.text || '').toLowerCase();
    const authorName = String(item.authorName || '').toLowerCase();
    const placeName = String(item.placeName || '').toLowerCase();

    return (
      title.includes(keyword) ||
      text.includes(keyword) ||
      authorName.includes(keyword) ||
      placeName.includes(keyword)
    );
  });
}

function applyMediaFilterInMemory(items, mediaKind) {
  // Filter media trên memory để không phải tạo thêm index Firestore.
  if (!mediaKind) return items;

  return items.filter((item) => {
    const media = Array.isArray(item.media) ? item.media : [];
    const mediaTypes = media.map((entry) => String(entry.type || '').toLowerCase());

    if (mediaKind === 'none') return media.length === 0;
    if (mediaKind === 'image') return mediaTypes.includes('image');
    if (mediaKind === 'video') return mediaTypes.includes('video');

    return true;
  });
}

function getTimestampValue(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return 0;
}

function sortPostsInMemory(items, sortBy) {
  // Sắp xếp trên memory để tránh lỗi index khi đang phát triển.
  const list = [...items];

  list.sort((left, right) => {
    if (sortBy === 'oldest') {
      return getTimestampValue(left.createdAt) - getTimestampValue(right.createdAt);
    }

    if (sortBy === 'most_liked') {
      const likeDiff = Number(right.likeCount || 0) - Number(left.likeCount || 0);
      if (likeDiff !== 0) return likeDiff;
      return getTimestampValue(right.createdAt) - getTimestampValue(left.createdAt);
    }

    if (sortBy === 'most_commented') {
      const commentDiff =
        Number(right.commentCount || 0) - Number(left.commentCount || 0);
      if (commentDiff !== 0) return commentDiff;
      return getTimestampValue(right.createdAt) - getTimestampValue(left.createdAt);
    }

    return getTimestampValue(right.createdAt) - getTimestampValue(left.createdAt);
  });

  return list;
}

async function getPostsListPage(query = {}) {
  const filters = normalizePostListQuery(query);

  const docs = await getPostsFilteredDocsFromRepository(filters);

  let items = docs.map(toPostViewModel);
  items = applySearchInMemory(items, filters.search);
  items = applyMediaFilterInMemory(items, filters.mediaKind);
  items = sortPostsInMemory(items, filters.sortBy);

  const total = items.length;
  const totalPages = Math.max(1, Math.ceil(total / filters.pageSize));

  const pagedItems = items.slice(
    (filters.page - 1) * filters.pageSize,
    filters.page * filters.pageSize,
  );

  return {
    items: pagedItems,
    meta: {
      page: filters.page,
      pageSize: filters.pageSize,
      total,
      totalPages,
      search: filters.search,
      provinceCode34: filters.provinceCode34,
      moderationStatus: filters.moderationStatus,
      postType: filters.postType,
      mediaKind: filters.mediaKind,
      sortBy: filters.sortBy,
    },
    formData: {
      provinces: CANONICAL_PROVINCES_34,
      moderationStatuses: [
        { value: '', label: 'Tất cả kiểm duyệt' },
        { value: 'published', label: 'Đã xuất bản' },
        { value: 'pending', label: 'Chờ duyệt' },
        { value: 'hidden', label: 'Đã ẩn' },
        { value: 'flagged', label: 'Bị gắn cờ' },
        { value: 'rejected', label: 'Bị từ chối' },
      ],
      postTypes: [
        { value: '', label: 'Tất cả loại bài' },
        { value: 'review', label: 'Review' },
        { value: 'checkin', label: 'Check-in' },
        { value: 'story', label: 'Chia sẻ' },
        { value: 'question', label: 'Hỏi đáp' },
      ],
      mediaOptions: [
        { value: '', label: 'Tất cả media' },
        { value: 'image', label: 'Có ảnh' },
        { value: 'video', label: 'Có video' },
        { value: 'none', label: 'Không có media' },
      ],
    },
  };
}

// lấy dữ liệu chi tiết bài viết
async function getPostDetail(id) {
  if (!id) {
    throw new AppError('Thiếu mã bài viết', 400);
  }

  const [postDoc, commentDocs, likeDocs] = await Promise.all([
    getPostDetailFromRepository(id),
    getCommentsForPostFromRepository(id, 20),
    getLikesForPostFromRepository(id, 20),
  ]);

  if (!postDoc) {
    throw new AppError('Không tìm thấy bài viết', 404);
  }

  const post = toPostViewModel(postDoc);
  const comments = commentDocs.map(toPostCommentViewModel);
  const likes = likeDocs.map(toPostLikeViewModel);

  return {
    ...post,
    comments,
    likes,
  };
}

async function getPostEditData(id) {
  if (!id) {
    throw new AppError('Thiếu mã bài viết', 400);
  }

  const postDoc = await getPostDetailFromRepository(id);
  if (!postDoc) {
    throw new AppError('Không tìm thấy bài viết', 404);
  }

  const post = toPostViewModel(postDoc);

  return {
    ...post,
    mediaJson: JSON.stringify(post.media || [], null, 2),
  };
}

async function updatePost(id, payload) {
  if (!id) {
    throw new AppError('Thiếu mã bài viết', 400);
  }

  const postDoc = await getPostDetailFromRepository(id);
  if (!postDoc) {
    throw new AppError('Không tìm thấy bài viết', 404);
  }

  let data;
  try {
    data = normalizePostUpdatePayload(payload);
  } catch (error) {
    throw new AppError(error.message || 'Dữ liệu cập nhật không hợp lệ', 400);
  }

  if (!data.text && !data.mediaCount) {
    throw new AppError('Bài viết phải có nội dung hoặc media', 400);
  }

  const current = toPostViewModel(postDoc);

  await updatePostInRepository(id, {
    title: data.title,
    text: data.text,
    postType: data.postType,
    visibility: data.visibility,
    moderationStatus: data.moderationStatus,
    placeName: data.placeName,
    provinceCode34: data.provinceCode34,
    provinceName34: data.provinceName34,
    regionCode: data.regionCode,
    media: data.media,
    mediaCount: data.mediaCount,
    hasMedia: data.hasMedia,
    placeSnapshot: {
      ...(current.placeSnapshot || {}),
      name: data.placeName,
    },
  });

  return { id };
}

async function deletePost(id) {
  // Xóa mềm để vẫn giữ dữ liệu cho audit hoặc khôi phục.
  if (!id) {
    throw new AppError('Thiếu mã bài viết', 400);
  }

  const postDoc = await getPostDetailFromRepository(id);
  if (!postDoc) {
    throw new AppError('Không tìm thấy bài viết', 404);
  }

  await softDeletePostInRepository(id);
  return { id };
}

function buildModerationNotificationContent(status) {
  // Gom message tại một chỗ để sau này sửa wording không phải dò nhiều file.
  switch (String(status || '').toLowerCase()) {
    case 'published':
      return {
        title: 'Bài viết đã được duyệt',
        snippet: 'Bài viết của bạn đã được admin duyệt và hiển thị công khai.',
      };
    case 'hidden':
      return {
        title: 'Bài viết đã bị ẩn',
        snippet: 'Bài viết của bạn tạm thời bị ẩn khỏi cộng đồng.',
      };
    case 'rejected':
      return {
        title: 'Bài viết bị từ chối',
        snippet: 'Bài viết của bạn chưa được duyệt. Vui lòng kiểm tra lại nội dung.',
      };
    case 'pending':
      return {
        title: 'Bài viết đang chờ duyệt',
        snippet: 'Bài viết của bạn đã được chuyển về trạng thái chờ duyệt.',
      };
    default:
      return {
        title: 'Trạng thái bài viết đã thay đổi',
        snippet: `Bài viết của bạn vừa được cập nhật sang trạng thái: ${status}.`,
      };
  }
}

async function pushModerationNotificationIfNeeded(postDoc, moderationStatus) {
  const current = toPostViewModel(postDoc);
  const nextStatus = String(moderationStatus || '').toLowerCase();
  const prevStatus = String(current.moderationStatus || '').toLowerCase();

  // Không bắn thông báo nếu trạng thái không đổi.
  if (!current.authorId || !nextStatus || nextStatus === prevStatus) {
    return;
  }

  const content = buildModerationNotificationContent(nextStatus);

  await createPostModerationNotificationInRepository({
    uid: current.authorId,
    postId: current.id,
    moderationStatus: nextStatus,
    title: content.title,
    snippet: content.snippet,
  });
}

async function deletePosts(ids = []) {
  // Chuẩn hóa ID trước để tránh xóa lặp cùng một bài.
  const normalizedIds = normalizePostIds(ids);
  if (!normalizedIds.length) {
    throw new AppError('Thiếu danh sách bài viết', 400);
  }

  // Kiểm tra tồn tại trước khi batch xóa để user biết ID nào sai.
  const docs = await Promise.all(
    normalizedIds.map((id) => getPostDetailFromRepository(id)),
  );

  const foundIds = [];
  const notFound = [];
  docs.forEach((doc, index) => {
    if (doc) foundIds.push(normalizedIds[index]);
    else notFound.push(normalizedIds[index]);
  });

  if (foundIds.length) {
    await softDeletePostsInRepository(foundIds);
  }

  return {
    deleted: foundIds,
    notFound,
  };
}

async function updatePostModerationStatus(id, moderationStatus) {
  if (!id) {
    throw new AppError('Thiếu mã bài viết', 400);
  }

  const normalizedStatus = normalizeModerationStatusInput(moderationStatus);
  const postDoc = await getPostDetailFromRepository(id);
  if (!postDoc) {
    throw new AppError('Không tìm thấy bài viết', 404);
  }

  await updatePostModerationStatusInRepository(id, normalizedStatus);
  await pushModerationNotificationIfNeeded(postDoc, normalizedStatus);
  return {
    id,
    moderationStatus: normalizedStatus,
  };
}

async function updatePostsModerationStatus(ids = [], moderationStatus) {
  const normalizedIds = normalizePostIds(ids);
  if (!normalizedIds.length) {
    throw new AppError('Thiếu danh sách bài viết', 400);
  }

  const normalizedStatus = normalizeModerationStatusInput(moderationStatus);
  const docs = await Promise.all(
    normalizedIds.map((id) => getPostDetailFromRepository(id)),
  );

  const foundIds = [];
  const notFound = [];
  docs.forEach((doc, index) => {
    if (doc) foundIds.push(normalizedIds[index]);
    else notFound.push(normalizedIds[index]);
  });

  if (foundIds.length) {
    await updatePostsModerationStatusInRepository(foundIds, normalizedStatus);
    // Gửi thông báo theo từng bài để app của đúng user nhận được cập nhật.
    await Promise.all(
      docs.map((doc) => {
        if (!doc) return Promise.resolve();
        return pushModerationNotificationIfNeeded(doc, normalizedStatus);
      }),
    );
  }

  return {
    updated: foundIds,
    notFound,
    moderationStatus: normalizedStatus,
  };
}

module.exports = {
  getPostsListPage,
  getPostDetail,
  getPostEditData,
  updatePost,
  deletePost,
  deletePosts,
  updatePostModerationStatus,
  updatePostsModerationStatus,
};
