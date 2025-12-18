const { db, admin } = require('../firebase/config');
const ExcelJS = require('exceljs');

// Render trang quan ly tai khoan
async function renderUserManager(req, res) {
  try {
    res.render('manager_uses/manager_uses', { pageTitle: 'Quan ly tai khoan' });
  } catch (error) {
    console.error('Error rendering manager uses:', error);
    res.status(500).send('Error rendering manager uses');
  }
}

// API lay danh sach user
async function listUsers(req, res) {
  try {
    const snap = await db.collection('users').get();
    let users = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const sort = (req.query?.sort || '').toLowerCase();
    if (sort === 'name-asc' || sort === 'name-desc') {
      const asc = sort === 'name-asc';
      const getLast = (v) => {
        const parts = (v.fullName || '').trim().toLowerCase().split(/\s+/);
        return parts.length ? parts[parts.length - 1] : '';
      };
      users = users.sort((a, b) => {
        const aLast = getLast(a);
        const bLast = getLast(b);
        if (aLast < bLast) return asc ? -1 : 1;
        if (aLast > bLast) return asc ? 1 : -1;
        return 0;
      });
    } else if (sort === 'created-asc' || sort === 'created-desc') {
      const asc = sort === 'created-asc';
      const getTime = (val) => {
        if (!val) return 0;
        if (typeof val === 'object' && val._seconds) return val._seconds * 1000;
        const t = new Date(val).getTime();
        return isNaN(t) ? 0 : t;
      };
      users = users.sort((a, b) => {
        const ta = getTime(a.createdAt);
        const tb = getTime(b.createdAt);
        return asc ? ta - tb : tb - ta;
      });
    }

    res.json({ data: users });
  } catch (err) {
    console.error('users api error:', err);
    res.status(500).json({ error: 'Failed to load users' });
  }
}

// API xoa user theo id
async function deleteUser(req, res) {
  try {
    const { id } = req.params;
    if (!id) {
      return res.status(400).json({ error: 'Missing user id' });
    }

    // Lay doc de biet uid chinh xac (phong truong hop doc id khac uid)
    const docSnap = await db.collection('users').doc(id).get();
    const docData = docSnap.exists ? docSnap.data() : null;
    const authUid = docData?.authUid || id;

    // Xoa tai khoan trong Firebase Auth (bo qua neu khong ton tai)
    try {
      await admin.auth().deleteUser(authUid);
      console.log('[deleteUser] deleted auth uid:', authUid);
    } catch (e) {
      if (e?.code !== 'auth/user-not-found') {
        console.error('[deleteUser] delete auth failed:', e);
        return res.status(500).json({ error: 'Failed to delete auth user', code: e.code });
      }
    }

    // Xoa document trong Firestore
    await db.collection('users').doc(id).delete();
    console.log('[deleteUser] deleted firestore doc:', id);
    res.json({ ok: true });
  } catch (err) {
    console.error('delete user error:', err);
    res.status(500).json({ error: 'Failed to delete user' });
  }
}

// API tao user moi (Auth + Firestore)
async function createUser(req, res) {
  try {
    const { email, password, fullName, phone, role } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: 'Missing email or password' });
    }

    const normalizedRole = role || 'user';

    // Tao tai khoan trong Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: fullName || '',
    });

    // Gan custom claims
    if (normalizedRole === 'admin') {
      await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true, role: 'admin' });
    } else {
      await admin.auth().setCustomUserClaims(userRecord.uid, { role: normalizedRole });
    }

    // Luu Firestore
    const payload = {
      email,
      fullName: fullName || '',
      phone: phone || null,
      role: normalizedRole,
      authUid: userRecord.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection('users').doc(userRecord.uid).set(payload);

    res.status(201).json({ ok: true, id: userRecord.uid });
  } catch (err) {
    console.error('create user error:', err);
    const badRequestCodes = ['auth/email-already-exists', 'auth/invalid-password', 'auth/invalid-email'];
    if (badRequestCodes.includes(err?.code)) {
      return res.status(400).json({ error: err.code });
    }
    res.status(500).json({ error: 'Failed to create user' });
  }
}
// cap nhat va chinh sua user
async function updateUser(req, res){
  try{
    const { id } = req.params;
    const {email, fullName, phone, role } = req.body || {};
    if (!id) return res.status(400).json({error: 'Missing id'});
    if(!email) return res.status(400).json({error:'Missing email'});

    // lay doc để biết uid thật ( tránh id != uid)
    const docSnap = await db.collection('users').doc(id).get();
    if(!docSnap.exists) return res.status(404).json({ error: 'User not found'});
    const docData = docSnap.data();
    const authUid = docData?.authUid || id;

    // cap nhat auth
    await admin.auth().updateUser(authUid, {
      email,
      displayName: fullName || '',
    });
    // Cập nhật claims nếu đổi role
    const normalizedRole = role || docData?.role || 'user';
    const claims = normalizedRole === 'admin'
      ? { admin: true, role: 'admin' }
      : { role: normalizedRole };
    await admin.auth().setCustomUserClaims(authUid, claims);

    // Cập nhật Firestore
    await db.collection('users').doc(id).set(
      {
        email,
        fullName: fullName || '',
        phone: phone || null,
        role: normalizedRole,
        authUid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    res.json({ ok: true });
} catch (err) {
  console.error('update user error:', err);
  const badCodes = ['auth/email-already-exists', 'auth/invalid-email'];
  if (badCodes.includes(err?.code)) return res.status(400).json({ error: err.code });
  res.status(500).json({ error: 'Failed to update user' });
}
}

// Export danh sach user ra Excel
async function exportUsersExcel(req, res) {
  try {
    const snap = await db.collection('users').get();
    let users = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const sort = (req.query?.sort || '').toLowerCase();
    if (sort === 'name-asc' || sort === 'name-desc') {
      const asc = sort === 'name-asc';
      const getLast = (v) => {
        const parts = (v.fullName || '').trim().toLowerCase().split(/\s+/);
        return parts.length ? parts[parts.length - 1] : '';
      };
      users = users.sort((a, b) => {
        const aLast = getLast(a);
        const bLast = getLast(b);
        if (aLast < bLast) return asc ? -1 : 1;
        if (aLast > bLast) return asc ? 1 : -1;
        return 0;
      });
    } else if (sort === 'created-asc' || sort === 'created-desc') {
      const asc = sort === 'created-asc';
      const getTime = (val) => {
        if (!val) return 0;
        if (typeof val === 'object' && val._seconds) return val._seconds * 1000;
        const t = new Date(val).getTime();
        return isNaN(t) ? 0 : t;
      };
      users = users.sort((a, b) => {
        const ta = getTime(a.createdAt);
        const tb = getTime(b.createdAt);
        return asc ? ta - tb : tb - ta;
      });
    }

    const workbook = new ExcelJS.Workbook();
    const ws = workbook.addWorksheet('Users');
    ws.columns = [
      { header: 'Ho ten', key: 'fullName', width: 30 },
      { header: 'Email', key: 'email', width: 30 },
      { header: 'Phone', key: 'phone', width: 18 },
      { header: 'Vai tro', key: 'role', width: 12 },
      { header: 'Ngay tao', key: 'createdAt', width: 22 },
    ];

    users.forEach(u => {
      ws.addRow({
        fullName: u.fullName || '',
        email: u.email || '',
        phone: u.phone || '',
        role: u.role || '',
        createdAt: u.createdAt?._seconds ? new Date(u.createdAt._seconds * 1000).toLocaleString('vi-VN') : '',
      });
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=users.xlsx');
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error('export users error:', err);
    res.status(500).send('Failed to export users');
  }
}



module.exports = { renderUserManager, listUsers, deleteUser, createUser, updateUser, exportUsersExcel };
