(function () {
    const STYLE_ID = 'app-notify-style';
    const DEFAULTS = { delay: 2400, autohide: true };
  
    const TYPE_META = {
      success: {
        title: 'Thanh cong',
        color: '#1f8a4c',
        icon:
          '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>',
      },
      danger: {
        title: 'Loi',
        color: '#d64550',
        icon:
          '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.3 3.6L2.4 17a2 2 0 0 0 1.7 3h15.8a2 2 0 0 0 1.7-3L13.7 3.6a2 2 0 0 0-3.4 0z"/><path d="M12 9v4"/><path d="M12 16h.01"/></svg>',
      },
      warning: {
        title: 'Canh bao',
        color: '#b86a07',
        icon:
          '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 9v4"/><path d="M12 16h.01"/><path d="M10.3 3.6L2.4 17a2 2 0 0 0 1.7 3h15.8a2 2 0 0 0 1.7-3L13.7 3.6a2 2 0 0 0-3.4 0z"/></svg>',
      },
      info: {
        title: 'Thong bao',
        color: '#0f7dc2',
        icon:
          '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 10v6"/><path d="M12 7h.01"/></svg>',
      },
    };
  
    function ensureStyles() {
      if (document.getElementById(STYLE_ID)) return;
      const style = document.createElement('style');
      style.id = STYLE_ID;
      style.textContent = `
        .app-notify-overlay {
          position: fixed;
          inset: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          background: rgba(17, 24, 39, 0.35);
          z-index: 2000;
          padding: 16px;
        }
        .app-notify-card {
          width: min(440px, 92vw);
          background: #fff;
          border-radius: 14px;
          border: 1px solid rgba(15, 23, 42, 0.08);
          box-shadow: 0 18px 46px rgba(0, 0, 0, 0.25);
          overflow: hidden;
          transform: translateY(6px);
          opacity: 0;
          transition: transform 160ms ease, opacity 160ms ease;
        }
        .app-notify-card.is-show {
          transform: translateY(0);
          opacity: 1;
        }
        .app-notify-accent {
          height: 4px;
          background: var(--accent);
        }
        .app-notify-body {
          display: flex;
          gap: 12px;
          padding: 16px 18px 10px;
          align-items: flex-start;
        }
        .app-notify-icon {
          width: 36px;
          height: 36px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--accent);
          background: var(--accent-bg);
          flex-shrink: 0;
        }
        .app-notify-title {
          font-weight: 700;
          color: #0f172a;
          font-size: 16px;
        }
        .app-notify-msg {
          margin-top: 4px;
          color: #334155;
          line-height: 1.45;
          word-break: break-word;
        }
        .app-notify-close {
          margin-left: auto;
          background: transparent;
          border: 0;
          color: #94a3b8;
          font-size: 18px;
          cursor: pointer;
        }
        .app-notify-actions {
          display: flex;
          justify-content: flex-end;
          padding: 0 18px 16px;
        }
        .app-notify-btn {
          background: var(--accent);
          color: #fff;
          border: 0;
          padding: 8px 14px;
          border-radius: 10px;
          font-weight: 600;
          cursor: pointer;
        }
        .app-notify-hide {
          transform: translateY(6px);
          opacity: 0;
        }
      `;
      document.head.appendChild(style);
    }
  
    function escapeHtml(input) {
      return String(input || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }
  
    function hexToRgba(hex, alpha) {
      const h = hex.replace('#', '');
      const r = parseInt(h.substring(0, 2), 16);
      const g = parseInt(h.substring(2, 4), 16);
      const b = parseInt(h.substring(4, 6), 16);
      return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }
  
    function getOverlay() {
      ensureStyles();
      let overlay = document.getElementById('app-notify-overlay');
      if (!overlay) {
        overlay = document.createElement('div');
        overlay.id = 'app-notify-overlay';
        overlay.className = 'app-notify-overlay';
        overlay.innerHTML = `
          <div class="app-notify-card" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="app-notify-accent"></div>
            <div class="app-notify-body">
              <div class="app-notify-icon" id="app-notify-icon"></div>
              <div class="app-notify-content">
                <div class="app-notify-title" id="app-notify-title"></div>
                <div class="app-notify-msg" id="app-notify-msg"></div>
              </div>
              <button class="app-notify-close" id="app-notify-close" type="button">x</button>
            </div>
            <div class="app-notify-actions">
              <button class="app-notify-btn" id="app-notify-ok" type="button">Dong</button>
            </div>
          </div>
        `;
        overlay.addEventListener('click', (e) => {
          if (e.target === overlay) closeOverlay(overlay);
        });
        document.body.appendChild(overlay);
      }
      return overlay;
    }
  
    function closeOverlay(overlay) {
      const card = overlay.querySelector('.app-notify-card');
      if (card) card.classList.add('app-notify-hide');
      setTimeout(() => overlay.remove(), 160);
    }
  
    function show(message, type = 'success', options = {}) {
      const meta = TYPE_META[type] || TYPE_META.success;
      const overlay = getOverlay();
  
      const card = overlay.querySelector('.app-notify-card');
      const iconEl = overlay.querySelector('#app-notify-icon');
      const titleEl = overlay.querySelector('#app-notify-title');
      const msgEl = overlay.querySelector('#app-notify-msg');
      const closeBtn = overlay.querySelector('#app-notify-close');
      const okBtn = overlay.querySelector('#app-notify-ok');
  
      if (card) {
        card.style.setProperty('--accent', meta.color);
        card.style.setProperty('--accent-bg', hexToRgba(meta.color, 0.12));
        card.classList.remove('app-notify-hide');
        requestAnimationFrame(() => card.classList.add('is-show'));
      }
      if (iconEl) iconEl.innerHTML = meta.icon;
      if (titleEl) titleEl.textContent = meta.title;
      if (msgEl) msgEl.innerHTML = escapeHtml(message).replace(/\n/g, '<br>');
  
      if (closeBtn) closeBtn.onclick = () => closeOverlay(overlay);
      if (okBtn) okBtn.onclick = () => closeOverlay(overlay);
  
      if (overlay._timer) clearTimeout(overlay._timer);
      const delay = Number.isFinite(options.delay) ? options.delay : DEFAULTS.delay;
      const autohide = options.autohide !== undefined ? options.autohide : DEFAULTS.autohide;
      if (autohide) {
        overlay._timer = setTimeout(() => closeOverlay(overlay), delay);
      }
    }
  
    window.notify = {
      success: (msg, opt) => show(msg || 'Thanh cong', 'success', opt),
      error: (msg, opt) => show(msg || 'Co loi xay ra', 'danger', opt),
      warning: (msg, opt) => show(msg || 'Canh bao', 'warning', opt),
      info: (msg, opt) => show(msg || 'Thong bao', 'info', opt),
      show,
    };
  })();
  