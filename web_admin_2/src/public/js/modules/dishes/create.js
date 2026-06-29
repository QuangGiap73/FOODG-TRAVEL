(function () {
  const provinceSelect = document.getElementById('dish-province-code34');
  const provinceCodePreview = document.querySelector('[data-province-code-preview]');
  const provinceNameInput = document.getElementById('dish-province-name34');
  const legacyProvinceInput = document.getElementById('dish-legacy-province');
  const provinceCodeInput = document.getElementById('dish-province-code');
  const regionCodeInput = document.getElementById('dish-region-code');

  const nameViInput = document.getElementById('dish-name-vi');
  const idInput = document.getElementById('dish-id');
  const slugInput = document.getElementById('dish-slug');
  const generateSlugButton = document.getElementById('dish-generate-slug');
  const imageUrlInput = document.getElementById('dish-image-url');
  const imageFileInput = document.getElementById('dish-image-file');
  const uploadTrigger = document.getElementById('dish-upload-trigger');
  const uploadStatus = document.getElementById('dish-upload-status');

  const previewName = document.getElementById('dish-preview-name');
  const previewNameEn = document.getElementById('dish-preview-name-en');
  const previewMeta = document.getElementById('dish-preview-meta');
  const previewSlug = document.getElementById('dish-preview-slug');
  const previewImage = document.getElementById('dish-preview-image');
  const previewEmpty = document.getElementById('dish-preview-empty');

  const requiredStatus = document.getElementById('dish-required-status');
  const contentStatus = document.getElementById('dish-content-status');
  const imageStatus = document.getElementById('dish-image-status');

  const form = document.getElementById('dish-create-form');
  if (!form) return;

  function slugify(value) {
    return String(value || '')
      .trim()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/\u0111/g, 'd')
      .replace(/\u0110/g, 'd')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  function toSnakeCase(value) {
    return slugify(value).replace(/-/g, '_');
  }

  function mapRegionCode(regionCode) {
    const code = String(regionCode || '').trim().toLowerCase();
    if (
      code === 'dong_bang_song_hong' ||
      code === 'trung_du_mien_nui_bac_bo'
    ) {
      return 'Miền Bắc';
    }

    if (
      code === 'bac_trung_bo' ||
      code === 'duyen_hai_nam_trung_bo' ||
      code === 'tay_nguyen'
    ) {
      return 'Miền Trung';
    }

    if (
      code === 'dong_nam_bo' ||
      code === 'dong_bang_song_cuu_long'
    ) {
      return 'Miền Nam';
    }

    return '';
  }

  function updateProvinceFields() {
    const option = provinceSelect?.selectedOptions?.[0];
    if (!option) return;

    const provinceCode = String(option.value || '').trim();
    const provinceName = String(option.dataset.provinceName || '').trim();
    const regionCode = String(option.dataset.regionCode || '').trim();
    const primaryLegacyCode = String(option.dataset.primaryLegacyCode || '').trim();
    const mappedRegion = mapRegionCode(regionCode);

    if (provinceCodePreview) provinceCodePreview.value = provinceCode;
    if (provinceNameInput) provinceNameInput.value = provinceName;

    if (regionCodeInput) {
      regionCodeInput.value = mappedRegion;
    }

    if (legacyProvinceInput && !legacyProvinceInput.value && primaryLegacyCode) {
      legacyProvinceInput.value = primaryLegacyCode;
      updateLegacyProvinceFields();
    }
  }

  function updateLegacyProvinceFields() {
    const option = legacyProvinceInput?.selectedOptions?.[0];
    const legacyProvinceName = String(option?.textContent || '').trim();

    if (provinceCodeInput) {
      provinceCodeInput.value = legacyProvinceName && option.value ? legacyProvinceName : '';
    }
  }

  function updateGeneratedFields(force = false) {
    const nameVi = String(nameViInput?.value || '').trim();

    if (force || !idInput.value.trim()) {
      idInput.value = toSnakeCase(nameVi);
    }

    if (force || !slugInput.value.trim()) {
      slugInput.value = slugify(nameVi);
    }
  }

  function updatePreview() {
    const provinceName = provinceNameInput?.value || 'Chua chon tinh/thanh';
    const imageUrl = String(imageUrlInput?.value || '').trim();
    const nameEnValue = form.elements.nameEn?.value || 'English name preview';

    if (previewName) previewName.textContent = nameViInput?.value || 'Ten mon se hien o day';
    if (previewNameEn) previewNameEn.textContent = nameEnValue;
    if (previewMeta) previewMeta.textContent = provinceName;
    if (previewSlug) previewSlug.textContent = slugInput?.value || 'slug-preview';

    if (previewImage && previewEmpty) {
      if (imageUrl) {
        previewImage.src = imageUrl;
        previewImage.hidden = false;
        previewEmpty.hidden = true;
      } else {
        previewImage.hidden = true;
        previewEmpty.hidden = false;
      }
    }
  }

  function updateProgress() {
    const requiredCount = [
      idInput?.value,
      slugInput?.value,
      nameViInput?.value,
      form.elements.nameEn?.value,
      provinceSelect?.value,
    ].filter((value) => String(value || '').trim()).length;

    const contentCount = [
      form.elements.descriptionVi?.value,
      form.elements.descriptionEn?.value,
      form.elements.ingredientsVi?.value,
      form.elements.instructionsVi?.value,
    ].filter((value) => String(value || '').trim()).length;

    const imageCount = [imageUrlInput?.value].filter((value) => String(value || '').trim()).length;

    if (requiredStatus) requiredStatus.textContent = `${requiredCount}/5`;
    if (contentStatus) contentStatus.textContent = `${contentCount}/4`;
    if (imageStatus) imageStatus.textContent = `${imageCount}/1`;
  }

  function updateAll() {
    updatePreview();
    updateProgress();
  }

  async function uploadImageFile(file) {
    if (!file) return;

    const formData = new FormData();
    formData.append('image', file);

    if (uploadStatus) {
      uploadStatus.textContent = 'Dang tai anh len...';
    }

    try {
      const response = await fetch('/admin/dishes/api/upload-image', {
        method: 'POST',
        body: formData,
      });

      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new Error(body.message || body.error || 'Tai anh that bai');
      }

      const imageUrl = body.data?.url || '';
      if (!imageUrl) {
        throw new Error('Khong nhan duoc URL anh tu server');
      }

      imageUrlInput.value = imageUrl;
      if (uploadStatus) {
        uploadStatus.textContent = 'Tai anh thanh cong. URL da duoc dien vao form.';
      }
      updateAll();
    } catch (error) {
      if (uploadStatus) {
        uploadStatus.textContent = error.message || 'Tai anh that bai';
      }
    } finally {
      if (imageFileInput) {
        imageFileInput.value = '';
      }
    }
  }

  provinceSelect?.addEventListener('change', () => {
    updateProvinceFields();
    updateAll();
  });

  legacyProvinceInput?.addEventListener('change', () => {
    updateLegacyProvinceFields();
    updateAll();
  });

  nameViInput?.addEventListener('input', () => {
    updateGeneratedFields(false);
    updateAll();
  });

  generateSlugButton?.addEventListener('click', () => {
    updateGeneratedFields(true);
    updateAll();
  });

  uploadTrigger?.addEventListener('click', () => {
    imageFileInput?.click();
  });

  imageFileInput?.addEventListener('change', () => {
    const file = imageFileInput.files?.[0];
    uploadImageFile(file);
  });

  form.addEventListener('input', updateAll);
  imageUrlInput?.addEventListener('input', updatePreview);

  document.querySelectorAll('.dish-create-steps a').forEach((link) => {
    link.addEventListener('click', (event) => {
      const targetId = link.getAttribute('href');
      const section = targetId ? document.querySelector(targetId) : null;
      if (!section) return;

      event.preventDefault();
      document.querySelectorAll('.dish-create-steps a').forEach((item) => item.classList.remove('is-active'));
      link.classList.add('is-active');
      section.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });

  updateProvinceFields();
  updateLegacyProvinceFields();
  updateGeneratedFields(false);
  updateAll();
})();
