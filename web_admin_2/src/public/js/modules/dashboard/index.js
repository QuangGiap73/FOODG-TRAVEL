(() => {
  const root = document.querySelector('[data-dashboard]');
  if (!root) return;

  const parseData = (name) => {
    try { return JSON.parse(root.dataset[name] || '[]'); } catch (_error) { return []; }
  };

  function renderChart() {
    const chart = root.querySelector('[data-dashboard-chart]');
    const data = parseData('chart');
    if (!chart || !data.length) return;
    const max = Math.max(...data.map((item) => item.value), 1);
    chart.innerHTML = data.map((item) => `
      <div class="dashboard-chart__column" title="${item.date}: ${item.value} bài viết">
        <span>${item.value}</span>
        <div><i style="height:${Math.max(item.value ? 12 : 3, Math.round(item.value / max * 100))}%"></i></div>
        <small>${item.label}<em>${item.date}</em></small>
      </div>`).join('');
  }

  renderChart();
})();
