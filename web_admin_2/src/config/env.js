const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

const envPaths = [
  path.join(__dirname, '../../.env'),
  path.join(__dirname, '../../../.env'),
];

envPaths.forEach((envPath) => {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
  }
});

const env = {
  port: Number(process.env.PORT || 3100),
  nodeEnv: process.env.NODE_ENV || 'development',
  appName: process.env.APP_NAME || 'Food Travel Admin 2',
  sessionCookieName: process.env.SESSION_COOKIE_NAME || 'idToken',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || 'foodg-travel',
};

module.exports = { env };
