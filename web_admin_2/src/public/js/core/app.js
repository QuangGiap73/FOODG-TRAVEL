document.documentElement.classList.add('js-ready');

(() => {
  const body = document.body;
  const toggleButton = document.querySelector('[data-sidebar-toggle]');
  const closeButton = document.querySelector('[data-sidebar-close]');
  const overlay = document.querySelector('[data-sidebar-overlay]');
  const profileDropdown = document.querySelector('[data-profile-dropdown]');
  const profileTrigger = document.querySelector('[data-profile-dropdown-trigger]');

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

  profileTrigger?.addEventListener('click', (event) => {
    event.stopPropagation();
    const isOpen = profileDropdown?.classList.toggle('is-open');
    profileTrigger.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
  });

  document.addEventListener('click', (event) => {
    if (!profileDropdown || profileDropdown.contains(event.target)) return;
    profileDropdown.classList.remove('is-open');
    profileTrigger?.setAttribute('aria-expanded', 'false');
  });

  window.addEventListener('resize', () => {
    if (window.innerWidth > 860) {
      closeSidebar();
    }
  });
})();
