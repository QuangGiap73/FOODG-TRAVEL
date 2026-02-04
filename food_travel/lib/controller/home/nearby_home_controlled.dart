import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/places_model.dart';
import '../../services/location_service.dart';
import '../../services/map/serpapi_places_service.dart';

enum NearbyHomeStatus { idle, loading, success, empty, locationDisabled, error }

class _NearbyCacheEntry {
  const _NearbyCacheEntry(this.at, this.places);

  final DateTime at;
  final List<GoongNearbyPlace> places;
}

class NearbyHomeController extends ChangeNotifier {
  NearbyHomeController({
    SerpApiPlacesService? placesService,
    LocationService? locationService,
  }) : _placesService = placesService ?? SerpApiPlacesService(),
       _locationService = locationService ?? LocationService();

  final SerpApiPlacesService _placesService;
  final LocationService _locationService;

  static const Duration _cacheTtl = Duration(minutes: 8);
  static const int _radius = 8000;
  static const int _limit = 12;

  final Map<String, _NearbyCacheEntry> _cache = {};
  final List<GoongNearbyPlace> _places = [];

  NearbyHomeStatus _status = NearbyHomeStatus.idle;
  String? _errorMessage;
  LatLng? _userLatLng;

  NearbyHomeStatus get status => _status;
  String? get errorMessage => _errorMessage;
  LatLng? get userLatLng => _userLatLng;
  List<GoongNearbyPlace> get places => List.unmodifiable(_places);

  Future<void> load({bool force = false}) async {
    if (_status == NearbyHomeStatus.loading) return;

    // Bat dau tai danh sach quan gan day.
    _status = NearbyHomeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final location = await _locationService.getCurrentLocation(
      accuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
      useLastKnown: true,
    );
    if (!location.isSuccess || location.position == null) {
      if (location.failReason == LocationFailReason.serviceDisabled ||
          location.failReason == LocationFailReason.permissionDenied ||
          location.failReason == LocationFailReason.permissionDeniedForever) {
        _status = NearbyHomeStatus.locationDisabled;
      } else {
        _status = NearbyHomeStatus.error;
      }
      _errorMessage = location.message ?? 'Khong lay duoc vi tri.';
      notifyListeners();
      return;
    }

    final pos = location.position!;
    _userLatLng = LatLng(pos.latitude, pos.longitude);
    final cacheKey = _buildCacheKey(_userLatLng!);
    final cached = _cache[cacheKey];
    // Neu cache con han thi dung lai de giam goi API.
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.at) <= _cacheTtl) {
      _places
        ..clear()
        ..addAll(cached.places);
      _status =
          _places.isEmpty ? NearbyHomeStatus.empty : NearbyHomeStatus.success;
      notifyListeners();
      return;
    }

    try {
      // Tim "quan an" quanh vi tri hien tai.
      final result = await _placesService.searchNearby(
        lat: pos.latitude,
        lng: pos.longitude,
        query: 'quan an',
        radius: _radius,
        limit: _limit,
      );
      final sorted = _sortPlaces(
        result,
        userLat: pos.latitude,
        userLng: pos.longitude,
      );
      _places
        ..clear()
        ..addAll(sorted);
      _cache[cacheKey] = _NearbyCacheEntry(DateTime.now(), List.of(sorted));
      _status =
          _places.isEmpty ? NearbyHomeStatus.empty : NearbyHomeStatus.success;
      notifyListeners();
    } catch (_) {
      _status = NearbyHomeStatus.error;
      _errorMessage = 'Khong tai duoc danh sach quan an gan day.';
      notifyListeners();
    }
  }

  List<GoongNearbyPlace> _sortPlaces(
    List<GoongNearbyPlace> input, {
    required double userLat,
    required double userLng,
  }) {
    final list = List<GoongNearbyPlace>.from(input);
    list.sort((a, b) {
      // Uu tien quan dang mo cua.
      final aOpen = a.isOpen == true ? 1 : 0;
      final bOpen = b.isOpen == true ? 1 : 0;
      if (aOpen != bOpen) return bOpen.compareTo(aOpen);

      // Sau do sap xep theo khoang cach tang dan.
      final aDist = Geolocator.distanceBetween(userLat, userLng, a.lat, a.lng);
      final bDist = Geolocator.distanceBetween(userLat, userLng, b.lat, b.lng);
      final byDistance = aDist.compareTo(bDist);
      if (byDistance != 0) return byDistance;

      // Cuoi cung uu tien rating cao hon.
      final aRating = a.rating ?? 0;
      final bRating = b.rating ?? 0;
      return bRating.compareTo(aRating);
    });
    return list;
  }

  String _buildCacheKey(LatLng target) {
    final lat = (target.latitude * 1000).round();
    final lng = (target.longitude * 1000).round();
    return 'nearby_${lat}_$lng';
  }
}

class NearbyHomeControlled extends NearbyHomeController {
  NearbyHomeControlled({
    SerpApiPlacesService? placesService,
    LocationService? locationService,
  }) : super(placesService: placesService, locationService: locationService);
}
