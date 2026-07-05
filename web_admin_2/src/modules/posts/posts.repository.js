const { getFirebaseAdmin } = require('../../config/firebase-admin');
const { COLLECTIONS } = require('../../core/constants/collections');

function getDb() {
  // Dùng chung Firebase Admin giống các module khác trong dự án.
  const admin = getFirebaseAdmin();
  if (!admin) {
    throw new Error('Firebase Admin chua duoc cau hinh');
  }
  return admin.firestore();
}

function buildPostsBaseQuery(db, filters = {}) {
  const {
    provinceCode34 = '',
    moderationStatus = '',
    postType = '',
  } = filters;

  let query = db.collection(COLLECTIONS.POSTS);
  query = query.where('status', '==', 'active');

  if (provinceCode34) {
    query = query.where('provinceCode34', '==', provinceCode34);
  }

  if (moderationStatus) {
    query = query.where('moderationStatus', '==', moderationStatus);
  }

  if (postType) {
    query = query.where('postType', '==', postType);
  }

  return query;
}

async function getPostsFilteredDocsFromRepository(filters = {}) {
  const db = getDb();
  const snapshot = await buildPostsBaseQuery(db, filters).get();
  return snapshot.docs;
}

// lấy 1 bài viết theo ID
async function getPostDetailFromRepository(id) {
  const snapshot = await getDb().collection(COLLECTIONS.POSTS).doc(id).get();
  if (!snapshot.exists) {
    return null;
  }
  return snapshot;
}

// lấy comment của bài viết
async function getCommentsForPostFromRepository(postId, limit = 20) {
  const snapshot = await getDb()
    .collection(COLLECTIONS.POSTS)
    .doc(postId)
    .collection('comments')
    .limit(limit)
    .get();
  return snapshot.docs;
}

// lấy likes bài viết
async function getLikesForPostFromRepository(postId, limit = 20) {
  const snapshot = await getDb()
    .collection(COLLECTIONS.POSTS)
    .doc(postId)
    .collection('likes')
    .limit(limit)
    .get();
  return snapshot.docs;
}

// Xóa mềm: chỉ đổi trạng thái, không xóa dữ liệu vật lý.
async function softDeletePostInRepository(id) {
  const admin = getFirebaseAdmin();

  await getDb().collection(COLLECTIONS.POSTS).doc(id).set(
    {
      status: 'deleted',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

// Xóa mềm nhiều bài viết bằng batch để số lần ghi ít hơn
// và dữ liệu cập nhật đồng nhất trong cùng một đợt thao tác.
async function softDeletePostsInRepository(ids = []) {
  const admin = getFirebaseAdmin();
  const db = getDb();
  const batch = db.batch();

  ids.forEach((id) => {
    const ref = db.collection(COLLECTIONS.POSTS).doc(id);
    batch.set(ref, {
      status: 'deleted',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  await batch.commit();
}

async function updatePostInRepository(id, payload) {
  const admin = getFirebaseAdmin();

  await getDb().collection(COLLECTIONS.POSTS).doc(id).set(
    {
      ...payload,
      isEdited: true,
      editedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

// Đổi nhanh trạng thái kiểm duyệt của một bài viết ngay trên danh sách.
async function updatePostModerationStatusInRepository(id, moderationStatus) {
  const admin = getFirebaseAdmin();

  await getDb().collection(COLLECTIONS.POSTS).doc(id).set(
    {
      moderationStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

// Tạo thông báo hệ thống cho chủ bài viết khi admin đổi trạng thái duyệt.
// Dùng collection con: users/{uid}/notifications để app mobile đọc trực tiếp.
async function createPostModerationNotificationInRepository({
  uid,
  postId,
  moderationStatus,
  title,
  snippet,
}) {
  if (!uid) return;

  const admin = getFirebaseAdmin();

  await getDb()
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection('notifications')
    .add({
      type: 'post_moderation_update',
      postId: postId || '',
      actorId: 'system',
      actorName: title || 'Cập nhật bài viết',
      actorPhoto: '',
      snippet: snippet || '',
      moderationStatus: moderationStatus || '',
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

// Đổi nhanh trạng thái kiểm duyệt của nhiều bài viết đã tick checkbox.
async function updatePostsModerationStatusInRepository(ids = [], moderationStatus) {
  const admin = getFirebaseAdmin();
  const db = getDb();
  const batch = db.batch();

  ids.forEach((id) => {
    const ref = db.collection(COLLECTIONS.POSTS).doc(id);
    batch.set(ref, {
      moderationStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  await batch.commit();
}

module.exports = {
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
};
