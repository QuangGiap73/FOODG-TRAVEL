(function () {
  const page = document.querySelector('.user-edit-page');
  const form = document.getElementById('user-edit-form');
  const message = document.querySelector('[data-user-edit-message]');
  const submitButton = document.querySelector('[data-user-edit-submit]');
  const avatarInput = document.getElementById('user-avatar-input');
  const avatarTrigger = document.querySelector('[data-user-avatar-trigger]');
  const avatarPreview = document.querySelector('[data-user-avatar-preview]');

  if (!page || !form) return;

  function setMessage(text, isError) {
    if (!message) return;
    message.textContent = text;
    message.classList.toggle('is-error', Boolean(isError));
  }

  function setSaving(isSaving) {
    if (!submitButton) return;
    submitButton.disabled = isSaving;
    submitButton.textContent = isSaving ? 'Đang lưu...' : 'Lưu thay đổi';
  }

  async function uploadAvatar(file) {
    const data = new FormData();
    data.append('avatar', file);

    const response = await fetch(`/admin/users/api/list/${page.dataset.userId}/avatar`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
      body: data,
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.success === false) {
      throw new Error(result.message || 'Không thể cập nhật ảnh đại diện');
    }
    return result.data;
  }

  avatarTrigger?.addEventListener('click', () => {
    avatarInput?.click();
  });

  avatarInput?.addEventListener('change', async () => {
    const file = avatarInput.files?.[0];
    if (!file) return;

    setMessage('Đang tải ảnh đại diện...', false);

    try {
      const result = await uploadAvatar(file);
      if (avatarPreview && result?.photoUrl) {
        avatarPreview.src = result.photoUrl;
      }
      avatarInput.value = '';
      setMessage('Đã cập nhật ảnh đại diện thành công.', false);
    } catch (error) {
      setMessage(error.message || 'Không thể cập nhật ảnh đại diện', true);
    }
  });

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    setSaving(true);
    setMessage('Đang lưu thay đổi...', false);

    const formData = new FormData(form);
    const payload = {
      fullName: String(formData.get('fullName') || '').trim(),
      email: String(formData.get('email') || '').trim(),
      phone: String(formData.get('phone') || '').trim(),
      role: String(formData.get('role') || 'user').trim(),
      gender: String(formData.get('gender') || '').trim(),
      dateOfBirth: String(formData.get('dateOfBirth') || '').trim(),
    };
    const password = String(formData.get('password') || '');
    const passwordConfirm = String(formData.get('passwordConfirm') || '');

    if (password || passwordConfirm) {
      if (password.length < 6) {
        setMessage('Mật khẩu mới phải có ít nhất 6 ký tự.', true);
        return;
      }

      if (password !== passwordConfirm) {
        setMessage('Xác nhận mật khẩu mới không khớp.', true);
        return;
      }

      payload.password = password;
    }

    try {
      const response = await fetch(`/admin/users/api/list/${page.dataset.userId}`, {
        method: 'PUT',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok || result.success === false) {
        throw new Error(result.message || 'Không thể lưu thay đổi');
      }
      form.password.value = '';
      form.passwordConfirm.value = '';
      const authUpdated = result.data ? result.data.authUpdated !== false : true;
      setMessage(
        authUpdated
          ? 'Đã lưu thay đổi thành công.'
          : 'Đã lưu thông tin vào Firestore. Không tìm thấy Firebase Auth user để cập nhật email/mật khẩu.',
        false,
      );
    } catch (error) {
      setMessage(error.message || 'Không thể lưu thay đổi', true);
    } finally {
      setSaving(false);
    }
  });
})();
