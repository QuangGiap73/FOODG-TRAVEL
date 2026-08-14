(function () {
  const form = document.querySelector('.system-posts-filter');
  const status = form?.querySelector('select[name="status"]');
  status?.addEventListener('change', () => form.requestSubmit());
})();
