import 'dart:async';
import 'package:geolocator/geolocator.dart';

// ly do thong bao cac loi
enum LocationFailReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeoutOrError,
}

class LocationResult {
  final Position? position;
  final LocationFailReason? failReason;
  final String? message;

  // tạo private để ko muốn cho người dùng tạo lung tung
  const LocationResult._({this.position, this.failReason,this.message});

  factory LocationResult.success(Position position) =>
        LocationResult._(position: position);
  factory LocationResult.fail(LocationFailReason reason, {String? message}) =>
        LocationResult._(failReason: reason, message: message);
  // tien dung chi can check
  bool get isSuccess => position != null;
}
class LocationService {
  Future<LocationResult> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 10),
    bool useLastKnown = true,
  }) async {
    try {
      // kiem tra gps co bat ko
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.fail(
          LocationFailReason.serviceDisabled,
          message: 'Location service is disabled.',
        );
      }
      // chech quyen
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return LocationResult.fail(
          LocationFailReason.permissionDenied,
          message: 'Location permission denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.fail(
          LocationFailReason.permissionDeniedForever,
          message: 'Location permission is permanently denied.',
        );
      }
      if (useLastKnown) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return LocationResult.success(last);
        }
      }
      // lay vi tri hien tai 
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );
      return LocationResult.success(position);
    } on TimeoutException {
      return LocationResult.fail(
        LocationFailReason.timeoutOrError,
        message: 'Location request timed out.',
      );
    } catch (error) {
      return LocationResult.fail(
        LocationFailReason.timeoutOrError,
        message: 'Failed to get location: $error',
      );
    }
  }
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}