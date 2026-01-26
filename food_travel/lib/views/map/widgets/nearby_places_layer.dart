import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/places_model.dart';

class NearbyPlacesLayer {
  NearbyPlacesLayer(this._controller);

  final MapLibreMapController _controller;
  final List<Circle> _circles = [];

  Future<void> showPlaces(
    List<GoongNearbyPlace> places, {
    bool animate = true,
    double zoom = 14,
  }) async {
    await clear();
    if (places.isEmpty) return;

    // Ve marker bang circle (don gian, de nhin).
    for (final place in places) {
      final circle = await _controller.addCircle(
        CircleOptions(
          geometry: LatLng(place.lat, place.lng),
          circleRadius: 8,
          circleColor: '#FF6D00',
          circleOpacity: 0.9,
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _circles.add(circle);
    }

    if (animate) {
      final first = places.first;
      await _controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(first.lat, first.lng),
          zoom,
        ),
      );
    }
  }

  Future<void> clear() async {
    for (final circle in _circles) {
      await _controller.removeCircle(circle);
    }
    _circles.clear();
  }
}
