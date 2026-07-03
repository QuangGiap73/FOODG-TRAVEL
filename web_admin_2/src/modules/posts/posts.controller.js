const { ok } = require('../../core/http/response');
const {
  getPostsListPage,
  getPostDetail,
  getPostEditData,
  updatePost,
  deletePost,
  deletePosts,
  updatePostModerationStatus,
  updatePostsModerationStatus,
} = require('./posts.service');
const { asyncHandler } = require('../../core/errors/async-handler');

async function getPostsPage(req, res) {
  const pageData = await getPostsListPage(req.query);

  res.render('pages/posts/index', {
    pageTitle: 'Bài viết',
    posts: pageData.items,
    pagination: pageData.meta,
    formData: pageData.formData,
  });
}

// hàm render chi tiết bài viết
async function getPostDetailPage(req, res) {
  const post = await getPostDetail(req.params.id);

  res.render('pages/posts/detail', {
    pageTitle: post.title || post.authorName || 'Chi tiết bài viết',
    post,
  });
}

async function getPostEditPage(req, res) {
  const post = await getPostEditData(req.params.id);

  res.render('pages/posts/edit', {
    pageTitle: post.title || post.authorName || 'Chỉnh sửa bài viết',
    post,
    errorMessage: '',
  });
}

async function updatePostPage(req, res) {
  try {
    await updatePost(req.params.id, req.body);
    return res.redirect(`/admin/posts/${encodeURIComponent(req.params.id)}`);
  } catch (error) {
    const post = {
      ...(await getPostEditData(req.params.id)),
      ...req.body,
    };

    return res.status(error.statusCode || 400).render('pages/posts/edit', {
      pageTitle: post.title || post.authorName || 'Chỉnh sửa bài viết',
      post,
      errorMessage: error.message || 'Không thể cập nhật bài viết',
    });
  }
}

// hàm xóa mềm bài viết rồi quay lại danh sách
async function deletePostPage(req, res) {
  await deletePost(req.params.id);
  return res.redirect('/admin/posts');
}

const deletePostsApi = asyncHandler(async (req, res) => {
  return ok(res, await deletePosts(req.body?.ids), 'Deleted');
});

const updatePostModerationApi = asyncHandler(async (req, res) => {
  return ok(
    res,
    await updatePostModerationStatus(req.params.id, req.body?.moderationStatus),
    'Updated',
  );
});

const updatePostsModerationApi = asyncHandler(async (req, res) => {
  return ok(
    res,
    await updatePostsModerationStatus(req.body?.ids, req.body?.moderationStatus),
    'Updated',
  );
});

module.exports = {
  getPostsPage: asyncHandler(getPostsPage),
  getPostDetailPage: asyncHandler(getPostDetailPage),
  getPostEditPage: asyncHandler(getPostEditPage),
  updatePostPage: asyncHandler(updatePostPage),
  deletePostPage: asyncHandler(deletePostPage),
  deletePostsApi,
  updatePostModerationApi,
  updatePostsModerationApi,
};
