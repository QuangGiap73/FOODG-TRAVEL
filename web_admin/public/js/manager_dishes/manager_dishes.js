document.addEventListener('DOMContentLoaded', () => {
  const tbody = document.getElementById('dish-table-body');
  const searchInput = document.getElementById('dish-search');
  const btnSearch = document.getElementById('btn-search-dish');
  const btnReset = document.getElementById('btn-reset-dish');
  const selectAll = document.getElementById('select-all-dishes');
  const bulkActions = document.getElementById('bulk-actions-dishes');
  const selectedCount = document.getElementById('selected-count-dishes');
  const btnDeleteSelected = document.getElementById('btn-delete-selected-dishes');
  const pageInfo = document.getElementById('dish-page-info');
  const pageList = document.getElementById('dish-page-list');
  const PAGE_SIZE = 50;
  let currentPage = 1;
  let currentList = [];

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
      currentList = sortByStt(list);
      currentPage = 1;
      renderPage();
    } catch (err) {
      console.error(err);
      tbody.innerHTML = `<tr><td colspan="9" class="text-center text-danger">${err.message || 'Loi tai du lieu'}</td></tr>`;
      currentList = [];
      currentPage = 1;
      if (pageInfo) pageInfo.textContent = '';
      if (pageList) pageList.innerHTML = '';
    }
  }


  function sortByStt(list) {
    return [...list].sort((a, b) => {
      const aStt = Number(a.STT || a.stt || 0);
      const bStt = Number(b.STT || b.stt || 0);
      return aStt - bStt;
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
    if (!list.length) {
      tbody.innerHTML = '<tr><td colspan="9" class="text-center text-muted">Chua co du lieu</td></tr>';
      return;
    }
    // sắp xếp theo STT
    const rows = list
      .map((item, idx) => {
        const images = Array.isArray(item.Images || item.images || item.imageUrls)
          ? (item.Images || item.images || item.imageUrls)
          : [];
        const img = images[0] || item.Img || item.img || item.imageUrl || '';

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
        const rowNum = item.STT || offset + idx + 1;
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
              <div class="cell-ellipsis" style="max-width: 220px;">${name}</div>
            \
            </td>
            <td>
              <div>${province || '-'}</div>
            </td>
            <td>
              <div>${region || ''}</div>
            </td>
            <td class="cell-ellipsis" style="max-width: 160px;">${cat || ''}</td>
            <td class="cell-ellipsis" style="max-width: 180px;">
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
      if (window.notify) window.notify.success(`Da xoa ${ids.length} mon`);
    } catch (err) {
      alert('Xoa mon that bai');
    }
  });
  pageList?.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-page]');
    if (!btn) return;
    const page = Number(btn.dataset.page);
    if (!Number.isFinite(page) || page < 1) return;
    currentPage = page;
    renderPage();
  });
  loadDishes();
});
