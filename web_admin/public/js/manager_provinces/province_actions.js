(() => {
  const modalEl = document.getElementById('modal-edit-province');
  const modal = modalEl ? new bootstrap.Modal(modalEl) : null;
  const form = document.getElementById('form-edit-province');
  const alertBox = document.getElementById('edit-province-alert');
  const editCode = document.getElementById('edit-province-code');
  const editName = document.getElementById('edit-province-name');
  const editRegion = document.getElementById('edit-province-region');
  const editSlug = document.getElementById('edit-province-slug');
  const editLat = document.getElementById('edit-province-lat');
  const editLng = document.getElementById('edit-province-lng');
  const editImage = document.getElementById('edit-province-image');
  const editDesc = document.getElementById('edit-province-desc');
  const btnUpdate = document.getElementById('btn-update-province');

  function openEdit(province) {
    if (!province) return;
    if (alertBox) {
      alertBox.style.display = 'none';
      alertBox.textContent = '';
    }
    editCode && (editCode.value = province.code || '');
    editName && (editName.value = province.name || '');
    editRegion && (editRegion.value = province.regionsCode || '');
    editSlug && (editSlug.value = province.slug || '');
    editLat && (editLat.value = province.centerLat || 0);
    editLng && (editLng.value = province.centerLng || 0);
    editImage && (editImage.value = province.imageUrl || '');
    editDesc && (editDesc.value = province.description || '');
    modal?.show();
  }

  async function submitEdit(e) {
    e.preventDefault();
    if (!editCode || !editName || !editRegion) return;
    const payload = {
      code: editCode.value.trim(),
      name: editName.value.trim(),
      regionsCode: editRegion.value.trim(),
      slug: editSlug?.value.trim() || '',
      centerLat: editLat?.value || 0,
      centerLng: editLng?.value || 0,
      imageUrl: editImage?.value.trim() || '',
      description: editDesc?.value.trim() || '',
    };
    if (!payload.code || !payload.name || !payload.regionsCode) {
      if (alertBox) {
        alertBox.style.display = 'block';
        alertBox.className = 'alert alert-danger';
        alertBox.textContent = 'Ma tinh, ten tinh va ma mien la bat buoc';
      }
      return;
    }
    try {
      btnUpdate && (btnUpdate.disabled = true, btnUpdate.textContent = 'Dang luu...');
      await window.provincePage.fetchJSON(
        `/manager-provinces/api/provinces/${encodeURIComponent(payload.code)}`,
        {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        },
      );
      modal?.hide();
      await window.provincePage.selectRegion(window.provincePage.getCurrentRegion());
    } catch (err) {
      console.error(err);
      if (alertBox) {
        alertBox.style.display = 'block';
        alertBox.className = 'alert alert-danger';
        alertBox.textContent = err.message || 'Cap nhat that bai';
      }
    } finally {
      btnUpdate && (btnUpdate.disabled = false, btnUpdate.textContent = 'Cap nhat');
    }
  }

  // Event delegation fallback in case custom event is missed
  document.addEventListener('click', (ev) => {
    const btn = ev.target.closest('.province-action-menu .dropdown-item');
    if (!btn) return;
    const action = btn.dataset.action;
    const code = btn.dataset.id;
    const provinces = window.provincePage?.getProvincesCache?.() || [];
    const province = provinces.find((p) => (p.code || p.id) === code);
    if (!province) return;
    if (action === 'view') {
      alert([
        `Ma: ${province.code}`,
        `Ten: ${province.name}`,
        `Mien: ${province.regionsCode}`,
        `Slug: ${province.slug || ''}`,
        `Lat: ${province.centerLat || 0}`,
        `Lng: ${province.centerLng || 0}`,
        `Image: ${province.imageUrl || ''}`,
        `Mo ta: ${province.description || ''}`,
      ].join('\n'));
    } else if (action === 'edit') {
      openEdit(province);
    }
  });

  document.addEventListener('province:list-rendered', (ev) => {
    const { container, provinces } = ev.detail || {};
    if (!container) return;
    container.querySelectorAll('.province-action-menu .dropdown-item').forEach((btn) => {
      btn.addEventListener('click', () => {
        const action = btn.dataset.action;
        const code = btn.dataset.id;
        const province = provinces?.find((p) => (p.code || p.id) === code);
        if (!province) return alert('Khong tim thay tinh thanh');
        if (action === 'view') {
          alert([
            `Ma: ${province.code}`,
            `Ten: ${province.name}`,
            `Mien: ${province.regionsCode}`,
            `Slug: ${province.slug || ''}`,
            `Lat: ${province.centerLat || 0}`,
            `Lng: ${province.centerLng || 0}`,
            `Image: ${province.imageUrl || ''}`,
            `Mo ta: ${province.description || ''}`,
          ].join('\n'));
        } else if (action === 'edit') {
          openEdit(province);
        }
      });
    });
  });

  form?.addEventListener('submit', submitEdit);
})();
