(() => {
  const STORAGE_KEY = 'foods:pending-notification';
  const DEFAULT_DURATION = 4500;
  const TITLES = {
    success: 'Thành công',
    error: 'Có lỗi xảy ra',
    warning: 'Cần chú ý',
    info: 'Thông báo',
  };
  const ICONS = { success: '✓', error: '!', warning: '!', info: 'i' };

  function getRegion() {
    let region = document.querySelector('[data-notification-region]');
    if (!region) {
      region = document.createElement('div');
      region.className = 'foods-notifications';
      region.dataset.notificationRegion = '';
      region.setAttribute('aria-live', 'polite');
      document.body.appendChild(region);
    }
    return region;
  }

  function normalizeOptions(messageOrOptions, type) {
    if (typeof messageOrOptions === 'object' && messageOrOptions !== null) {
      return { ...messageOrOptions, type: messageOrOptions.type || type || 'info' };
    }
    return { message: String(messageOrOptions || ''), type: type || 'info' };
  }

  function dismiss(notification) {
    if (!notification || notification.dataset.closing === 'true') return;
    notification.dataset.closing = 'true';
    notification.classList.remove('is-visible');
    notification.classList.add('is-leaving');
    window.setTimeout(() => notification.remove(), 220);
  }

  function show(messageOrOptions, type) {
    const options = normalizeOptions(messageOrOptions, type);
    const safeType = Object.hasOwn(TITLES, options.type) ? options.type : 'info';
    if (!options.message) return null;

    const region = getRegion();
    while (region.children.length >= 4) dismiss(region.firstElementChild);

    const notification = document.createElement('article');
    notification.className = `foods-notification foods-notification--${safeType}`;
    notification.setAttribute('role', safeType === 'error' ? 'alert' : 'status');

    const icon = document.createElement('span');
    icon.className = 'foods-notification__icon';
    icon.textContent = ICONS[safeType];

    const content = document.createElement('div');
    content.className = 'foods-notification__content';
    const title = document.createElement('strong');
    title.textContent = options.title || TITLES[safeType];
    const message = document.createElement('p');
    message.textContent = options.message;
    content.append(title, message);

    const close = document.createElement('button');
    close.className = 'foods-notification__close';
    close.type = 'button';
    close.setAttribute('aria-label', 'Đóng thông báo');
    close.textContent = '×';
    close.addEventListener('click', () => dismiss(notification));

    notification.append(icon, content, close);
    const duration = options.persistent ? 0 : Math.max(1800, Number(options.duration) || DEFAULT_DURATION);
    if (duration) {
      const progress = document.createElement('span');
      progress.className = 'foods-notification__progress';
      progress.style.animationDuration = `${duration}ms`;
      notification.appendChild(progress);
      let timer = window.setTimeout(() => dismiss(notification), duration);
      notification.addEventListener('mouseenter', () => { window.clearTimeout(timer); progress.style.animationPlayState = 'paused'; });
      notification.addEventListener('mouseleave', () => {
        progress.style.animationPlayState = 'running';
        timer = window.setTimeout(() => dismiss(notification), 1200);
      });
    }
    region.appendChild(notification);
    requestAnimationFrame(() => notification.classList.add('is-visible'));
    return notification;
  }

  const api = {
    show,
    success: (message, options = {}) => show({ ...options, message, type: 'success' }),
    error: (message, options = {}) => show({ ...options, message, type: 'error' }),
    warning: (message, options = {}) => show({ ...options, message, type: 'warning' }),
    info: (message, options = {}) => show({ ...options, message, type: 'info' }),
    clear: () => getRegion().querySelectorAll('.foods-notification').forEach(dismiss),
    queue(messageOrOptions, type) {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(normalizeOptions(messageOrOptions, type)));
    },
    redirect(url, messageOrOptions, type) {
      if (messageOrOptions) this.queue(messageOrOptions, type);
      window.location.href = url;
    },
  };

  window.FoodsNotify = api;
  window.notify = (type, message, options) => api.show({ ...options, type, message });
  window.alert = (message) => api.warning(String(message || ''));

  document.querySelectorAll('[data-notification]').forEach((node) => {
    const message = node.textContent.trim();
    if (message) api.show({ type: node.dataset.notification || 'info', message });
    if (node.dataset.notificationKeep !== 'true') node.hidden = true;
  });

  try {
    const pending = JSON.parse(sessionStorage.getItem(STORAGE_KEY) || 'null');
    if (pending) {
      sessionStorage.removeItem(STORAGE_KEY);
      window.setTimeout(() => api.show(pending), 80);
    }
  } catch (_error) {
    sessionStorage.removeItem(STORAGE_KEY);
  }
})();
