// Usage: node scripts/import_dishes.js [path/to/data.json]
// Đọc file JSON (mảng món ăn) và import vào Firestore collection "dishes".

const fs = require('fs');
const path = require('path');

// Reuse Firebase Admin đã cấu hình trong dự án
const { db } = require('../firebase/config');

// Lấy đường dẫn file JSON (mặc định: web_admin/data.json)
const dataPath = process.argv[2] || path.join(__dirname, '..', 'data1.json');
if (!fs.existsSync(dataPath)) {
  console.error('Không tìm thấy file:', dataPath);
  process.exit(1);
}

const raw = fs.readFileSync(dataPath, 'utf8');
let data;
try {
  data = JSON.parse(raw);
} catch (err) {
  console.error('Không parse được JSON:', err.message);
  process.exit(1);
}

if (!Array.isArray(data)) {
  console.error('data.json phải là mảng object.');
  process.exit(1);
}

async function importData() {
  const BATCH_LIMIT = 500; // an toàn < 500 ghi/batch
  console.log('Tổng số món cần import:', data.length);

  for (let i = 0; i < data.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    data.slice(i, i + BATCH_LIMIT).forEach((item) => {
      const docId = String(item.id || item.code || db.collection('dishes').doc().id);
      batch.set(db.collection('dishes').doc(docId), item, { merge: true });
    });
    await batch.commit();
    console.log(`Đã import ${Math.min(i + BATCH_LIMIT, data.length)}/${data.length}`);
  }
  console.log('Import xong!');
}

importData().catch((err) => {
  console.error('Import thất bại:', err);
  process.exit(1);
});
