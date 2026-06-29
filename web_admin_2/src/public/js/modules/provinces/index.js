(function () {
  const initial = window.__PROVINCES_INITIAL__ || { regions: [], provinces: [] };

  const regionForm = document.getElementById('region-form');
  const regionCode = document.getElementById('region-code');
  const regionName = document.getElementById('region-name');
  const regionMacro = document.getElementById('region-macro');
  const regionNumber = document.getElementById('region-number');
  const regionError = document.getElementById('region-error');
  const regionList = document.getElementById('region-list');
  const regionFilter = document.getElementById('province-region-filter');
  const regionOpenCreate = document.getElementById('region-open-create');
  const regionModal = document.getElementById('region-modal');
  const regionModalClose = document.getElementById('region-modal-close');
  const regionModalCancel = document.getElementById('region-modal-cancel');

  const provinceForm = document.getElementById('province-form');
  const provinceCode = document.getElementById('province-code');
  const provinceName = document.getElementById('province-name');
  const provinceRegion = document.getElementById('province-region');
  const provinceSlug = document.getElementById('province-slug');
  const provinceLat = document.getElementById('province-lat');
  const provinceLng = document.getElementById('province-lng');
  const provinceDescription = document.getElementById('province-description');
  const provinceImages = document.getElementById('province-images');
  const provinceImageFiles = document.getElementById('province-image-files');
  const provinceImagePreview = document.getElementById('province-image-preview');
  const provinceError = document.getElementById('province-error');
  const provinceSubmitButton = document.getElementById('province-submit-button');
  const provincesTableBody = document.getElementById('provinces-table-body');
  const provinceSearch = document.getElementById('province-search');
  const provinceReset = document.getElementById('province-reset');
  const provinceOpenCreate = document.getElementById('province-open-create');
  const provinceCount = document.getElementById('province-count');
  const provinceTableTitle = document.getElementById('province-table-title');
  const provinceModal = document.getElementById('province-modal');
  const provinceModalTitle = document.getElementById('province-modal-title');
  const provinceModalClose = document.getElementById('province-modal-close');
  const provinceModalCancel = document.getElementById('province-modal-cancel');
  const modalBackdrop = document.getElementById('province-modal-backdrop');

  const drawer = document.getElementById('province-drawer');
  const drawerBackdrop = document.getElementById('province-drawer-backdrop');
  const drawerClose = document.getElementById('province-drawer-close');
  const drawerImageWrap = document.getElementById('province-drawer-image-wrap');
  const drawerImage = document.getElementById('province-drawer-image');
  const drawerName = document.getElementById('province-drawer-name');
  const drawerCode = document.getElementById('province-drawer-code');
  const drawerRegion = document.getElementById('province-drawer-region');
  const drawerSlug = document.getElementById('province-drawer-slug');
  const drawerDishes = document.getElementById('province-drawer-dishes');
  const drawerCheckins = document.getElementById('province-drawer-checkins');
  const drawerCoordinates = document.getElementById('province-drawer-coordinates');
  const drawerCreated = document.getElementById('province-drawer-created');
  const drawerUpdated = document.getElementById('province-drawer-updated');
  const drawerDescription = document.getElementById('province-drawer-description');
  const drawerGallery = document.getElementById('province-drawer-gallery');

  let regionsCache = Array.isArray(initial.regions) ? initial.regions : [];
  let provincesCache = Array.isArray(initial.provinces) ? initial.provinces : [];
  let currentRegionFilter = '';
  let currentEditingCode = '';
  let selectedFiles = [];
  const objectUrls = new Set();

  function notify(type, message) {
    if (window.notify?.[type]) {
      window.notify[type](message);
      return;
    }
    if (type === 'error') {
      window.alert(message);
    }
  }

  function setError(node, message) {
    if (node) node.textContent = message || '';
  }

  function resetError(node) {
    setError(node, '');
  }

  function parseImageUrls(value) {
    const seen = new Set();
    return String(value || '')
      .split(/\r?\n/)
      .map((item) => item.trim())
      .filter(Boolean)
      .filter((item) => {
        if (seen.has(item)) return false;
        seen.add(item);
        return true;
      });
  }

  function clearObjectUrls() {
    objectUrls.forEach((url) => URL.revokeObjectURL(url));
    objectUrls.clear();
  }

  function mergeImageUrls(manualUrls, uploadedUrls) {
    return parseImageUrls([...manualUrls, ...uploadedUrls].join('\n'));
  }

  function openModal(modal) {
    if (!modal) return;
    closeDrawer();
    modal.classList.add('is-open');
    modalBackdrop?.classList.add('is-visible');
  }

  function closeModal(modal) {
    if (!modal) return;
    modal.classList.remove('is-open');
    if (!regionModal?.classList.contains('is-open') && !provinceModal?.classList.contains('is-open')) {
      modalBackdrop?.classList.remove('is-visible');
    }
  }

  function closeAllModals() {
    closeModal(regionModal);
    closeModal(provinceModal);
  }

  function renderImagePreview(urls, files) {
    clearObjectUrls();
    provinceImagePreview.innerHTML = '';

    const items = [
      ...urls.map((url, index) => ({ type: 'url', url, index })),
      ...files.map((file, index) => {
        const url = URL.createObjectURL(file);
        objectUrls.add(url);
        return { type: 'file', url, index };
      }),
    ];

    if (!items.length) {
      provinceImagePreview.innerHTML = '<span class="provinces-muted">Chưa có ảnh nào được chọn.</span>';
      return;
    }

    items.forEach((item) => {
      const card = document.createElement('div');
      card.className = 'provinces-preview-item';
      card.innerHTML = `<img src="${item.url}" alt="">`;

      const removeButton = document.createElement('button');
      removeButton.type = 'button';
      removeButton.className = 'icon-action danger';
      removeButton.textContent = 'X';
      removeButton.addEventListener('click', () => {
        if (item.type === 'url') {
          const nextUrls = parseImageUrls(provinceImages.value);
          nextUrls.splice(item.index, 1);
          provinceImages.value = nextUrls.join('\n');
        } else {
          selectedFiles.splice(item.index, 1);
        }
        renderImagePreview(parseImageUrls(provinceImages.value), selectedFiles);
      });

      card.appendChild(removeButton);
      provinceImagePreview.appendChild(card);
    });
  }

  function renderRegions() {
    regionList.innerHTML = regionsCache.map((region) => `
      <button class="provinces-region-item ${currentRegionFilter === region.code ? 'is-active' : ''}" type="button" data-region-code="${region.code}">
        <span class="provinces-region-item__main">
          <strong>${region.name}</strong>
          <small>${region.code}</small>
        </span>
        <span class="provinces-region-item__meta">
          <em>${region.macro_region || '-'}</em>
          <span class="icon-action danger" data-region-delete="${region.code}">Xóa</span>
        </span>
      </button>
    `).join('');

    regionFilter.innerHTML = `
      <option value="">Tất cả miền</option>
      ${regionsCache.map((region) => `<option value="${region.code}">${region.name}</option>`).join('')}
    `;

    provinceRegion.innerHTML = `
      <option value="">Chọn miền</option>
      ${regionsCache.map((region) => `<option value="${region.code}">${region.name}</option>`).join('')}
    `;

    if (currentEditingCode) {
      const item = provincesCache.find((province) => province.code === currentEditingCode);
      if (item) provinceRegion.value = item.regionsCode;
    }

    if (currentRegionFilter) {
      regionFilter.value = currentRegionFilter;
    }
  }

  function formatCoordinate(lat, lng) {
    const latNumber = Number(lat) || 0;
    const lngNumber = Number(lng) || 0;
    return `${latNumber}, ${lngNumber}`;
  }

  function filterProvinces() {
    const searchValue = String(provinceSearch.value || '').trim().toLowerCase();
    const regionValue = currentRegionFilter || regionFilter.value || '';

    const filtered = provincesCache.filter((province) => {
      const matchesRegion = !regionValue || province.regionsCode === regionValue;
      const matchesSearch = !searchValue || String(province.name || '').toLowerCase().includes(searchValue);
      return matchesRegion && matchesSearch;
    });

    provinceTableTitle.textContent = regionValue
      ? `Tỉnh thành thuộc miền ${regionValue}`
      : 'Tất cả tỉnh thành';
    provinceCount.textContent = `${filtered.length} tỉnh`;

    provincesTableBody.innerHTML = filtered.map((province) => `
      <tr>
        <td>${province.code}</td>
        <td>${province.name}</td>
        <td>${province.regionsCode}</td>
        <td>${Number(province.dishesCount || 0).toLocaleString('vi-VN')}</td>
        <td>${Number(province.checkinsCount || 0).toLocaleString('vi-VN')}</td>
        <td>${province.slug || '-'}</td>
        <td>${formatCoordinate(province.centerLat, province.centerLng)}</td>
        <td class="table-actions">
          <button class="icon-action" type="button" data-province-view="${province.code}">Xem</button>
          <button class="icon-action" type="button" data-province-edit="${province.code}">Sửa</button>
          <button class="icon-action danger" type="button" data-province-delete="${province.code}">Xóa</button>
        </td>
      </tr>
    `).join('') || '<tr><td colspan="8">Không có tỉnh thành phù hợp.</td></tr>';
  }

  async function fetchJson(url, options = {}) {
    const response = await fetch(url, options);
    const body = await response.json().catch(() => ({}));

    if (!response.ok || body.success === false) {
      throw new Error(body.message || body.error || 'Yêu cầu thất bại');
    }

    return body.data;
  }

  async function loadRegions() {
    regionsCache = await fetchJson('/admin/provinces/api/regions');
    renderRegions();
  }

  async function loadProvinces() {
    provincesCache = await fetchJson('/admin/provinces/api/list');
    filterProvinces();
  }

  async function uploadProvinceImage(file) {
    const formData = new FormData();
    formData.append('image', file);
    const result = await fetchJson('/admin/provinces/api/list/upload-image', {
      method: 'POST',
      body: formData,
    });
    return result.url || '';
  }

  async function uploadSelectedFiles() {
    if (!selectedFiles.length) return [];
    return Promise.all(selectedFiles.map((file) => uploadProvinceImage(file)));
  }

  function normalizeProvinceImages(province) {
    const urls = Array.isArray(province.imageUrls) ? province.imageUrls : [];
    const primary = province.imageUrl || urls[0] || '';
    return mergeImageUrls(primary ? [primary] : [], urls);
  }

  function resetProvinceForm() {
    provinceForm.reset();
    provinceCode.readOnly = false;
    resetError(provinceError);
    currentEditingCode = '';
    selectedFiles = [];
    provinceSubmitButton.textContent = 'Lưu tỉnh thành';
    provinceModalTitle.textContent = 'Thêm tỉnh thành';
    clearObjectUrls();
    renderImagePreview([], []);
    if (currentRegionFilter) {
      provinceRegion.value = currentRegionFilter;
    }
  }

  function fillProvinceForm(province) {
    currentEditingCode = province.code;
    provinceCode.value = province.code;
    provinceCode.readOnly = true;
    provinceName.value = province.name || '';
    provinceRegion.value = province.regionsCode || '';
    provinceSlug.value = province.slug || '';
    provinceLat.value = province.centerLat || 0;
    provinceLng.value = province.centerLng || 0;
    provinceDescription.value = province.description || '';
    provinceImages.value = normalizeProvinceImages(province).join('\n');
    selectedFiles = [];
    provinceSubmitButton.textContent = 'Cập nhật tỉnh thành';
    provinceModalTitle.textContent = 'Chỉnh sửa tỉnh thành';
    renderImagePreview(parseImageUrls(provinceImages.value), selectedFiles);
    openModal(provinceModal);
  }

  function toDateLabel(value) {
    if (!value) return '-';
    const date = typeof value === 'object' && value._seconds
      ? new Date(value._seconds * 1000)
      : new Date(value);
    return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString('vi-VN');
  }

  function openDrawer(province) {
    const images = normalizeProvinceImages(province);

    drawerName.textContent = province.name || '-';
    drawerCode.textContent = `Mã: ${province.code || '-'}`;
    drawerRegion.textContent = province.regionsCode || '-';
    drawerSlug.textContent = province.slug || '-';
    drawerDishes.textContent = Number(province.dishesCount || 0).toLocaleString('vi-VN');
    drawerCheckins.textContent = Number(province.checkinsCount || 0).toLocaleString('vi-VN');
    drawerCoordinates.textContent = formatCoordinate(province.centerLat, province.centerLng);
    drawerCreated.textContent = toDateLabel(province.createdAt);
    drawerUpdated.textContent = toDateLabel(province.updatedAt);
    drawerDescription.textContent = province.description || '-';
    drawerGallery.innerHTML = images.map((url) => `<img src="${url}" alt="">`).join('') || '<span class="provinces-muted">Không có ảnh.</span>';

    if (images[0]) {
      drawerImage.src = images[0];
      drawerImageWrap.classList.add('has-image');
    } else {
      drawerImage.removeAttribute('src');
      drawerImageWrap.classList.remove('has-image');
    }

    closeAllModals();
    drawer.classList.add('is-open');
    drawerBackdrop.classList.add('is-visible');
  }

  function closeDrawer() {
    drawer.classList.remove('is-open');
    drawerBackdrop.classList.remove('is-visible');
  }

  regionForm?.addEventListener('submit', async (event) => {
    event.preventDefault();
    resetError(regionError);

    try {
      await fetchJson('/admin/provinces/api/regions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code: regionCode.value.trim(),
          name: regionName.value.trim(),
          macro_region: regionMacro.value,
          number: regionNumber.value,
        }),
      });

      regionForm.reset();
      regionMacro.value = 'bac';
      await loadRegions();
      closeModal(regionModal);
      notify('success', 'Đã thêm miền');
    } catch (error) {
      setError(regionError, error.message);
    }
  });

  provinceForm?.addEventListener('submit', async (event) => {
    event.preventDefault();
    resetError(provinceError);

    const manualUrls = parseImageUrls(provinceImages.value);
    const isEditing = Boolean(currentEditingCode);

    try {
      provinceSubmitButton.disabled = true;
      const uploadedUrls = await uploadSelectedFiles();
      const imageUrls = mergeImageUrls(manualUrls, uploadedUrls);
      const payload = {
        code: provinceCode.value.trim(),
        name: provinceName.value.trim(),
        regionsCode: provinceRegion.value,
        slug: provinceSlug.value.trim(),
        centerLat: provinceLat.value,
        centerLng: provinceLng.value,
        description: provinceDescription.value.trim(),
        imageUrls,
        imageUrl: imageUrls[0] || '',
      };

      const method = currentEditingCode ? 'PUT' : 'POST';
      const endpoint = currentEditingCode
        ? `/admin/provinces/api/list/${encodeURIComponent(currentEditingCode)}`
        : '/admin/provinces/api/list';

      await fetchJson(endpoint, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      resetProvinceForm();
      await loadProvinces();
      closeModal(provinceModal);
      notify('success', isEditing ? 'Đã cập nhật tỉnh thành' : 'Đã thêm tỉnh thành');
    } catch (error) {
      setError(provinceError, error.message);
    } finally {
      provinceSubmitButton.disabled = false;
    }
  });

  regionList?.addEventListener('click', async (event) => {
    const deleteButton = event.target.closest('[data-region-delete]');
    if (deleteButton) {
      event.preventDefault();
      event.stopPropagation();

      const confirmed = window.confirm('Bạn chắc chắn muốn xóa miền này?');
      if (!confirmed) return;

      try {
        await fetchJson(`/admin/provinces/api/regions/${encodeURIComponent(deleteButton.dataset.regionDelete)}`, {
          method: 'DELETE',
        });
        if (currentRegionFilter === deleteButton.dataset.regionDelete) {
          currentRegionFilter = '';
          regionFilter.value = '';
        }
        await Promise.all([loadRegions(), loadProvinces()]);
        notify('success', 'Đã xóa miền');
      } catch (error) {
        setError(regionError, error.message);
      }
      return;
    }

    const regionButton = event.target.closest('[data-region-code]');
    if (!regionButton) return;

    currentRegionFilter = regionButton.dataset.regionCode || '';
    regionFilter.value = currentRegionFilter;
    renderRegions();
    filterProvinces();
  });

  provincesTableBody?.addEventListener('click', async (event) => {
    const viewButton = event.target.closest('[data-province-view]');
    if (viewButton) {
      const province = provincesCache.find((item) => item.code === viewButton.dataset.provinceView);
      if (province) openDrawer(province);
      return;
    }

    const editButton = event.target.closest('[data-province-edit]');
    if (editButton) {
      const province = provincesCache.find((item) => item.code === editButton.dataset.provinceEdit);
      if (province) fillProvinceForm(province);
      return;
    }

    const deleteButton = event.target.closest('[data-province-delete]');
    if (!deleteButton) return;

    const confirmed = window.confirm('Bạn chắc chắn muốn xóa tỉnh thành này?');
    if (!confirmed) return;

    try {
      await fetchJson(`/admin/provinces/api/list/${encodeURIComponent(deleteButton.dataset.provinceDelete)}`, {
        method: 'DELETE',
      });
      await loadProvinces();
      notify('success', 'Đã xóa tỉnh thành');
    } catch (error) {
      setError(provinceError, error.message);
    }
  });

  provinceSearch?.addEventListener('input', filterProvinces);
  regionFilter?.addEventListener('change', () => {
    currentRegionFilter = regionFilter.value || '';
    renderRegions();
    filterProvinces();
  });

  provinceReset?.addEventListener('click', () => {
    currentRegionFilter = '';
    provinceSearch.value = '';
    regionFilter.value = '';
    renderRegions();
    filterProvinces();
  });

  provinceOpenCreate?.addEventListener('click', () => {
    resetProvinceForm();
    openModal(provinceModal);
    provinceCode.focus();
  });

  regionOpenCreate?.addEventListener('click', () => {
    regionForm.reset();
    resetError(regionError);
    openModal(regionModal);
    regionCode.focus();
  });

  regionModalClose?.addEventListener('click', () => closeModal(regionModal));
  regionModalCancel?.addEventListener('click', () => closeModal(regionModal));
  provinceModalClose?.addEventListener('click', () => closeModal(provinceModal));
  provinceModalCancel?.addEventListener('click', () => closeModal(provinceModal));
  modalBackdrop?.addEventListener('click', closeAllModals);

  provinceImages?.addEventListener('input', () => {
    renderImagePreview(parseImageUrls(provinceImages.value), selectedFiles);
  });

  provinceImageFiles?.addEventListener('change', (event) => {
    const incomingFiles = Array.from(event.target.files || []).filter((file) => file.type.startsWith('image/'));
    selectedFiles = [...selectedFiles, ...incomingFiles];
    event.target.value = '';
    renderImagePreview(parseImageUrls(provinceImages.value), selectedFiles);
  });

  drawerClose?.addEventListener('click', closeDrawer);
  drawerBackdrop?.addEventListener('click', closeDrawer);
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      closeAllModals();
      closeDrawer();
    }
  });

  renderRegions();
  filterProvinces();
  renderImagePreview([], []);
})();
