(function () {
  const toolbarInput = document.getElementById('users-search-input');
  const sidebarInput = document.getElementById('users-filter-keyword');
  const roleSelect = document.getElementById('users-filter-role');
  const statusSelect = document.getElementById('users-filter-status');
  const provinceSelect = document.getElementById('users-filter-province');
  const sortSelect = document.getElementById('users-filter-sort');
  const applyButton = document.getElementById('users-apply-filter');
  const resetButton = document.getElementById('users-reset-filter');
  const tableBody = document.getElementById('users-table-body');

  // Chuẩn hóa chuỗi để tìm kiếm tên, email và số điện thoại ổn định hơn.
  function normalize(value) {
    return String(value || '').trim().toLowerCase();
  }

  // Tách số để tìm SĐT dù có khoảng trắng hay ký tự phân cách.
  function normalizePhone(value) {
    return String(value || '').replace(/\D/g, '');
  }

  function rows() {
    return Array.from(document.querySelectorAll('#users-table-body tr'));
  }

  function syncKeywordInputs(source) {
    const value = source?.value || '';
    if (toolbarInput && source !== toolbarInput) toolbarInput.value = value;
    if (sidebarInput && source !== sidebarInput) sidebarInput.value = value;
  }

  function parseVietnameseDate(value) {
    const match = String(value || '').match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
    if (!match) return 0;
    const [, day, month, year] = match;
    return new Date(Number(year), Number(month) - 1, Number(day)).getTime();
  }

  function sortRows(activeRows) {
    const sortValue = normalize(sortSelect?.value || 'Ngày tham gia mới nhất');
    const sorted = [...activeRows];

    sorted.sort((left, right) => {
      if (sortValue === normalize('Tên A-Z')) {
        return normalize(left.dataset.fullName).localeCompare(normalize(right.dataset.fullName), 'vi');
      }

      if (sortValue === normalize('Ngày cập nhật mới nhất')) {
        return parseVietnameseDate(right.dataset.updatedDate) - parseVietnameseDate(left.dataset.updatedDate);
      }

      return parseVietnameseDate(right.dataset.createdDate) - parseVietnameseDate(left.dataset.createdDate);
    });

    return sorted;
  }

  function applyFilters() {
    const keyword = normalize(toolbarInput?.value || sidebarInput?.value || '');
    const keywordPhone = normalizePhone(keyword);
    const roleValue = normalize(roleSelect?.value || 'Tất cả');
    const statusValue = normalize(statusSelect?.value || 'Tất cả');
    const provinceValue = normalize(provinceSelect?.value || 'Tất cả');
    const visibleRows = [];

    rows().forEach((row) => {
      const fullName = normalize(row.dataset.fullName);
      const email = normalize(row.dataset.email);
      const phone = String(row.dataset.phone || '');
      const phoneNormalized = normalizePhone(phone);
      const role = normalize(row.dataset.role);
      const status = normalize(row.dataset.status);
      const province = normalize(row.dataset.province);

      const roleMatch = roleValue === 'tất cả' || role === roleValue;
      const statusMatch = statusValue === 'tất cả' || status === statusValue;
      const provinceMatch = provinceValue === 'tất cả' || province === provinceValue;
      const keywordMatch = !keyword
        || fullName.includes(keyword)
        || email.includes(keyword)
        || phone.includes(keyword)
        || (keywordPhone && phoneNormalized.includes(keywordPhone));

      const isVisible = roleMatch && statusMatch && provinceMatch && keywordMatch;
      row.style.display = isVisible ? '' : 'none';
      if (isVisible) visibleRows.push(row);
    });

    // Sắp xếp sau khi lọc để không phá vỡ các row đang bị ẩn.
    sortRows(visibleRows).forEach((row) => {
      tableBody?.appendChild(row);
    });
  }

  toolbarInput?.addEventListener('input', () => {
    syncKeywordInputs(toolbarInput);
    applyFilters();
  });

  sidebarInput?.addEventListener('input', () => {
    syncKeywordInputs(sidebarInput);
    applyFilters();
  });

  [roleSelect, statusSelect, provinceSelect, sortSelect].forEach((select) => {
    select?.addEventListener('change', applyFilters);
  });

  applyButton?.addEventListener('click', applyFilters);

  resetButton?.addEventListener('click', () => {
    if (toolbarInput) toolbarInput.value = '';
    if (sidebarInput) sidebarInput.value = '';
    if (roleSelect) roleSelect.selectedIndex = 0;
    if (statusSelect) statusSelect.selectedIndex = 0;
    if (provinceSelect) provinceSelect.selectedIndex = 0;
    if (sortSelect) sortSelect.selectedIndex = 0;
    applyFilters();
  });

  applyFilters();
})();
