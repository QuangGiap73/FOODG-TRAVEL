(function () {
  // Modal + form elements
  const modalEl = document.getElementById('modal-edit-dish');
  const modal = modalEl && window.bootstrap ? new bootstrap.Modal(modalEl) : null;
  const form = document.getElementById('form-edit-dish');
  const errorEl = document.getElementById('edit-error');
  const btnSave = document.getElementById('btn-save-dish');
  const closeSelectors = '[data-bs-dismiss="modal"], .btn-close, .btn-secondary';

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

  let cache = [];

  function showModal() {
    if (modal) {
      modal.show();
    } else if (modalEl) {
      modalEl.style.display = 'block';
      modalEl.classList.add('show');
    }
  }

  function hideModal() {
    if (modal) {
      modal.hide();
    } else if (modalEl) {
      modalEl.style.display = 'none';
      modalEl.classList.remove('show');
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

  // Nhận event render để gắn click vào dropdown
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

  // Fallback dropdown nếu không có Bootstrap JS
  document.addEventListener('click', (e) => {
    const toggleBtn = e.target.closest('[data-bs-toggle=\"dropdown\"]');
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

  // Fallback đóng modal khi không có Bootstrap JS
  if (!window.bootstrap && modalEl) {
    modalEl.addEventListener('click', (e) => {
      if (e.target === modalEl) hideModal();
    });
    modalEl.querySelectorAll(closeSelectors).forEach((btn) => {
      btn.addEventListener('click', hideModal);
    });
  }

  btnSave?.addEventListener('click', saveDish);
})();
