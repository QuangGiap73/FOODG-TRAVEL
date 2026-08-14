(function () {
  const form = document.getElementById('system-post-form');
  if (!form) return;

  const get = (selector) => form.querySelector(selector) || document.querySelector(selector);
  const titleVi = get('[name="titleVi"]');
  const slug = get('[name="slug"]');
  const coverUrl = get('[name="coverImage"]');
  const coverFile = document.getElementById('system-post-cover-file');
  const coverBox = document.getElementById('system-post-cover-preview');
  const coverImage = document.getElementById('system-post-cover-preview-image');
  const uploadStatus = document.getElementById('system-post-upload-status');
  const saveState = document.getElementById('system-post-save-state');
  let uploadPromise = null;
  let isUploading = false;
  let submitted = false;
  let initialState = new FormData(form);

  function slugify(value) {
    return String(value || '').trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/gi, 'd').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  }

  function syncProvince() {
    const option = get('[name="provinceCode34"]')?.selectedOptions?.[0];
    if (!option) return;
    get('[name="provinceName34"]').value = option.dataset.name || '';
    get('[name="regionCode"]').value = option.dataset.region || '';
  }

  function syncLegacyFields() {
    ['title', 'summary', 'content', 'category'].forEach((name) => {
      const target = get(`[name="${name}"]`);
      const source = get(`[name="${name === 'title' ? 'titleVi' : name === 'summary' ? 'summaryVi' : name === 'content' ? 'contentVi' : 'categoryVi'}"]`);
      if (target && source) target.value = source.value;
    });
  }

  function syncPreview(url) {
    const value = String(url || '').trim();
    coverBox?.classList.toggle('has-image', Boolean(value));
    if (coverImage) coverImage.src = value;
    updateProgress();
  }

  function updateCounts() {
    form.querySelectorAll('[data-count-for]').forEach((counter) => {
      const input = get(`[name="${counter.dataset.countFor}"]`);
      counter.textContent = String(input?.value.length || 0);
    });
  }

  function updateSeoPreview() {
    const seoTitle = get('[name="seoTitle"]')?.value.trim();
    const seoDescription = get('[name="seoDescription"]')?.value.trim();
    document.getElementById('system-post-seo-preview-title').textContent = seoTitle || titleVi?.value.trim() || 'Tiêu đề bài viết';
    document.getElementById('system-post-seo-preview-description').textContent = seoDescription || get('[name="summaryVi"]')?.value.trim() || 'Mô tả bài viết sẽ xuất hiện tại đây.';
  }

  function updateProgress() {
    const checks = {
      title: Boolean(titleVi?.value.trim()), content: Boolean(get('[name="contentVi"]')?.value.trim()),
      cover: Boolean(coverUrl?.value.trim()), summary: Boolean(get('[name="summaryVi"]')?.value.trim()),
      seo: Boolean(get('[name="seoTitle"]')?.value.trim() && get('[name="seoDescription"]')?.value.trim()),
    };
    Object.entries(checks).forEach(([key, complete]) => document.querySelector(`[data-check="${key}"]`)?.classList.toggle('is-complete', complete));
    const percent = Math.round(Object.values(checks).filter(Boolean).length / Object.keys(checks).length * 100);
    const label = document.getElementById('system-post-progress');
    const bar = document.getElementById('system-post-progress-bar');
    if (label) label.textContent = `${percent}%`;
    if (bar) bar.style.width = `${percent}%`;
    document.querySelector('[data-editor-language="vi"]')?.classList.toggle('is-complete', checks.title && checks.content);
    document.querySelector('[data-editor-language="en"]')?.classList.toggle('is-complete', Boolean(get('[name="titleEn"]')?.value.trim() && get('[name="contentEn"]')?.value.trim()));
  }

  function setDirty() {
    if (!saveState) return;
    saveState.textContent = 'Có thay đổi chưa lưu';
    saveState.classList.add('is-dirty');
  }

  async function uploadCover(file) {
    if (!file) return;
    const payload = new FormData(); payload.append('image', file);
    isUploading = true;
    if (uploadStatus) { uploadStatus.textContent = 'Đang tải ảnh lên...'; uploadStatus.classList.remove('is-error'); }
    try {
      const response = await fetch('/admin/system-posts/api/upload-image', { method: 'POST', body: payload });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(body.message || 'Tải ảnh thất bại');
      const url = body.data?.url;
      if (!url) throw new Error('Không nhận được URL ảnh');
      coverUrl.value = url; syncPreview(url); setDirty();
      if (uploadStatus) uploadStatus.textContent = 'Ảnh đã tải lên thành công.';
    } catch (error) {
      if (uploadStatus) { uploadStatus.textContent = error.message || 'Tải ảnh thất bại'; uploadStatus.classList.add('is-error'); }
      window.AdminNotify?.error(error.message || 'Tải ảnh thất bại');
      throw error;
    } finally { isUploading = false; if (coverFile) coverFile.value = ''; }
  }

  document.querySelectorAll('[data-editor-language]').forEach((button) => button.addEventListener('click', () => {
    const language = button.dataset.editorLanguage;
    document.querySelectorAll('[data-editor-language]').forEach((item) => { item.classList.toggle('is-active', item === button); item.setAttribute('aria-selected', String(item === button)); });
    document.querySelectorAll('[data-language-panel]').forEach((panel) => { panel.hidden = panel.dataset.languagePanel !== language; });
  }));
  get('[name="provinceCode34"]')?.addEventListener('change', syncProvince);
  document.getElementById('system-post-generate-slug')?.addEventListener('click', () => { slug.value = slugify(titleVi?.value); setDirty(); });
  titleVi?.addEventListener('input', () => { if (!slug.dataset.userTouched) slug.value = slugify(titleVi.value); });
  slug?.addEventListener('input', () => { slug.dataset.userTouched = '1'; });
  document.getElementById('system-post-upload-trigger')?.addEventListener('click', () => coverFile?.click());
  coverFile?.addEventListener('change', () => { const file = coverFile.files?.[0]; if (file) uploadPromise = uploadCover(file).catch(() => null).finally(() => { uploadPromise = null; }); });
  coverUrl?.addEventListener('input', () => syncPreview(coverUrl.value));
  form.addEventListener('input', () => { updateCounts(); updateSeoPreview(); updateProgress(); syncLegacyFields(); setDirty(); });
  form.addEventListener('change', () => { updateProgress(); setDirty(); });
  form.addEventListener('submit', async (event) => { syncProvince(); syncLegacyFields(); if (isUploading && uploadPromise) { event.preventDefault(); await uploadPromise; form.requestSubmit(); return; } submitted = true; });
  window.addEventListener('beforeunload', (event) => { if (!submitted && saveState?.classList.contains('is-dirty')) { event.preventDefault(); event.returnValue = ''; } });
  syncProvince(); syncPreview(coverUrl?.value); updateCounts(); updateSeoPreview(); updateProgress(); initialState = null;
})();
