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

  function syncUrlState(page = currentPage) {
    const query = buildQuery(page);
    const url = `${window.location.pathname}?${query}`;
    window.history.replaceState(null, '', url);
  }

  function restoreFiltersFromUrl() {
    const params = new URLSearchParams(window.location.search);

    if (searchInput) searchInput.value = params.get('search') || '';
    if (provinceFilter) provinceFilter.value = params.get('provinceCode34') || '';
    if (spicyFilter) spicyFilter.value = params.get('spicyLevel') || '';
    if (sortSelect) sortSelect.value = params.get('sortBy') || sortSelect.value;

    const pageParam = Number(params.get('page'));
    if (Number.isFinite(pageParam) && pageParam > 0) {
      currentPage = pageParam;
    }

    const pageSizeParam = Number(params.get('pageSize'));
    if (Number.isFinite(pageSizeParam) && pageSizeParam > 0) {
      currentPageSize = pageSizeParam;
    }
  }

  function renderPageInfo(meta) {
    if (!pageInfo) return;
    pageInfo.textContent = `Hien thi trang ${meta.page}/${meta.totalPages}, tong ${meta.total} mon an.`;
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
      tableBody.innerHTML = '<tr><td colspan="11" class="dishes-empty">Khong co du lieu</td></tr>';
      syncSelectAllState();
      return;
    }

    tableBody.innerHTML = items
      .map((dish) => `
        <tr>
          <td><input type="checkbox" class="dish-row-check" data-dish-id="${dish.id || ''}"></td>
          <td>${dish.stt || '-'}</td>
          <td>
            <button type="button" class="dishes-thumb-button" data-action="view" data-id="${dish.id || ''}">
              ${dish.imageUrl ? `<img class="dishes-thumb" src="${dish.imageUrl}" alt="">` : '<div class="dishes-thumb dishes-thumb--empty">N/A</div>'}
            </button>
          </td>
          <td>${dish.nameVi || '-'}</td>
          <td>${dish.nameEn || '-'}</td>
          <td>${dish.provinceName34 || '-'}</td>
          <td>${dish.categoryVi || '-'}</td>
          <td><span class="dishes-metric">&#127798; ${dish.spicyLevel || 0}</span></td>
          <td><span class="dishes-metric">&#127869; ${dish.satietyLevel || 0}</span></td>
          <td>${dish.priceRangeVi || '-'}</td>
          <td>
            <div class="dishes-actions">
              <button type="button" class="dishes-action" data-action="view" data-id="${dish.id || ''}">&#128065;</button>
              <button type="button" class="dishes-action" data-action="edit" data-id="${dish.id || ''}">&#9998;</button>
              <button type="button" class="dishes-action dishes-action--danger" data-action="delete" data-id="${dish.id || ''}">&#128465;</button>
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
    const createPageItem = (targetPage, label = targetPage, className = '') =>
      `<li class="${className}"><a href="#" data-page="${targetPage}">${label}</a></li>`;
    const createEllipsisItem = () => '<li class="disabled dishes-pagination-ellipsis"><span>...</span></li>';

    const windowSize = 2;
    const pages = new Set([1, totalPages]);

    for (let index = page - windowSize; index <= page + windowSize; index += 1) {
      if (index > 1 && index < totalPages) {
        pages.add(index);
      }
    }

    pageList.innerHTML = '';

    pageList.insertAdjacentHTML('beforeend', createPageItem(page - 1, 'Prev', page <= 1 ? 'disabled' : ''));

    let previousPage = 0;
    Array.from(pages)
      .sort((left, right) => left - right)
      .forEach((currentPageNumber) => {
        if (previousPage && currentPageNumber - previousPage > 1) {
          pageList.insertAdjacentHTML('beforeend', createEllipsisItem());
        }

        pageList.insertAdjacentHTML(
          'beforeend',
          createPageItem(
            currentPageNumber,
            currentPageNumber,
            currentPageNumber === page ? 'is-active' : '',
          ),
        );

        previousPage = currentPageNumber;
      });

    if (totalPages <= 1 && page !== 1) {
      pageList.insertAdjacentHTML('beforeend', createPageItem(1, 1, 'is-active'));
    }

    pageList.insertAdjacentHTML('beforeend', createPageItem(page + 1, 'Next', page >= totalPages ? 'disabled' : ''));
  }

  async function fetchDishes(page = 1) {
    if (!tableBody) return;
    tableBody.innerHTML = '<tr><td colspan="11" class="dishes-empty">Dang tai...</td></tr>';

    try {
      const query = buildQuery(page);
      const response = await fetch(`/admin/dishes/api/list?${query}`);
      const body = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(body.message || body.error || 'Tai danh sach mon that bai');
      }

      const data = body.data || {};
      const items = Array.isArray(data.items) ? data.items : [];
      const meta = data.meta || {};

      currentPage = Number(meta.page || page || 1);
      currentPageSize = Number(meta.pageSize || currentPageSize || 50);

      syncUrlState(currentPage);
      renderTable(items);
      renderPagination(meta);
      renderPageInfo(meta);
    } catch (error) {
      console.error(error);
      tableBody.innerHTML = `<tr><td colspan="11" class="dishes-empty">${error.message || 'Loi tai du lieu'}</td></tr>`;
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
    if (!window.confirm(`Ban co chac muon xoa ${ids.length} mon da chon?`)) return;

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

  function handleFilterChange() {
    fetchDishes(1);
  }

  searchInput?.addEventListener('input', () => {
    clearTimeout(window.__dishSearchTimer);
    window.__dishSearchTimer = setTimeout(() => fetchDishes(1), 350);
  });

  provinceFilter?.addEventListener('change', handleFilterChange);
  spicyFilter?.addEventListener('change', handleFilterChange);
  sortSelect?.addEventListener('change', handleFilterChange);
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

    if (action === 'view') {
      window.location.href = `/admin/dishes/${encodeURIComponent(id)}`;
      return;
    }

    if (action === 'edit') {
      window.location.href = `/admin/dishes/${encodeURIComponent(id)}/edit`;
      return;
    }

    if (action === 'delete') {
      if (window.confirm('Ban co chac muon xoa mon nay?')) {
        fetch(`/admin/dishes/api/list/${encodeURIComponent(id)}`, { method: 'DELETE' }).then(() => fetchDishes(currentPage));
      }
    }
  });

  pageList?.addEventListener('click', (event) => {
    const link = event.target.closest('a[data-page]');
    if (!link) return;

    event.preventDefault();

    const nextPage = Number(link.dataset.page);
    if (!Number.isFinite(nextPage) || nextPage < 1) return;
    if (nextPage === currentPage) return;

    fetchDishes(nextPage);
  });

  restoreFiltersFromUrl();
  fetchDishes(currentPage);
})();
