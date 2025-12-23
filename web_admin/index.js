require('dotenv').config();
const path = require('path');
const express = require('express');
const expressLayouts = require('express-ejs-layouts');
const { requireAdmin, requireUser, getRoleFromClaims } = require('./middlewares/auth');

const { db, checkFirebaseConnection } = require('./firebase/config');
const managerUsesRouter = require('./routes/managerUses');
const managerProvincesRouter = require('./routes/managerProvinces');
const managerDishesRouter = require('./routes/managerDishes');

const app = express();
const PORT = process.env.PORT || 3000;
// đọc dữ liệu từ form
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.set('layout', 'layout');

app.use(expressLayouts);
app.use(express.static(path.join(__dirname, 'public')));

// Expose current path for active menu states
app.use((req, res, next) => {
  res.locals.currentPath = req.path;
  next();
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// App user profile endpoint (role: user or admin)
app.get('/api/user/me', requireUser, (req, res) => {
  const role = getRoleFromClaims(req.user);
  res.json({
    uid: req.user.uid,
    email: req.user.email || null,
    role: role || null,
    auth_time: req.user.auth_time,
  });
});

app.get('/login', (req, res) => {
  res.render('login', { layout: false, pageTitle: 'Dang nhap' });
});

app.get('/register', (req, res) => {
  res.render('register', { layout: false, pageTitle: 'Dang ky' });
});

app.get(['/', '/dashboard'], requireAdmin, (req, res) => {
  res.render('dashboard', { pageTitle: 'Trang chu' });
});

app.get('/landing', (req, res) => {
  res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

app.use('/manager-uses', managerUsesRouter);
app.use('/manager-provinces', managerProvincesRouter);
app.use('/manager-dishes', managerDishesRouter);
app.get('/test-firebase', async (req, res) => {
  try {
    // Test writing a sample document to Firestore
    const docRef = db.collection('test').doc('connection_check');
    await docRef.set({
      status: 'connected',
      time: new Date().toISOString(),
    });

    res.json({ message: 'Ket noi Firebase thanh cong!' });
  } catch (error) {
    console.error('Loi Firebase:', error);
    res.status(500).json({ message: 'Ket noi Firebase that bai!', error: error.message });
  }
});

// Endpoint kiem tra nhanh trang thai ket noi Firebase
app.get('/firebase/health', async (req, res) => {
  try {
    const data = await checkFirebaseConnection();
    res.json({ ok: true, message: 'Firebase san sang', data });
    console.log('[firebase/health] ok:', data);
  } catch (error) {
    console.error('Firebase health check loi:', error);
    res.status(500).json({ ok: false, message: 'Firebase khong phan hoi', error: error.message });
  }
});

// Catch-all 404 handler should be registered after all other routes
app.use((req, res) => {
  if (req.accepts('json')) {
    res.status(404).json({ error: 'Not found' });
  } else {
    res.status(404).send('Not found');
  }
});

// Log Firebase health status to the terminal on startup
async function logStartupHealthCheck() {
  try {
    const data = await checkFirebaseConnection();
    console.log('[startup] Firebase ok:', data);
  } catch (error) {
    console.error('[startup] Firebase health check failed:', error.message);
  }
}

app.listen(PORT, () => {
  console.log(`Admin demo dang chay tai http://localhost:${PORT}`);
  logStartupHealthCheck();
});
