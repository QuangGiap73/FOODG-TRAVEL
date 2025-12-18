document.addEventListener('DOMContentLoaded', () => {
  const editModalEl = document.getElementById('editUserModal');
  const editModal = window.bootstrap && editModalEl ? new bootstrap.Modal(editModalEl) : null;
  const editForm = document.getElementById('edit-user-form');
  const editError = document.getElementById('edit-user-error');
  let currentEditId = null;
  const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

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
    editForm.email.value = cells[0]?.textContent.trim() || '';
    editForm.fullName.value = cells[1]?.textContent.trim() || '';
    editForm.role.value = cells[2]?.textContent.trim() || 'user';
    editForm.phone.value = cells[3]?.textContent.trim() || '';
    if (editModal) {
      editModal.show();
    } else if (editModalEl) {
      editModalEl.style.display = 'block';
    }
  };

  // Lưu chỉnh sửa
  document.getElementById('btn-update-user')?.addEventListener('click', async () => {
    if (!currentEditId || !editForm) return;
    clearEditErrors();
    const payload = {
      email: editForm.email.value.trim(),
      fullName: editForm.fullName.value.trim(),
      phone: editForm.phone.value.trim(),
      role: editForm.role.value,
    };
    if (!payload.email || !emailRe.test(payload.email)) {
      setEditError(editForm.email, 'Email khong hop le');
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
        };
        throw new Error(msgMap[body?.error] || body?.error || 'Cap nhat that bai');
      }
      if (editModal) {
        editModal.hide();
      } else if (editModalEl) {
        editModalEl.style.display = 'none';
      }
      if (window.loadUsers) {
        await window.loadUsers();
      }
    } catch (err) {
      if (editError) editError.textContent = err.message || 'Cap nhat that bai';
    }
  });
});
