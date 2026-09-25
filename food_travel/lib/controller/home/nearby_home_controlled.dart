import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/places_model.dart';
import '../../services/location_service.dart';
import '../../services/location_repository.dart';
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
    LocationRepository? locationRepository,
  }) : _placesService = placesService ?? SerpApiPlacesService(),
       _locationService = locationService ?? LocationService(),
       _locationRepository = locationRepository ?? LocationRepository.instance;

  final SerpApiPlacesService _placesService;
  final LocationService _locationService;
  final LocationRepository _locationRepository;
  final Random _random = Random();

  static const Duration _cacheTtl = Duration(minutes: 8);
  static const List<int> _radiusSteps = [6000, 10000, 15000];
  static const int _limit = 12;
  // Home only renders 12 cards. Stop as soon as that many places are found so
  // one refresh does not unnecessarily consume several SerpAPI searches.
  static const int _targetPlaceCount = _limit;
  static const int _queriesPerRadius = 3;

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

    final sharedPosition = _locationRepository.position;
    var location =
        sharedPosition == null
            ? await _locationService.getCurrentLocation(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10),
              // Home must still be usable while the GPS provider is warming
              // up. LocationService will prefer the last device fix and only
              // wait for a fresh one when no fix exists.
              useLastKnown: true,
            )
            : LocationResult.success(sharedPosition);

    // A provider can publish a last-known fix just after the request times out.
    // It is better to show nearby places from that fix than hide the whole Home
    // section. The active location stream will refresh the list when GPS moves.
    if (!location.isSuccess) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) location = LocationResult.success(lastKnown);
    }
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
    _locationRepository.update(pos);
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
      final places = await _searchAndMergeNearby(
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
    } catch (error, stackTrace) {
      debugPrint('[NearbyHome] load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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

  Future<List<GoongNearbyPlace>> _searchAndMergeNearby({
    required double lat,
    required double lng,
    required List<String> queries,
  }) async {
    final selectedQueries = _pickDiverseQueries(queries);
    final merged = <String, GoongNearbyPlace>{};

    for (final radius in _radiusSteps) {
      for (final query in selectedQueries) {
        final result = await _placesService.searchNearby(
          lat: lat,
          lng: lng,
          query: query,
          radius: radius,
          limit: _limit,
          enrichDetails: false,
        );
        for (final place in result) {
          merged.putIfAbsent(_placeDedupKey(place), () => place);
        }
        if (merged.length >= _targetPlaceCount) break;
      }

      // Chi mo rong ban kinh khi khu vuc hien tai chua du phong phu.
      if (merged.length >= _targetPlaceCount) break;
    }

    return merged.values.toList();
  }

  List<String> _pickDiverseQueries(List<String> queries) {
    if (queries.length <= _queriesPerRadius) return queries;

    // Giu mot query rong, sau do chon ngau nhien cac nhom mon con lai.
    final generic = queries.first;
    final specific =
        queries.skip(1).where((q) => q != generic).toList()..shuffle(_random);
    return [generic, ...specific.take(_queriesPerRadius - 1)];
  }

  String _placeDedupKey(GoongNearbyPlace place) {
    final stableId =
        place.serpDataId.trim().isNotEmpty
            ? place.serpDataId.trim()
            : place.id.trim();
    if (stableId.isNotEmpty) return 'id:$stableId';

    final normalizedName = place.name.trim().toLowerCase();
    final lat = (place.lat * 10000).round();
    final lng = (place.lng * 10000).round();
    return 'place:$normalizedName:$lat:$lng';
  }

  List<GoongNearbyPlace> _sortPlaces(
    List<GoongNearbyPlace> input, {
    required double userLat,
    required double userLng,
  }) {
    final list = List<GoongNearbyPlace>.from(input);
    list.sort((a, b) {
      // Sap xep theo khoang cach tang dan de quan gan nhat luon len truoc.
      final aDist = Geolocator.distanceBetween(userLat, userLng, a.lat, a.lng);
      final bDist = Geolocator.distanceBetween(userLat, userLng, b.lat, b.lng);
      final byDistance = aDist.compareTo(bDist);
      if (byDistance != 0) return byDistance;

      // Neu cung khoang cach thi uu tien quan dang mo cua, sau do rating cao hon.
      final aOpen = a.isOpen == true ? 1 : 0;
      final bOpen = b.isOpen == true ? 1 : 0;
      if (aOpen != bOpen) return bOpen.compareTo(aOpen);

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
    LocationRepository? locationRepository,
  }) : super(
         placesService: placesService,
         locationService: locationService,
         locationRepository: locationRepository,
       );
}
