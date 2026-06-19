// Usage: node scripts/import_dishes.js [path/to/data.json]
// Doc file JSON (mang mon an) va import vao Firestore collection "dishes".
// Khi import, script tu dong backfill provinceCode34/provinceName34/
// legacyProvinceCode/legacyProvinceName.

const fs = require('fs');
const path = require('path');

// Reuse Firebase Admin da cau hinh trong du an
const { db } = require('../firebase/config');

const provinceMergeMap = require('../../food_travel/functions/src/migrations/province34/data/province_merge_map.official_2025.json');
const canonicalSeeds = require('../../food_travel/functions/src/migrations/province34/data/canonical_provinces_34.official_2025.json');

const seedsByCode = new Map(
  canonicalSeeds.map((item) => [item.code, item]),
);

// Lay duong dan file JSON (mac dinh: web_admin/thai_binh_vi_en.json)
const dataPath =
  process.argv[2] || path.join(__dirname, '..', 'thai_binh_vi_en.json');
if (!fs.existsSync(dataPath)) {
  console.error('Khong tim thay file:', dataPath);
  process.exit(1);
}

const raw = fs.readFileSync(dataPath, 'utf8');
let data;
try {
  data = JSON.parse(raw);
} catch (err) {
  console.error('Khong parse duoc JSON:', err.message);
  process.exit(1);
}

if (!Array.isArray(data)) {
  console.error('File JSON phai la mang object.');
  process.exit(1);
}

function asString(value) {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

function pickLocalizedString(value) {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return (
      asString(value.vi) ||
      asString(value.en) ||
      asString(value.code) ||
      asString(value.name)
    );
  }
  return asString(value);
}

function normalizeKey(input) {
  const lower = asString(input).toLowerCase().trim();
  const source =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩ' +
    'òóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const target =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiii' +
    'ooooooooooooooooouuuuuuuuuuuyyyyyd';
  let next = '';
  for (const ch of lower) {
    const idx = source.indexOf(ch);
    next += idx === -1 ? ch : target[idx];
  }
  return next.replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
}

function detectCanonicalProvinceCode(item) {
  const candidates = [
    pickLocalizedString(item.provinceCode34),
    pickLocalizedString(item.province_code),
    pickLocalizedString(item.provinceCode),
    pickLocalizedString(item.province_name_vi),
    pickLocalizedString(item.province_name),
    pickLocalizedString(item.province),
  ];

  for (const candidate of candidates) {
    const key = normalizeKey(candidate);
    if (!key) continue;
    const mapped = provinceMergeMap[key];
    if (mapped) return mapped;
  }
  return '';
}

function enrichDish(item) {
  const canonicalCode = detectCanonicalProvinceCode(item);
  if (!canonicalCode) {
    return item;
  }

  const seed = seedsByCode.get(canonicalCode);
  if (!seed) {
    return item;
  }

  const legacyProvinceCode =
    pickLocalizedString(item.provinceCode) ||
    pickLocalizedString(item.province_code);
  const legacyProvinceName =
    pickLocalizedString(item.province_name_vi) ||
    pickLocalizedString(item.province_name) ||
    pickLocalizedString(item.province) ||
    pickLocalizedString(item.province_code);

  return {
    ...item,
    provinceCode34: seed.code,
    provinceName34: seed.name,
    legacyProvinceCode: legacyProvinceCode || null,
    legacyProvinceName: legacyProvinceName || null,
  };
}

async function importData() {
  const BATCH_LIMIT = 500; // an toan < 500 ghi/batch
  console.log('Tong so mon can import:', data.length);

  let enrichedCount = 0;
  let unmatchedCount = 0;

  for (let i = 0; i < data.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    data.slice(i, i + BATCH_LIMIT).forEach((item) => {
      const enriched = enrichDish(item);
      if (enriched.provinceCode34) {
        enrichedCount++;
      } else {
        unmatchedCount++;
      }
      const docId = String(
        enriched.id || enriched.code || db.collection('dishes').doc().id,
      );
      batch.set(db.collection('dishes').doc(docId), enriched, { merge: true });
    });
    await batch.commit();
    console.log(
      `Da import ${Math.min(i + BATCH_LIMIT, data.length)}/${data.length}`,
    );
  }

  console.log(`Mon duoc gan provinceCode34: ${enrichedCount}`);
  console.log(`Mon chua map duoc 34 tinh: ${unmatchedCount}`);
  console.log('Import xong!');
}

importData().catch((err) => {
  console.error('Import that bai:', err);
  process.exit(1);
});
