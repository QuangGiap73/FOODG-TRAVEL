import 'dart:math';

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
  final Random _random = Random();

  static const Duration _cacheTtl = Duration(minutes: 8);
  static const int _radius = 8000;
  static const List<int> _radiusSteps = [6000, 10000, 15000];
  static const int _limit = 12;

  final Map<String, _NearbyCacheEntry> _cache = {};
  final List<GoongNearbyPlace> _places = [];

  NearbyHomeStatus _status = NearbyHomeStatus.idle;
  String? _errorMessage;
  LatLng? _userLatLng;
  String? _lastPickedQuery;

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
      // Thu nhieu query theo khung gio + mo rong ban kinh de tang ty le co ket qua.
      final queries = _queryCandidatesByHour(DateTime.now());
      final places = await _searchFirstNonEmpty(
        lat: pos.latitude,
        lng: pos.longitude,
        queries: queries,
      );

      final sorted = _sortPlaces(
        places,
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

  String _pickQueryByHour(DateTime now) {
    final hour = now.hour;
    List<String> pool;

    if (hour >= 5 && hour < 11) {
      pool = ['an sang', 'quan an', 'pho', 'bun', 'banh mi'];
    } else if (hour >= 11 && hour < 14) {
      pool = ['an trua', 'quan an', 'com van phong', 'com tam', 'bun cha'];
    } else if (hour >= 14 && hour < 17) {
      pool = ['an vat', 'quan an', 'tra sua', 'cafe', 'banh ngot'];
    } else if (hour >= 17 && hour < 22) {
      pool = ['an toi', 'quan an', 'lau', 'nuong', 'nha hang'];
    } else {
      pool = ['an dem', 'quan mo khuya', 'do an dem', 'quan an'];
    }

    // Tranh lap query vua dung (neu co the).
    if (pool.length > 1 && _lastPickedQuery != null) {
      pool = pool.where((q) => q != _lastPickedQuery).toList();
    }

    final picked = pool[_random.nextInt(pool.length)];
    _lastPickedQuery = picked;
    return picked;
  }

  List<String> _queryCandidatesByHour(DateTime now) {
    final picked = _pickQueryByHour(now);
    final hour = now.hour;
    List<String> base;

    if (hour >= 5 && hour < 11) {
      base = [
        'quan an',
        'quan an sang',
        'an sang',
        'pho',
        'bun',
        'banh mi',
        picked,
      ];
    } else if (hour >= 11 && hour < 14) {
      base = [
        'quan an',
        'quan an trua',
        'an trua',
        'com van phong',
        'com tam',
        'bun cha',
        picked,
      ];
    } else if (hour >= 14 && hour < 17) {
      base = [
        'quan an',
        'quan an vat',
        'an vat',
        'tra sua',
        'cafe',
        'banh ngot',
        picked,
      ];
    } else if (hour >= 17 && hour < 22) {
      base = [
        'quan an',
        'quan an toi',
        'an toi',
        'lau',
        'nuong',
        'nha hang',
        picked,
      ];
    } else {
      base = [
        'quan an',
        'quan an dem',
        'an dem',
        'quan mo khuya',
        'do an dem',
        picked,
      ];
    }

    // Fallback rong de dam bao moi khung gio deu co co hoi co quan.
    base.addAll(const ['quan an', 'nha hang', 'an uong']);

    final seen = <String>{};
    return base
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && seen.add(e))
        .toList();
  }

  Future<List<GoongNearbyPlace>> _searchFirstNonEmpty({
    required double lat,
    required double lng,
    required List<String> queries,
  }) async {
    for (final radius in _radiusSteps) {
      for (final query in queries) {
        final result = await _placesService.searchNearby(
          lat: lat,
          lng: lng,
          query: query,
          radius: radius,
          limit: _limit,
        );
        if (result.isNotEmpty) return result;
      }
    }

    // Fallback cuoi cung.
    return _placesService.searchNearby(
      lat: lat,
      lng: lng,
      query: 'quan an',
      radius: _radius,
      limit: _limit,
    );
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
