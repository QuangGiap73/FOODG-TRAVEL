document.addEventListener('DOMContentLoaded', () => {
  const tbody = document.getElementById('post-table-body');
  const searchInput = document.getElementById('post-search');
  const statusSelect = document.getElementById('post-status');
  const btnSearch = document.getElementById('btn-search-post');
  const btnReset = document.getElementById('btn-reset-post');
  const selectAll = document.getElementById('select-all-posts');
  const bulkActions = document.getElementById('bulk-actions-posts');
  const selectedCount = document.getElementById('selected-count-posts');
  const btnDeleteSelected = document.getElementById('btn-delete-selected-posts');
  const btnRestoreSelected = document.getElementById('btn-restore-selected-posts');
  const pageInfo = document.getElementById('post-page-info');
  const pageList = document.getElementById('post-page-list');

  const detailModalEl = document.getElementById('postDetailModal');
  const detailModal = detailModalEl && window.bootstrap ? new bootstrap.Modal(detailModalEl) : null;
  const detailEls = {
    author: document.getElementById('post-detail-author'),
    uid: document.getElementById('post-detail-uid'),
    text: document.getElementById('post-detail-text'),
    place: document.getElementById('post-detail-place'),
    placeAddr: document.getElementById('post-detail-place-addr'),
    status: document.getElementById('post-detail-status'),
    like: document.getElementById('post-detail-like'),
    comment: document.getElementById('post-detail-comment'),
    created: document.getElementById('post-detail-created'),
    media: document.getElementById('post-detail-media'),
    mediaEmpty: document.getElementById('post-detail-media-empty'),
  };

  const PAGE_SIZE = 30;
  let currentPage = 1;
  let currentList = [];

  function formatDate(val) {
    if (!val) return '-';
    if (typeof val === 'object' && val._seconds) {
      return new Date(val._seconds * 1000).toLocaleString('vi-VN');
    }
    const t = new Date(val);
    return isNaN(t) ? '-' : t.toLocaleString('vi-VN');
  }

  function textShort(text, max = 80) {
    const raw = String(text || '').trim();
    if (!raw) return '-';
    if (raw.length <= max) return raw;
    return `${raw.slice(0, max)}...`;
  }

  function getPlace(post) {
    return post.placeSnapshot || post.place || null;
  }

  function getMedia(post) {
    return Array.isArray(post.media) ? post.media : [];
  }

  function refreshBulkState() {
    if (!tbody) return;
    const checked = tbody.querySelectorAll('.row-check:checked').length;
    const total = tbody.querySelectorAll('.row-check').length;
    if (selectedCount) selectedCount.textContent = `${checked} da chon`;
    if (btnDeleteSelected) btnDeleteSelected.disabled = checked === 0;
    if (btnRestoreSelected) btnRestoreSelected.disabled = checked === 0;
    if (bulkActions) {
      if (checked > 0) bulkActions.classList.remove('d-none');
      else bulkActions.classList.add('d-none');
    }
    if (selectAll) {
      selectAll.checked = total > 0 && checked === total;
      selectAll.indeterminate = checked > 0 && checked < total;
    }
  }

  function renderPagination(totalPages, total, start, count) {
    if (!pageList) return;
    if (pageInfo) {
      const from = total === 0 ? 0 : start + 1;
      const to = start + count;
      pageInfo.textContent = total ? `Hien thi ${from}-${to} / ${total}` : '';
    }
    pageList.innerHTML = '';
    if (totalPages <= 1) return;

    const addItem = (label, page, disabled, active) => {
      const li = document.createElement('li');
      li.className = `page-item${active ? ' active' : ''}${disabled ? ' disabled' : ''}`;
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'page-link';
      btn.textContent = label;
      btn.dataset.page = page;
      if (disabled) btn.disabled = true;
      li.appendChild(btn);
      pageList.appendChild(li);
    };

    addItem('<', currentPage - 1, currentPage === 1, false);
    for (let p = 1; p <= totalPages; p += 1) {
      addItem(String(p), p, false, p === currentPage);
    }
    addItem('>', currentPage + 1, currentPage === totalPages, false);
  }

  function renderTable(list, offset = 0) {
    if (!tbody) return;
    if (!list.length) {
      tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted">Khong co bai viet</td></tr>';
      refreshBulkState();
      return;
    }

    const rows = list.map((item) => {
      const author = item.authorName || 'Unknown';
      const place = getPlace(item);
      const placeName = place?.name || '-';
      const placeAddr = place?.address || '';
      const media = getMedia(item);
      const mediaCount = media.length;
      const likeCount = Number(item.likeCount || 0);
      const commentCount = Number(item.commentCount || 0);
      const status = (item.status || 'active').toLowerCase();
      const statusLabel = status === 'deleted' ? 'Da an' : 'Dang hien';
      const statusBadge = status === 'deleted' ? 'badge-soft-secondary' : 'badge-soft-success';
      const created = formatDate(item.createdAt);
      const text = textShort(item.text, 90);

      const actionDelete = status === 'deleted'
        ? '<button class="dropdown-item text-success" type="button" data-action="restore" data-id="' + item.id + '">Khoi phuc</button>'
        : '<button class="dropdown-item text-danger" type="button" data-action="delete" data-id="' + item.id + '">Xoa mem</button>';

      return `
        <tr data-id="${item.id}">
          <td><input type="checkbox" class="row-check" data-id="${item.id}"></td>
          <td>
            <div class="fw-semibold">${author}</div>
            <div class="text-muted small">${item.authorId || ''}</div>
          </td>
          <td>
            <div class="cell-ellipsis" style="max-width: 260px;">${text}</div>
          </td>
          <td>
            <div class="cell-ellipsis" style="max-width: 200px;">${placeName}</div>
            <div class="text-muted small cell-ellipsis" style="max-width: 200px;">${placeAddr}</div>
          </td>
          <td class="text-center">${mediaCount}</td>
          <td class="text-center">${likeCount}</td>
          <td class="text-center">${commentCount}</td>
          <td class="text-center"><span class="badge ${statusBadge}">${statusLabel}</span></td>
          <td>${created}</td>
          <td class="text-center">
            <div class="dropdown">
              <button class="btn btn-sm btn-light dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                <i class="bi-three-dots-vertical"></i>
              </button>
              <ul class="dropdown-menu dropdown-menu-end">
                <li><button class="dropdown-item" type="button" data-action="view" data-id="${item.id}">Xem</button></li>
                <li>${actionDelete}</li>
              </ul>
            </div>
          </td>
        </tr>
      `;
    }).join('');

    tbody.innerHTML = rows;
    refreshBulkState();

    tbody.querySelectorAll('.dropdown-item').forEach((btn) => {
      btn.addEventListener('click', async (e) => {
        const action = e.currentTarget.dataset.action;
        const id = e.currentTarget.dataset.id;
        if (!id) return;
        if (action === 'view') {
          const post = currentList.find((p) => String(p.id) === String(id));
          if (post) openDetail(post);
        } else if (action === 'delete') {
          const ok = confirm('Ban chac chan muon an bai viet nay?');
          if (!ok) return;
          await updateStatus(id, 'deleted');
        } else if (action === 'restore') {
          const ok = confirm('Khoi phuc bai viet nay?');
          if (!ok) return;
          await updateStatus(id, 'active');
        }
      });
    });
  }

  function renderPage() {
    const total = currentList.length;
    const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
    if (currentPage > totalPages) currentPage = totalPages;
    const start = (currentPage - 1) * PAGE_SIZE;
    const pageItems = currentList.slice(start, start + PAGE_SIZE);
    renderTable(pageItems, start);
    renderPagination(totalPages, total, start, pageItems.length);
  }

  async function loadPosts() {
    if (!tbody) return;
    const q = encodeURIComponent((searchInput?.value || '').trim());
    const status = encodeURIComponent((statusSelect?.value || 'all').trim());
    tbody.innerHTML = '<tr><td colspan="10" class="text-center text-muted">Dang tai...</td></tr>';
    try {
      const res = await fetch(`/manager-posts/api/posts?q=${q}&status=${status}&limit=500`);
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || 'Tai bai viet that bai');
      currentList = Array.isArray(body.data) ? body.data : [];
      currentPage = 1;
      renderPage();
    } catch (err) {
      console.error(err);
      tbody.innerHTML = `<tr><td colspan="10" class="text-center text-danger">${err.message || 'Loi tai du lieu'}</td></tr>`;
      currentList = [];
      currentPage = 1;
      if (pageInfo) pageInfo.textContent = '';
      if (pageList) pageList.innerHTML = '';
    }
  }

  async function updateStatus(id, status, options = {}) {
    try {
      const res = await fetch(`/manager-posts/api/posts/${encodeURIComponent(id)}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || 'Cap nhat that bai');
      const shouldReload = options.reload !== false;
      if (shouldReload) await loadPosts();
      if (window.notify) {
        if (status === 'deleted') window.notify.success('Da an bai viet');
        else window.notify.success('Da khoi phuc bai viet');
      }
    } catch (err) {
      alert(err.message || 'Cap nhat that bai');
    }
  }

  function showDetailModal() {
    if (!detailModalEl) return;
    if (detailModal) {
      detailModal.show();
      return;
    }
    detailModalEl.style.display = 'block';
    detailModalEl.classList.add('show');
    document.body.classList.add('modal-open');
  }

  function hideDetailModal() {
    if (!detailModalEl) return;
    if (detailModal) {
      detailModal.hide();
      return;
    }
    detailModalEl.classList.remove('show');
    detailModalEl.style.display = 'none';
    document.body.classList.remove('modal-open');
  }

  function openDetail(post) {
    if (!detailModalEl) return;
    const place = getPlace(post);
    const media = getMedia(post);
    const status = (post.status || 'active').toLowerCase();

    if (detailEls.author) detailEls.author.textContent = post.authorName || 'Unknown';
    if (detailEls.uid) detailEls.uid.textContent = post.authorId || '-';
    if (detailEls.text) detailEls.text.textContent = (post.text || '').trim() || '-';
    if (detailEls.place) detailEls.place.textContent = place?.name || '-';
    if (detailEls.placeAddr) detailEls.placeAddr.textContent = place?.address || '';
    if (detailEls.status) {
      detailEls.status.textContent = status === 'deleted' ? 'Da an' : 'Dang hien';
      detailEls.status.className = status === 'deleted' ? 'badge badge-soft-secondary' : 'badge badge-soft-success';
    }
    if (detailEls.like) detailEls.like.textContent = `Like: ${Number(post.likeCount || 0)}`;
    if (detailEls.comment) detailEls.comment.textContent = `Comment: ${Number(post.commentCount || 0)}`;
    if (detailEls.created) detailEls.created.textContent = `Created: ${formatDate(post.createdAt)}`;

    if (detailEls.media) {
      detailEls.media.innerHTML = '';
      if (!media.length) {
        if (detailEls.mediaEmpty) detailEls.mediaEmpty.style.display = 'block';
      } else {
        if (detailEls.mediaEmpty) detailEls.mediaEmpty.style.display = 'none';
        media.forEach((m) => {
          const url = m?.url || '';
          if (!url) return;
          const wrap = document.createElement('div');
          wrap.style.width = '96px';
          wrap.style.height = '96px';
          wrap.innerHTML = `<img src="${url}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:8px;border:1px solid #eee;">`;
          detailEls.media.appendChild(wrap);
        });
      }
    }

    showDetailModal();
  }

  // Event handlers
  btnSearch?.addEventListener('click', loadPosts);
  btnReset?.addEventListener('click', () => {
    if (searchInput) searchInput.value = '';
    if (statusSelect) statusSelect.value = 'all';
    loadPosts();
  });
  searchInput?.addEventListener('keyup', (e) => {
    if (e.key === 'Enter') loadPosts();
  });
  statusSelect?.addEventListener('change', loadPosts);

  selectAll?.addEventListener('change', () => {
    tbody?.querySelectorAll('.row-check').forEach((ch) => {
      ch.checked = selectAll.checked;
    });
    refreshBulkState();
  });

  tbody?.addEventListener('change', (e) => {
    if (e.target.classList.contains('row-check')) refreshBulkState();
  });

  btnDeleteSelected?.addEventListener('click', async () => {
    const ids = Array.from(tbody.querySelectorAll('.row-check:checked')).map((ch) => ch.dataset.id);
    if (!ids.length) return;
    if (!confirm(`An ${ids.length} bai viet?`)) return;
    await Promise.all(ids.map((id) => updateStatus(id, 'deleted', { reload: false })));
    await loadPosts();
  });

  btnRestoreSelected?.addEventListener('click', async () => {
    const ids = Array.from(tbody.querySelectorAll('.row-check:checked')).map((ch) => ch.dataset.id);
    if (!ids.length) return;
    if (!confirm(`Khoi phuc ${ids.length} bai viet?`)) return;
    await Promise.all(ids.map((id) => updateStatus(id, 'active', { reload: false })));
    await loadPosts();
  });

  pageList?.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-page]');
    if (!btn) return;
    const page = Number(btn.dataset.page);
    if (!Number.isFinite(page) || page < 1) return;
    currentPage = page;
    renderPage();
  });

  // Fallback dropdown toggle if Bootstrap JS is missing
  document.addEventListener('click', (e) => {
    const toggleBtn = e.target.closest('[data-bs-toggle="dropdown"]');
    const openMenus = document.querySelectorAll('.dropdown-menu.show');
    if (toggleBtn) {
      const menu = toggleBtn.parentElement?.querySelector('.dropdown-menu');
      openMenus.forEach((m) => {
        if (m !== menu) m.classList.remove('show');
      });
      if (menu) menu.classList.toggle('show');
      e.preventDefault();
      e.stopPropagation();
    } else {
      openMenus.forEach((m) => m.classList.remove('show'));
    }
  });

  // Close detail modal (fallback when Bootstrap JS is missing)
  detailModalEl
    ?.querySelectorAll('[data-bs-dismiss="modal"], .btn-close, .btn-secondary')
    .forEach((btn) => {
      btn.addEventListener('click', hideDetailModal);
    });
  detailModalEl?.addEventListener('click', (e) => {
    if (!detailModal && e.target === detailModalEl) hideDetailModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') hideDetailModal();
  });

  loadPosts();
});

