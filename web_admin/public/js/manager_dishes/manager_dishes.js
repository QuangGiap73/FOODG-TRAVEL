document.addEventListener('DOMContentLoaded', () => {
  const tbody = document.getElementById('dish-table-body');
  const searchInput = document.getElementById('dish-search');
  const btnSearch = document.getElementById('btn-search-dish');
  const btnReset = document.getElementById('btn-reset-dish');
  const selectAll = document.getElementById('select-all-dishes');
  const bulkActions = document.getElementById('bulk-actions-dishes');
  const selectedCount = document.getElementById('selected-count-dishes');
  const btnDeleteSelected = document.getElementById('btn-delete-selected-dishes');

  async function loadDishes() {
    if (!tbody) return;
    const q = encodeURIComponent((searchInput?.value || '').trim());
    const provinceSelect = document.getElementById('dish-filter-province');
    const province = encodeURIComponent((provinceSelect?.value || '').trim().toLowerCase());

    tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">Dang tai...</td></tr>';
    try {
      const res = await fetch(`/manager-dishes/api/dishes?q=${q}&province=${province}`);
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error || 'Tai mon that bai');
      const list = Array.isArray(body.data) ? body.data : [];
      renderTable(list);
    } catch (err) {
      console.error(err);
      tbody.innerHTML = `<tr><td colspan="9" class="text-center text-danger">${err.message || 'Loi tai du lieu'}</td></tr>`;
    }
  }


  function renderTable(list) {
    if (!list.length) {
      tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">Chua co du lieu</td></tr>';
      return;
    }

    const rows = list
      .map((item, idx) => {
        const img = item.Img || item.img || item.imageUrl || '';
        const name = item.Name || item.name || '';
        const slug = item.slug || '';
        const region = item.region_code || '';
        const province = item.province_code || '';
        const cat = item.category || '';
        const price = item.price_range || '';
        const spicy = item.spicy_level != null ? item.spicy_level : '';
        const satiety = item.satiety_level != null ? item.satiety_level : '';
        const bestTime = item.Best_time || item.best_time || '';
        const bestSeason = item.Best_season || item.best_season || '';
        const tags = item.Tags || item.tags || '';
        const rowNum = item.STT || idx + 1;
        const id = item.id || rowNum;

        return `
          <tr data-id="${id}">
            <td><input type="checkbox" class="row-check" data-id="${id}"></td>
            <td class="text-muted small">${rowNum}</td>
            <td style="width:70px;">
              ${
                img
                  ? `<img src="${img}" alt="" style="width:56px;height:56px;object-fit:cover;border-radius:6px;">`
                  : `<div style="width:56px;height:56px;border-radius:6px;background:#f4f6f8;display:flex;align-items:center;justify-content:center;" class="text-muted small">N/A</div>`
              }
            </td>
            <td>
              <div class="fw-semibold">${name}</div>
              <div class="text-muted small">${slug}</div>
            </td>
            <td>
              <div>${province || '-'}</div>
            </td>
            <td>
              <div>${region || ''}</div>
            </td>
            <td>${cat || ''}</td>
            <td>
            ${bestTime || ''}
            </td>
            
            <td class="text-center">
              <div class="dropdown">
                <button class="btn btn-sm btn-light dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                  <i class="bi-three-dots-vertical"></i>
                </button>
                <ul class="dropdown-menu dropdown-menu-end dish-action-menu">
                  <li><button class="dropdown-item" type="button" data-action="view" data-id="${id}">Xem</button></li>
                  <li><button class="dropdown-item" type="button" data-action="edit" data-id="${id}">Sua</button></li>
                  <li><button class="dropdown-item text-danger" type="button" data-action="delete" data-id="${id}">Xoa</button></li>
                </ul>
              </div>
            </td>
          </tr>
        `;
      })
      .join('');

    tbody.innerHTML = rows;
    refreshBulkState();

    // Thông báo cho file action biết đã render xong
    document.dispatchEvent(
      new CustomEvent('dish:list-rendered', {
        detail: { container: tbody, list },
      }),
    );
  }
  // hàm xóa nhiều 
  function refreshBulkState() {
    if (!tbody) return;
    const checked = tbody.querySelectorAll('.row-check:checked').length;
    const total = tbody.querySelectorAll('.row-check').length;
    if (selectedCount) selectedCount.textContent = `${checked} da chon`;
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
  document.getElementById('dish-filter-province')?.addEventListener('change', loadDishes);


  btnSearch?.addEventListener('click', loadDishes);
  btnReset?.addEventListener('click', () => {
    if (searchInput) searchInput.value = '';
    loadDishes();
  });
  searchInput?.addEventListener('keyup', (e) => {
    if (e.key === 'Enter') loadDishes();
  });
  // hàm lắng nghe sự kiện chọn xóa nhiều
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
  // nút xóa nhiều
  btnDeleteSelected?.addEventListener('click', async () => {
    if (!tbody) return;
    const ids = Array.from(tbody.querySelectorAll('.row-check:checked')).map((ch) => ch.dataset.id);
    if (!ids.length) return;
    if (!confirm(`Xoa ${ids.length} mon?`)) return;
    try {
      await Promise.all(ids.map((id) => fetch(`/manager-dishes/api/dishes/${encodeURIComponent(id)}`, { method: 'DELETE' })));
      await loadDishes();
    } catch (err) {
      alert('Xoa mon that bai');
    }
  });
  loadDishes();
});
