(function () {
  const initial = window.__DISHES_INITIAL__ || { pagination: {} };

  const tableBody = document.getElementById('dishes-table-body');
  const pageInfo = document.getElementById('dish-page-info');
  const pageList = document.getElementById('dish-page-list');

  const searchInput = document.getElementById('dish-search');
  const provinceFilter = document.getElementById('dish-filter-province');
  const spicyFilter = document.getElementById('dish-filter-spicy');
  const sortSelect = document.getElementById('dish-sort-select');

  const exportExcelBtn = document.getElementById('btn-export-excel');
  const openAddDishBtn = document.getElementById('btn-open-add-dish');
  const deleteSelectedBtn = document.getElementById('btn-delete-selected-dishes');
  const selectAllHeader = document.getElementById('select-all-dishes');
  const selectAllTable = document.getElementById('select-all-dishes-table');

  let currentPage = Number(initial.pagination?.page || 1);
  let currentPageSize = Number(initial.pagination?.pageSize || 50);

  function buildQuery(page = currentPage) {
    const params = new URLSearchParams();
    params.set('page', String(page));
    params.set('pageSize', String(currentPageSize));

    const search = String(searchInput?.value || '').trim();
    if (search) params.set('search', search);

    const provinceCode34 = String(provinceFilter?.value || '').trim();
    if (provinceCode34) params.set('provinceCode34', provinceCode34);

    const spicyLevel = String(spicyFilter?.value || '').trim();
    if (spicyLevel !== '') params.set('spicyLevel', spicyLevel);

    const sortBy = String(sortSelect?.value || 'stt_asc').trim();
    if (sortBy) params.set('sortBy', sortBy);

    return params.toString();
  }

  function renderPageInfo(meta) {
    if (!pageInfo) return;
    pageInfo.textContent = `Hiển thị trang ${meta.page}/${meta.totalPages}, tổng ${meta.total} món ăn.`;
  }

  function syncSelectAllState() {
    const totalCount = document.querySelectorAll('.dish-row-check').length;
    const checkedCount = document.querySelectorAll('.dish-row-check:checked').length;

    if (selectAllHeader) {
      selectAllHeader.checked = totalCount > 0 && checkedCount === totalCount;
      selectAllHeader.indeterminate = checkedCount > 0 && checkedCount < totalCount;
    }

    if (selectAllTable) {
      selectAllTable.checked = totalCount > 0 && checkedCount === totalCount;
      selectAllTable.indeterminate = checkedCount > 0 && checkedCount < totalCount;
    }

    if (deleteSelectedBtn) {
      deleteSelectedBtn.disabled = checkedCount === 0;
    }
  }

  function renderTable(items) {
    if (!items.length) {
      tableBody.innerHTML = '<tr><td colspan="11" class="dishes-empty">Chưa có dữ liệu</td></tr>';
      syncSelectAllState();
      return;
    }

    tableBody.innerHTML = items
      .map((dish) => `
        <tr>
          <td><input type="checkbox" class="dish-row-check" data-dish-id="${dish.id || ''}"></td>
          <td>${dish.stt || '-'}</td>
          <td>${dish.imageUrl ? `<img class="dishes-thumb" src="${dish.imageUrl}" alt="">` : '<div class="dishes-thumb dishes-thumb--empty">N/A</div>'}</td>
          <td>${dish.nameVi || '-'}</td>
          <td>${dish.nameEn || '-'}</td>
          <td>${dish.provinceName34 || '-'}</td>
          <td>${dish.categoryVi || '-'}</td>
          <td><span class="dishes-metric">🌶 ${dish.spicyLevel || 0}</span></td>
          <td><span class="dishes-metric">🍜 ${dish.satietyLevel || 0}</span></td>
          <td>${dish.priceRangeVi || '-'}</td>
          <td>
            <div class="dishes-actions">
              <button type="button" class="dishes-action" data-action="view" data-id="${dish.id || ''}">👁</button>
              <button type="button" class="dishes-action" data-action="edit" data-id="${dish.id || ''}">✎</button>
              <button type="button" class="dishes-action dishes-action--danger" data-action="delete" data-id="${dish.id || ''}">🗑</button>
            </div>
          </td>
        </tr>
      `)
      .join('');

    syncSelectAllState();
  }

  function renderPagination(meta) {
    if (!pageList) return;
    const totalPages = Number(meta.totalPages || 1);
    const page = Number(meta.page || 1);

    pageList.innerHTML = '';

    pageList.insertAdjacentHTML(
      'beforeend',
      `<li class="${page <= 1 ? 'disabled' : ''}"><a href="#">‹</a></li>`,
    );

    for (let index = 1; index <= totalPages; index += 1) {
      pageList.insertAdjacentHTML(
        'beforeend',
        `<li class="${index === page ? 'is-active' : ''}"><a href="#">${index}</a></li>`,
      );
    }

    pageList.insertAdjacentHTML(
      'beforeend',
      `<li class="${page >= totalPages ? 'disabled' : ''}"><a href="#">›</a></li>`,
    );
  }

  async function fetchDishes(page = 1) {
    if (!tableBody) return;
    tableBody.innerHTML = '<tr><td colspan="11" class="dishes-empty">Đang tải...</td></tr>';

    try {
      const query = buildQuery(page);
      const response = await fetch(`/admin/dishes/api/list?${query}`);
      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(body.message || body.error || 'Tải danh sách món thất bại');
      }

      const data = body.data || {};
      const items = Array.isArray(data.items) ? data.items : [];
      const meta = data.meta || {};

      currentPage = Number(meta.page || page || 1);
      currentPageSize = Number(meta.pageSize || currentPageSize || 50);

      renderTable(items);
      renderPagination(meta);
      renderPageInfo(meta);
    } catch (error) {
      console.error(error);
      tableBody.innerHTML = `<tr><td colspan="11" class="dishes-empty">${error.message || 'Lỗi tải dữ liệu'}</td></tr>`;
    }
  }

  function setAllRowChecks(checked) {
    document.querySelectorAll('.dish-row-check').forEach((checkbox) => {
      checkbox.checked = checked;
    });
    syncSelectAllState();
  }

  async function deleteSelectedDishes() {
    const ids = Array.from(document.querySelectorAll('.dish-row-check:checked')).map(
      (checkbox) => checkbox.dataset.dishId,
    );

    if (!ids.length) return;
    if (!window.confirm(`Bạn có chắc muốn xóa ${ids.length} món đã chọn?`)) return;

    await Promise.all(
      ids.map((id) =>
        fetch(`/admin/dishes/api/list/${encodeURIComponent(id)}`, { method: 'DELETE' }),
      ),
    );

    await fetchDishes(currentPage);
  }

  function exportExcel() {
    const query = buildQuery(currentPage);
    window.location.href = `/admin/dishes/api/export?${query}`;
  }

  searchInput?.addEventListener('input', () => {
    clearTimeout(window.__dishSearchTimer);
    window.__dishSearchTimer = setTimeout(() => fetchDishes(1), 350);
  });

  provinceFilter?.addEventListener('change', () => fetchDishes(1));
  spicyFilter?.addEventListener('change', () => fetchDishes(1));
  sortSelect?.addEventListener('change', () => fetchDishes(1));
  exportExcelBtn?.addEventListener('click', exportExcel);
  openAddDishBtn?.addEventListener('click', () => {
    window.location.href = '/admin/dishes/add';
  });
  deleteSelectedBtn?.addEventListener('click', deleteSelectedDishes);

  selectAllHeader?.addEventListener('change', () => setAllRowChecks(selectAllHeader.checked));
  selectAllTable?.addEventListener('change', () => setAllRowChecks(selectAllTable.checked));

  tableBody?.addEventListener('change', (event) => {
    if (event.target.classList.contains('dish-row-check')) {
      syncSelectAllState();
    }
  });

  tableBody?.addEventListener('click', (event) => {
    const button = event.target.closest('[data-action]');
    if (!button) return;

    const action = button.dataset.action;
    const id = button.dataset.id;

    if (action === 'view') alert(`Xem món: ${id}`);
    if (action === 'edit') alert(`Sửa món: ${id}`);
    if (action === 'delete') {
      if (window.confirm('Bạn có chắc muốn xóa món này?')) {
        fetch(`/admin/dishes/api/list/${encodeURIComponent(id)}`, { method: 'DELETE' }).then(() => fetchDishes(currentPage));
      }
    }
  });

  pageList?.addEventListener('click', (event) => {
    const link = event.target.closest('a');
    if (!link) return;
    event.preventDefault();

    const text = String(link.textContent || '').trim();
    if (text === '‹') {
      fetchDishes(Math.max(1, currentPage - 1));
      return;
    }

    if (text === '›') {
      fetchDishes(currentPage + 1);
      return;
    }

    const page = Number(text);
    if (Number.isFinite(page)) fetchDishes(page);
  });

  fetchDishes(currentPage);
})();
