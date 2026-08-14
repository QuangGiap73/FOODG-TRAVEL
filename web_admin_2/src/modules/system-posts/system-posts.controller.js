const { asyncHandler } = require('../../core/errors/async-handler');
const {
  getSystemPostsPageData,
  getSystemPostDetailData,
  getSystemPostCreateData,
  getSystemPostEditData,
  createSystemPost,
  updateSystemPost,
  deleteSystemPost,
  uploadSystemPostImage,
  buildSystemPostDefaults,
  getSystemPostFormData,
} = require('./system-posts.service');

async function getSystemPostsPage(req, res) {
  const pageData = await getSystemPostsPageData(req.query);
  res.render('pages/system-posts/index', {
    pageTitle: 'Bài viết hệ thống',
    posts: pageData.items,
    stats: pageData.stats,
    pagination: pageData.meta,
    pageStyles: ['/public/css/pages/system-posts.css'],
    pageScripts: ['/public/js/modules/system-posts/index.js'],
  });
}

async function getSystemPostDetailPage(req, res) {
  const detailData = await getSystemPostDetailData(req.params.id);
  res.render('pages/system-posts/detail', {
    pageTitle: 'Chi tiết bài viết hệ thống',
    pageStyles: ['/public/css/pages/system-posts.css'],
    ...detailData,
  });
}

async function renderFormPage(res, options = {}) {
  res.status(options.statusCode || 200).render('pages/system-posts/form', {
    pageTitle: options.pageTitle || 'Tạo bài viết hệ thống',
    successMessage: options.successMessage || '',
    errorMessage: options.errorMessage || '',
    formData: options.formData || await getSystemPostFormData(),
    formValues: options.formValues || buildSystemPostDefaults(),
    submitAction: options.submitAction || '/admin/system-posts/add',
    mode: options.mode || 'create',
    pageStyles: ['/public/css/pages/system-posts.css'],
    pageScripts: ['/public/js/modules/system-posts/form.js'],
  });
}

async function getSystemPostCreatePage(_req, res) {
  await renderFormPage(res, {
    pageTitle: 'Tạo bài viết hệ thống',
    ...(await getSystemPostCreateData()),
  });
}

async function createSystemPostPage(req, res) {
  try {
    const created = await createSystemPost(req.body);
    return res.redirect(`/admin/system-posts/${encodeURIComponent(created.id)}/edit?created=1`);
  } catch (error) {
    return renderFormPage(res, {
      statusCode: error.statusCode || 400,
      pageTitle: 'Tạo bài viết hệ thống',
      errorMessage: error.message || 'Không thể tạo bài viết hệ thống',
      formData: await getSystemPostFormData(),
      formValues: buildSystemPostDefaults(req.body),
      submitAction: '/admin/system-posts/add',
      mode: 'create',
    });
  }
}

async function getSystemPostEditPage(req, res) {
  await renderFormPage(res, {
    pageTitle: 'Chỉnh sửa bài viết hệ thống',
    successMessage: req.query.created ? 'Đã tạo bài viết hệ thống thành công.' : req.query.updated ? 'Đã cập nhật bài viết hệ thống thành công.' : '',
    ...(await getSystemPostEditData(req.params.id)),
    submitAction: `/admin/system-posts/${encodeURIComponent(req.params.id)}/edit`,
    mode: 'edit',
  });
}

async function updateSystemPostPage(req, res) {
  try {
    await updateSystemPost(req.params.id, req.body);
    return res.redirect(`/admin/system-posts/${encodeURIComponent(req.params.id)}/edit?updated=1`);
  } catch (error) {
    return renderFormPage(res, {
      statusCode: error.statusCode || 400,
      pageTitle: 'Chỉnh sửa bài viết hệ thống',
      errorMessage: error.message || 'Không thể cập nhật bài viết hệ thống',
      formData: await getSystemPostFormData(),
      formValues: buildSystemPostDefaults({ ...req.body, id: req.params.id }),
      submitAction: `/admin/system-posts/${encodeURIComponent(req.params.id)}/edit`,
      mode: 'edit',
    });
  }
}

const deleteSystemPostApi = asyncHandler(async (req, res) => res.json({
  success: true,
  message: 'Deleted',
  data: await deleteSystemPost(req.params.id),
}));

const uploadSystemPostImageApi = asyncHandler(async (req, res) => res.json({
  success: true,
  message: 'Uploaded',
  data: await uploadSystemPostImage(req.file),
}));

module.exports = {
  getSystemPostsPage: asyncHandler(getSystemPostsPage),
  getSystemPostDetailPage: asyncHandler(getSystemPostDetailPage),
  getSystemPostCreatePage: asyncHandler(getSystemPostCreatePage),
  createSystemPostPage: asyncHandler(createSystemPostPage),
  getSystemPostEditPage: asyncHandler(getSystemPostEditPage),
  updateSystemPostPage: asyncHandler(updateSystemPostPage),
  deleteSystemPostApi,
  uploadSystemPostImageApi,
};
