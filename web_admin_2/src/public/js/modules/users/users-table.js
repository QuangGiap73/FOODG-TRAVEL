(function () {
  const checkAll = document.getElementById('users-check-all');
  const selectedCount = document.getElementById('users-selected-count');
  const bulkDeleteButton = document.querySelector('[data-users-bulk-delete]');

  function rowChecks() {
    return Array.from(document.querySelectorAll('.users-row-check'));
  }

  function renderSelectedCount() {
    const checked = rowChecks().filter((item) => item.checked).length;
    if (selectedCount) selectedCount.textContent = String(checked);
    if (bulkDeleteButton) bulkDeleteButton.disabled = checked === 0;
    if (checkAll) {
      checkAll.checked = checked > 0 && checked === rowChecks().length;
      checkAll.indeterminate = checked > 0 && checked < rowChecks().length;
    }
  }

  function selectedIds() {
    return rowChecks()
      .filter((item) => item.checked)
      .map((item) => item.value)
      .filter(Boolean);
  }

  async function deleteUsers(ids) {
    const response = await fetch('/admin/users/api/list', {
      method: 'DELETE',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ ids }),
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.success === false) {
      throw new Error(result.message || 'Không thể xóa người dùng');
    }
    return result;
  }

  checkAll?.addEventListener('change', () => {
    rowChecks().forEach((item) => {
      item.checked = checkAll.checked;
    });
    renderSelectedCount();
  });

  document.addEventListener('change', (event) => {
    if (event.target.classList.contains('users-row-check')) {
      renderSelectedCount();
    }
  });

  document.addEventListener('click', async (event) => {
    const deleteButton = event.target.closest('[data-action="delete"]');
    if (!deleteButton) return;

    const userId = deleteButton.dataset.id;
    if (!userId) return;

    const confirmed = window.confirm('Bạn chắc chắn muốn xóa người dùng này? Hành động này không thể hoàn tác.');
    if (!confirmed) return;

    deleteButton.disabled = true;
    try {
      await deleteUsers([userId]);
      deleteButton.closest('tr')?.remove();
      renderSelectedCount();
    } catch (error) {
      window.alert(error.message || 'Không thể xóa người dùng');
      deleteButton.disabled = false;
    }
  });

  bulkDeleteButton?.addEventListener('click', async () => {
    const ids = selectedIds();
    if (!ids.length) {
      window.alert('Vui lòng chọn ít nhất một người dùng để xóa.');
      return;
    }

    const confirmed = window.confirm(`Bạn chắc chắn muốn xóa ${ids.length} người dùng đã chọn? Hành động này không thể hoàn tác.`);
    if (!confirmed) return;

    bulkDeleteButton.disabled = true;
    try {
      await deleteUsers(ids);
      ids.forEach((id) => {
        document.querySelector(`tr[data-user-id="${CSS.escape(id)}"]`)?.remove();
      });
      renderSelectedCount();
    } catch (error) {
      window.alert(error.message || 'Không thể xóa người dùng');
      renderSelectedCount();
    }
  });

  renderSelectedCount();
})();
