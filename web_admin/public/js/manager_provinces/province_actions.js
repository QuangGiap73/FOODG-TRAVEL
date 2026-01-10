(() => {
  const modalEl = document.getElementById('modal-edit-province');
  const modal = modalEl && window.bootstrap ? new bootstrap.Modal(modalEl) : null;
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
  const modalDismissSelectors = '[data-bs-dismiss="modal"], .btn-close, .btn-secondary';
  const drawer = document.getElementById('province-drawer');
  const drawerOverlay = document.getElementById('province-drawer-overlay');
  const drawerClose = document.getElementById('province-drawer-close');
  const detailEls = {
    imageWrap: document.getElementById('province-detail-image-wrap'),
    image: document.getElementById('province-detail-image'),
    name: document.getElementById('province-detail-name'),
    code: document.getElementById('province-detail-code'),
    region: document.getElementById('province-detail-region'),
    slug: document.getElementById('province-detail-slug'),
    coord: document.getElementById('province-detail-coord'),
    created: document.getElementById('province-detail-created'),
    updated: document.getElementById('province-detail-updated'),
    desc: document.getElementById('province-detail-desc'),
  };

  function hideModal() {
    if (modal) {
      modal.hide();
    } else if (modalEl) {
      modalEl.classList.remove('show');
      modalEl.style.display = 'none';
    }
  }

  function setText(el, value) {
    if (el) el.textContent = value;
  }

  function formatDate(val) {
    if (!val) return '-';
    if (typeof val === 'object' && val._seconds) {
      return new Date(val._seconds * 1000).toLocaleString('vi-VN');
    }
    const t = new Date(val);
    return isNaN(t) ? '-' : t.toLocaleString('vi-VN');
  }

  function formatCoord(lat, lng) {
    const latNum = Number(lat);
    const lngNum = Number(lng);
    const hasLat = Number.isFinite(latNum);
    const hasLng = Number.isFinite(lngNum);
    if (!hasLat && !hasLng) return '-';
    const latText = hasLat ? latNum.toFixed(6) : '-';
    const lngText = hasLng ? lngNum.toFixed(6) : '-';
    return `${latText}, ${lngText}`;
  }

  function setImage(url) {
    if (!detailEls.imageWrap || !detailEls.image) return;
    if (url) {
      detailEls.image.src = url;
      detailEls.imageWrap.classList.add('has-image');
    } else {
      detailEls.image.removeAttribute('src');
      detailEls.imageWrap.classList.remove('has-image');
    }
  }

  function openProvinceDrawer(province) {
    if (!drawer || !province) return;
    setText(detailEls.name, province.name || '-');
    setText(detailEls.code, `Ma: ${province.code || province.id || '-'}`);
    setText(detailEls.region, province.regionsCode || '-');
    setText(detailEls.slug, province.slug || '-');
    setText(detailEls.coord, formatCoord(province.centerLat, province.centerLng));
    setText(detailEls.created, formatDate(province.createdAt));
    setText(detailEls.updated, formatDate(province.updatedAt));
    setText(detailEls.desc, province.description || '-');
    setImage(province.imageUrl || '');
    drawer.classList.add('is-open');
    drawerOverlay?.classList.add('is-visible');
    document.body.classList.add('drawer-open');
  }

  function closeProvinceDrawer() {
    drawer?.classList.remove('is-open');
    drawerOverlay?.classList.remove('is-visible');
    document.body.classList.remove('drawer-open');
  }

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
    if (modal) {
      modal.show();
    } else if (modalEl) {
      // fallback khi bootstrap JS chưa sẵn sàng
      modalEl.style.display = 'block';
      modalEl.classList.add('show');
    }
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
      hideModal();
      await window.provincePage.selectRegion(window.provincePage.getCurrentRegion());
      if (window.notify) window.notify.success('Cap nhat tinh thanh thanh cong');
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

  // Hàm để file chính gọi sau khi render bảng
  window.provinceActionsWire = function wire(container, provinces) {
    if (!container) return;
    container.querySelectorAll('.province-action-menu .dropdown-item').forEach((btn) => {
      btn.addEventListener('click', () => {
        const action = btn.dataset.action;
        const code = btn.dataset.id;
        const province = provinces?.find((p) => (p.code || p.id) === code);
        if (!province) return alert('Khong tim thay tinh thanh');
        if (action === 'view') {
          openProvinceDrawer(province);
        } else if (action === 'edit') {
          openEdit(province);
        } else if (action === 'delete') {
          const ok = confirm('Ban chac chan muon xoa tinh thanh nay?');
          if (!ok) return;
          window.provincePage.fetchJSON(
            `/manager-provinces/api/provinces/${encodeURIComponent(code)}`,
            { method: 'DELETE' },
          )
            .then(() => window.provincePage.selectRegion(window.provincePage.getCurrentRegion()))
            .then(() => {
              if (window.notify) window.notify.success('Xoa tinh thanh thanh cong');
            })
            .catch((err) => {
              console.error(err);
              alert(err.message || 'Xoa tinh that bai');
            });
        }
      });
    });
  };

  // Vẫn lắng nghe event phát từ file chính (dự phòng)
  document.addEventListener('province:list-rendered', (ev) => {
    const { container, provinces } = ev.detail || {};
    if (!container) return;
    window.provinceActionsWire(container, provinces);
  });

  // Wire ngay sau khi trang sẵn sàng (phòng event render đã bắn trước)
  document.addEventListener('DOMContentLoaded', () => {
    const listEl = document.getElementById('province-list');
    const provinces = window.provincePage?.getProvincesCache?.() || [];
    if (listEl && provinces.length) {
      window.provinceActionsWire(listEl, provinces);
    }
  });

  form?.addEventListener('submit', submitEdit);

  // Fallback đóng modal khi click overlay hoặc nút close nếu không có bootstrap
  if (!window.bootstrap && modalEl) {
    modalEl.addEventListener('click', (e) => {
      if (e.target === modalEl) hideModal();
    });
    modalEl.querySelectorAll(modalDismissSelectors).forEach((btn) => {
      btn.addEventListener('click', hideModal);
    });
  }

  drawerClose?.addEventListener('click', closeProvinceDrawer);
  drawerOverlay?.addEventListener('click', closeProvinceDrawer);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeProvinceDrawer();
  });
})();
