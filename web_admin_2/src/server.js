const { createApp } = require('./app');
const { env } = require('./config/env');

const app = createApp();

app.listen(env.port, () => {
  console.log(`[web_admin_2] listening on http://localhost:${env.port}`);
});
