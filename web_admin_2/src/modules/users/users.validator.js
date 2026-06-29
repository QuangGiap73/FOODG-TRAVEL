function validateUserPayload(payload = {}) {
  const data = {
    fullName: String(payload.fullName || '').trim(),
    email: String(payload.email || '').trim(),
    role: String(payload.role || 'user').trim(),
    phone: payload.phone ? String(payload.phone).trim() : '',
    gender: payload.gender ? String(payload.gender).trim() : '',
    dateOfBirth: payload.dateOfBirth ? String(payload.dateOfBirth).trim() : '',
  };

  if (payload.password !== undefined) {
    data.password = String(payload.password || '');
  }

  return data;
}

module.exports = { validateUserPayload };
