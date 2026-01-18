document.addEventListener('DOMContentLoaded', () => {
  const regionListEl = document.getElementById('region-list');
  const provinceListEl = document.getElementById('province-list');
  const provinceTitle = document.getElementById('province-title');
  const provinceCount = document.getElementById('province-count');
  const searchInput = document.getElementById('search-province');
  const searchBtn = document.getElementById('btn-search-province');
  const resetBtn = document.getElementById('btn-reset-province');
  const addRegionBtn = document.getElementById('btn-add-region');
  const addRegionModalEl = document.getElementById('modal-add-region');
  const addRegionForm = document.getElementById('form-add-region');
  const alertRegion = document.getElementById('add-region-alert');
  const saveRegionBtn = document.getElementById('btn-save-region');
  const inputRegionCode = document.getElementById('region-code');
  const inputRegionName = document.getElementById('region-name');
  const inputRegionNumber = document.getElementById('region-number');
  const inputRegionMacro = document.getElementById('region-macro');
  const addRegionModal = addRegionModalEl && window.bootstrap ? new bootstrap.Modal(addRegionModalEl) : null;
  const addRegionCloseSelectors = '[data-bs-dismiss="modal"], .btn-close, .btn-light, .btn-secondary';
  // Add province elements
  const addProvinceBtn = document.getElementById('btn-add-province');
  const addProvinceModalEl = document.getElementById('modal-add-province');
  const addProvinceModal = addProvinceModalEl && window.bootstrap ? new bootstrap.Modal(addProvinceModalEl) : null;
  const addProvinceCloseSelectors = '[data-bs-dismiss="modal"], .btn-close, .btn-light, .btn-secondary';
  const addProvinceForm = document.getElementById('form-add-province');
  const alertProvince = document.getElementById('add-province-alert');
  const inputProvinceCode = document.getElementById('province-code');
  const inputProvinceName = document.getElementById('province-name');
  const selectProvinceRegion = document.getElementById('province-region');
  const inputProvinceSlug = document.getElementById('province-slug');
  const inputProvinceLat = document.getElementById('province-lat');
  const inputProvinceLng = document.getElementById('province-lng');
  const inputProvinceImages = document.getElementById('province-images');
  const inputProvinceImageFiles = document.getElementById('province-image-files');
  const previewProvinceImages = document.getElementById('province-image-preview-list');
  const inputProvinceDesc = document.getElementById('province-desc');
  const saveProvinceBtn = document.getElementById('btn-save-province');
  let regionsCache = [];
  let provincesCache = [];
  let currentRegion = null;
  let addSelectedFiles = [];
  let addManualUrls = [];
  const addImageObjectUrls = new Set();

  function showAddRegionModal() {
    if (addRegionModal) {
      addRegionModal.show();
    } else if (addRegionModalEl) {
      addRegionModalEl.style.display = 'block';
      addRegionModalEl.classList.add('show');
      document.body.classList.add('modal-open');
    }
  }

  function hideAddRegionModal() {
    if (addRegionModal) {
      addRegionModal.hide();
    } else if (addRegionModalEl) {
      addRegionModalEl.classList.remove('show');
      addRegionModalEl.style.display = 'none';
      document.body.classList.remove('modal-open');
    }
  }

  function showAddProvinceModal() {
    if (addProvinceModal) {
      addProvinceModal.show();
    } else if (addProvinceModalEl) {
      addProvinceModalEl.style.display = 'block';
      addProvinceModalEl.classList.add('show');
      document.body.classList.add('modal-open');
    }
  }

  function hideAddProvinceModal() {
    if (addProvinceModal) {
      addProvinceModal.hide();
    } else if (addProvinceModalEl) {
      addProvinceModalEl.classList.remove('show');
      addProvinceModalEl.style.display = 'none';
      document.body.classList.remove('modal-open');
    }
    clearObjectUrls(addImageObjectUrls);
  }

  function parseImageUrls(text) {
    const raw = (text || '').split(/\r?\n/).map((item) => item.trim()).filter(Boolean);
    const unique = [];
    const seen = new Set();
    raw.forEach((url) => {
      if (!seen.has(url)) {
        seen.add(url);
        unique.push(url);
      }
    });
    return unique;
  }

  function setImageUrlsInput(input, urls) {
    if (!input) return;
    input.value = urls.join('\n');
  }

  function clearObjectUrls(store) {
    store.forEach((url) => URL.revokeObjectURL(url));
    store.clear();
  }

  function pushFiles(target, fileList) {
    Array.from(fileList || []).forEach((file) => {
      if (!file.type || !file.type.startsWith('image/')) return;
      const key = `${file.name}_${file.size}_${file.lastModified}`;
      const exists = target.some((f) => `${f.name}_${f.size}_${f.lastModified}` === key);
      if (!exists) target.push(file);
    });
  }

  function renderImagePreview(container, urls, files, objectUrls, onUpdateUrls) {
    if (!container) return;
    clearObjectUrls(objectUrls);
    container.innerHTML = '';

    const items = [];
    urls.forEach((url, idx) => items.push({ kind: 'url', url, idx }));
    files.forEach((file, idx) => {
      const url = URL.createObjectURL(file);
      objectUrls.add(url);
      items.push({ kind: 'file', url, idx });
    });

    if (!items.length) {
      const empty = document.createElement('div');
      empty.className = 'text-muted small';
      empty.textContent = 'Chua co anh';
      container.appendChild(empty);
      return;
    }

    items.forEach((item) => {
      const wrap = document.createElement('div');
      wrap.className = 'position-relative';
      wrap.style.width = '80px';
      wrap.style.height = '80px';
      wrap.innerHTML =
        `<img src="${item.url}" alt="" ` +
        'style="width:100%;height:100%;object-fit:cover;border-radius:6px;border:1px solid #eee;">';
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'btn btn-sm btn-light position-absolute top-0 end-0';
      btn.textContent = 'x';
      btn.addEventListener('click', () => {
        if (item.kind === 'url') {
          urls.splice(item.idx, 1);
          onUpdateUrls && onUpdateUrls(urls);
        } else {
          files.splice(item.idx, 1);
        }
        renderImagePreview(container, urls, files, objectUrls, onUpdateUrls);
      });
      wrap.appendChild(btn);
      container.appendChild(wrap);
    });
  }

  function updateAddManualUrls(nextUrls) {
    addManualUrls = nextUrls;
    setImageUrlsInput(inputProvinceImages, addManualUrls);
  }

  function syncAddManualUrls() {
    addManualUrls = parseImageUrls(inputProvinceImages?.value || '');
  }

  function renderAddImagePreview() {
    renderImagePreview(
      previewProvinceImages,
      addManualUrls,
      addSelectedFiles,
      addImageObjectUrls,
      updateAddManualUrls,
    );
  }

  async function fetchJSON(url, options = {}) {
    const res = await fetch(url, options);
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || 'Request failed');
    return data;
  }

  async function loadRegions(selectCode) {
    regionListEl.innerHTML = '<div class="list-group-item text-center text-muted">Dang tai...</div>';
    try {
      const data = await fetchJSON('/manager-provinces/api/regions');
      regionsCache = data?.data || [];
      if (!regionsCache.length) {
        regionListEl.innerHTML = '<div class="list-group-item text-center text-muted">Chua co mien</div>';
        return;
      }
      renderRegions(regionsCache);
      const targetCode = selectCode && regionsCache.find((r) => (r.code || r.id) === selectCode)
        ? selectCode
        : (regionsCache[0].code || regionsCache[0].id);
      selectRegion(targetCode);
    } catch (e) {
      console.error(e);
      regionListEl.innerHTML = '<div class="list-group-item text-danger text-center">Loi tai mien</div>';
    }
  }

  function renderRegions(list) {
    regionListEl.innerHTML = list
      .map(
        (r) => `
        <div class="list-group-item region-item-wrapper" data-code="${r.code || r.id}">
          <div class="d-flex justify-content-between align-items-center">
            <div class="flex-grow-1">
              <div class="fw-semibold">${r.name || r.code || 'Chua dat ten'}</div>
              ${r.macro_region ? `<small class="text-muted">Vung: ${r.macro_region}</small>` : ''}
            </div>
            <div class="d-flex align-items-center gap-2">
              ${r.number ? `<span class="badge badge-soft-primary">${r.number}</span>` : ''}
              <button type="button" class="btn btn-sm btn-light text-danger btn-del-region" title="Xoa" data-code="${r.code || r.id}">
                <i class="bi-trash"></i>
              </button>
            </div>
          </div>
        </div>
      `,
      )
      .join('');
    regionListEl.querySelectorAll('.region-item-wrapper').forEach((item) => {
      item.addEventListener('click', (e) => {
        const target = e.target;
        if (target.closest('.btn-del-region')) return;
        selectRegion(item.dataset.code);
      });
    });
    regionListEl.querySelectorAll('.btn-del-region').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const code = btn.dataset.code;
        if (!code) return;
        handleDeleteRegion(code);
      });
    });
    // fill region select in province modal + edit modal
    const options =
      '<option value=\"\">-- Chon mien --</option>' +
      list.map((r) => `<option value=\"${r.code || r.id}\">${r.name || r.code}</option>`).join('');
    if (selectProvinceRegion) selectProvinceRegion.innerHTML = options;
    const editRegion = document.getElementById('edit-province-region');
    if (editRegion) editRegion.innerHTML = options;
  }

  async function selectRegion(code) {
    currentRegion = code;
    // highlight
    regionListEl
      .querySelectorAll('.region-item-wrapper')
      .forEach((btn) => btn.classList.toggle('active', btn.dataset.code === code));
    provinceTitle.textContent = `Tinh thanh - ${code}`;
    provinceListEl.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Dang tai...</td></tr>';
    try {
      const data = await fetchJSON(`/manager-provinces/api/provinces?regionCode=${encodeURIComponent(code)}`);
      provincesCache = data?.data || [];
      renderProvinces(provincesCache);
    } catch (e) {
      console.error(e);
      provinceListEl.innerHTML = '<tr><td colspan="4" class="text-center text-danger">Loi tai tinh thanh</td></tr>';
    }
  }

  function renderProvinces(list) {
    if (provinceCount) provinceCount.textContent = `${list.length} tinh`;
    if (!list.length) {
      provinceListEl.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Chua co tinh thanh</td></tr>';
      return;
    }
    provinceListEl.innerHTML = list
      .map(
        (p) => `
        <tr data-code="${p.code || ''}">
          <td>${p.code || ''}</td>
          <td>${p.name || ''}</td>
          <td>${p.regionsCode || ''}</td>
          <td class="text-center">
            <div class="dropdown">
              <button class="btn btn-sm btn-light dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                <i class="bi-three-dots-vertical"></i>
              </button>
              <ul class="dropdown-menu dropdown-menu-end province-action-menu">
                <li><button class="dropdown-item" type="button" data-action="view" data-id="${p.code || ''}">Xem</button></li>
                <li><button class="dropdown-item" type="button" data-action="edit" data-id="${p.code || ''}">Sua</button></li>
                <li><button class="dropdown-item text-danger" type="button" data-action="delete" data-id="${p.code || ''}">Xoa</button></li>
              </ul>
            </div>
          </td>
        </tr>
      `,
      )
      .join('');

    document.dispatchEvent(
      new CustomEvent('province:list-rendered', {
        detail: { container: provinceListEl, provinces: list },
      }),
    );

    if (window.provinceActionsWire) {
      window.provinceActionsWire(provinceListEl, list);
    }

  }
// Tim kiem tinh theo ten
  function applyProvinceSearch() {
    const q = (searchInput?.value || '').trim().toLowerCase();
    if (!q) {
      renderProvinces(provincesCache);
      return;
    }
    const filtered = provincesCache.filter((p) => (p.name || '').toLowerCase().includes(q));
    renderProvinces(filtered);
  }

  searchBtn?.addEventListener('click', applyProvinceSearch);
  searchInput?.addEventListener('keyup', (e) => {
    if (e.key === 'Enter') applyProvinceSearch();
  });
  resetBtn?.addEventListener('click', () => {
    if (searchInput) searchInput.value = '';
    renderProvinces(provincesCache);
  });

  function showRegionAlert(message) {
    if (!alertRegion) return;
    alertRegion.style.display = 'block';
    alertRegion.className = 'alert alert-danger';
    alertRegion.textContent = message;
  }

  addRegionBtn?.addEventListener('click', () => {
    addRegionForm?.reset();
    if (alertRegion) {
      alertRegion.style.display = 'none';
      alertRegion.textContent = '';
    }
    saveRegionBtn && (saveRegionBtn.disabled = false);
    saveRegionBtn && (saveRegionBtn.textContent = 'Luu');
    showAddRegionModal();
    setTimeout(() => inputRegionCode?.focus(), 200);
  });

  addRegionForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!inputRegionCode || !inputRegionName) return;
    const code = inputRegionCode.value.trim();
    const name = inputRegionName.value.trim();
    const number = inputRegionNumber?.value || '';
    const macroRegion = inputRegionMacro?.value || '';
    if (!code || !name) {
      showRegionAlert('Vui long nhap ma va ten mien');
      return;
    }
    if (!macroRegion) {
      showRegionAlert('Vui long chon macro_region (Bac/Trung/Nam)');
      return;
    }
    try {
      if (saveRegionBtn) {
        saveRegionBtn.disabled = true;
        saveRegionBtn.textContent = 'Dang luu...';
      }
      const res = await fetch('/manager-provinces/api/regions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code, name, number, macro_region: macroRegion }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.error || 'Them mien that bai');
      }
      hideAddRegionModal();
      await loadRegions(code);
      if (window.notify) window.notify.success('Them mien thanh cong');
    } catch (err) {
      console.error(err);
      showRegionAlert(err.message || 'Them mien that bai');
    } finally {
      if (saveRegionBtn) {
        saveRegionBtn.disabled = false;
        saveRegionBtn.textContent = 'Luu';
      }
    }
  });

  async function handleDeleteRegion(code) {
    const confirmed = window.confirm('Ban co chac muon xoa mien nay? (Khong the xoa neu con tinh thanh)');
    if (!confirmed) return;
    try {
      const res = await fetch(`/manager-provinces/api/regions/${encodeURIComponent(code)}`, {
        method: 'DELETE',
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.error || 'Xoa that bai');
      }
      await loadRegions();
      if (window.notify) window.notify.success('Xoa mien thanh cong');
    } catch (err) {
      console.error(err);
      alert(err.message || 'Xoa that bai');
    }
  }

  function showProvinceAlert(message) {
    if (!alertProvince) return;
    alertProvince.style.display = 'block';
    alertProvince.className = 'alert alert-danger';
    alertProvince.textContent = message;
  }

  addProvinceBtn?.addEventListener('click', () => {
    addProvinceForm?.reset();
    if (alertProvince) {
      alertProvince.style.display = 'none';
      alertProvince.textContent = '';
    }
    if (selectProvinceRegion && currentRegion) {
      selectProvinceRegion.value = currentRegion;
    }
    addSelectedFiles = [];
    addManualUrls = [];
    clearObjectUrls(addImageObjectUrls);
    if (inputProvinceImageFiles) inputProvinceImageFiles.value = '';
    if (inputProvinceImages) inputProvinceImages.value = '';
    renderAddImagePreview();
    saveProvinceBtn && (saveProvinceBtn.disabled = false);
    saveProvinceBtn && (saveProvinceBtn.textContent = 'Luu');
    showAddProvinceModal();
    setTimeout(() => inputProvinceCode?.focus(), 200);
  });

  inputProvinceImages?.addEventListener('input', () => {
    syncAddManualUrls();
    renderAddImagePreview();
  });

  inputProvinceImageFiles?.addEventListener('change', (e) => {
    const files = Array.from(e.target.files || []);
    const hasInvalid = files.some((file) => !file.type || !file.type.startsWith('image/'));
    if (hasInvalid) showProvinceAlert('Vui long chon file anh hop le');
    pushFiles(addSelectedFiles, files);
    e.target.value = '';
    renderAddImagePreview();
  });

  async function uploadProvinceImageFile(file) {
    const formData = new FormData();
    formData.append('image', file);
    const res = await fetch('/manager-provinces/api/provinces/upload-image', {
      method: 'POST',
      body: formData,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || 'Upload anh that bai');
    if (!data.url) throw new Error('Khong nhan duoc URL anh');
    return data.url;
  }

  async function uploadProvinceImageFiles(files) {
    if (!files || !files.length) return [];
    const uploads = files.map((file) => uploadProvinceImageFile(file));
    return Promise.all(uploads);
  }

  addProvinceForm?.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!inputProvinceCode || !inputProvinceName || !selectProvinceRegion) return;
    const manualUrls = parseImageUrls(inputProvinceImages?.value || '');
    let uploadedUrls = [];
    if (addSelectedFiles.length) {
      try {
        uploadedUrls = await uploadProvinceImageFiles(addSelectedFiles);
      } catch (uploadErr) {
        console.error(uploadErr);
        showProvinceAlert(uploadErr.message || 'Upload anh that bai');
        return;
      }
    }
    const imageUrls = parseImageUrls([...manualUrls, ...uploadedUrls].join('\n'));
    const imageUrl = imageUrls[0] || '';
    const payload = {
      code: inputProvinceCode.value.trim(),
      name: inputProvinceName.value.trim(),
      regionsCode: selectProvinceRegion.value.trim(),
      slug: inputProvinceSlug?.value.trim() || '',
      centerLat: inputProvinceLat?.value || 0,
      centerLng: inputProvinceLng?.value || 0,
      imageUrl,
      imageUrls,
      description: inputProvinceDesc?.value.trim() || '',
    };
    if (!payload.code || !payload.name || !payload.regionsCode) {
      showProvinceAlert('Ma tinh, ten tinh va ma mien la bat buoc');
      return;
    }
    try {
      if (saveProvinceBtn) {
        saveProvinceBtn.disabled = true;
        saveProvinceBtn.textContent = 'Dang luu...';
      }
      const res = await fetch('/manager-provinces/api/provinces', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || 'Them tinh that bai');
      hideAddProvinceModal();
      await selectRegion(payload.regionsCode);
      if (window.notify) window.notify.success('Them tinh thanh cong');
    } catch (err) {
      console.error(err);
      showProvinceAlert(err.message || 'Them tinh that bai');
    } finally {
      if (saveProvinceBtn) {
        saveProvinceBtn.disabled = false;
        saveProvinceBtn.textContent = 'Luu';
      }
    }
  });

// Fallback dropdown toggle (phòng khi Bootstrap JS chưa được load)
  document.addEventListener('click', (e) => {
    const toggle = e.target.closest('[data-bs-toggle="dropdown"]');
    const menus = document.querySelectorAll('.dropdown-menu.show');
    if (toggle) {
      const menu = toggle.parentElement.querySelector('.dropdown-menu');
      menus.forEach((m) => {
        if (m !== menu) m.classList.remove('show');
      });
      if (menu) menu.classList.toggle('show');
      e.preventDefault();
      e.stopPropagation();
    } else {
      menus.forEach((m) => m.classList.remove('show'));
    }
  });

  addRegionModalEl?.querySelectorAll(addRegionCloseSelectors).forEach((btn) => {
    btn.addEventListener('click', hideAddRegionModal);
  });
  addRegionModalEl?.addEventListener('click', (e) => {
    if (!addRegionModal && e.target === addRegionModalEl) hideAddRegionModal();
  });

  addProvinceModalEl?.querySelectorAll(addProvinceCloseSelectors).forEach((btn) => {
    btn.addEventListener('click', hideAddProvinceModal);
  });
  addProvinceModalEl?.addEventListener('click', (e) => {
    if (!addProvinceModal && e.target === addProvinceModalEl) hideAddProvinceModal();
  });

  // expose ham dung chung cho file action
  window.provincePage = {
    fetchJSON,
    selectRegion,
    getCurrentRegion: () => currentRegion,
    getProvincesCache: () => provincesCache,
  };

  loadRegions();
});





