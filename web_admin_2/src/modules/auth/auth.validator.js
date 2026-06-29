function validateLoginPayload(payload = {}) {
  return {
    email: String(payload.email || '').trim(),
    password: String(payload.password || ''),
  };
}

module.exports = { validateLoginPayload };
