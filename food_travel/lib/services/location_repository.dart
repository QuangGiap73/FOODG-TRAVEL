import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// In-memory source of truth for the latest device position.
///
/// Pages may stop their own GPS stream when they become inactive, but the last
/// fix remains available to every feature for the lifetime of the app process.
class LocationRepository extends ChangeNotifier {
  LocationRepository();

  static final LocationRepository instance = LocationRepository();

  Position? _position;

  Position? get position => _position;

  void update(Position position) {
    final previous = _position;
    _position = position;

    if (previous == null ||
        previous.latitude != position.latitude ||
        previous.longitude != position.longitude ||
        previous.timestamp != position.timestamp) {
      notifyListeners();
    }
  }

  void clear() {
    if (_position == null) return;
    _position = null;
    notifyListeners();
  }
}
