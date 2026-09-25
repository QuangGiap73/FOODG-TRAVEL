import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:food_travel/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/map/map_search_controller.dart';
import '../../controller/map/navigation_controller.dart';
import '../../config/goong_secrets.dart';
import '../../models/places_model.dart';
import '../../services/map/places_service.dart';
import '../../services/map/serpapi_places_service.dart';
import '../../services/location_preference_service.dart';
import '../../services/location_repository.dart';
import '../../views/favorites/place_detail_page.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/nearby_places_layer.dart';
import 'widgets/nearby_places_sheet.dart';
import 'widgets/place_detail_sheet.dart';
import 'widgets/route_layer.dart';

class _MapStyle {
  const _MapStyle(this.label, this.url);

  final String label;
  final String url;
}

class _NearbyCategory {
  const _NearbyCategory(this.id, this.label, this.keywords);

  final String id;
  final String label;
  final List<String> keywords;
}

class _NearbyCacheEntry {
  const _NearbyCacheEntry(this.at, this.places);

  final DateTime at;
  final List<GoongNearbyPlace> places;
}

List<GoongNearbyPlace> _sortPlacesByDistance(
  Iterable<GoongNearbyPlace> places,
  LatLng origin,
) {
  final sorted = List<GoongNearbyPlace>.from(places);
  sorted.sort((a, b) {
    final aDistance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      a.lat,
      a.lng,
    );
    final bDistance = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      b.lat,
      b.lng,
    );
    final byDistance = aDistance.compareTo(bDistance);
    if (byDistance != 0) return byDistance;

    final aRating = a.rating ?? 0;
    final bRating = b.rating ?? 0;
    return bRating.compareTo(aRating);
  });
  return sorted;
}

enum _DirectionsChoice { inApp, googleMaps }

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.initialNearbyPlaces = const [],
    this.initialNearbyQuery,
    this.initialPlace,
    this.isActive,
  });

  final List<GoongNearbyPlace> initialNearbyPlaces;
  final String? initialNearbyQuery;
  final GoongNearbyPlace? initialPlace;

  /// Chỉ được truyền khi MapPage nằm trong IndexedStack của màn Home.
  /// MapPage mở bằng Navigator không truyền giá trị này và luôn hoạt động.
  final ValueListenable<bool>? isActive;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Update the Normal URL if you create your own Goong style.
  static const _styles = <_MapStyle>[
    _MapStyle(
      'Normal',
      'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongMapApiKey',
    ),
    _MapStyle(
      'Highlight',
      'https://tiles.goong.io/assets/goong_map_highlight.json?api_key=$goongMapApiKey',
    ),
    _MapStyle(
      'Satellite',
      'https://tiles.goong.io/assets/goong_satellite.json?api_key=$goongMapApiKey',
    ),
  ];

  int _styleIndex = 0; // Default to normal (known to work).
  String get _styleUrl => _styles[_styleIndex].url;

  MapLibreMapController? _controller;
  final _locationPrefs = LocationPreferenceService();
  final _locationRepository = LocationRepository.instance;
  late final MapSearchController _searchController;
  final _searchTextController = TextEditingController();
  final _serpService = SerpApiPlacesService();
  late final NavigationController _navController;
  RouteLayer? _routeLayer;
  StreamSubscription<Position>? _positionSub;
  bool _styleReady = false;
  bool _locationEnabled = LocationPreferenceService.enabled.value;
  bool _centeredOnUser = false;
  LatLng? _lastLatLng;
  Circle? _searchCircle;
  LatLng? _searchLatLng;
  // Danh sach quan gan day + layer ve marker
  final List<GoongNearbyPlace> _nearbyPlaces = [];
  NearbyPlacesLayer? _nearbyLayer;
  bool _nearbyLoading = false;
  bool _restaurantSearchLoading = false;
  final List<GoongNearbyPlace> _restaurantSuggestions = [];
  Timer? _restaurantSearchDebounce;
  int _restaurantSearchVersion = 0;
  bool _nearbySheetExpanded = false;
  int _selectedCategory = 0;
  final Map<String, _NearbyCacheEntry> _nearbyCache = {};
  String? _toastMessage;
  Timer? _toastTimer;
  late bool _mapActive;

  static const int _nearbyRadius = 8000;
  static const Duration _nearbyCacheTtl = Duration(seconds: 60);
  static const _categories = <_NearbyCategory>[
    _NearbyCategory('quan_an', 'Quan an', [
      'nha hang',
      'quan an',
      'an uong',
      'com',
      'bun',
      'pho',
      'mi',
      'lau',
      'nuong',
    ]),
    _NearbyCategory('cafe', 'Cafe', [
      'cafe',
      'coffee',
      'ca phe',
      'tra',
      'tra sua',
    ]),
    _NearbyCategory('an_vat', 'An vat', [
      'an vat',
      'snack',
      'do an vat',
      'banh',
    ]),
    _NearbyCategory('fast_food', 'Do an nhanh', [
      'fast food',
      'burger',
      'pizza',
      'ga ran',
      'banh mi',
    ]),
    _NearbyCategory('hai_san', 'Hai san', ['hai san', 'seafood']),
  ];

  List<String> _categoryLabels(AppLocalizations t) => [
    t.mapCategoryRestaurants,
    t.mapCategoryCafe,
    t.mapCategorySnack,
    t.mapCategoryFastFood,
    t.mapCategorySeafood,
  ];

  String _styleLabel(AppLocalizations t, int index) {
    switch (index) {
      case 0:
        return t.mapStyleNormal;
      case 1:
        return t.mapStyleHighlight;
      case 2:
        return t.mapStyleSatellite;
      default:
        return t.mapStyleNormal;
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    // Tao layer ve route khi map duoc tao
    _routeLayer = RouteLayer(controller);
    controller.onSymbolTapped.add(_onSymbolTapped);
  }

  void _ensureNearbyLayer() {
    if (_controller == null) return;
    _nearbyLayer ??= NearbyPlacesLayer(_controller!);
  }

  void _onSymbolTapped(Symbol symbol) {
    final place = _nearbyLayer?.placeForSymbol(symbol);
    if (place == null) return;
    _openPlaceDetail(place);
  }

  void _onNavChanged() {
    if (!mounted) return;
    if (_routeLayer == null) return;
    final route = _navController.route;
    if (route == null) {
      _routeLayer!.clear();
    } else {
      _routeLayer!.showRoute(route.points);
    }
  }

  Future<void> _handleLocationPreferenceChanged() async {
    final enabled = LocationPreferenceService.enabled.value;
    if (_locationEnabled != enabled && mounted) {
      setState(() => _locationEnabled = enabled);
    } else {
      _locationEnabled = enabled;
    }

    if (!_mapActive) {
      await _stopLocationStream();
      return;
    }

    if (enabled) {
      await _startLocationStream();
    } else {
      await _stopLocationStream();
      await _clearUserMarker();
    }
  }

  void _startDirections(GoongNearbyPlace place) {
    // Bat dau dan duong den quan
    _startDirectionsInternal(place);
  }

  // lua chon cach thuc chi duong den map
  Future<void> _openDirectionsChooser(GoongNearbyPlace place) async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<_DirectionsChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const ListTile(
                title: Text(
                  'Chọn cách chỉ đường',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.navigation),
                title: const Text('Dẫn đường trong ứng dụng'),
                onTap: () => Navigator.of(ctx).pop(_DirectionsChoice.inApp),
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Mở Google Maps'),
                onTap:
                    () => Navigator.of(ctx).pop(_DirectionsChoice.googleMaps),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null) return;
    switch (choice) {
      case _DirectionsChoice.inApp:
        _startDirectionsInternal(place);
        break;
      case _DirectionsChoice.googleMaps:
        await _openGoogleMapsDirections(place);
        break;
    }
  }

  Future<void> _openGoogleMapsDirections(GoongNearbyPlace place) async {
    final lat = place.lat;
    final lng = place.lng;
    if (!lat.isFinite || !lng.isFinite || (lat == 0 && lng == 0)) {
      _showSnack('Tọa độ quán ăn không hợp lệ');
      return;
    }

    // Android dùng google.navigation; iOS dùng scheme comgooglemaps.
    final appUri =
        defaultTargetPlatform == TargetPlatform.iOS
            ? Uri.parse(
              'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
            )
            : Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });

    try {
      if (await canLaunchUrl(appUri) &&
          await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
        return;
      }

      // Nếu chưa cài Google Maps thì mở trang chỉ đường trong trình duyệt.
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        return;
      }

      _showSnack('Không thể mở Google Maps trên thiết bị này');
    } catch (error) {
      debugPrint('Lỗi mở Google Maps: $error');
      _showSnack('Có lỗi khi mở Google Maps');
    }
  }

  Future<void> _startDirectionsInternal(GoongNearbyPlace place) async {
    final ok = await _navController.startNavigation(
      LatLng(place.lat, place.lng),
    );
    if (!ok) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      final msg = _navigationErrorMessage(t);
      _showSnack(msg);
      _navController.clearError();
    }
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;

    _ensureNearbyLayer();

    if (_searchLatLng != null) {
      await _showSearchMarker(_searchLatLng!, animate: false);
    }

    if (_nearbyPlaces.isNotEmpty && _nearbyLayer != null) {
      // Ve lai marker quan gan day khi doi style.
      await _nearbyLayer!.showPlaces(
        _nearbyPlaces,
        animate: _lastLatLng == null,
      );
    }

    // Ve lai route neu dang dan duong
    if (_routeLayer != null && _navController.route != null) {
      await _routeLayer!.showRoute(_navController.route!.points);
    }
  }

  Future<void> _onUserLocationUpdated(UserLocation location) async {
    // MapLibre can also emit user location updates.
    _lastLatLng = location.position;
    _searchController.setBias(
      lat: location.position.latitude,
      lng: location.position.longitude,
      radius: _nearbyRadius,
    );
    if (_nearbyPlaces.length > 1) {
      final sorted = _sortPlacesByDistance(_nearbyPlaces, location.position);
      _nearbyPlaces
        ..clear()
        ..addAll(sorted);
      if (mounted) setState(() {});
    }
    await _updateUserMarker(location.position);
  }

  Future<void> _updateUserMarker(LatLng position) async {
    if (!_styleReady || _controller == null) return;

    if (!_centeredOnUser) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
      _centeredOnUser = true;
    }
  }

  Future<void> _clearUserMarker({bool keepLastLocation = false}) async {
    _centeredOnUser = false;
    if (!keepLastLocation) {
      _lastLatLng = null;
    }
  }

  Future<void> _startLocationStream() async {
    if (_positionSub != null) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) async {
      _locationRepository.update(pos);
      if (!_styleReady) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      _lastLatLng = latLng;
      _searchController.setBias(
        lat: latLng.latitude,
        lng: latLng.longitude,
        radius: _nearbyRadius,
      );
      await _updateUserMarker(latLng);
    });
  }

  Future<void> _stopLocationStream() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _selectStyle(int index) async {
    if (index == _styleIndex) return;

    await _clearUserMarker(keepLastLocation: true);
    await _clearSearchMarker(keepSearch: true);
    await _nearbyLayer?.clear();
    _nearbyLayer = null;
    setState(() {
      _styleIndex = index;
      _styleReady = false;
    });
  }

  void _zoomIn() {
    _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _controller?.animateCamera(CameraUpdate.zoomOut());
  }

  String _cacheKey(int categoryIndex, LatLng target, {String? query}) {
    final lat = (target.latitude * 1000).round();
    final lng = (target.longitude * 1000).round();
    final queryKey = query == null ? '' : _normalizeQuery(query);
    final scope = queryKey.isEmpty ? _categories[categoryIndex].id : 'q';
    final suffix = queryKey.isEmpty ? '' : '_$queryKey';
    return '${scope}_${lat}_$lng$suffix';
  }

  String _normalizeQuery(String input) {
    final cleaned = input.trim().toLowerCase();
    if (cleaned.isEmpty) return '';
    return cleaned.replaceAll(RegExp(r'\s+'), '_');
  }

  String _buildSerpQuery(_NearbyCategory category) {
    for (final keyword in category.keywords) {
      final trimmed = keyword.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    final label = category.label.trim();
    return label.isNotEmpty ? label : 'quan an';
  }

  String _navigationErrorMessage(AppLocalizations t) {
    final code = _navController.lastErrorCode;
    switch (code) {
      case NavigationController.errorPermissionDenied:
        return t.mapPermissionDenied;
      case NavigationController.errorRouteUnavailable:
      case NavigationController.errorRouteFailed:
      default:
        return t.mapDirectionsError;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _toastMessage = null);
    });
  }

  Future<void> _recenterOnUser() async {
    if (_controller == null) return;
    final t = AppLocalizations.of(context)!;

    if (!LocationPreferenceService.enabled.value) {
      _showSnack(t.mapEnableLocation);
      return;
    }

    var target = _lastLatLng;
    target ??= await _controller!.requestMyLocationLatLng();

    if (target == null) {
      _showSnack(t.mapLocationUnavailable);
      return;
    }

    await _controller!.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  void _onSearchStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearSearch() {
    _restaurantSearchDebounce?.cancel();
    _restaurantSearchVersion++;
    _searchTextController.clear();
    _searchController.clear();
    _restaurantSuggestions.clear();
    _nearbyPlaces.clear();
    _nearbyLayer?.clear();
    _clearSearchMarker();
    if (mounted) setState(() => _restaurantSearchLoading = false);
  }

  void _onRestaurantQueryChanged(String value) {
    final query = value.trim();
    final version = ++_restaurantSearchVersion;
    _restaurantSearchDebounce?.cancel();

    if (query.length < 2) {
      setState(() {
        _restaurantSearchLoading = false;
        _restaurantSuggestions.clear();
        _nearbyPlaces.clear();
      });
      _nearbyLayer?.clear();
      return;
    }

    setState(() => _restaurantSearchLoading = true);
    _restaurantSearchDebounce = Timer(
      const Duration(milliseconds: 600),
      () => _searchRestaurantByName(query, version),
    );
  }

  Future<void> _searchRestaurantByName(String query, int version) async {
    final t = AppLocalizations.of(context)!;
    try {
      LatLng? target = _lastLatLng;
      target ??= await _controller?.requestMyLocationLatLng();
      if (target == null) {
        if (!LocationPreferenceService.enabled.value) {
          if (version == _restaurantSearchVersion) {
            _showSnack(t.mapEnableGpsToSearch);
          }
          return;
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (version == _restaurantSearchVersion) {
            _showSnack(t.mapPermissionDenied);
          }
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        target = LatLng(position.latitude, position.longitude);
        _lastLatLng = target;
      }
      final origin = target;

      final cacheKey = _cacheKey(_selectedCategory, origin, query: query);
      final cached = _nearbyCache[cacheKey];
      List<GoongNearbyPlace> places;
      if (cached != null &&
          DateTime.now().difference(cached.at) < _nearbyCacheTtl) {
        places = List<GoongNearbyPlace>.from(cached.places);
      } else {
        final raw = await _serpService.searchNearby(
          lat: origin.latitude,
          lng: origin.longitude,
          query: query,
          radius: _nearbyRadius,
          limit: 12,
          enrichDetails: false,
        );
        places =
            raw.where((place) {
              final distance = Geolocator.distanceBetween(
                origin.latitude,
                origin.longitude,
                place.lat,
                place.lng,
              );
              return distance <= 30000;
            }).toList();
        places = _sortPlacesByDistance(places, origin);
        _nearbyCache[cacheKey] = _NearbyCacheEntry(
          DateTime.now(),
          List<GoongNearbyPlace>.from(places),
        );
      }

      if (!mounted || version != _restaurantSearchVersion) return;
      setState(() {
        _restaurantSuggestions
          ..clear()
          ..addAll(places);
        _nearbyPlaces
          ..clear()
          ..addAll(places);
      });
      if (_styleReady) {
        _ensureNearbyLayer();
        if (places.isEmpty) {
          await _nearbyLayer?.clear();
        } else {
          await _nearbyLayer?.showPlaces(places, animate: true);
        }
      }
    } on TimeoutException {
      if (version == _restaurantSearchVersion) {
        _showSnack(t.mapLocationTimeout);
      }
    } catch (error) {
      debugPrint('Map restaurant search failed: $error');
      if (version == _restaurantSearchVersion) {
        _showSnack(t.mapSearchError(error.toString()));
      }
    } finally {
      if (mounted && version == _restaurantSearchVersion) {
        setState(() => _restaurantSearchLoading = false);
      }
    }
  }

  Future<void> _selectRestaurantSuggestion(GoongNearbyPlace place) async {
    FocusScope.of(context).unfocus();
    _searchTextController.text = place.name;
    setState(() => _restaurantSuggestions.clear());
    await _openPlaceDetail(place);
  }

  Future<void> _onSelectPrediction(GoongPrediction prediction) async {
    FocusScope.of(context).unfocus();
    final detail = await _searchController.fetchDetail(prediction);
    if (!mounted) return;

    if (detail == null) {
      final t = AppLocalizations.of(context)!;
      _showSnack(t.mapPlaceNotFound);
      return;
    }

    _searchTextController.text = prediction.description;
    _searchController.clear();
    await _showSearchMarker(LatLng(detail.lat, detail.lng));
    if (!mounted) return;

    // Ô này dùng để chọn khu vực. Sau khi có tọa độ, tìm loại quán đang chọn
    // quanh khu vực đó thay vì tiếp tục dùng vị trí GPS của người dùng.
    await _findNearbyFood(
      queryOverride: _buildSerpQuery(_categories[_selectedCategory]),
    );
  }

  Future<void> _showSearchMarker(LatLng position, {bool animate = true}) async {
    if (_controller == null) return;

    _searchLatLng = position;
    if (_searchCircle == null) {
      _searchCircle = await _controller!.addCircle(
        CircleOptions(
          geometry: position,
          circleRadius: 8,
          circleColor: '#FF6D00',
          circleOpacity: 0.9,
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
    } else {
      await _controller!.updateCircle(
        _searchCircle!,
        CircleOptions(geometry: position),
      );
    }

    if (animate) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );
    }
  }

  Future<void> _clearSearchMarker({bool keepSearch = false}) async {
    if (_controller != null && _searchCircle != null) {
      await _controller!.removeCircle(_searchCircle!);
    }
    _searchCircle = null;
    if (!keepSearch) {
      _searchLatLng = null;
    }
  }

  Widget _buildCategoryChips() {
    final t = AppLocalizations.of(context)!;
    final labels = _categoryLabels(t);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ChoiceChip(
            label: Text(labels[index]),
            selected: index == _selectedCategory,
            onSelected: (selected) {
              if (!selected) return;
              setState(() => _selectedCategory = index);
            },
          );
        },
      ),
    );
  }

  Future<void> _focusNearbyPlace(GoongNearbyPlace place) async {
    if (_controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(place.lat, place.lng), 16),
    );
  }

  Future<void> _openPlaceDetail(GoongNearbyPlace place) async {
    await _focusNearbyPlace(place);
    if (!mounted) return;
    await showPlaceDetailSheet(
      context,
      place,
      userLocation: _lastLatLng,
      onDirections: () {
        Navigator.of(context).pop();
        _openDirectionsChooser(place);
      },
      onImageTap: () {
        Navigator.of(context).pop(); // dong bottom sheet
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FavoritePlaceDetailPage(place: place),
          ),
        );
      },
    );
  }

  Future<void> _findNearbyFood({String? queryOverride}) async {
    if (_nearbyLoading) return;
    setState(() => _nearbyLoading = true);
    final t = AppLocalizations.of(context)!;

    try {
      // Nếu người dùng đã chọn địa điểm trong ô tìm kiếm, tìm quanh địa điểm
      // đó. Chỉ yêu cầu GPS khi chưa có tâm tìm kiếm thủ công.
      LatLng? target = _searchLatLng;
      if (target == null) {
        if (!LocationPreferenceService.enabled.value) {
          _showSnack(t.mapEnableGpsToSearch);
          return;
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _showSnack(t.mapPermissionDenied);
          return;
        }

        target = _lastLatLng;
        target ??= await _controller?.requestMyLocationLatLng();
        if (target == null) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 12),
          );
          target = LatLng(pos.latitude, pos.longitude);
        }
      }
      debugPrint('SerpAPI search at ${target.latitude},${target.longitude}');
      if (target.latitude.abs() < 0.0001 && target.longitude.abs() < 0.0001) {
        _showSnack(t.mapGpsInvalid);
        return;
      }

      final rawQuery = queryOverride?.trim();
      final searchQuery =
          (rawQuery != null && rawQuery.isNotEmpty)
              ? rawQuery
              : _buildSerpQuery(_categories[_selectedCategory]);

      final cacheKey = _cacheKey(_selectedCategory, target, query: searchQuery);
      final cached = _nearbyCache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.at) < _nearbyCacheTtl) {
        final sortedCached = _sortPlacesByDistance(cached.places, target);
        _nearbyPlaces
          ..clear()
          ..addAll(sortedCached);
        setState(() {});
        if (_styleReady) {
          _ensureNearbyLayer();
          await _nearbyLayer?.showPlaces(_nearbyPlaces, animate: true);
        }
        return;
      }

      final places = await _serpService.searchNearby(
        lat: target.latitude,
        lng: target.longitude,
        query: searchQuery,
        radius: _nearbyRadius,
        limit: 12,
      );

      if (!mounted) return;
      if (places.isEmpty) {
        _showSnack(t.mapNearbyNotFound);
        return;
      }

      final sortedPlaces = _sortPlacesByDistance(places, target);
      _nearbyPlaces
        ..clear()
        ..addAll(sortedPlaces);
      _nearbyCache[cacheKey] = _NearbyCacheEntry(
        DateTime.now(),
        List.of(sortedPlaces),
      );
      setState(() {}); // Hien danh sach ngay ca khi marker chua ve.

      if (_styleReady) {
        _ensureNearbyLayer();
        await _nearbyLayer?.showPlaces(_nearbyPlaces, animate: true);
      }
    } on TimeoutException {
      _showSnack(t.mapLocationTimeout);
    } catch (e, st) {
      debugPrint('Loi tim quan: $e');
      debugPrint('$st');
      _showSnack(t.mapSearchError(e.toString()));
    } finally {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final sharedPosition = _locationRepository.position;
    if (sharedPosition != null) {
      _lastLatLng = LatLng(sharedPosition.latitude, sharedPosition.longitude);
    }
    _mapActive = widget.isActive?.value ?? true;
    widget.isActive?.addListener(_handleExternalVisibility);
    final loadFuture = _locationPrefs.load();
    LocationPreferenceService.enabled.addListener(
      _handleLocationPreferenceChanged,
    );
    // Khoi tao controller dan duong
    _navController = NavigationController();
    _navController.addListener(_onNavChanged);
    _searchController = MapSearchController();
    _searchController.addListener(_onSearchStateChanged);
    _nearbyPlaces.addAll(widget.initialNearbyPlaces);
    final initialQuery = widget.initialNearbyQuery?.trim();
    if (initialQuery != null && initialQuery.isNotEmpty) {
      loadFuture.whenComplete(() {
        if (!mounted) return;
        _findNearbyFood(queryOverride: initialQuery);
      });
    }
    if (widget.initialPlace != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDirections(widget.initialPlace!);
      });
    }
    loadFuture.whenComplete(() {
      if (_mapActive) _handleLocationPreferenceChanged();
    });
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    oldWidget.isActive?.removeListener(_handleExternalVisibility);
    _mapActive = widget.isActive?.value ?? true;
    widget.isActive?.addListener(_handleExternalVisibility);
  }

  void _handleExternalVisibility() {
    final active = widget.isActive?.value ?? true;
    if (active == _mapActive || !mounted) return;
    if (!active) {
      _suspendMap();
      return;
    }

    setState(() => _mapActive = true);
    _navController.resumeTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapActive) _handleLocationPreferenceChanged();
    });
  }

  Future<void> _suspendMap() async {
    // Dừng mọi nguồn phát frame/cập nhật vị trí trước khi tháo native map.
    setState(() {
      _mapActive = false;
      _styleReady = false;
      _controller = null;
      _routeLayer = null;
      _nearbyLayer = null;
      _centeredOnUser = false;
    });
    await _stopLocationStream();
    await _navController.pauseTracking();
  }

  @override
  void dispose() {
    widget.isActive?.removeListener(_handleExternalVisibility);
    _stopLocationStream();
    LocationPreferenceService.enabled.removeListener(
      _handleLocationPreferenceChanged,
    );
    _controller?.onSymbolTapped.remove(_onSymbolTapped);
    _nearbyLayer?.clear();
    _controller?.dispose();
    _toastTimer?.cancel();
    _restaurantSearchDebounce?.cancel();
    _navController.removeListener(_onNavChanged);
    _navController.dispose();
    _searchController.removeListener(_onSearchStateChanged);
    _searchController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapActive) return const SizedBox.shrink();
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.navMap),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers_outlined),
            onSelected: _selectStyle,
            itemBuilder: (context) {
              return List.generate(
                _styles.length,
                (index) => PopupMenuItem(
                  value: index,
                  child: Text(_styleLabel(t, index)),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            key: ValueKey(_styleUrl),
            styleString: _styleUrl,
            initialCameraPosition: const CameraPosition(
              target: LatLng(21.0278, 105.8342),
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onUserLocationUpdated: _onUserLocationUpdated,
            zoomGesturesEnabled: true,
            myLocationEnabled: _locationEnabled,
            myLocationTrackingMode:
                _locationEnabled
                    ? MyLocationTrackingMode.tracking
                    : MyLocationTrackingMode.none,
            // Chỉ dùng chấm vị trí mặc định để không che marker quán khi zoom xa.
            myLocationRenderMode: MyLocationRenderMode.normal,
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: SafeArea(
              child: Column(
                children: [
                  RepaintBoundary(
                    child: MapSearchBar(
                      controller: _searchTextController,
                      loading: _restaurantSearchLoading,
                      suggestions: const [],
                      placeSuggestions: _restaurantSuggestions,
                      onQueryChanged: _onRestaurantQueryChanged,
                      onClear: _clearSearch,
                      onSelect: _onSelectPrediction,
                      onSelectPlace: _selectRestaurantSuggestion,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),
          if (_toastMessage != null)
            Positioned(
              left: 16,
              right: 16,
              top: 120,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _toastMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (_nearbyPlaces.isNotEmpty)
            NearbyPlacesSheet(
              places: _nearbyPlaces,
              // Khi tìm một khu vực khác, khoảng cách và thứ tự phải tính từ
              // tâm tìm kiếm đó; nếu không có thì dùng vị trí GPS hiện tại.
              userLocation: _searchLatLng ?? _lastLatLng,
              onExtentChanged: (extent) {
                final expanded = extent > 0.24;
                if (!mounted || expanded == _nearbySheetExpanded) return;
                setState(() => _nearbySheetExpanded = expanded);
              },
              onOpenDetail: (place) {
                _openPlaceDetail(place);
              },
              onDirections: (place) {
                _openDirectionsChooser(place);
              },
            ),
          Positioned(
            right: 16,
            bottom: 24,
            child: AnimatedOpacity(
              opacity: _nearbySheetExpanded ? 0.35 : 1,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: _nearbySheetExpanded,
                child: _MapControls(
                  nearbyLoading: _nearbyLoading,
                  onFindNearby: _findNearbyFood,
                  onRecenter: _recenterOnUser,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.nearbyLoading,
    required this.onFindNearby,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final bool nearbyLoading;
  final VoidCallback onFindNearby;
  final VoidCallback onRecenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ControlButton(
              icon: nearbyLoading ? null : Icons.restaurant_rounded,
              onTap: nearbyLoading ? null : onFindNearby,
              foreground: const Color(0xFFF97316),
              child:
                  nearbyLoading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : null,
            ),
            const SizedBox(height: 10),
            _ControlButton(icon: Icons.my_location_rounded, onTap: onRecenter),
            const SizedBox(height: 10),
            _ControlButton(icon: Icons.add_rounded, onTap: onZoomIn),
            const SizedBox(height: 10),
            _ControlButton(icon: Icons.remove_rounded, onTap: onZoomOut),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.foreground = const Color(0xFF111827),
    this.child,
  });

  final IconData? icon;
  final VoidCallback? onTap;
  final Color foreground;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: foreground.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: child ?? Icon(icon, color: foreground, size: 22),
          ),
        ),
      ),
    );
  }
}
