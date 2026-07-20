const { getFirebaseAdmin } = require('../../config/firebase-admin');
const { COLLECTIONS } = require('../../core/constants/collections');
const provinceMergeMap = require('../../../../food_travel/functions/src/migrations/province34/data/province_merge_map.official_2025.json');

// Một số tỉnh có dữ liệu legacy 63 tỉnh nhưng 34 tỉnh đã đổi tên/code.
// Giữ nguyên dữ liệu gốc trong province_code, nhưng khi map/lọc thì quy về code 34.
const LEGACY_TO_34_PROVINCE_ALIASES = {
  thua_thien_hue: 'hue',
};

function getAdmin() {
  const admin = getFirebaseAdmin();
  if (!admin) throw new Error('Firebase Admin is not configured');
  return admin;
}

function normalizeProvinceKey(value) {
  const raw = String(value || '').toLowerCase().trim();
  const normalized = raw
    .normalize('NFD')
    .replace(/\u0300-\u036f/g, '')
    .replace(/[-]/g, '');
  const map = {
    à: 'a', á: 'a', ạ: 'a', ả: 'a', ã: 'a',

    â: 'a', ầ: 'a', ấ: 'a', ậ: 'a', ẩ: 'a', ẫ: 'a',
    ă: 'a', ằ: 'a', ắ: 'a', ặ: 'a', ẳ: 'a', ẵ: 'a',
    è: 'e', é: 'e', ẹ: 'e', ẻ: 'e', ẽ: 'e',
    ê: 'e', ề: 'e', ế: 'e', ệ: 'e', ể: 'e', ễ: 'e',
    ì: 'i', í: 'i', ị: 'i', ỉ: 'i', ĩ: 'i',
    ò: 'o', ó: 'o', ọ: 'o', ỏ: 'o', õ: 'o',
    ô: 'o', ồ: 'o', ố: 'o', ộ: 'o', ổ: 'o', ỗ: 'o',
    ơ: 'o', ờ: 'o', ớ: 'o', ợ: 'o', ở: 'o', ỡ: 'o',
    ù: 'u', ú: 'u', ụ: 'u', ủ: 'u', ũ: 'u',
    ư: 'u', ừ: 'u', ứ: 'u', ự: 'u', ử: 'u', ữ: 'u',
    ỳ: 'y', ý: 'y', ỵ: 'y', ỷ: 'y', ỹ: 'y',
    đ: 'd',
  };
  let result = '';
  for (const char of normalized) {
    result += map[char] || char;
  }
  return result.replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

function canonicalProvinceCode(value) {
  const key = normalizeProvinceKey(value);
  if (!key) return '';
  if (LEGACY_TO_34_PROVINCE_ALIASES[key]) {
    return LEGACY_TO_34_PROVINCE_ALIASES[key];
  }
  if (provinceMergeMap[key]) return String(provinceMergeMap[key]).trim().toLowerCase();
  const stripped = key.replace(/^(tp|thanh_pho|tinh)_/, '');
  if (LEGACY_TO_34_PROVINCE_ALIASES[stripped]) {
    return LEGACY_TO_34_PROVINCE_ALIASES[stripped];
  }
  return String(provinceMergeMap[stripped] || key).trim().toLowerCase();
}

function getDb() {
  return getAdmin().firestore();
}

function normalizeDishViewModel(doc) {
  return {
    id: doc.id,
    ...doc.data(),
  };
}

function getServerTimestamp() {
  return getAdmin().firestore.FieldValue.serverTimestamp();
}

function applyDishFilters(ref, filters = {}) {
  const safeSpicyLevel = filters.spicyLevel === '' || filters.spicyLevel === undefined ? '' : Number(filters.spicyLevel);

  if (safeSpicyLevel !== '') {
    ref = ref.where('spicy_level', '==', safeSpicyLevel);
  }

  return ref;
}

async function countDishesFromRepository(filters = {}) {
  const ref = applyDishFilters(getDb().collection(COLLECTIONS.DISHES), filters);
  const snapshot = await ref.count().get();
  return Number(snapshot.data()?.count || 0);
}

async function listDishesFromRepository({
  page = 1,
  pageSize = 50,
  search = '',
  provinceCode34 = '',
  spicyLevel = '',
  sortBy = 'stt_asc',
} = {}) {
  const safePage = Math.max(1, Number(page) || 1);
  const safePageSize = Math.max(1, Number(pageSize) || 50);

  // Lay bo du lieu an toan, sau do loc/sap xep tren memory de tranh loi index Firestore.
  const ref = applyDishFilters(getDb().collection(COLLECTIONS.DISHES), { spicyLevel });
  const snap = await ref.get();
  let docs = snap.docs.map(normalizeDishViewModel);

  const safeProvinceCode34 = String(provinceCode34 || '').trim().toLowerCase();
  const safeSearch = String(search || '').trim().toLowerCase();

  if (safeProvinceCode34) {
    docs = docs.filter((dish) => {
      const candidate = String(dish.provinceCode34 || dish.province_code || dish.legacyProvinceCode || dish.provinceName34 || '').trim().toLowerCase();
      return (
        candidate === safeProvinceCode34 ||
        canonicalProvinceCode(candidate) === canonicalProvinceCode(safeProvinceCode34)
      );
    });
  }

  if (safeSearch) {
    docs = docs.filter((dish) => {
      const searchableText = [
        dish.id,
        dish.slug,
        dish.Name?.vi,
        dish.Name?.en,
        dish.name?.vi,
        dish.name?.en,
        dish.provinceName34,
        dish.provinceCode34,
      ]
        .map((value) => String(value || '').trim().toLowerCase())
        .join(' ');

      return searchableText.includes(safeSearch);
    });
  }

  const sortValue = String(sortBy || 'stt_asc').trim();
  docs.sort((left, right) => {
    if (sortValue === 'stt_desc') return Number(right.STT || 0) - Number(left.STT || 0);
    if (sortValue === 'name_desc') return String(right.nameSort || '').localeCompare(String(left.nameSort || ''));
    if (sortValue === 'name_asc') return String(left.nameSort || '').localeCompare(String(right.nameSort || ''));
    return Number(left.STT || 0) - Number(right.STT || 0);
  });

  const offset = (safePage - 1) * safePageSize;
  const pagedDocs = docs.slice(offset, offset + safePageSize);

  return {
    items: pagedDocs,
    hasNextPage: offset + safePageSize < docs.length,
  };
}

async function listAllDishesFromRepository(filters = {}) {
  const ref = applyDishFilters(getDb().collection(COLLECTIONS.DISHES), filters);
  const snapshot = await ref.get();
  let docs = snapshot.docs.map(normalizeDishViewModel);

  const safeProvinceCode34 = String(filters.provinceCode34 || '').trim().toLowerCase();
  const safeSearch = String(filters.search || '').trim().toLowerCase();

  if (safeProvinceCode34) {
    docs = docs.filter((dish) => {
      const candidate = String(dish.provinceCode34 || dish.province_code || dish.legacyProvinceCode || dish.provinceName34 || '').trim().toLowerCase();
      return (
        candidate === safeProvinceCode34 ||
        canonicalProvinceCode(candidate) === canonicalProvinceCode(safeProvinceCode34)
      );
    });
  }

  if (safeSearch) {
    docs = docs.filter((dish) => {
      const searchableText = [
        dish.id,
        dish.slug,
        dish.Name?.vi,
        dish.Name?.en,
        dish.name?.vi,
        dish.name?.en,
        dish.provinceName34,
        dish.provinceCode34,
      ]
        .map((value) => String(value || '').trim().toLowerCase())
        .join(' ');

      return searchableText.includes(safeSearch);
    });
  }

  const sortValue = String(filters.sortBy || 'stt_asc').trim();
  docs.sort((left, right) => {
    if (sortValue === 'stt_desc') return Number(right.STT || 0) - Number(left.STT || 0);
    if (sortValue === 'name_desc') return String(right.nameSort || '').localeCompare(String(left.nameSort || ''));
    if (sortValue === 'name_asc') return String(left.nameSort || '').localeCompare(String(right.nameSort || ''));
    return Number(left.STT || 0) - Number(right.STT || 0);
  });

  return docs;
}

async function listAllDishesWithSearchFromRepository(filters = {}) {
  const safeSearch = String(filters.search || '').trim().toLowerCase();
  const dishes = await listAllDishesFromRepository(filters);

  if (!safeSearch) {
    return dishes;
  }

  return dishes.filter((dish) => {
    const searchableText = [
      dish.id,
      dish.slug,
      dish.Name?.vi,
      dish.Name?.en,
      dish.name?.vi,
      dish.name?.en,
      dish.provinceName34,
      dish.provinceCode34,
    ]
      .map((value) => String(value || '').trim().toLowerCase())
      .join(' ');

    return searchableText.includes(safeSearch);
  });
}

async function getDishByIdFromRepository(id) {
  const snapshot = await getDb().collection(COLLECTIONS.DISHES).doc(id).get();
  return snapshot.exists ? normalizeDishViewModel(snapshot) : null;
}

async function getNextDishSttFromRepository() {
  const snapshot = await getDb()
    .collection(COLLECTIONS.DISHES)
    .orderBy('STT', 'desc')
    .limit(1)
    .get();

  if (snapshot.empty) {
    return 1;
  }

  return Number(snapshot.docs[0].data()?.STT || 0) + 1;
}

async function createDishInRepository(id, payload) {
  await getDb()
    .collection(COLLECTIONS.DISHES)
    .doc(id)
    .set({
      ...payload,
      createdAt: getServerTimestamp(),
      updatedAt: getServerTimestamp(),
    });

  return { id };
}

async function deleteDishFromRepository(id) {
  await getDb().collection(COLLECTIONS.DISHES).doc(id).delete();
}
// hàm cập nhật, chỉnh sửa món 
async function updateDishInRepository(id, payload) {
  await getDb()
    .collection(COLLECTIONS.DISHES)
    .doc(id)
    .update({
      ...payload,
      updatedAt: getServerTimestamp(),
    });

  return { id };
}

module.exports = {
  countDishesFromRepository,
  listDishesFromRepository,
  listAllDishesFromRepository,
  listAllDishesWithSearchFromRepository,
  getDishByIdFromRepository,
  getNextDishSttFromRepository,
  createDishInRepository,
  deleteDishFromRepository,
  updateDishInRepository,
};
