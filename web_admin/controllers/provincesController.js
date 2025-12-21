const streamifier = require('streamifier');
const { db } = require('../firebase/config');
const cloudinary = require('../config/cloudinary');

// Render trang quan ly mien/tinh
async function renderProvincesPage(req, res) {
  res.render('manager_provinces/manager_provinces', { pageTitle: 'Quan ly tinh thanh' });
}

// API: danh sach mien (regions)
async function listRegions(req, res) {
  try {
    const snap = await db.collection('regions').get();
    const regions = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ data: regions });
  } catch (err) {
    console.error('listRegions error:', err);
    res.status(500).json({ error: 'Failed to load regions' });
  }
}

// API: danh sach tinh theo regionCode (neu co)
async function listProvinces(req, res) {
  try {
    const regionCode = req.query.regionCode;
    let ref = db.collection('provinces');
    if (regionCode) {
      ref = ref.where('regionsCode', '==', regionCode);
    }
    const snap = await ref.get();
    const provinces = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ data: provinces });
  } catch (err) {
    console.error('listProvinces error:', err);
    res.status(500).json({ error: 'Failed to load provinces' });
  }
}

// API: them moi mien
async function addRegion(req, res) {
  try {
    const code = (req.body.code || '').trim();
    const name = (req.body.name || '').trim();
    const macroRegionRaw = (req.body.macro_region || '').trim().toLowerCase();
    const numberRaw = req.body.number;
    if (!code || !name) {
      return res.status(400).json({ error: 'Vui long nhap ma va ten mien' });
    }
    const allowedMacro = ['bac', 'trung', 'nam'];
    if (!allowedMacro.includes(macroRegionRaw)) {
      return res.status(400).json({ error: 'macro_region phai la mot trong: Bac/Trung/Nam' });
    }
    const macroRegion =
      macroRegionRaw === 'bac'
        ? 'Bac'
        : macroRegionRaw === 'trung'
        ? 'Trung'
        : 'Nam';

    const number = Number.isFinite(Number(numberRaw)) ? Number(numberRaw) : null;

    const docRef = db.collection('regions').doc(code);
    const docSnap = await docRef.get();
    if (docSnap.exists) {
      return res.status(400).json({ error: 'Ma mien da ton tai' });
    }

    await docRef.set({
      code,
      name,
      macro_region: macroRegion,
      ...(number !== null ? { number } : {}),
    });

    res
      .status(201)
      .json({ message: 'Da tao mien', data: { code, name, macro_region: macroRegion, number } });
  } catch (err) {
    console.error('addRegion error:', err);
    res.status(500).json({ error: 'Failed to add region' });
  }
}

// API: xoa mien (chan neu con tinh thanh thuoc mien do)
async function deleteRegion(req, res) {
  try {
    const code = (req.params.code || '').trim();
    if (!code) return res.status(400).json({ error: 'Thieu ma mien' });

    const provincesSnap = await db
      .collection('provinces')
      .where('regionsCode', '==', code)
      .limit(1)
      .get();
    if (!provincesSnap.empty) {
      return res.status(400).json({ error: 'Khong the xoa: con tinh thanh thuoc mien nay' });
    }

    await db.collection('regions').doc(code).delete();
    res.json({ message: 'Da xoa mien', code });
  } catch (err) {
    console.error('deleteRegion error:', err);
    res.status(500).json({ error: 'Failed to delete region' });
  }
}

// API: them tinh thanh
async function addProvince(req, res) {
  try {
    const code = (req.body.code || '').trim();
    const name = (req.body.name || '').trim();
    const regionsCode = (req.body.regionsCode || '').trim();
    const description = (req.body.description || '').trim();
    const imageUrl = (req.body.imageUrl || '').trim();
    const slug = (req.body.slug || '').trim();
    const centerLat = Number(req.body.centerLat) || 0;
    const centerLng = Number(req.body.centerLng) || 0;

    if (!code || !name || !regionsCode) {
      return res.status(400).json({ error: 'Ma tinh, ten tinh va ma mien la bat buoc' });
    }

    const regionSnap = await db.collection('regions').doc(regionsCode).get();
    if (!regionSnap.exists) {
      return res.status(400).json({ error: 'Ma mien khong ton tai' });
    }

    const docRef = db.collection('provinces').doc(code);
    const docSnap = await docRef.get();
    if (docSnap.exists) {
      return res.status(400).json({ error: 'Ma tinh da ton tai' });
    }

    await docRef.set({
      code,
      name,
      regionsCode,
      description: description || '',
      imageUrl: imageUrl || '',
      slug: slug || code,
      centerLat,
      centerLng,
      createdAt: new Date().toISOString(),
    });

    res.status(201).json({ message: 'Da tao tinh thanh', data: { code, name, regionsCode } });
  } catch (err) {
    console.error('addProvince error:', err);
    res.status(500).json({ error: 'Failed to add province' });
  }
}

// Upload anh tinh thanh len Cloudinary
async function uploadProvinceImage(req, res) {
  try {
    if (!req.file) return res.status(400).json({ error: 'Chua chon file anh' });

    const folder = process.env.CLOUDINARY_FOLDER || 'provinces';
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'image' },
      (error, result) => {
        if (error) {
          console.error('Cloudinary upload error:', error);
          return res.status(500).json({ error: 'Upload anh that bai', detail: error.message });
        }
        return res.json({ url: result.secure_url, public_id: result.public_id });
      },
    );

    streamifier.createReadStream(req.file.buffer).pipe(uploadStream);
  } catch (err) {
    console.error('uploadProvinceImage error:', err);
    res.status(500).json({ error: 'Upload anh that bai' });
  }
}

// API: cap nhat tinh thanh
async function updateProvince(req, res) {
  try {
    const code = (req.params.code || req.body.code || '').trim();
    const name = (req.body.name || '').trim();
    const regionsCode = (req.body.regionsCode || '').trim();
    const description = (req.body.description || '').trim();
    const imageUrl = (req.body.imageUrl || '').trim();
    const slug = (req.body.slug || '').trim();
    const centerLat = Number(req.body.centerLat) || 0;
    const centerLng = Number(req.body.centerLng) || 0;

    if (!code || !name || !regionsCode) {
      return res.status(400).json({ error: 'Ma tinh, ten tinh va ma mien la bat buoc' });
    }

    const docRef = db.collection('provinces').doc(code);
    const docSnap = await docRef.get();
    if (!docSnap.exists) return res.status(404).json({ error: 'Tinh thanh khong ton tai' });

    const regionSnap = await db.collection('regions').doc(regionsCode).get();
    if (!regionSnap.exists) return res.status(400).json({ error: 'Ma mien khong ton tai' });

    await docRef.set(
      {
        code,
        name,
        regionsCode,
        description,
        imageUrl,
        slug: slug || code,
        centerLat,
        centerLng,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );

    res.json({ message: 'Da cap nhat tinh thanh', data: { code, name, regionsCode } });
  } catch (err) {
    console.error('updateProvince error:', err);
    res.status(500).json({ error: 'Failed to update province' });
  }
}

module.exports = {
  renderProvincesPage,
  listRegions,
  listProvinces,
  addRegion,
  deleteRegion,
  addProvince,
  uploadProvinceImage,
  updateProvince,
};
