const { AppError } = require('../../core/errors/app-error');
const { createUploadService } = require('../uploads/upload.service');
const { listProvinces } = require('../provinces/provinces.service');
const { toSystemPostViewModel } = require('./system-posts.mapper');
const {
  listSystemPostsFromRepository,
  getSystemPostByIdFromRepository,
  createSystemPostInRepository,
  updateSystemPostInRepository,
  softDeleteSystemPostInRepository,
} = require('./system-posts.repository');
const {
  validateSystemPostPayload,
  validateSystemPostListQuery,
  slugify,
  ALLOWED_STATUS,
} = require('./system-posts.validator');

async function getSystemPostsPageData(query = {}) {
  const filters = validateSystemPostListQuery(query);
  let items = (await listSystemPostsFromRepository()).map(toSystemPostViewModel);

  if (filters.search) {
    const keyword = filters.search.toLowerCase();
    items = items.filter((item) =>
      String(item.titleVi || '').toLowerCase().includes(keyword)
      || String(item.titleEn || '').toLowerCase().includes(keyword)
      || String(item.slug || '').toLowerCase().includes(keyword)
      || String(item.summaryVi || '').toLowerCase().includes(keyword),
    );
  }

  if (filters.status) items = items.filter((item) => item.status === filters.status);

  items.sort((a, b) => (b.updatedAtDate?.getTime() || 0) - (a.updatedAtDate?.getTime() || 0));

  const total = items.length;
  const start = (filters.page - 1) * filters.pageSize;

  return {
    items: items.slice(start, start + filters.pageSize),
    meta: {
      page: filters.page,
      pageSize: filters.pageSize,
      total,
      totalPages: Math.max(1, Math.ceil(total / filters.pageSize)),
      search: filters.search,
      status: filters.status,
    },
  };
}

async function getSystemPostFormData() {
  return {
    provinces: await listProvinces(),
    statuses: ALLOWED_STATUS.map((status) => ({
      value: status,
      label: status === 'draft'
        ? 'Nháp'
        : status === 'published'
          ? 'Đã xuất bản'
          : 'Đã ẩn',
    })),
  };
}

function buildSystemPostDefaults(values = {}) {
  return {
    id: values.id || '',
    titleVi: values.titleVi || values.title || '',
    titleEn: values.titleEn || '',
    slug: values.slug || '',
    summaryVi: values.summaryVi || values.summary || '',
    summaryEn: values.summaryEn || '',
    contentVi: values.contentVi || values.content || '',
    contentEn: values.contentEn || '',
    coverImage: values.coverImage || '',
    categoryVi: values.categoryVi || values.category || '',
    categoryEn: values.categoryEn || '',
    provinceCode34: values.provinceCode34 || '',
    provinceName34: values.provinceName34 || '',
    regionCode: values.regionCode || '',
    tags: values.tagsText || values.tags || '',
    seoTitle: values.seoTitle || '',
    seoDescription: values.seoDescription || '',
    status: values.status || 'draft',
    featured: Boolean(values.featured),
    pinned: Boolean(values.pinned),
  };
}

async function getSystemPostCreateData() {
  return { formData: await getSystemPostFormData(), formValues: buildSystemPostDefaults() };
}

async function getSystemPostEditData(id) {
  if (!id) throw new AppError('Thiếu mã bài viết hệ thống', 400);
  const doc = await getSystemPostByIdFromRepository(id);
  if (!doc) throw new AppError('Không tìm thấy bài viết hệ thống', 404);
  return {
    formData: await getSystemPostFormData(),
    formValues: buildSystemPostDefaults(toSystemPostViewModel(doc)),
  };
}

async function getSystemPostDetailData(id) {
  if (!id) throw new AppError('Thiếu mã bài viết hệ thống', 400);
  const doc = await getSystemPostByIdFromRepository(id);
  if (!doc) throw new AppError('Không tìm thấy bài viết hệ thống', 404);

  const post = toSystemPostViewModel(doc);

  return {
    post,
    statusLabel:
      post.status === 'published'
        ? 'Đã xuất bản'
        : post.status === 'hidden'
          ? 'Đã ẩn'
          : 'Nháp',
    statusTone:
      post.status === 'published'
        ? 'success'
        : post.status === 'hidden'
          ? 'muted'
          : 'warning',
    tags: Array.isArray(post.tags) ? post.tags.filter(Boolean) : [],
  };
}

function buildSystemPostDocument(data, id) {
  return {
    id,
    slug: data.slug,
    title: { vi: data.titleVi, en: data.titleEn },
    summary: { vi: data.summaryVi, en: data.summaryEn },
    content: { vi: data.contentVi, en: data.contentEn },
    category: { vi: data.categoryVi, en: data.categoryEn },
    coverImage: data.coverImage,
    provinceCode34: data.provinceCode34,
    provinceName34: data.provinceName34,
    regionCode: data.regionCode,
    tags: data.tags,
    seoTitle: data.seoTitle,
    seoDescription: data.seoDescription,
    status: data.status,
    featured: data.featured,
    pinned: data.pinned,
  };
}

async function createSystemPost(payload) {
  const data = validateSystemPostPayload(payload);
  const id = slugify(payload.id || data.slug || data.titleVi || data.titleEn);
  if (!id) throw new AppError('Thiếu ID bài viết hệ thống', 400);
  if (!data.titleVi) throw new AppError('Tiêu đề tiếng Việt là trường bắt buộc', 400);
  if (!data.slug) throw new AppError('Slug là trường bắt buộc', 400);
  if (!data.contentVi) throw new AppError('Nội dung tiếng Việt là trường bắt buộc', 400);
  if (await getSystemPostByIdFromRepository(id)) throw new AppError('ID bài viết hệ thống đã tồn tại', 400);
  await createSystemPostInRepository(id, buildSystemPostDocument(data, id));
  return { id };
}

async function updateSystemPost(id, payload) {
  if (!id) throw new AppError('Thiếu mã bài viết hệ thống', 400);
  if (!await getSystemPostByIdFromRepository(id)) throw new AppError('Không tìm thấy bài viết hệ thống', 404);
  const data = validateSystemPostPayload(payload);
  if (!data.titleVi) throw new AppError('Tiêu đề tiếng Việt là trường bắt buộc', 400);
  if (!data.slug) throw new AppError('Slug là trường bắt buộc', 400);
  if (!data.contentVi) throw new AppError('Nội dung tiếng Việt là trường bắt buộc', 400);
  await updateSystemPostInRepository(id, buildSystemPostDocument(data, id));
  return { id };
}

async function deleteSystemPost(id) {
  if (!id) throw new AppError('Thiếu mã bài viết hệ thống', 400);
  await softDeleteSystemPostInRepository(id);
  return { id };
}

async function uploadSystemPostImage(file) {
  if (!file?.buffer) throw new AppError('Chưa chọn ảnh để tải lên', 400);
  const uploadService = createUploadService();
  return uploadService.uploadImage(file, {
    folder: process.env.CLOUDINARY_FOLDER || 'food-travel/system-posts',
  });
}

module.exports = {
  getSystemPostsPageData,
  getSystemPostCreateData,
  getSystemPostEditData,
  getSystemPostDetailData,
  createSystemPost,
  updateSystemPost,
  deleteSystemPost,
  uploadSystemPostImage,
  buildSystemPostDefaults,
  getSystemPostFormData,
};
