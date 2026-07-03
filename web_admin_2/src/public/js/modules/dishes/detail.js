(function () {
  const page = document.querySelector('[data-dish-detail-page]');
  if (!page) return;

  const STORAGE_KEY = 'dish_detail_language';
  let currentLanguage = localStorage.getItem(STORAGE_KEY) || 'vi';

  function syncExpandableBlock(container) {
    const textNode = container.querySelector('p, .dish-detail-hero-card__summary');
    const button = container.querySelector('[data-expand-toggle]');
    if (!textNode || !button) return;

    const isOverflowing = textNode.scrollHeight > textNode.clientHeight + 2;
    button.hidden = !isOverflowing;
    if (!isOverflowing) {
      container.classList.remove('is-expanded');
      button.textContent = 'Xem thêm';
    }
  }

  function syncFactsPanel() {
    const factsList = document.querySelector('[data-facts-list]');
    const button = document.querySelector('[data-facts-toggle]');
    if (!factsList || !button) return;

    const values = Array.from(factsList.querySelectorAll('.dish-detail-fact-value'));
    const isOverflowing = values.some((node) => node.scrollHeight > node.clientHeight + 2);
    button.hidden = !isOverflowing;
    if (!isOverflowing) {
      factsList.classList.remove('is-expanded');
      button.textContent = 'Xem tất cả';
    }
  }

  function toggleFactsPanel() {
    const factsList = document.querySelector('[data-facts-list]');
    const button = document.querySelector('[data-facts-toggle]');
    if (!factsList || !button) return;

    factsList.classList.toggle('is-expanded');
    const expanded = factsList.classList.contains('is-expanded');
    button.textContent = expanded ? 'Thu gọn' : 'Xem tất cả';
  }

  function renderTagList(container, items) {
    if (!container) return;
    if (!items.length) {
      container.innerHTML = '<span>-</span>';
      return;
    }

    container.innerHTML = items
      .map((item) => `<span class="dish-detail-tag">${item}</span>`)
      .join('');
  }

  function renderStepList(container, items) {
    if (!container) return;
    if (!items.length) {
      container.innerHTML = '<p>-</p>';
      return;
    }

    container.innerHTML = items
      .map(
        (item, index) => `
          <div class="dish-detail-step">
            <span>${index + 1}</span>
            <p>${item}</p>
          </div>
        `,
      )
      .join('');
  }

  function applyLanguage(language) {
    currentLanguage = language;
    localStorage.setItem(STORAGE_KEY, language);

    document.querySelectorAll('[data-lang-button]').forEach((button) => {
      button.classList.toggle('is-active', button.dataset.langButton === language);
    });

    document.querySelectorAll('[data-lang-vi]').forEach((node) => {
      const value = node.dataset[`lang${language === 'vi' ? 'Vi' : 'En'}`];
      if (typeof value === 'string' && value.trim()) {
        node.textContent = value;
        node.setAttribute('title', value);
      }
    });

    document.querySelectorAll('[data-lang-list-vi]').forEach((container) => {
      const raw = container.dataset[`langList${language === 'vi' ? 'Vi' : 'En'}`] || '[]';
      const items = JSON.parse(raw);
      if (container.dataset.listVariant === 'tag') {
        renderTagList(container, items);
      }
      if (container.dataset.listVariant === 'step') {
        renderStepList(container, items);
      }
    });

    document.querySelectorAll('[data-expandable]').forEach((container) => {
      container.classList.remove('is-expanded');
      const button = container.querySelector('[data-expand-toggle]');
      if (button) button.textContent = 'Xem thêm';
    });

    requestAnimationFrame(() => {
      document.querySelectorAll('[data-expandable]').forEach(syncExpandableBlock);
      syncFactsPanel();
    });
  }

  document.querySelectorAll('[data-expandable]').forEach((container) => {
    const button = container.querySelector('[data-expand-toggle]');
    if (!button) return;

    button.addEventListener('click', () => {
      container.classList.toggle('is-expanded');
      const expanded = container.classList.contains('is-expanded');
      button.textContent = expanded ? 'Thu gọn' : 'Xem thêm';
    });
  });

  const factsToggle = document.querySelector('[data-facts-toggle]');
  if (factsToggle) {
    factsToggle.addEventListener('click', toggleFactsPanel);
  }

  document.querySelectorAll('[data-lang-button]').forEach((button) => {
    button.addEventListener('click', () => {
      applyLanguage(button.dataset.langButton || 'vi');
    });
  });

  window.addEventListener('resize', () => {
    document.querySelectorAll('[data-expandable]').forEach(syncExpandableBlock);
    syncFactsPanel();
  });

  applyLanguage(currentLanguage);
})();
