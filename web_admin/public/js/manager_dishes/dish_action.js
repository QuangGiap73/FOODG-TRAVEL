/* global bootstrap */
(function () {
  // Modal + form elements
  const modalEl = document.getElementById('modal-edit-dish');
  const modal = modalEl && window.bootstrap ? new bootstrap.Modal(modalEl) : null;
  const form = document.getElementById('form-edit-dish');
  const errorEl = document.getElementById('edit-error');
  const btnSave = document.getElementById('btn-save-dish');
  const closeSelectors = '[data-bs-dismiss="modal"], .btn-close, .btn-secondary';

  const addModalEl = document.getElementById('modal-add-dish');
  const addModal = addModalEl && window.bootstrap ? new bootstrap.Modal(addModalEl) : null;
  const addForm = document.getElementById('form-add-dish');
  const addError = document.getElementById('add-error');
  const btnSaveAdd = document.getElementById('btn-save-add');
  const btnOpenAdd = document.getElementById('btn-add-dish');

  // object s­a
  const f = {
    id: document.getElementById('edit-id'),
    name: document.getElementById('edit-name'),
    slug: document.getElementById('edit-slug'),
    province: document.getElementById('edit-province'),
    region: document.getElementById('edit-region'),
    category: document.getElementById('edit-category'),
    price: document.getElementById('edit-price'),
    bestTime: document.getElementById('edit-best-time'),
    bestSeason: document.getElementById('edit-best-season'),
    tags: document.getElementById('edit-tags'),
    spicy: document.getElementById('edit-spicy'),
    satiety: document.getElementById('edit-satiety'),
    img: document.getElementById('edit-img'),
    desc: document.getElementById('edit-desc'),
  };
  // object them mon
  const a = {
    id: document.getElementById('add-id'),
    name: document.getElementById('add-name'),
    slug: document.getElementById('add-slug'),
    province: document.getElementById('add-province'),
    region: document.getElementById('add-region'),
    category: document.getElementById('add-category'),
    price: document.getElementById('add-price'),
    bestTime: document.getElementById('add-best-time'),
    bestSeason: document.getElementById('add-best-season'),
    tags: document.getElementById('add-tags'),
    spicy: document.getElementById('add-spicy'),
    satiety: document.getElementById('add-satiety'),
    img: document.getElementById('add-img'),
    desc: document.getElementById('add-desc'),
  };

  let cache = [];

  // tao api de tao select tinh mien cho phan them mon an
  let provincesCache = []; // taoj mang cache luu danh sach
  // tao ham load danh sach tinh tu serve
  async function loadProvinces() {
    const res = await fetch('/manager-provinces/api/provinces'); // gui request lay api danh sach
    const data = await res.json().catch(() => ({})); // chuyen sang json

    if (!res.ok) {
      throw new Error(data.error || 'Tai danh sach that bai');
    }
    provincesCache = data.data || []; //luu danh sach tinh vao cache

    // xu ly danh sach mien
    const regions = [
      // lay danh sach tinh
      ...new Set(provincesCache.map((p) => p.regionsCode || p.region)),
    ].filter(Boolean);
    // tao danh sach option cho select mien
    const regionOpts = ['<option value="">-- Chon mien --</option>']
      .concat(regions.map((r) => `<option value="${r}">${r}</option>`))
      .join('');
    // do option mien vao select o form
    const addRegion = document.getElementById('add-region');
    if (addRegion) addRegion.innerHTML = regionOpts;
    const editRegion = document.getElementById('edit-region');
    if (editRegion) editRegion.innerHTML = regionOpts;
    renderProvinceOptions('', false); // hien thi tat ca tinh khi chua chon mien
    renderProvinceOptions('', true);
  }
  // ham render danh sach tinh theo mien
  function renderProvinceOptions(regionCode, isEdit = false) {
    const sel = document.getElementById(isEdit ? 'edit-province' : 'add-province');
    if (!sel) return;
    // chon mien thi loc tinh
    const list = regionCode
      ? provincesCache.filter((p) => (p.regionsCode || p.region) === regionCode)
      : provincesCache;
    // tao option cho select tinh
    sel.innerHTML = ['<option value="">-- Chon tinh --</option>']
      .concat(
        list.map(
          (p) => `
        <option 
          value="${p.code || p.id}" 
          data-region="${p.regionsCode || p.region}">
          ${p.name || p.code}
        </option>
      `,
        ),
      )
      .join('');
  }

  // ham may modal sua mon an
  function showModal() {
    if (modal) {
      modal.show();
    } else if (modalEl) {
      modalEl.style.display = 'block';
      modalEl.classList.add('show');
    }
  }
  // ham dong modal sua mon an
  function hideModal() {
    if (modal) {
      modal.hide();
    } else if (modalEl) {
      modalEl.style.display = 'none';
      modalEl.classList.remove('show');
    }
  }
  // ham may modal them mon an
  function showAddModal() {
    addError && (addError.textContent = '');
    addForm?.reset();
    renderProvinceOptions('', false); // reset select tinh khi mo modal
    if (addModal) addModal.show();
    else if (addModalEl) {
      addModalEl.style.display = 'block';
      addModalEl.classList.add('show');
    }
  }
  // ham dong modal them mon an
  function hideAddModal() {
    if (addModal) addModal.hide();
    else if (addModalEl) {
      addModalEl.style.display = 'none';
      addModalEl.classList.remove('show');
    }
  }
  function onView(id) {
    alert(`Xem mon ${id}`);
  }

  function onEdit(id) {
    const dish = cache.find((d) => String(d.id || d.STT) === String(id));
    if (!dish) {
      alert('Khong tim thay mon');
      return;
    }
    errorEl && (errorEl.textContent = '');
    form?.reset();
    if (f.id) f.id.value = dish.id || '';
    if (f.name) f.name.value = dish.Name || dish.name || '';
    if (f.slug) f.slug.value = dish.slug || '';
    if (f.province) f.province.value = dish.province_code || '';
    if (f.region) f.region.value = dish.region_code || '';
    if (f.category) f.category.value = dish.category || '';
    if (f.price) f.price.value = dish.price_range || '';
    if (f.bestTime) f.bestTime.value = dish.Best_time || dish.best_time || '';
    if (f.bestSeason) f.bestSeason.value = dish.Best_season || dish.best_season || '';
    if (f.tags) f.tags.value = dish.Tags || dish.tags || '';
    if (f.spicy) f.spicy.value = dish.spicy_level ?? '';
    if (f.satiety) f.satiety.value = dish.satiety_level ?? '';
    if (f.img) f.img.value = dish.Img || dish.img || dish.imageUrl || '';
    if (f.desc) f.desc.value = dish.description || '';
    showModal();
    // neu ban doi edit-region/edit-province sang select thi goi renderProvinceOptions(f.region.value, true) o day va set value
  }

  async function onDelete(id) {
    if (!id) return;
    if (!confirm('Ban chac chan muon xoa mon nay?')) return;
    try {
      const res = await fetch(`/manager-dishes/api/dishes/${encodeURIComponent(id)}`, { method: 'DELETE' });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || 'Xoa mon that bai');
      document.getElementById('btn-search-dish')?.click();
    } catch (err) {
      console.error(err);
      alert(err.message || 'Xoa mon that bai');
    }
  }
  // ham cap nhat sau khi sua
  async function saveDish() {
    if (!f.id || !f.name) return;
    const id = f.id.value || '';
    const payload = {
      Name: f.name.value.trim(),
      slug: f.slug.value.trim(),
      province_code: f.province.value.trim(),
      region_code: f.region.value.trim(),
      category: f.category.value.trim(),
      price_range: f.price.value.trim(),
      Best_time: f.bestTime.value.trim(),
      Best_season: f.bestSeason.value.trim(),
      Tags: f.tags.value.trim(),
      spicy_level: Number(f.spicy.value || 0),
      satiety_level: Number(f.satiety.value || 0),
      Img: f.img.value.trim(),
      description: f.desc.value.trim(),
      updatedAt: new Date().toISOString(),
    };
    if (!payload.Name) {
      errorEl && (errorEl.textContent = 'Ten mon bat buoc');
      return;
    }
    try {
      if (btnSave) btnSave.disabled = true;
      const res = await fetch(`/manager-dishes/api/dishes/${encodeURIComponent(id)}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || 'Cap nhat that bai');
      hideModal();
      document.getElementById('btn-search-dish')?.click();
    } catch (err) {
      console.error(err);
      errorEl && (errorEl.textContent = err.message || 'Cap nhat that bai');
    } finally {
      if (btnSave) btnSave.disabled = false;
    }
  }
  // ham luu khi them mon len firebase
  async function saveNewDish() {
    if (!a.id || !a.name) return;
    const payload = {
      id: a.id.value.trim(),
      Name: a.name.value.trim(),
      slug: a.slug.value.trim(),
      province_code: a.province.value.trim(),
      region_code: a.region.value.trim(),
      category: a.category.value.trim(),
      price_range: a.price.value.trim(),
      Best_time: a.bestTime.value.trim(),
      Best_season: a.bestSeason.value.trim(),
      Tags: a.tags.value.trim(),
      spicy_level: Number(a.spicy.value || 0),
      satiety_level: Number(a.satiety.value || 0),
      Img: a.img.value.trim(),
      description: a.desc.value.trim(),
      createdAt: new Date().toISOString(),
    };
    if (!payload.id || !payload.Name) {
      addError && (addError.textContent = 'Id va Ten la bat buoc');
      return;
    }
    try {
      if (btnSaveAdd) btnSaveAdd.disabled = true;
      const res = await fetch('/manager-dishes/api/dishes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error || 'Them mon that bai');
      hideAddModal();
      document.getElementById('btn-search-dish')?.click();
    } catch (err) {
      console.error(err);
      addError && (addError.textContent = err.message || 'Them mon that bai');
    } finally {
      if (btnSaveAdd) btnSaveAdd.disabled = false;
    }
  }

  // Nhan event render de gan click vao dropdown
  document.addEventListener('dish:list-rendered', (e) => {
    const { container, list } = e.detail || {};
    if (!container) return;
    cache = list || [];
    container.querySelectorAll('.dropdown-item').forEach((btn) => {
      btn.addEventListener('click', () => {
        const action = btn.dataset.action;
        const id = btn.dataset.id;
        if (action === 'view') onView(id);
        else if (action === 'edit') onEdit(id);
        else if (action === 'delete') onDelete(id);
      });
    });
  });

  // Fallback dropdown neu khong co Bootstrap JS
  document.addEventListener('click', (e) => {
    const toggleBtn = e.target.closest('[data-bs-toggle="dropdown"]');
    const openMenus = document.querySelectorAll('.dropdown-menu.show');
    if (toggleBtn) {
      const menu = toggleBtn.parentElement?.querySelector('.dropdown-menu');
      openMenus.forEach((m) => {
        if (m !== menu) m.classList.remove('show');
      });
      if (menu) menu.classList.toggle('show');
      e.preventDefault();
      e.stopPropagation();
    } else {
      openMenus.forEach((m) => m.classList.remove('show'));
    }
  });

  // Fallback dong modal khi khong co Bootstrap JS
  if (!window.bootstrap && modalEl) {
    modalEl.addEventListener('click', (e) => {
      if (e.target === modalEl) hideModal();
    });
    modalEl.querySelectorAll(closeSelectors).forEach((btn) => {
      btn.addEventListener('click', hideModal);
    });
  }
  // Fallback dong modal cua them mon an
  if (!window.bootstrap && addModalEl) {
    addModalEl.addEventListener('click', (e) => {
      if (e.target === addModalEl) hideAddModal();
    });
    addModalEl.querySelectorAll(closeSelectors).forEach((btn) => {
      btn.addEventListener('click', hideAddModal);
    });
  }

  // bat su kien khi nguoi dung thay doi mien o form add
  document.getElementById('add-region')?.addEventListener('change', (e) => {
    renderProvinceOptions(e.target.value, false); // goi ham renderProvinceOption de loc tinh theo mien
  });
  document.getElementById('add-province')?.addEventListener('change', (e) => {
    // lay option dang duoc chon
    const option = e.target.selectedOptions[0];
    const region = option?.dataset.region || '';
    const regionSelect = document.getElementById('add-region');
    if (region && regionSelect) {
      regionSelect.value = region;
    }
  });
  // bat su kien khi nguoi dung thay doi mien o form edit
  document.getElementById('edit-region')?.addEventListener('change', (e) => {
    renderProvinceOptions(e.target.value, true);
  });
  // bat su kien khi nguoi dung duungf thay doi tinh o form edit
  document.getElementById('edit-province')?.addEventListener('change', (e) => {
    const option = e.target.selectedOptions[0];
    const region = option?.dataset.region || '';
    const regionSelect = document.getElementById('edit-region');
    if (region && regionSelect) {
      regionSelect.value = region;
    }
  });

  btnSave?.addEventListener('click', saveDish);
  btnOpenAdd?.addEventListener('click', showAddModal);
  btnSaveAdd?.addEventListener('click', saveNewDish);

  loadProvinces().catch((err) => console.error(err));
})();
