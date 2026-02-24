const { db, admin } = require('../firebase/config');

// Render page
async function renderPostsPage(req, res) {
  try {
    res.render('manager_posts/manager_posts', { pageTitle: 'Quan ly bai viet' });
  } catch (error) {
    console.error('Error rendering manager posts:', error);
    res.status(500).send('Error rendering manager posts');
  }
}

// List posts (optionally filter by status + search)
async function listPosts(req, res) {
  try {
    const q = (req.query.q || '').toString().trim().toLowerCase();
    const status = (req.query.status || 'all').toString().trim().toLowerCase();
    const limitRaw = Number(req.query.limit || 200);
    const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 500) : 200;

    let ref = db.collection('posts').orderBy('createdAt', 'desc').limit(limit);
    const snap = await ref.get();
    let posts = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    if (status && status !== 'all') {
      posts = posts.filter((p) => (p.status || 'active') === status);
    }

    if (q) {
      posts = posts.filter((p) => {
        const author = (p.authorName || '').toString().toLowerCase();
        const text = (p.text || '').toString().toLowerCase();
        const placeName = (p.placeSnapshot?.name || '').toString().toLowerCase();
        const placeAddr = (p.placeSnapshot?.address || '').toString().toLowerCase();
        const placeId = (p.placeId || '').toString().toLowerCase();
        return (
          author.includes(q) ||
          text.includes(q) ||
          placeName.includes(q) ||
          placeAddr.includes(q) ||
          placeId.includes(q)
        );
      });
    }

    res.json({ data: posts });
  } catch (err) {
    console.error('listPosts error:', err);
    res.status(500).json({ error: 'Failed to load posts' });
  }
}

// Update post status: active / deleted (soft delete)
async function updatePostStatus(req, res) {
  try {
    const { id } = req.params;
    const nextStatus = (req.body?.status || '').toString().trim().toLowerCase();
    if (!id) return res.status(400).json({ error: 'Missing post id' });
    if (!['active', 'deleted'].includes(nextStatus)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const data = {
      status: nextStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (nextStatus === 'deleted') {
      data.deletedAt = admin.firestore.FieldValue.serverTimestamp();
    } else {
      data.deletedAt = admin.firestore.FieldValue.delete();
    }

    await db.collection('posts').doc(id).set(data, { merge: true });
    res.json({ ok: true });
  } catch (err) {
    console.error('updatePostStatus error:', err);
    res.status(500).json({ error: 'Failed to update status' });
  }
}

module.exports = {
  renderPostsPage,
  listPosts,
  updatePostStatus,
};
