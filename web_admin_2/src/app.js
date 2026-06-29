const path = require('path');
const express = require('express');
const expressLayouts = require('express-ejs-layouts');

const { env } = require('./config/env');
const { getFirebaseAdmin } = require('./config/firebase-admin');
const { adminShell } = require('./middlewares/admin-shell.middleware');
const { notFoundMiddleware } = require('./middlewares/not-found.middleware');
const { errorMiddleware } = require('./middlewares/error.middleware');
const authRoutes = require('./modules/auth/auth.routes');
const dashboardRoutes = require('./modules/dashboard/dashboard.routes');
const usersRoutes = require('./modules/users/users.routes');
const provincesRoutes = require('./modules/provinces/provinces.routes');
const dishesRoutes = require('./modules/dishes/dishes.routes');
const postsRoutes = require('./modules/posts/posts.routes');

function createApp() {
  const app = express();

  app.set('view engine', 'ejs');
  app.set('views', path.join(__dirname, 'views'));
  app.set('layout', 'layouts/admin');

  app.use(expressLayouts);
  app.use(express.urlencoded({ extended: true }));
  app.use(express.json());
  app.use('/public', express.static(path.join(__dirname, 'public')));

  app.locals.appName = env.appName;
  app.locals.appEnv = env.nodeEnv;

  app.use(adminShell);

  app.get('/health', (_req, res) => {
    res.json({ success: true, data: { status: 'ok', app: env.appName } });
  });

  app.get('/firebase/health', async (_req, res) => {
    const admin = getFirebaseAdmin();
    if (!admin) {
      return res.status(500).json({
        success: false,
        message: 'Firebase Admin is not configured',
      });
    }

    try {
      const db = admin.firestore();
      const docRef = db.collection('monitoring').doc('connection_check');
      const payload = {
        status: 'connected',
        checkedAt: new Date().toISOString(),
      };
      await docRef.set(payload, { merge: true });
      const snapshot = await docRef.get();

      return res.json({
        success: true,
        data: snapshot.data(),
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        message: error.message || 'Firebase health check failed',
      });
    }
  });

  app.use('/', authRoutes);
  app.use('/admin', dashboardRoutes);
  app.use('/admin/users', usersRoutes);
  app.use('/admin/provinces', provincesRoutes);
  app.use('/admin/dishes', dishesRoutes);
  app.use('/admin/posts', postsRoutes);

  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
}

module.exports = { createApp };
