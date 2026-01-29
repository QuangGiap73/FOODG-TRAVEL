import 'package:maplibre_gl/maplibre_gl.dart';

class RouteLayer {
  RouteLayer(this._controller);

  final MapLibreMapController _controller;
  Line? _line;
  // Ve polyline route
  Future<void> showRoute(List<LatLng> points) async {
    if (points.length < 2) return;
    if (_line == null) {
      _line = await _controller.addLine(
        LineOptions(
          geometry: points,
          lineColor: '#FF6D00',
          lineWidth: 4,
          lineOpacity: 0.9,
        ),
      );
    } else {
      await _controller.updateLine(_line!, LineOptions(geometry: points));
    }
  }
  // Xoa route tren map
  Future<void> clear() async {
    if (_line != null) {
      await _controller.removeLine(_line!);
      _line = null;
    }
  }
}
