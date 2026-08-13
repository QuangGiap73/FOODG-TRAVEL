(() => {
  const root = document.querySelector('[data-dashboard]');
  const svgNode = root?.querySelector('[data-dashboard-map]');
  const container = svgNode?.closest('.dashboard-map-wrap');
  const state = root?.querySelector('[data-map-state]');
  const tooltip = root?.querySelector('[data-map-tooltip]');
  if (!root || !svgNode || !container || !window.d3) return;

  const normalize = (value) => String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  const businessPoints = (() => { try { return JSON.parse(root.dataset.map || '[]'); } catch (_error) { return []; } })();
  const businessByName = new Map(businessPoints.map((point) => [normalize(point.name), point]));
  let geographicData = null;
  let resizeFrame = null;

  const polygonMaxLongitude = (polygon) => d3.max(polygon.flat(1), (point) => point[0]);
  const filterGeometry = (geometry, predicate) => {
    const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
    const selected = polygons.filter(predicate);
    if (!selected.length) return null;
    return selected.length === 1
      ? { type: 'Polygon', coordinates: selected[0] }
      : { type: 'MultiPolygon', coordinates: selected };
  };

  const subset = (data, predicate) => ({
    type: 'FeatureCollection',
    features: data.features.map((feature) => ({ ...feature, geometry: filterGeometry(feature.geometry, predicate) })).filter((feature) => feature.geometry),
  });

  function showTooltip(event, point) {
    const rect = container.getBoundingClientRect();
    const targetRect = event.currentTarget?.getBoundingClientRect?.();
    const clientX = Number.isFinite(event.clientX) && event.clientX ? event.clientX : (targetRect?.left || rect.left) + (targetRect?.width || 0) / 2;
    const clientY = Number.isFinite(event.clientY) && event.clientY ? event.clientY : (targetRect?.top || rect.top) + (targetRect?.height || 0) / 2;
    const x = Math.min(rect.width - 190, Math.max(10, clientX - rect.left + 12));
    const y = Math.min(rect.height - 95, Math.max(10, clientY - rect.top - 64));
    tooltip.innerHTML = `<strong>${point.name}</strong><span>${point.dishes || 0} món ăn</span><span>${point.posts || 0} bài viết</span><b>${point.total || 0} nội dung</b>`;
    tooltip.style.left = `${x}px`;
    tooltip.style.top = `${y}px`;
    tooltip.hidden = false;
  }

  function hideTooltip() { tooltip.hidden = true; }

  function renderMap() {
    if (!geographicData) return;
    const width = Math.max(320, container.clientWidth);
    const height = Math.max(400, container.clientHeight);
    const svg = d3.select(svgNode).attr('viewBox', `0 0 ${width} ${height}`);
    const mainland = subset(geographicData, (polygon) => polygonMaxLongitude(polygon) < 111);
    const islands = subset(geographicData, (polygon) => polygonMaxLongitude(polygon) >= 111);
    // Fit mainland toward the left so real offshore polygons remain visible
    // in their geographic positions east of Vietnam.
    const projection = d3.geoMercator().fitExtent([[width * .04, 24], [width * .58, height - 24]], mainland);
    const path = d3.geoPath(projection);
    const maxContent = d3.max(businessPoints, (point) => point.total) || 1;
    const provinceColor = d3.scaleLinear().domain([0, maxContent]).range(['#FBE3C5', '#F7C996']);

    svg.select('[data-map-provinces]').selectAll('path').data(geographicData.features, (feature) => feature.properties.code).join('path')
      .attr('class', 'dashboard-map__province')
      .attr('d', path)
      .attr('fill', (feature) => provinceColor(businessByName.get(normalize(feature.properties.name))?.total || 0))
      .attr('tabindex', 0)
      .on('mouseenter focus', function (event, feature) {
        const point = businessByName.get(normalize(feature.properties.name)) || { name: feature.properties.name, dishes: 0, posts: 0, total: 0 };
        showTooltip(event, point);
      })
      .on('mousemove', (event, feature) => showTooltip(event, businessByName.get(normalize(feature.properties.name)) || { name: feature.properties.name }))
      .on('mouseleave blur', hideTooltip)
      .on('click', () => { window.location.href = '/admin/provinces'; });

    const islandLayer = svg.select('[data-map-islands]');
    islandLayer.selectAll('*').remove();
    if (islands.features.length) {
      islandLayer.append('text')
        .attr('class', 'dashboard-map__sea-label')
        .attr('x', width * .78)
        .attr('y', height * .46)
        .text('BIỂN ĐÔNG');
      islandLayer.selectAll('.dashboard-map__archipelago-label').data(islands.features).join('text')
        .attr('class', 'dashboard-map__archipelago-label')
        .attr('x', (feature) => path.centroid(feature)[0] + 8)
        .attr('y', (feature) => path.centroid(feature)[1])
        .text((feature) => normalize(feature.properties.name) === normalize('Đà Nẵng') ? 'Hoàng Sa' : 'Trường Sa');
    }

    svgNode.classList.add('is-ready');
    state.hidden = true;
  }

  fetch('/public/data/vietnam-provinces-34.geojson')
    .then((response) => { if (!response.ok) throw new Error(`HTTP ${response.status}`); return response.json(); })
    .then((data) => {
      if (data.type !== 'FeatureCollection' || data.features.length !== 34) throw new Error('GeoJSON không hợp lệ');
      geographicData = data;
      renderMap();
    })
    .catch((error) => {
      console.error('[dashboard-map]', error);
      state.classList.add('is-error');
      state.innerHTML = 'Không thể tải dữ liệu bản đồ.';
    });

  new ResizeObserver(() => {
    cancelAnimationFrame(resizeFrame);
    resizeFrame = requestAnimationFrame(renderMap);
  }).observe(container);
})();
