const { getFirebaseAdmin } = require('../../config/firebase-admin');
const { COLLECTIONS } = require('../../core/constants/collections');

function getDb() {
  const admin = getFirebaseAdmin();
  if (!admin) throw new Error('Firebase Admin chua duoc cau hinh');
  return admin.firestore();
}

async function listSystemPostsFromRepository() {
  const snapshot = await getDb().collection(COLLECTIONS.SYSTEM_POSTS).get();
  return snapshot.docs;
}

async function getSystemPostByIdFromRepository(id) {
  const doc = await getDb().collection(COLLECTIONS.SYSTEM_POSTS).doc(id).get();
  if (!doc.exists) return null;
  return doc;
}

async function createSystemPostInRepository(id, payload) {
  const admin = getFirebaseAdmin();
  await getDb().collection(COLLECTIONS.SYSTEM_POSTS).doc(id).set({
    ...payload,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function updateSystemPostInRepository(id, payload) {
  const admin = getFirebaseAdmin();
  const nextPayload = {
    ...payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (payload.status === 'published') {
    nextPayload.publishedAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await getDb().collection(COLLECTIONS.SYSTEM_POSTS).doc(id).set(nextPayload, { merge: true });
}

async function softDeleteSystemPostInRepository(id) {
  const admin = getFirebaseAdmin();
  await getDb().collection(COLLECTIONS.SYSTEM_POSTS).doc(id).set({
    status: 'hidden',
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

module.exports = {
  listSystemPostsFromRepository,
  getSystemPostByIdFromRepository,
  createSystemPostInRepository,
  updateSystemPostInRepository,
  softDeleteSystemPostInRepository,
};
