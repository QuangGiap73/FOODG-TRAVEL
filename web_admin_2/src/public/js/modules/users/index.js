(function () {
  const pageData = window.__USERS_PAGE__ || {};
  const addButton = document.getElementById('users-add-btn');
  const modal = document.getElementById('users-create-modal');
  const createForm = document.getElementById('users-create-form');
  const message = document.getElementById('users-create-message');
  const submitButton = document.getElementById('users-create-submit');
  const closeButtons = Array.from(document.querySelectorAll('[data-users-modal-close]'));
  const previewName = document.getElementById('users-create-name');
  const previewEmail = document.getElementById('users-create-email');
  const previewRole = document.getElementById('users-create-role');
  const previewAvatar = document.getElementById('users-create-avatar');

  window.UsersPage = {
    data: pageData,
  };

  function setMessage(text, isError) {
    if (!message) return;
    message.textContent = text;
    message.classList.toggle('is-error', Boolean(isError));
  }

  function setSubmitting(isSubmitting) {
    if (!submitButton) return;
    submitButton.disabled = isSubmitting;
    submitButton.textContent = isSubmitting ? 'Đang tạo...' : 'Tạo người dùng';
  }

  function syncPreview() {
    const formData = new FormData(createForm);
    const fullName = String(formData.get('fullName') || '').trim();
    const email = String(formData.get('email') || '').trim();
    const role = String(formData.get('role') || 'user').trim();

    if (previewName) previewName.textContent = fullName || 'Người dùng mới';
    if (previewEmail) previewEmail.textContent = email || 'email@example.com';
    if (previewRole) previewRole.textContent = role;
    if (previewAvatar) {
      previewAvatar.textContent = (fullName || email || 'U').trim().charAt(0).toUpperCase() || 'U';
    }
  }

  function openModal() {
    modal?.classList.add('is-open');
    modal?.setAttribute('aria-hidden', 'false');
    syncPreview();
    createForm?.querySelector('input[name="fullName"]')?.focus();
  }

  function closeModal() {
    modal?.classList.remove('is-open');
    modal?.setAttribute('aria-hidden', 'true');
    createForm?.reset();
    setMessage('', false);
    syncPreview();
    setSubmitting(false);
  }

  // Đồng bộ preview để modal phản ánh ngay dữ liệu người dùng đang nhập.
  createForm?.addEventListener('input', syncPreview);

  addButton?.addEventListener('click', openModal);
  closeButtons.forEach((button) => button.addEventListener('click', closeModal));

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && modal?.classList.contains('is-open')) {
      closeModal();
    }
  });

  // Gui form tao user moi qua API co san va reload de bang nhan du lieu Firestore moi nhat.
  createForm?.addEventListener('submit', async (event) => {
    event.preventDefault();

    const formData = new FormData(createForm);
    const payload = {
      fullName: String(formData.get('fullName') || '').trim(),
      email: String(formData.get('email') || '').trim(),
      phone: String(formData.get('phone') || '').trim(),
      role: String(formData.get('role') || 'user').trim(),
      password: String(formData.get('password') || ''),
    };
    const passwordConfirm = String(formData.get('passwordConfirm') || '');

    if (!payload.fullName || !payload.email || !payload.password) {
      setMessage('Vui lòng nhập đầy đủ họ tên, email và mật khẩu.', true);
      return;
    }

    if (payload.password.length < 6) {
      setMessage('Mật khẩu phải có ít nhất 6 ký tự.', true);
      return;
    }

    if (payload.password !== passwordConfirm) {
      setMessage('Xác nhận mật khẩu không khớp.', true);
      return;
    }

    setSubmitting(true);
    setMessage('Đang tạo người dùng...', false);

    try {
      const response = await fetch('/admin/users/api/list', {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok || result.success === false) {
        throw new Error(result.message || 'Không thể tạo người dùng');
      }
      setMessage('Đã tạo người dùng thành công. Đang tải lại danh sách...', false);
      window.setTimeout(() => window.location.reload(), 500);
    } catch (error) {
      setMessage(error.message || 'Không thể tạo người dùng', true);
      setSubmitting(false);
    }
  });

  syncPreview();
})();
