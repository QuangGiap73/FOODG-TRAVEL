import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/journey/checkin_result.dart';
import '../../services/journey/checkin_service.dart';
import '../../services/location_service.dart';

class JourneyController extends ChangeNotifier {
  JourneyController({
    CheckinService? checkinService,
    LocationService? locationService,
  })  : _checkinService = checkinService ?? CheckinService(),
        _locationService = locationService ?? LocationService();

  final CheckinService _checkinService;
  final LocationService _locationService;

  bool _isLoading = false;
  String? _errorCode;
  String? _errorMessage;
  JourneyCheckinResult? _lastCheckinResult;

  bool get isLoading => _isLoading;
  String? get errorCode => _errorCode;
  String? get errorMessage => _errorMessage;
  JourneyCheckinResult? get lastCheckinResult => _lastCheckinResult;

  bool get hasResult => _lastCheckinResult != null;

  /// Goi check-in tu UI.
  /// Controller se tu lay GPS, sau do goi Cloud Function.
  Future<bool> checkInPlace({
    required String placeId,
    required String placeName,
    required String placeAddress,
    required double placeLat,
    required double placeLng,
    String verificationType = 'gps',
    String source = 'gps',
    String? photoUrl,
    double? placeRating,
    String? districtName,
    String? placeType,
    String? provinceCode,
    String? provinceName,
  }) async {
    _errorCode = null;
    _errorMessage = null;
    _lastCheckinResult = null;
    _isLoading = true;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      if (!location.isSuccess || location.position == null) {
        _errorCode = _mapLocationError(location.failReason);
        _errorMessage = location.message;
        return false;
      }

      final Position position = location.position!;
      final result = await _checkinService.createCheckin(
        placeId: placeId,
        placeName: placeName,
        placeAddress: placeAddress,
        placeLat: placeLat,
        placeLng: placeLng,
        userLat: position.latitude,
        userLng: position.longitude,
        verificationType: verificationType,
        source: source,
        photoUrl: photoUrl,
        placeRating: placeRating,
        districtName: districtName,
        placeType: placeType,
        provinceCode: provinceCode,
        provinceName: provinceName,
      );

      _lastCheckinResult = result;
      return result.success;
    } on FirebaseFunctionsException catch (e) {
      _errorCode = e.code;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorCode = 'unknown';
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _lastCheckinResult = null;
    _errorCode = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _mapLocationError(LocationFailReason? reason) {
    switch (reason) {
      case LocationFailReason.serviceDisabled:
        return 'location_service_disabled';
      case LocationFailReason.permissionDenied:
        return 'location_permission_denied';
      case LocationFailReason.permissionDeniedForever:
        return 'location_permission_denied_forever';
      case LocationFailReason.timeoutOrError:
        return 'location_timeout';
      case null:
        return 'location_unknown';
    }
  }
}
