const { getFirebaseAdmin } = require('../../config/firebase-admin');
const { COLLECTIONS } = require('../../core/constants/collections');

function getDb() {
  const admin = getFirebaseAdmin();
  if (!admin) throw new Error('Firebase Admin is not configured');
  return admin.firestore();
}

async function getDashboardCollections() {
  const db = getDb();
  const [users, dishes, posts, provinces, systemPosts] = await Promise.all([
    db.collection(COLLECTIONS.USERS).get(),
    db.collection(COLLECTIONS.DISHES).get(),
    db.collection(COLLECTIONS.POSTS).get(),
    db.collection(COLLECTIONS.PROVINCES).get(),
    db.collection(COLLECTIONS.SYSTEM_POSTS).get(),
  ]);

  const mapDocs = (snapshot) => snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  return {
    users: mapDocs(users),
    dishes: mapDocs(dishes),
    posts: mapDocs(posts),
    provinces: mapDocs(provinces),
    systemPosts: mapDocs(systemPosts),
  };
}

module.exports = { getDashboardCollections };
