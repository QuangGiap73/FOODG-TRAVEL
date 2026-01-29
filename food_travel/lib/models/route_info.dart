import 'package:maplibre_gl/maplibre_gl.dart';

// model tuyen duong
class RouteInfo {
  RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}