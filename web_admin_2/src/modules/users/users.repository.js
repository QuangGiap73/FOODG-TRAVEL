const { getFirebaseAdmin } = require('../../config/firebase-admin');
const { COLLECTIONS } = require('../../core/constants/collections');

function getDb() {
  const admin = getFirebaseAdmin();
  if (!admin) throw new Error('Firebase Admin is not configured');
  return admin.firestore();
}

function getAuth() {
  const admin = getFirebaseAdmin();
  if (!admin) throw new Error('Firebase Admin is not configured');
  return admin.auth();
}

async function hydrateUserWithJourney(doc) {
  const journeySummaryDoc = await getDb()
    .collection(COLLECTIONS.USERS)
    .doc(doc.id)
    .collection('journey')
    .doc('summary')
    .get();

  return {
    id: doc.id,
    ...doc.data(),
    journeySummary: journeySummaryDoc.exists ? journeySummaryDoc.data() : null,
  };
}

async function getUserDetailByIdFromRepository(id) {
  const db = getDb();
  const userDoc = await db.collection(COLLECTIONS.USERS).doc(id).get();
  if (!userDoc.exists) return null;

  const baseUser = await hydrateUserWithJourney(userDoc);
  const summaryRef = db.collection(COLLECTIONS.USERS).doc(id).collection('journey').doc('summary');

  const [checkinsSnap, badgesSnap, postsSnap] = await Promise.all([
    summaryRef.collection('checkins').orderBy('createdAt', 'desc').limit(6).get(),
    summaryRef.collection('badges').orderBy('updatedAt', 'desc').limit(6).get(),
    db.collection(COLLECTIONS.POSTS).where('authorId', '==', id).get(),
  ]);

  const recentPosts = postsSnap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((left, right) => {
      const leftTime = left.createdAt?._seconds ? left.createdAt._seconds * 1000 : new Date(left.createdAt || 0).getTime() || 0;
      const rightTime = right.createdAt?._seconds ? right.createdAt._seconds * 1000 : new Date(right.createdAt || 0).getTime() || 0;
      return rightTime - leftTime;
    })
    .slice(0, 6);

  return {
    ...baseUser,
    recentCheckins: checkinsSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    badges: badgesSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    recentPosts,
  };
}

async function listUsersFromRepository() {
  const snap = await getDb().collection(COLLECTIONS.USERS).get();
  return Promise.all(snap.docs.map(hydrateUserWithJourney));
}

async function getUserByIdFromRepository(id) {
  const doc = await getDb().collection(COLLECTIONS.USERS).doc(id).get();
  if (!doc.exists) return null;
  return hydrateUserWithJourney(doc);
}

async function createUserInRepository(payload) {
  const admin = getFirebaseAdmin();
  const auth = getAuth();
  const db = getDb();
  const normalizedRole = payload.role || 'user';

  const userRecord = await auth.createUser({
    email: payload.email,
    password: payload.password,
    displayName: payload.fullName || '',
  });

  const claims = normalizedRole === 'admin'
    ? { admin: true, role: 'admin' }
    : { role: normalizedRole };
  await auth.setCustomUserClaims(userRecord.uid, claims);

  await db.collection(COLLECTIONS.USERS).doc(userRecord.uid).set({
    email: payload.email,
    fullName: payload.fullName || '',
    phone: payload.phone || null,
    role: normalizedRole,
    authUid: userRecord.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return userRecord.uid;
}

async function updateUserInRepository(id, payload) {
  const admin = getFirebaseAdmin();
  const auth = getAuth();
  const db = getDb();
  const current = await getUserByIdFromRepository(id);
  if (!current) return null;

  const authUid = current.authUid || id;
  const authUpdate = {
    email: payload.email,
    displayName: payload.fullName || '',
    ...(payload.password ? { password: payload.password } : {}),
  };

  const normalizedRole = payload.role || current.role || 'user';
  const claims = normalizedRole === 'admin'
    ? { admin: true, role: 'admin' }
    : { role: normalizedRole };
  let authUpdated = true;

  try {
    await auth.updateUser(authUid, authUpdate);
    await auth.setCustomUserClaims(authUid, claims);
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') {
      throw error;
    }
    authUpdated = false;
  }

  await db.collection(COLLECTIONS.USERS).doc(id).set(
    {
      email: payload.email,
      fullName: payload.fullName || '',
      phone: payload.phone || null,
      gender: payload.gender || null,
      dateOfBirth: payload.dateOfBirth || null,
      role: normalizedRole,
      authUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { authUid, authUpdated };
}

async function deleteUserInRepository(id) {
  const current = await getUserByIdFromRepository(id);
  if (!current) return null;
  const authUid = current.authUid || id;

  try {
    await getAuth().deleteUser(authUid);
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  const userRef = getDb().collection(COLLECTIONS.USERS).doc(id);
  if (typeof getDb().recursiveDelete === 'function') {
    await getDb().recursiveDelete(userRef);
  } else {
    await userRef.delete();
  }
  return authUid;
}

async function updateUserAvatarInRepository(id, photoUrl) {
  const admin = getFirebaseAdmin();
  const current = await getUserByIdFromRepository(id);
  if (!current) return null;

  await getDb().collection(COLLECTIONS.USERS).doc(id).set(
    {
      photoUrl: photoUrl || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { id, photoUrl };
}

module.exports = {
  listUsersFromRepository,
  getUserByIdFromRepository,
  getUserDetailByIdFromRepository,
  createUserInRepository,
  updateUserInRepository,
  updateUserAvatarInRepository,
  deleteUserInRepository,
};
