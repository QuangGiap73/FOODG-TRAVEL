(function () {
  function syncExpandableBlock(container) {
    const textNode = container.querySelector('p');
    const button = container.querySelector('[data-expand-toggle]');
    if (!textNode || !button) return;

    const isOverflowing = textNode.scrollHeight > textNode.clientHeight + 2;
    button.hidden = !isOverflowing;
  }

  function syncFactsPanel() {
    const factsList = document.querySelector('[data-facts-list]');
    const button = document.querySelector('[data-facts-toggle]');
    if (!factsList || !button) return;

    const values = Array.from(factsList.querySelectorAll('.dish-detail-fact-value'));
    const isOverflowing = values.some((node) => node.scrollHeight > node.clientHeight + 2);
    button.hidden = !isOverflowing;
  }

  function toggleFactsPanel() {
    const factsList = document.querySelector('[data-facts-list]');
    const button = document.querySelector('[data-facts-toggle]');
    if (!factsList || !button) return;

    factsList.classList.toggle('is-expanded');
    const expanded = factsList.classList.contains('is-expanded');
    button.textContent = expanded ? 'Thu gọn' : 'Xem tất cả';

    factsList.querySelectorAll('.dish-detail-fact-value').forEach((node) => {
      if (expanded) {
        node.style.webkitLineClamp = 'unset';
        node.style.display = 'block';
      } else {
        node.style.webkitLineClamp = '5';
        node.style.display = '-webkit-box';
      }
    });
  }

  document.querySelectorAll('[data-expandable]').forEach((container) => {
    syncExpandableBlock(container);

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
    syncFactsPanel();
    factsToggle.addEventListener('click', toggleFactsPanel);
  }

  window.addEventListener('resize', () => {
    document.querySelectorAll('[data-expandable]').forEach(syncExpandableBlock);
    syncFactsPanel();
  });
})();
