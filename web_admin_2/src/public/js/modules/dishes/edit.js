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
    const imageUrlsInput = document.getElementById('dish-image-urls');
    const imageFileInput = document.getElementById('dish-image-file');
    const uploadTrigger = document.getElementById('dish-upload-trigger');
    const uploadStatus = document.getElementById('dish-upload-status');
    const previewList = document.getElementById('dish-image-preview-list');
  
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
  
    function buildImagePreviewEntries() {
      const entries = [];
      const primaryUrl = String(imageUrlInput?.value || '').trim();
      if (primaryUrl) entries.push({ url: primaryUrl, label: 'Ảnh đại diện' });

      const additionalUrls = String(imageUrlsInput?.value || '')
        .split(/\r?\n/)
        .map((value) => value.trim())
        .filter(Boolean);

      additionalUrls.forEach((url, index) => {
        if (url !== primaryUrl) {
          entries.push({ url, label: `Ảnh ${index + 2}` });
        }
      });

      return entries;
    }

    function renderImagePreview() {
      if (!previewList) return;

      const entries = buildImagePreviewEntries();
      if (!entries.length) {
        previewList.innerHTML = '<div class="dish-create-notice">Chưa có ảnh nào được chọn.</div>';
        return;
      }

      previewList.innerHTML = entries.map((entry) => `
        <div class="dish-image-preview-card">
          <img src="${entry.url}" alt="${entry.label}" />
          <div class="dish-image-preview-card__meta">
            <strong>${entry.label}</strong>
            <small>${entry.url}</small>
          </div>
        </div>
      `).join('');
    }

    function updateGeneratedFields() {
      const nameVi = String(nameViInput?.value || '').trim();
      if (slugInput && !slugInput.dataset.userTouched) {
        slugInput.value = slugify(nameVi);
      }
    }

    async function uploadImageFiles(files) {
      if (!files?.length) return;

      if (uploadStatus) uploadStatus.textContent = 'Đang tải ảnh lên...';

      const uploadedUrls = [];

      for (const file of Array.from(files)) {
        const formData = new FormData();
        formData.append('image', file);

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

          uploadedUrls.push(imageUrl);
        } catch (error) {
          if (uploadStatus) uploadStatus.textContent = error.message || 'Tải ảnh thất bại';
          return;
        }
      }

      const previousPrimary = String(imageUrlInput?.value || '').trim();
      const previousAdditional = String(imageUrlsInput?.value || '')
        .split(/\r?\n/)
        .map((value) => value.trim())
        .filter(Boolean);

      const nextUrls = uploadedUrls.filter((url) => !previousAdditional.includes(url) && url !== previousPrimary);
      if (!previousPrimary && nextUrls.length) {
        imageUrlInput.value = nextUrls[0];
      }

      const mergedAdditional = [...previousAdditional, ...nextUrls];
      if (imageUrlsInput) {
        imageUrlsInput.value = mergedAdditional.join('\n');
      }

      if (uploadStatus) uploadStatus.textContent = `Tải thành công ${uploadedUrls.length} ảnh.`;
      renderImagePreview();
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
      uploadImageFiles(imageFileInput.files);
    });

    imageUrlInput?.addEventListener('input', renderImagePreview);
    imageUrlsInput?.addEventListener('input', renderImagePreview);
  
    updateProvinceFields();
    updateLegacyProvinceFields();
    renderImagePreview();
  })();