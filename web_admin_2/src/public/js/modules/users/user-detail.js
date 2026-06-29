(function () {
  const page = document.querySelector('.user-detail-page');
  const deleteButton = document.querySelector('[data-user-delete]');

  if (!page || !deleteButton) return;

  deleteButton.addEventListener('click', async () => {
    const confirmed = window.confirm('Bạn chắc chắn muốn xóa người dùng này? Hành động này không thể hoàn tác.');
    if (!confirmed) return;

    deleteButton.disabled = true;
    try {
      const response = await fetch(`/admin/users/api/list/${page.dataset.userId}`, {
        method: 'DELETE',
        headers: { Accept: 'application/json' },
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok || result.success === false) {
        throw new Error(result.message || 'Không thể xóa người dùng');
      }
      window.location.href = '/admin/users';
    } catch (error) {
      window.alert(error.message || 'Không thể xóa người dùng');
      deleteButton.disabled = false;
    }
  });
})();
