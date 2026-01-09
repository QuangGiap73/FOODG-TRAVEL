document.addEventListener('DOMContentLoaded', () => {
  const editModalEl = document.getElementById('editUserModal');
  const editModal = window.bootstrap && editModalEl ? new bootstrap.Modal(editModalEl) : null;
  const editForm = document.getElementById('edit-user-form');
  const editError = document.getElementById('edit-user-error');
  let currentEditId = null;
  const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  const closeSelectors = '[data-bs-dismiss="modal"], .btn-close, .btn-secondary';

  function showEditModal() {
    if (editModal) {
      editModal.show();
    } else if (editModalEl) {
      editModalEl.style.display = 'block';
      editModalEl.classList.add('show');
      document.body.classList.add('modal-open');
    }
  }

  function hideEditModal() {
    if (editModal) {
      editModal.hide();
    } else if (editModalEl) {
      editModalEl.classList.remove('show');
      editModalEl.style.display = 'none';
      document.body.classList.remove('modal-open');
    }
  }

  function clearEditErrors() {
    if (!editForm) return;
    editForm.querySelectorAll('.is-invalid').forEach((el) => el.classList.remove('is-invalid'));
    if (editError) editError.textContent = '';
  }

  function setEditError(input, message) {
    if (input) input.classList.add('is-invalid');
    if (editError && message) editError.textContent = message;
  }

  // Mở modal và fill dữ liệu từ row
  window.openEditModal = function (row) {
    if (!row || !editForm) return;
    currentEditId = row.dataset.id;
    clearEditErrors();
    const cells = row.querySelectorAll('td');
    editForm.email.value = cells[1]?.textContent.trim() || '';
    editForm.fullName.value = cells[2]?.textContent.trim() || '';
    editForm.role.value = cells[3]?.textContent.trim() || 'user';
    editForm.phone.value = cells[4]?.textContent.trim() || '';
    if (editForm.password) editForm.password.value = '';

    showEditModal();
  };

  // Lưu chỉnh sửa
  document.getElementById('btn-update-user')?.addEventListener('click', async () => {
    if (!currentEditId || !editForm) return;
    clearEditErrors();
    const passwordRaw = editForm.password?.value || '';
    const password = passwordRaw.trim();
    const payload = {
      email: editForm.email.value.trim(),
      fullName: editForm.fullName.value.trim(),
      phone: editForm.phone.value.trim(),
      role: editForm.role.value,
      ...(password ? { password } : {}),
    };
    if (!payload.email || !emailRe.test(payload.email)) {
      setEditError(editForm.email, 'Email khong hop le');
      return;
    }
    if (password && password.length < 6) {
      setEditError(editForm.password, 'Mat khau toi thieu 6 ky tu');
      return;
    }
    try {
      const res = await fetch(`/manager-uses/api/users/${currentEditId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        const msgMap = {
          'auth/email-already-exists': 'Email da ton tai',
          'auth/invalid-email': 'Email khong hop le',
          'auth/invalid-password': 'Mat khau toi thieu 6 ky tu',
        };
        throw new Error(msgMap[body?.error] || body?.error || 'Cap nhat that bai');
      }
      hideEditModal();
      if (window.loadUsers) {
        await window.loadUsers();
      }
    } catch (err) {
      if (editError) editError.textContent = err.message || 'Cap nhat that bai';
    }
  });

  editModalEl?.querySelectorAll(closeSelectors).forEach((btn) => {
    btn.addEventListener('click', hideEditModal);
  });

  editModalEl?.addEventListener('click', (e) => {
    if (!editModal && e.target === editModalEl) hideEditModal();
  });
});
