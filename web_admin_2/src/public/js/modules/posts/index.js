(function () {
  const checkAllTop = document.getElementById('posts-check-all');
  const checkAllTable = document.getElementById('posts-check-all-table');
  const selectedCount = document.getElementById('posts-selected-count');
  const bulkDeleteButton = document.querySelector('[data-posts-bulk-delete]');
  const bulkStatusButtons = Array.from(document.querySelectorAll('[data-posts-bulk-status]'));

  // Lấy tất cả checkbox của từng bài viết trong bảng.
  function rowChecks() {
    return Array.from(document.querySelectorAll('.posts-row-check'));
  }

  // Trả về danh sách ID của những bài đã được tick.
  function selectedIds() {
    return rowChecks()
      .filter((item) => item.checked)
      .map((item) => item.value)
      .filter(Boolean);
  }

  // Đồng bộ lại 2 checkbox "chọn tất cả", bộ đếm và trạng thái disable của các nút bulk.
  function renderSelectionState() {
    const checks = rowChecks();
    const checkedCount = checks.filter((item) => item.checked).length;
    const allChecked = checks.length > 0 && checkedCount === checks.length;
    const indeterminate = checkedCount > 0 && checkedCount < checks.length;

    if (selectedCount) selectedCount.textContent = String(checkedCount);

    [checkAllTop, checkAllTable].forEach((checkbox) => {
      if (!checkbox) return;
      checkbox.checked = allChecked;
      checkbox.indeterminate = indeterminate;
    });

    if (bulkDeleteButton) {
      bulkDeleteButton.disabled = checkedCount === 0;
    }

    bulkStatusButtons.forEach((button) => {
      button.disabled = checkedCount === 0;
    });
  }

  // Tick một checkbox tổng thì tick toàn bộ checkbox từng dòng.
  function bindCheckAll(sourceCheckbox) {
    sourceCheckbox?.addEventListener('change', () => {
      rowChecks().forEach((item) => {
        item.checked = sourceCheckbox.checked;
      });
      renderSelectionState();
      window.FoodsNotify?.success(`Đã xóa ${ids.length} bài viết.`);
    });
  }

  async function requestJson(url, options) {
    const response = await fetch(url, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      ...options,
    });

    const result = await response.json().catch(() => ({}));
    if (!response.ok || result.success === false) {
      throw new Error(result.message || 'Không thể xử lý bài viết');
    }
    return result;
  }

  // Gọi API xóa mềm nhiều bài viết theo checkbox đã chọn.
  async function deletePosts(ids) {
    return requestJson('/admin/posts/api/list', {
      method: 'DELETE',
      body: JSON.stringify({ ids }),
    });
  }

  // Gọi API đổi trạng thái kiểm duyệt cho 1 bài viết.
  async function updateSingleModeration(id, moderationStatus) {
    return requestJson(`/admin/posts/api/list/${encodeURIComponent(id)}/moderation`, {
      method: 'PATCH',
      body: JSON.stringify({ moderationStatus }),
    });
  }

  // Gọi API đổi trạng thái kiểm duyệt cho nhiều bài viết cùng lúc.
  async function updateBulkModeration(ids, moderationStatus) {
    return requestJson('/admin/posts/api/list/moderation', {
      method: 'PATCH',
      body: JSON.stringify({ ids, moderationStatus }),
    });
  }

  function getStatusMeta(status) {
    const normalized = String(status || '').toLowerCase();
    const map = {
      pending: { label: 'Chờ duyệt', className: 'pending' },
      published: { label: 'Đã xuất bản', className: 'published' },
      hidden: { label: 'Đã ẩn', className: 'hidden' },
      rejected: { label: 'Từ chối', className: 'rejected' },
    };
    return map[normalized] || map.published;
  }

  // Cập nhật lại badge trạng thái và nút Ẩn/Hiện ngay trên từng dòng
  // để user thấy kết quả mà không cần reload trang.
  function updateRowStatus(row, moderationStatus) {
    if (!row) return;

    const meta = getStatusMeta(moderationStatus);
    row.dataset.moderationStatus = moderationStatus;

    const statusLabel = row.querySelector('[data-post-status-label]');
    if (statusLabel) {
      statusLabel.textContent = meta.label;
      statusLabel.className = `posts-status posts-status--${meta.className}`;
    }

    const toggleButton = row.querySelector('[data-action="toggle-visibility"]');
    if (toggleButton) {
      toggleButton.dataset.currentStatus = moderationStatus;
      toggleButton.textContent = moderationStatus === 'hidden' ? 'Hiện bài' : 'Ẩn bài';
    }
  }

  bindCheckAll(checkAllTop);
  bindCheckAll(checkAllTable);

  document.addEventListener('change', (event) => {
    if (event.target.classList.contains('posts-row-check')) {
      renderSelectionState();
    }
  });

  // Xóa nhiều bài đã chọn.
  bulkDeleteButton?.addEventListener('click', async () => {
    const ids = selectedIds();
    if (!ids.length) {
      window.alert('Vui lòng chọn ít nhất một bài viết để xóa.');
      return;
    }

    const confirmed = window.confirm(`Bạn có chắc muốn xóa mềm ${ids.length} bài viết đã chọn?`);
    if (!confirmed) return;

    bulkDeleteButton.disabled = true;
    try {
      await deletePosts(ids);
      ids.forEach((id) => {
        document.querySelector(`tr[data-post-id="${CSS.escape(id)}"]`)?.remove();
      });
      renderSelectionState();
    } catch (error) {
      window.alert(error.message || 'Không thể xóa bài viết');
      renderSelectionState();
    }
  });

  // Đổi trạng thái kiểm duyệt cho nhiều bài đã chọn.
  bulkStatusButtons.forEach((button) => {
    button.addEventListener('click', async () => {
      const ids = selectedIds();
      const moderationStatus = button.dataset.postsBulkStatus;

      if (!ids.length) {
        window.alert('Vui lòng chọn ít nhất một bài viết.');
        return;
      }

      const label = getStatusMeta(moderationStatus).label;
      const confirmed = window.confirm(`Bạn có chắc muốn chuyển ${ids.length} bài viết sang "${label}"?`);
      if (!confirmed) return;

      button.disabled = true;
      try {
        await updateBulkModeration(ids, moderationStatus);
        ids.forEach((id) => {
          const row = document.querySelector(`tr[data-post-id="${CSS.escape(id)}"]`);
          updateRowStatus(row, moderationStatus);
        });
        renderSelectionState();
        window.FoodsNotify?.success(`Đã cập nhật ${ids.length} bài viết sang trạng thái "${label}".`);
      } catch (error) {
        window.alert(error.message || 'Không thể cập nhật trạng thái');
        renderSelectionState();
        window.FoodsNotify?.success('Đã xóa bài viết.');
      }
    });
  });

  // Xử lý các thao tác nhanh trên từng dòng: Ẩn/Hiện, Duyệt, Xóa.
  document.addEventListener('click', async (event) => {
    const actionButton = event.target.closest('[data-action]');
    if (!actionButton) return;

    const action = actionButton.dataset.action;
    const postId = actionButton.dataset.id;
    if (!postId) return;

    if (action === 'delete') {
      const confirmed = window.confirm('Bạn có chắc muốn xóa mềm bài viết này?');
      if (!confirmed) return;

      actionButton.disabled = true;
      try {
        await deletePosts([postId]);
        document.querySelector(`tr[data-post-id="${CSS.escape(postId)}"]`)?.remove();
        renderSelectionState();
      } catch (error) {
        window.alert(error.message || 'Không thể xóa bài viết');
        actionButton.disabled = false;
      }
      return;
    }

    if (action === 'toggle-visibility') {
      const currentStatus = String(actionButton.dataset.currentStatus || 'published').toLowerCase();
      const nextStatus = currentStatus === 'hidden' ? 'published' : 'hidden';

      actionButton.disabled = true;
      try {
        await updateSingleModeration(postId, nextStatus);
        updateRowStatus(
          document.querySelector(`tr[data-post-id="${CSS.escape(postId)}"]`),
          nextStatus,
        );
        window.FoodsNotify?.success(nextStatus === 'hidden' ? 'Đã ẩn bài viết.' : 'Đã hiển thị bài viết.');
      } catch (error) {
        window.alert(error.message || 'Không thể cập nhật trạng thái bài viết');
      } finally {
        actionButton.disabled = false;
      }
      return;
    }

    if (action === 'moderate') {
      const moderationStatus = actionButton.dataset.status;
      const label = getStatusMeta(moderationStatus).label;
      const confirmed = window.confirm(`Chuyển bài viết này sang trạng thái "${label}"?`);
      if (!confirmed) return;

      actionButton.disabled = true;
      try {
        await updateSingleModeration(postId, moderationStatus);
        updateRowStatus(
          document.querySelector(`tr[data-post-id="${CSS.escape(postId)}"]`),
          moderationStatus,
        );
        window.FoodsNotify?.success(`Đã chuyển bài viết sang trạng thái "${label}".`);
      } catch (error) {
        window.alert(error.message || 'Không thể cập nhật trạng thái bài viết');
      } finally {
        actionButton.disabled = false;
      }
    }
  });

  // Đóng menu 3 chấm khi click ra ngoài cho gọn UI.
  document.addEventListener('click', (event) => {
    document.querySelectorAll('.posts-action-menu[open]').forEach((menu) => {
      if (!menu.contains(event.target)) {
        menu.removeAttribute('open');
      }
    });
  });

  renderSelectionState();
})();
