const fs = require('fs');
const path = require('path');

const sourcePath = path.resolve(__dirname, '../../food_travel/assets/maps/geojson/vietnam_provinces_34.geojson');
const outputPath = path.resolve(__dirname, '../src/public/data/vietnam-provinces-34.geojson');
const source = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));

function squaredDistance(point, start, end) {
  const dx = end[0] - start[0];
  const dy = end[1] - start[1];
  if (!dx && !dy) return (point[0] - start[0]) ** 2 + (point[1] - start[1]) ** 2;
  const t = Math.max(0, Math.min(1, ((point[0] - start[0]) * dx + (point[1] - start[1]) * dy) / (dx * dx + dy * dy)));
  return (point[0] - (start[0] + t * dx)) ** 2 + (point[1] - (start[1] + t * dy)) ** 2;
}

function simplifyLine(points, tolerance = 0.003) {
  if (points.length <= 4) return points;
  const closed = points[0][0] === points.at(-1)[0] && points[0][1] === points.at(-1)[1];
  const line = closed ? points.slice(0, -1) : points.slice();
  const keep = new Uint8Array(line.length);
  keep[0] = 1;
  keep[line.length - 1] = 1;
  const stack = [[0, line.length - 1]];
  const threshold = tolerance ** 2;
  while (stack.length) {
    const [startIndex, endIndex] = stack.pop();
    let maxDistance = threshold;
    let selectedIndex = -1;
    for (let index = startIndex + 1; index < endIndex; index += 1) {
      const distance = squaredDistance(line[index], line[startIndex], line[endIndex]);
      if (distance > maxDistance) {
        maxDistance = distance;
        selectedIndex = index;
      }
    }
    if (selectedIndex !== -1) {
      keep[selectedIndex] = 1;
      stack.push([startIndex, selectedIndex], [selectedIndex, endIndex]);
    }
  }
  const result = line.filter((_point, index) => keep[index]);
  if (closed) result.push(result[0]);
  if (result.length <= 4) return points;

  const signedArea = (ring) => ring.reduce((sum, point, index) => {
    const next = ring[(index + 1) % ring.length];
    return sum + (next[0] - point[0]) * (next[1] + point[1]);
  }, 0);
  const originalDirection = Math.sign(signedArea(points));
  const simplifiedDirection = Math.sign(signedArea(result));
  if (!simplifiedDirection) return points;
  if (originalDirection !== simplifiedDirection) result.reverse();
  return result;
}

function simplifyGeometry(geometry) {
  const simplifyPolygon = (polygon) => polygon.map((ring) => simplifyLine(ring));
  if (geometry.type === 'Polygon') return { ...geometry, coordinates: simplifyPolygon(geometry.coordinates) };
  if (geometry.type === 'MultiPolygon') return { ...geometry, coordinates: geometry.coordinates.map(simplifyPolygon) };
  return geometry;
}

const optimized = {
  type: 'FeatureCollection',
  features: source.features.map((feature) => ({
    type: 'Feature',
    properties: {
      code: String(feature.properties.Ma || ''),
      name: feature.properties.TinhThanh || '',
    },
    geometry: simplifyGeometry(feature.geometry),
  })),
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(optimized));
console.log(`Created ${optimized.features.length} provinces at ${outputPath}`);
