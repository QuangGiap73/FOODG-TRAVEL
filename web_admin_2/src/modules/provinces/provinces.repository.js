const { getFirebaseAdmin } = require('../../config/firebase-admin');
const { COLLECTIONS } = require('../../core/constants/collections');

function getDb() {
  const admin = getFirebaseAdmin();
  if (!admin) throw new Error('Firebase Admin is not configured');
  return admin.firestore();
}

function normalizeProvinceKey(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

async function listRegionsFromRepository() {
  const snap = await getDb().collection(COLLECTIONS.REGIONS).get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function listProvincesFromRepository(regionCode) {
  let ref = getDb().collection(COLLECTIONS.PROVINCES);
  if (regionCode) {
    ref = ref.where('regionsCode', '==', regionCode);
  }

  const snap = await ref.get();
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getRegionByCodeFromRepository(code) {
  const doc = await getDb().collection(COLLECTIONS.REGIONS).doc(code).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function getProvinceByCodeFromRepository(code) {
  const doc = await getDb().collection(COLLECTIONS.PROVINCES).doc(code).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function createRegionInRepository(payload) {
  await getDb().collection(COLLECTIONS.REGIONS).doc(payload.code).set({
    code: payload.code,
    name: payload.name,
    macro_region: payload.macro_region,
    ...(payload.number !== null ? { number: payload.number } : {}),
  });
}

async function deleteRegionInRepository(code) {
  await getDb().collection(COLLECTIONS.REGIONS).doc(code).delete();
}

async function createProvinceInRepository(payload) {
  await getDb().collection(COLLECTIONS.PROVINCES).doc(payload.code).set({
    code: payload.code,
    name: payload.name,
    regionsCode: payload.regionsCode,
    description: payload.description || '',
    imageUrl: payload.imageUrl || '',
    imageUrls: payload.imageUrls || [],
    slug: payload.slug || payload.code,
    centerLat: payload.centerLat,
    centerLng: payload.centerLng,
    createdAt: new Date().toISOString(),
  });
}

async function updateProvinceInRepository(code, payload) {
  await getDb().collection(COLLECTIONS.PROVINCES).doc(code).set(
    {
      code,
      name: payload.name,
      regionsCode: payload.regionsCode,
      description: payload.description || '',
      imageUrl: payload.imageUrl || '',
      imageUrls: payload.imageUrls || [],
      slug: payload.slug || code,
      centerLat: payload.centerLat,
      centerLng: payload.centerLng,
      updatedAt: new Date().toISOString(),
    },
    { merge: true },
  );
}

async function deleteProvinceInRepository(code) {
  await getDb().collection(COLLECTIONS.PROVINCES).doc(code).delete();
}

async function hasProvinceInRegionFromRepository(regionCode) {
  const snap = await getDb()
    .collection(COLLECTIONS.PROVINCES)
    .where('regionsCode', '==', regionCode)
    .limit(1)
    .get();

  return !snap.empty;
}

async function buildProvinceStatsMapFromRepository() {
  const db = getDb();
  const [dishesSnap, checkinsSnap] = await Promise.all([
    db.collection(COLLECTIONS.DISHES).get(),
    db.collectionGroup('checkins').get(),
  ]);

  const statsMap = new Map();

  function ensureEntry(rawKey) {
    const key = normalizeProvinceKey(rawKey);
    if (!key) return null;
    if (!statsMap.has(key)) {
      statsMap.set(key, { dishesCount: 0, checkinsCount: 0 });
    }
    return statsMap.get(key);
  }

  dishesSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    const entry =
      ensureEntry(data.provinceCode34) ||
      ensureEntry(data.province_code) ||
      ensureEntry(data.provinceCode) ||
      ensureEntry(data.province_name) ||
      ensureEntry(data.provinceName) ||
      ensureEntry(data.province);

    if (entry) {
      entry.dishesCount += 1;
    }
  });

  checkinsSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    const entry =
      ensureEntry(data.provinceCode34) ||
      ensureEntry(data.provinceCode) ||
      ensureEntry(data.provinceName34) ||
      ensureEntry(data.provinceName) ||
      ensureEntry(data.placeProvinceCode) ||
      ensureEntry(data.placeProvinceName) ||
      ensureEntry(data.province);

    if (entry) {
      entry.checkinsCount += 1;
    }
  });

  return statsMap;
}

module.exports = {
  listRegionsFromRepository,
  listProvincesFromRepository,
  getRegionByCodeFromRepository,
  getProvinceByCodeFromRepository,
  createRegionInRepository,
  deleteRegionInRepository,
  createProvinceInRepository,
  updateProvinceInRepository,
  deleteProvinceInRepository,
  hasProvinceInRegionFromRepository,
  buildProvinceStatsMapFromRepository,
  normalizeProvinceKey,
};
