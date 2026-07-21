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
  const provincePopulation = document.getElementById('province-population');
  const provinceAreaKm2 = document.getElementById('province-area-km2');
  const provinceEstablishedDate = document.getElementById('province-established-date');
  const provinceVehiclePlate = document.getElementById('province-vehicle-plate');
  const provinceCodeLabel = document.getElementById('province-code-label');
  const provinceDescriptionEn = document.getElementById('province-description-en');
  const provinceDescription = document.getElementById('province-description');
  const provincePlaceAdd = document.getElementById('province-place-add');
  const provincePlaceList = document.getElementById('province-place-list');
  const provinceImages = document.getElementById('province-images');
  const provinceImageFiles = document.getElementById('province-image-files');
  const provinceImagePreview = document.getElementById('province-image-preview');
  const provinceError = document.getElementById('province-error');
  const provinceSubmitButton = document.getElementById('province-submit-button');
  const provincesTableBody = document.getElementById('provinces-table-body');
  const provinceCheckAll = document.getElementById('province-check-all');
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
  const drawerPopulation = document.getElementById('province-drawer-population');
  const drawerArea = document.getElementById('province-drawer-area');
  const drawerEstablished = document.getElementById('province-drawer-established');
  const drawerPlate = document.getElementById('province-drawer-plate');
  const drawerCodeLabel = document.getElementById('province-drawer-code-label');
  const drawerCoordinates = document.getElementById('province-drawer-coordinates');
  const drawerCreated = document.getElementById('province-drawer-created');
  const drawerUpdated = document.getElementById('province-drawer-updated');
  const drawerDescriptionEn = document.getElementById('province-drawer-description-en');
  const drawerDescription = document.getElementById('province-drawer-description');
  const drawerPlaces = document.getElementById('province-drawer-places');
  const drawerGallery = document.getElementById('province-drawer-gallery');

  let regionsCache = Array.isArray(initial.regions) ? initial.regions : [];
  let provincesCache = Array.isArray(initial.provinces) ? initial.provinces : [];
  let currentRegionFilter = '';
  let currentEditingCode = '';
  let selectedFiles = [];
  let provincePlaces = [];
  const objectUrls = new Set();
  let toastTimer = null;
  const placePreviewUrls = new WeakMap();

  function notify(type, message) {
    const toast = document.createElement('div');
    toast.className = `provinces-toast provinces-toast--${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);

    requestAnimationFrame(() => {
      toast.classList.add('is-visible');
    });

    clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => {
      toast.classList.remove('is-visible');
      window.setTimeout(() => {
        toast.remove();
      }, 220);
    }, 2000);
  }

  function setError(node, message) {
    if (node) node.textContent = message || '';
  }

  function provinceRowChecks() {
    return Array.from(document.querySelectorAll('.province-row-check'));
  }

  function syncProvinceCheckState() {
    if (!provinceCheckAll) return;
    const checks = provinceRowChecks();
    const checkedCount = checks.filter((item) => item.checked).length;
    provinceCheckAll.checked = checks.length > 0 && checkedCount === checks.length;
    provinceCheckAll.indeterminate = checkedCount > 0 && checkedCount < checks.length;
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

  function parsePlaceRows() {
    if (!provincePlaceList) return [];
    return Array.from(provincePlaceList.querySelectorAll('[data-place-row]')).map((row) => ({
      nameVi: String(row.querySelector('[data-place-name-vi]')?.value || '').trim(),
      nameEn: String(row.querySelector('[data-place-name-en]')?.value || '').trim(),
      imageUrl: String(row.querySelector('[data-place-image-url]')?.value || '').trim(),
      slug: String(row.querySelector('[data-place-slug]')?.value || '').trim(),
    })).filter((item) => item.nameVi || item.nameEn || item.imageUrl || item.slug);
  }

  function setPlacePreview(row, src) {
    const preview = row.querySelector('[data-place-preview]');
    const previewBox = row.querySelector('.provinces-place-card__preview');
    if (!previewBox) return;

    previewBox.innerHTML = src
      ? `<img data-place-preview src="${src}" alt="">`
      : '<span>Chưa có ảnh</span>';
  }

  function createPlaceRow(place = {}) {
    const item = document.createElement('div');
    item.className = 'provinces-place-row';
    item.dataset.placeRow = 'true';
    item.innerHTML = `
      <div class="provinces-place-card__header">
        <strong>Địa điểm</strong>
        <button type="button" class="secondary-button provinces-place-row__remove">Xóa</button>
      </div>
      <div class="provinces-place-card__preview">
        ${place.imageUrl ? `<img data-place-preview src="${place.imageUrl}" alt="">` : '<span>Chưa có ảnh</span>'}
      </div>
      <div class="provinces-place-grid">
        <label>
          <span>Tên VI</span>
          <input data-place-name-vi type="text" placeholder="Tên địa điểm (VI)" value="${place.nameVi || ''}">
        </label>
        <label>
          <span>Tên EN</span>
          <input data-place-name-en type="text" placeholder="Place name (EN)" value="${place.nameEn || ''}">
        </label>
        <label>
          <span>Slug</span>
          <input data-place-slug type="text" placeholder="slug" value="${place.slug || ''}">
        </label>
        <label>
          <span>Ảnh URL</span>
          <input data-place-image-url type="url" placeholder="https://..." value="${place.imageUrl || ''}">
        </label>
        <label class="provinces-place-file">
          <span>Ảnh từ máy</span>
          <input data-place-image-file type="file" accept="image/*">
        </label>
      </div>
    `;
    const fileInput = item.querySelector('[data-place-image-file]');
    const imageInput = item.querySelector('[data-place-image-url]');

    fileInput?.addEventListener('change', async () => {
      const file = fileInput.files?.[0];
      const oldUrl = placePreviewUrls.get(item);
      if (oldUrl) URL.revokeObjectURL(oldUrl);
      if (!file) return;

      const objectUrl = URL.createObjectURL(file);
      placePreviewUrls.set(item, objectUrl);
      setPlacePreview(item, objectUrl);
      try {
        const uploadedUrl = await uploadProvinceImage(file);
        imageInput.value = uploadedUrl;
        const currentObjectUrl = placePreviewUrls.get(item);
        if (currentObjectUrl) URL.revokeObjectURL(currentObjectUrl);
        placePreviewUrls.delete(item);
        setPlacePreview(item, uploadedUrl);
      } catch (error) {
        console.error('Upload anh dia diem that bai:', error);
        notify('error', error.message || 'Không thể tải ảnh địa điểm lên');
      }
    });

    imageInput?.addEventListener('input', () => {
      const oldUrl = placePreviewUrls.get(item);
      if (oldUrl) {
        URL.revokeObjectURL(oldUrl);
        placePreviewUrls.delete(item);
      }
      const url = String(imageInput.value || '').trim();
      setPlacePreview(item, url);
    });

    item.querySelector('.provinces-place-row__remove')?.addEventListener('click', () => {
      const oldUrl = placePreviewUrls.get(item);
      if (oldUrl) URL.revokeObjectURL(oldUrl);
      placePreviewUrls.delete(item);
      item.remove();
      if (!provincePlaceList.children.length) {
        provincePlaceList.innerHTML = '<p class="provinces-muted">Chưa có địa điểm nào.</p>';
      }
    });

    return item;
  }

  function renderPlaceRows(places = []) {
    if (!provincePlaceList) return;
    const rows = Array.isArray(places) && places.length ? places : provincePlaces;
    provincePlaceList.innerHTML = '';
    if (!rows.length) {
      provincePlaceList.innerHTML = '<p class="provinces-muted">Chưa có địa điểm nào.</p>';
      return;
    }

    rows.forEach((place) => {
      provincePlaceList.appendChild(createPlaceRow(place));
    });
  }

  function addEmptyPlaceRow() {
    if (!provincePlaceList) return;
    if (provincePlaceList.querySelector('.provinces-muted')) {
      provincePlaceList.innerHTML = '';
    }
    provincePlaceList.appendChild(createPlaceRow());
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
    if (!regionList || !regionFilter || !provinceRegion) return;

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
    if (!provincesTableBody || !provinceSearch || !provinceCount || !provinceTableTitle || !regionFilter) return;

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

    provincesTableBody.innerHTML = filtered.map((province) => {
      const cover = province.imageUrl || (Array.isArray(province.imageUrls) ? province.imageUrls[0] : '');
      const thumbMarkup = cover
        ? `<img src="${cover}" alt="${province.name || ''}">`
        : `<span>${String(province.name || 'P').charAt(0)}</span>`;

      return `
      <tr>
        <td><input type="checkbox" class="province-row-check" value="${province.code}" /></td>
        <td><div class="province-thumb">${thumbMarkup}</div></td>
        <td>${province.name}</td>
        <td>${province.regionsCode}</td>
        <td>${Number(province.dishesCount || 0).toLocaleString('vi-VN')}</td>
        <td>${Number(province.checkinsCount || 0).toLocaleString('vi-VN')}</td>
        <td>${formatCoordinate(province.centerLat, province.centerLng)}</td>
        <td class="table-actions">
          <details class="provinces-action-menu">
            <summary class="provinces-action-menu__trigger" aria-label="Mở menu thao tác">
              <span></span>
              <span></span>
              <span></span>
            </summary>
            <div class="provinces-action-menu__dropdown">
              <button class="provinces-action-menu__item" type="button" data-province-view="${province.code}">Xem</button>
              <button
                class="provinces-action-menu__item"
                type="button"
                data-province-edit="${province.code}"
                data-province-code="${province.code}"
                data-province-name="${province.name || ''}"
                data-province-region="${province.regionsCode || ''}"
                data-province-slug="${province.slug || ''}"
                data-province-lat="${province.centerLat || 0}"
                data-province-lng="${province.centerLng || 0}"
                data-province-description="${province.description || ''}"
                data-province-image-url="${province.imageUrl || ''}"
                data-province-image-urls="${Array.isArray(province.imageUrls) ? province.imageUrls.join('\n') : ''}"
              >Sửa</button>
              <button class="provinces-action-menu__item provinces-action-menu__item--danger" type="button" data-province-delete="${province.code}">Xóa</button>
            </div>
          </details>
        </td>
      </tr>`;
    }).join('') || '<tr><td colspan="8">Không có tỉnh thành phù hợp.</td></tr>';

    syncProvinceCheckState();
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
    provincePlaces = [];
    provinceSubmitButton.textContent = 'Lưu tỉnh thành';
    provinceModalTitle.textContent = 'Thêm tỉnh thành';
    clearObjectUrls();
    renderImagePreview([], []);
    renderPlaceRows([]);
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
    provincePopulation.value = province.population || '';
    provinceAreaKm2.value = province.areaKm2 || '';
    provinceEstablishedDate.value = province.establishedDate || '';
    provinceVehiclePlate.value = province.vehiclePlateCode || '';
    provinceCodeLabel.value = province.provinceCodeLabel || province.code || '';
    provinceDescriptionEn.value = province.descriptionEn || '';
    provinceDescription.value = province.description || '';
    provincePlaces = Array.isArray(province.places) ? province.places : [];
    renderPlaceRows(provincePlaces);
    provinceImages.value = normalizeProvinceImages(province).join('\n');
    selectedFiles = [];
    provincePlaces = Array.isArray(province.places) ? province.places : [];
    provinceSubmitButton.textContent = 'Cập nhật tỉnh thành';
    provinceModalTitle.textContent = 'Chỉnh sửa tỉnh thành';
    renderImagePreview(parseImageUrls(provinceImages.value), selectedFiles);
    openModal(provinceModal);
  }

  function readProvinceFromButton(button) {
    if (!button) return null;

    const code = String(button.dataset.provinceEdit || button.dataset.provinceCode || '').trim();
    if (!code) return null;

    return {
      code,
      name: String(button.dataset.provinceName || '').trim(),
      regionsCode: String(button.dataset.provinceRegion || '').trim(),
      slug: String(button.dataset.provinceSlug || '').trim(),
      centerLat: Number(button.dataset.provinceLat || 0) || 0,
      centerLng: Number(button.dataset.provinceLng || 0) || 0,
      description: String(button.dataset.provinceDescription || '').trim(),
      imageUrl: String(button.dataset.provinceImageUrl || '').trim(),
      imageUrls: String(button.dataset.provinceImageUrls || '')
        .split('\n')
        .map((item) => item.trim())
        .filter(Boolean),
    };
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
    drawerPopulation.textContent = province.population || '-';
    drawerArea.textContent = province.areaKm2 || '-';
    drawerEstablished.textContent = province.establishedDate || '-';
    drawerPlate.textContent = province.vehiclePlateCode || '-';
    drawerCodeLabel.textContent = province.provinceCodeLabel || province.code || '-';
    drawerCoordinates.textContent = formatCoordinate(province.centerLat, province.centerLng);
    drawerCreated.textContent = toDateLabel(province.createdAt);
    drawerUpdated.textContent = toDateLabel(province.updatedAt);
    drawerDescriptionEn.textContent = province.descriptionEn || '-';
    drawerDescription.textContent = province.description || '-';
    drawerPlaces.innerHTML = Array.isArray(province.places) && province.places.length
      ? province.places.map((place) => `
          <div class="province-place-card">
            ${place.imageUrl ? `<img src="${place.imageUrl}" alt="">` : '<div class="province-place-card__empty">No image</div>'}
            <div>
              <strong>${place.nameVi || '-'}</strong>
              <small>${place.nameEn || ''}</small>
            </div>
          </div>
        `).join('')
      : '<span class="provinces-muted">Chưa có địa điểm.</span>';
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

      closeModal(regionModal);
      closeDrawer();
      regionForm.reset();
      regionMacro.value = 'bac';
      await loadRegions();
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
      const placeRows = Array.from(provincePlaceList?.querySelectorAll('[data-place-row]') || []);
      const places = [];
      for (const row of placeRows) {
        const nameVi = String(row.querySelector('[data-place-name-vi]')?.value || '').trim();
        const nameEn = String(row.querySelector('[data-place-name-en]')?.value || '').trim();
        const slug = String(row.querySelector('[data-place-slug]')?.value || '').trim();
        const imageUrlInput = String(row.querySelector('[data-place-image-url]')?.value || '').trim();
        const file = row.querySelector('[data-place-image-file]')?.files?.[0] || null;
        let finalImageUrl = imageUrlInput;
        if (file) {
          finalImageUrl = await uploadProvinceImage(file);
        }
        if (nameVi || nameEn || slug || finalImageUrl) {
          places.push({
            nameVi,
            nameEn,
            imageUrl: finalImageUrl,
            slug,
          });
        }
      }

      const payload = {
        code: provinceCode.value.trim(),
        name: provinceName.value.trim(),
        regionsCode: provinceRegion.value,
        slug: provinceSlug.value.trim(),
        centerLat: provinceLat.value,
        centerLng: provinceLng.value,
        population: provincePopulation.value.trim(),
        areaKm2: provinceAreaKm2.value.trim(),
        establishedDate: provinceEstablishedDate.value.trim(),
        vehiclePlateCode: provinceVehiclePlate.value.trim(),
        provinceCodeLabel: provinceCodeLabel.value.trim(),
        descriptionEn: provinceDescriptionEn.value.trim(),
        description: provinceDescription.value.trim(),
        places,
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

      closeModal(provinceModal);
      closeDrawer();
      await loadProvinces();
      resetProvinceForm();
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
      const province =
        provincesCache.find((item) => item.code === editButton.dataset.provinceEdit) ||
        readProvinceFromButton(editButton);
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
  provinceCheckAll?.addEventListener('change', () => {
    provinceRowChecks().forEach((item) => {
      item.checked = provinceCheckAll.checked;
    });
    syncProvinceCheckState();
  });

  document.addEventListener('change', (event) => {
    if (event.target.classList.contains('province-row-check')) {
      syncProvinceCheckState();
    }
  });

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

  provincePlaceAdd?.addEventListener('click', addEmptyPlaceRow);

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


