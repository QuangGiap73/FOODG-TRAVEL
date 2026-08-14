const entries = new Map();

function getCached(key) {
  const entry = entries.get(key);
  if (!entry) return undefined;
  if (entry.expiresAt <= Date.now()) {
    entries.delete(key);
    return undefined;
  }
  return entry.value;
}

function setCached(key, value, ttlMs) {
  entries.set(key, { value, expiresAt: Date.now() + Math.max(1, Number(ttlMs) || 1) });
  return value;
}

async function remember(key, ttlMs, loader) {
  const cached = getCached(key);
  if (cached !== undefined) return cached;

  const pending = Promise.resolve().then(loader);
  setCached(key, pending, ttlMs);
  try {
    const value = await pending;
    setCached(key, value, ttlMs);
    return value;
  } catch (error) {
    entries.delete(key);
    throw error;
  }
}

function forget(keyOrPrefix) {
  for (const key of entries.keys()) {
    if (key === keyOrPrefix || key.startsWith(keyOrPrefix)) entries.delete(key);
  }
}

module.exports = { getCached, setCached, remember, forget };
