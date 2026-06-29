document.documentElement.classList.add('js-ready');

(() => {
  const body = document.body;
  const toggleButton = document.querySelector('[data-sidebar-toggle]');
  const closeButton = document.querySelector('[data-sidebar-close]');
  const overlay = document.querySelector('[data-sidebar-overlay]');

  if (!toggleButton || !overlay) return;

  function openSidebar() {
    body.classList.add('sidebar-open');
  }

  function closeSidebar() {
    body.classList.remove('sidebar-open');
  }

  toggleButton.addEventListener('click', openSidebar);
  closeButton?.addEventListener('click', closeSidebar);
  overlay.addEventListener('click', closeSidebar);

  window.addEventListener('resize', () => {
    if (window.innerWidth > 860) {
      closeSidebar();
    }
  });
})();
