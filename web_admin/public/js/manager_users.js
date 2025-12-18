document.addEventListener('DOMContentLoaded', () => {
  const tbody = document.querySelector('#users-table tbody');
  const addUserModalEl = document.getElementById('addUserModal');
  const addUserModal = window.bootstrap && addUserModalEl ? new bootstrap.Modal(addUserModalEl) : null;
  const addUserForm = document.getElementById('add-user-form');
  const addUserError = document.getElementById('add-user-error');
  const selectAll = document.getElementById('select-all');
  const bulkActions = document.getElementById('bulk-actions');
  const selectedCountEl = document.getElementById('selected-count');
  const btnDeleteSelected = document.getElementById('btn-delete-selected');
  const searchInput = document.getElementById('search-user');
  const searchBtn = document.getElementById('btn-search-user');
  const resetBtn = document.getElementById('btn-reset-users');
  const sortOptions = document.querySelectorAll('.sort-option');
  let usersCache = [];
  let sortState = { key: null, asc: true };

  function clearFieldErrors() {
    if (!addUserForm) return;
    addUserForm.querySelectorAll('.is-invalid').forEach((el) => el.classList.remove('is-invalid'));
    if (addUserError) addUserError.textContent = '';
  }

  function setFieldError(input, message) {
    if (input) input.classList.add('is-invalid');
    if (addUserError && message) addUserError.textContent = message;
  }

  function openAddModal() {
    if (addUserForm) addUserForm.reset();
    clearFieldErrors();
    if (addUserModal) {
      addUserModal.show();
    } else if (addUserModalEl) {
      addUserModalEl.style.display = 'block';
    }
  }

  function closeAddModal() {
    if (addUserModal) {
      addUserModal.hide();
    } else if (addUserModalEl) {
      addUserModalEl.style.display = 'none';
    }
  }

  function refreshBulkState() {
    if (!tbody) return;
    const checked = tbody.querySelectorAll('.row-check:checked').length;
    const total = tbody.querySelectorAll('.row-check').length;
    if (selectedCountEl) selectedCountEl.textContent = `${checked} da chon`;
    if (btnDeleteSelected) btnDeleteSelected.disabled = checked === 0;
    if (bulkActions) {
      if (checked > 0) {
        bulkActions.classList.remove('d-none');
      } else {
        bulkActions.classList.add('d-none');
      }
    }
    if (selectAll) {
      selectAll.checked = total > 0 && checked === total;
      selectAll.indeterminate = checked > 0 && checked < total;
    }
  }

  function applySort(list) {
    if (!sortState.key) return list;
    const asc = sortState.asc;
    const key = sortState.key;
    const getTime = (val) => {
      if (!val) return 0;
      if (typeof val === 'object' && val._seconds) return val._seconds * 1000;
      const t = new Date(val).getTime();
      return isNaN(t) ? 0 : t;
    };
    const getLast = (u) => {
      const parts = (u.fullName || '').trim().toLowerCase().split(/\s+/);
      return parts.length ? parts[parts.length - 1] : '';
    };
    return [...list].sort((a, b) => {
      if (key === 'name') {
        const aLast = getLast(a);
        const bLast = getLast(b);
        if (aLast < bLast) return asc ? -1 : 1;
        if (aLast > bLast) return asc ? 1 : -1;
        return 0;
      }
      if (key === 'createdAt') {
        const ta = getTime(a.createdAt);
        const tb = getTime(b.createdAt);
        return asc ? ta - tb : tb - ta;
      }
      return 0;
    });
  }

  function renderUsers(list) {
    if (!tbody) return;
    if (!list.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted">Khong co thong tin ve tai khoan nay</td></tr>';
      refreshBulkState();
      return;
    }
    const sorted = applySort(list);
    tbody.innerHTML = sorted
      .map(
        (u) => `
      <tr data-id="${u.id}">
        <td><input type="checkbox" class="row-check" data-id="${u.id}"></td>
        <td>${u.email || ''}</td>
        <td>${u.fullName || ''}</td>
        <td>${u.role || ''}</td>
        <td>${u.phone || ''}</td>
        <td>${u.createdAt ? new Date(u.createdAt._seconds ? u.createdAt._seconds * 1000 : u.createdAt).toLocaleString('vi-VN') : ''}</td>
        <td class="text-center">
          <div class="dropdown">
            <button class="btn btn-sm btn-light dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
              <i class="bi-three-dots-vertical"></i>
            </button>
            <ul class="dropdown-menu dropdown-menu-end">
              <li><button class="dropdown-item" type="button" data-action="view" data-id="${u.id}">Xem</button></li>
              <li><button class="dropdown-item" type="button" data-action="edit" data-id="${u.id}">Sua</button></li>
              <li><button class="dropdown-item text-danger" type="button" data-action="delete" data-id="${u.id}">Xoa</button></li>
            </ul>
          </div>
        </td>
      </tr>
    `,
      )
      .join('');

    refreshBulkState();

    tbody.querySelectorAll('.dropdown-item').forEach((btn) => {
      btn.addEventListener('click', async (e) => {
        const action = e.currentTarget.dataset.action;
        const userId = e.currentTarget.dataset.id;
        if (action === 'delete') {
          const ok = confirm('Ban chac chan muon xoa user nay?');
          if (!ok) return;
          try {
            const delRes = await fetch(`/manager-uses/api/users/${userId}`, { method: 'DELETE' });
            if (!delRes.ok) {
              const errBody = await delRes.json().catch(() => ({}));
              const msg = errBody?.error || 'Xoa user that bai';
              throw new Error(msg);
            }
            const row = e.currentTarget.closest('tr');
            if (row) row.remove();
            const menu = e.currentTarget.closest('.dropdown-menu');
            if (menu) menu.classList.remove('show');
            if (!tbody.querySelector('tr')) {
              tbody.innerHTML = '<tr><td colspan="6" class="text-center text-muted">Chua co user</td></tr>';
            }
            await loadUsers();
          } catch (err) {
            alert(err.message || 'Xoa user that bai');
          }
        } else if (action === 'view') {
          alert(`Xem user ${userId}`);
        } else if (action === 'edit') {
          const row = e.currentTarget.closest('tr');
          if (window.openEditModal && row) {
            window.openEditModal(row);
          }
        }
      });
    });
  }

  async function loadUsers() {
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="6">Dang tai...</td></tr>';
    try {
      const res = await fetch('/manager-uses/api/users');
      if (!res.ok) throw new Error('Tai users that bai');
      const { data } = await res.json();
      usersCache = Array.isArray(data) ? data : [];
      renderUsers(usersCache);
    } catch (e) {
      console.error(e);
      tbody.innerHTML = '<tr><td colspan="6" class="text-danger">Loi tai users</td></tr>';
    }
  }

  function applySearch() {
    const q = (searchInput?.value || '').trim().toLowerCase();
    if (!q) {
      renderUsers(usersCache);
      return;
    }
    const filtered = usersCache.filter((u) => {
      const full = (u.fullName || '').toLowerCase();
      const last = full.split(/\s+/).pop() || '';
      const phone = (u.phone || '').toLowerCase();
      const email = (u.email || '').toLowerCase();
      return full.includes(q) || last.includes(q) || phone.includes(q) || email.includes(q);
    });
    renderUsers(filtered);
  }

  // expose for other scripts
  window.loadUsers = loadUsers;

  // initial load
  loadUsers();

  // Bulk select handlers
  selectAll?.addEventListener('change', () => {
    tbody?.querySelectorAll('.row-check').forEach((ch) => {
      ch.checked = selectAll.checked;
    });
    refreshBulkState();
  });

  tbody?.addEventListener('change', (e) => {
    if (e.target.classList.contains('row-check')) {
      refreshBulkState();
    }
  });

  btnDeleteSelected?.addEventListener('click', async () => {
    if (!tbody) return;
    const ids = Array.from(tbody.querySelectorAll('.row-check:checked')).map((ch) => ch.dataset.id);
    if (!ids.length) return;
    if (!confirm(`Xoa ${ids.length} user?`)) return;
    try {
      await Promise.all(ids.map((id) => fetch(`/manager-uses/api/users/${id}`, { method: 'DELETE' })));
      await loadUsers();
    } catch (err) {
      alert('Xoa user that bai');
    }
  });

  // Tim kiem
  searchBtn?.addEventListener('click', applySearch);
  searchInput?.addEventListener('keyup', (e) => {
    if (e.key === 'Enter') applySearch();
  });

  // Reset
  resetBtn?.addEventListener('click', () => {
    sortState = { key: null, asc: true };
    if (searchInput) searchInput.value = '';
    renderUsers(usersCache);
  });

  // Sort menu
  sortOptions.forEach((btn) => {
    btn.addEventListener('click', () => {
      const key = btn.dataset.sort;
      if (sortState.key === key) {
        sortState.asc = !sortState.asc;
      } else {
        sortState = { key, asc: true };
      }
      applySearch();
    });
  });

  // Mo modal them user
  document.getElementById('btn-add-user')?.addEventListener('click', () => {
    openAddModal();
  });

  // Fallback close buttons for add modal
  addUserModalEl
    ?.querySelectorAll('[data-bs-dismiss="modal"], .btn-close, .btn-secondary')
    .forEach((btn) => {
      btn.addEventListener('click', () => closeAddModal());
    });

  addUserModalEl?.addEventListener('click', (e) => {
    if (!addUserModal && e.target === addUserModalEl) {
      closeAddModal();
    }
  });

  // Luu user moi
  document.getElementById('btn-save-user')?.addEventListener('click', async () => {
    if (!addUserForm) return;
    clearFieldErrors();
    const payload = {
      email: addUserForm.email.value.trim(),
      password: addUserForm.password.value,
      fullName: addUserForm.fullName.value.trim(),
      phone: addUserForm.phone.value.trim(),
      role: addUserForm.role.value,
    };

    const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
    if (!payload.email || !emailRe.test(payload.email)) {
      setFieldError(addUserForm.email, 'Email khong hop le');
      return;
    }
    if (!payload.password || payload.password.length < 6) {
      setFieldError(addUserForm.password, 'Mat khau toi thieu 6 ky tu');
      return;
    }
    try {
      const res = await fetch('/manager-uses/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        const msgMap = {
          'auth/email-already-exists': 'Email da ton tai',
          'auth/invalid-email': 'Email khong hop le',
          'auth/invalid-password': 'Mat khau khong hop le',
        };
        const message = msgMap[body?.error] || body?.error || 'Tao user that bai';
        throw new Error(message);
      }
      closeAddModal();
      await loadUsers();
    } catch (err) {
      if (addUserError) addUserError.textContent = err.message || 'Tao user that bai';
    }
  });

  // Fallback toggle if Bootstrap JS is not active
  document.addEventListener('click', (e) => {
    const toggle = e.target.closest('[data-bs-toggle="dropdown"]');
    const menus = document.querySelectorAll('.dropdown-menu.show');
    if (toggle) {
      const menu = toggle.parentElement.querySelector('.dropdown-menu');
      menus.forEach((m) => {
        if (m !== menu) m.classList.remove('show');
      });
      if (menu) menu.classList.toggle('show');
      e.preventDefault();
      e.stopPropagation();
    } else {
      menus.forEach((m) => m.classList.remove('show'));
    }
  });
});
