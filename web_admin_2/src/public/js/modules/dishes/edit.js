(function () {
    const provinceSelect = document.getElementById('dish-province-code34');
    const provinceCodePreview = document.querySelector('[data-province-code-preview]');
    const provinceNameInput = document.getElementById('dish-province-name34');
    const legacyProvinceInput = document.getElementById('dish-legacy-province');
    const provinceCodeInput = document.getElementById('dish-province-code');
    const regionCodeInput = document.getElementById('dish-region-code');
  
    const nameViInput = document.getElementById('dish-name-vi');
    const slugInput = document.getElementById('dish-slug');
    const generateSlugButton = document.getElementById('dish-generate-slug');
    const imageUrlInput = document.getElementById('dish-image-url');
    const imageFileInput = document.getElementById('dish-image-file');
    const uploadTrigger = document.getElementById('dish-upload-trigger');
    const uploadStatus = document.getElementById('dish-upload-status');
  
    const form = document.getElementById('dish-edit-form');
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
  
    function mapRegionCode(regionCode) {
      const code = String(regionCode || '').trim().toLowerCase();
  
      if (code === 'dong_bang_song_hong' || code === 'trung_du_mien_nui_bac_bo') {
        return 'Miền Bắc';
      }
  
      if (code === 'bac_trung_bo' || code === 'duyen_hai_nam_trung_bo' || code === 'tay_nguyen') {
        return 'Miền Trung';
      }
  
      if (code === 'dong_nam_bo' || code === 'dong_bang_song_cuu_long') {
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
      if (regionCodeInput) regionCodeInput.value = mappedRegion;
  
      if (legacyProvinceInput && !legacyProvinceInput.value && primaryLegacyCode) {
        const matchedOption = Array.from(legacyProvinceInput.options).find(
          (item) => item.textContent.trim().toLowerCase() === primaryLegacyCode.replaceAll('_', ' ').trim().toLowerCase(),
        );
        if (matchedOption) {
          legacyProvinceInput.value = matchedOption.value;
        }
      }
    }
  
    function updateLegacyProvinceFields() {
      const option = legacyProvinceInput?.selectedOptions?.[0];
      const legacyProvinceName = String(option?.value || '').trim();
  
      if (provinceCodeInput) {
        provinceCodeInput.value = legacyProvinceName;
      }
    }
  
    function updateGeneratedFields() {
      const nameVi = String(nameViInput?.value || '').trim();
      if (slugInput && !slugInput.dataset.userTouched) {
        slugInput.value = slugify(nameVi);
      }
    }
  
    async function uploadImageFile(file) {
      if (!file) return;
  
      const formData = new FormData();
      formData.append('image', file);
  
      if (uploadStatus) uploadStatus.textContent = 'Đang tải ảnh lên...';
  
      try {
        const response = await fetch('/admin/dishes/api/upload-image', {
          method: 'POST',
          body: formData,
        });
  
        const body = await response.json().catch(() => ({}));
        if (!response.ok) {
          throw new Error(body.message || body.error || 'Tải ảnh thất bại');
        }
  
        const imageUrl = body.data?.url || '';
        if (!imageUrl) {
          throw new Error('Không nhận được URL ảnh từ server');
        }
  
        imageUrlInput.value = imageUrl;
        if (uploadStatus) uploadStatus.textContent = 'Tải ảnh thành công.';
      } catch (error) {
        if (uploadStatus) uploadStatus.textContent = error.message || 'Tải ảnh thất bại';
      } finally {
        if (imageFileInput) imageFileInput.value = '';
      }
    }
  
    provinceSelect?.addEventListener('change', () => {
      updateProvinceFields();
      updateLegacyProvinceFields();
    });
  
    legacyProvinceInput?.addEventListener('change', updateLegacyProvinceFields);
  
    nameViInput?.addEventListener('input', updateGeneratedFields);
  
    slugInput?.addEventListener('input', () => {
      slugInput.dataset.userTouched = '1';
    });
  
    generateSlugButton?.addEventListener('click', () => {
      if (slugInput) {
        slugInput.dataset.userTouched = '';
        updateGeneratedFields();
      }
    });
  
    uploadTrigger?.addEventListener('click', () => imageFileInput?.click());
  
    imageFileInput?.addEventListener('change', () => {
      const file = imageFileInput.files?.[0];
      uploadImageFile(file);
    });
  
    updateProvinceFields();
    updateLegacyProvinceFields();
  })();