const fs = require('fs');
const path = require('path');

let adminInstance = null;

function readServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }

  const localCandidates = [
    path.join(__dirname, '../../serviceAccountKey.json'),
    path.join(__dirname, '../../../web_admin/serviceAccountKey.json'),
  ];

  for (const candidate of localCandidates) {
    if (fs.existsSync(candidate)) {
      return JSON.parse(fs.readFileSync(candidate, 'utf8'));
    }
  }

  return null;
}

function getFirebaseAdmin() {
  if (adminInstance) return adminInstance;

  const admin = require('firebase-admin');
  if (!admin.apps.length) {
    const serviceAccount = readServiceAccount();
    if (!serviceAccount) {
      return null;
    }

    const credential = admin.credential.cert(serviceAccount);
    admin.initializeApp({ credential });
  }

  adminInstance = admin;
  return adminInstance;
}

module.exports = { getFirebaseAdmin };
