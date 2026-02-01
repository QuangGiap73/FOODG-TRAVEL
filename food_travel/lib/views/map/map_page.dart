import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../controller/map/map_search_controller.dart';
import '../../controller/map/navigation_controller.dart';
import '../../config/goong_secrets.dart';
import '../../models/places_model.dart';
import '../../services/map/places_service.dart';
import '../../services/map/serpapi_places_service.dart';
import '../../services/location_preference_service.dart';
import '../../widgets/user_location_puck.dart';
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

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.initialNearbyPlaces = const [],
    this.initialNearbyQuery,
    this.initialPlace,
  });

  final List<GoongNearbyPlace> initialNearbyPlaces;
  final String? initialNearbyQuery;
  final GoongNearbyPlace? initialPlace;

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
  late final MapSearchController _searchController;
  final _searchTextController = TextEditingController();
  final _serpService = SerpApiPlacesService();
  late final NavigationController _navController;
  RouteLayer? _routeLayer;
  UserLocationPuck? _puck;
  StreamSubscription<Position>? _positionSub;
  bool _styleReady = false;
  bool _centeredOnUser = false;
  bool _pulseStarted = false;
  LatLng? _lastLatLng;
  Circle? _searchCircle;
  LatLng? _searchLatLng;
  // Danh sach quan gan day + layer ve marker
  final List<GoongNearbyPlace> _nearbyPlaces = [];
  NearbyPlacesLayer? _nearbyLayer;
  bool _nearbyLoading = false;
  int _selectedCategory = 0;
  final Map<String, _NearbyCacheEntry> _nearbyCache = {};
  String? _toastMessage;
  Timer? _toastTimer;

  static const int _nearbyRadius = 8000;
  static const Duration _nearbyCacheTtl = Duration(seconds: 60);
  static const _categories = <_NearbyCategory>[
    _NearbyCategory(
      'quan_an',
      'Quan an',
      [
        'nha hang',
        'quan an',
        'an uong',
        'com',
        'bun',
        'pho',
        'mi',
        'lau',
        'nuong',
      ],
    ),
    _NearbyCategory(
      'cafe',
      'Cafe',
      [
        'cafe',
        'coffee',
        'ca phe',
        'tra',
        'tra sua',
      ],
    ),
    _NearbyCategory(
      'an_vat',
      'An vat',
      [
        'an vat',
        'snack',
        'do an vat',
        'banh',
      ],
    ),
    _NearbyCategory(
      'fast_food',
      'Do an nhanh',
      [
        'fast food',
        'burger',
        'pizza',
        'ga ran',
        'banh mi',
      ],
    ),
    _NearbyCategory(
      'hai_san',
      'Hai san',
      [
        'hai san',
        'seafood',
      ],
    ),
  ];

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    // Tao layer ve route khi map duoc tao
    _routeLayer = RouteLayer(controller);
  }

  Future<void> _ensurePuckReady() async {
    if (!_styleReady || _controller == null) return;
    if (_puck != null) return;

    _puck = UserLocationPuck(_controller!);
    await _puck!.init();
  }

  void _ensureNearbyLayer() {
    if (_controller == null) return;
    _nearbyLayer ??= NearbyPlacesLayer(_controller!);
  }

  void _onNavChanged() {
    if (!mounted) return;
    setState(() {});

    // Neu co route thi ve polyline, neu khong thi xoa
    if (_routeLayer == null) return;
    final route = _navController.route;
    if (route == null) {
      _routeLayer!.clear();
    } else {
      _routeLayer!.showRoute(route.points);
    }
  }

  void _startDirections(GoongNearbyPlace place) {
    // Bat dau dan duong den quan
    _startDirectionsInternal(place);
  }

  Future<void> _startDirectionsInternal(GoongNearbyPlace place) async {
    final ok = await _navController.startNavigation(
      LatLng(place.lat, place.lng),
    );
    if (!ok) {
      final msg = _navController.lastError ?? 'Khong lay duoc chi duong.';
      _showSnack(msg);
      _navController.clearError();
    }
  }


  Future<void> _onStyleLoaded() async {
    _styleReady = true;

    // Style reload clears images/symbols, so we need to re-init the puck.
    await _ensurePuckReady();
    _ensureNearbyLayer();

    if (_lastLatLng != null) {
      await _updateUserMarker(_lastLatLng!);
    }

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
    await _ensurePuckReady();
    await _updateUserMarker(location.position);
  }

  Future<void> _updateUserMarker(LatLng position) async {
    if (!_styleReady || _controller == null || _puck == null) return;

    if (!_centeredOnUser) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
      _centeredOnUser = true;
    }

    await _puck!.setPosition(position);

    if (!_pulseStarted) {
      _puck!.startPulse();
      _pulseStarted = true;
    }
  }

  Future<void> _clearUserMarker({bool keepLastLocation = false}) async {
    if (_puck != null) {
      await _puck!.dispose();
      _puck = null;
    }
    _pulseStarted = false;
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
      final latLng = LatLng(pos.latitude, pos.longitude);
      _lastLatLng = latLng;
      await _ensurePuckReady();
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
    return '${scope}_${lat}_${lng}$suffix';
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

    if (!LocationPreferenceService.enabled.value) {
      _showSnack('Please enable location.');
      return;
    }

    var target = _lastLatLng;
    target ??= await _controller!.requestMyLocationLatLng();

    if (target == null) {
      _showSnack('Location not available yet.');
      return;
    }

    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(target, 16),
    );
  }

  void _onSearchStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearSearch() {
    _searchTextController.clear();
    _searchController.clear();
    _clearSearchMarker();
  }

  Future<void> _onSelectPrediction(GoongPrediction prediction) async {
    FocusScope.of(context).unfocus();
    final detail = await _searchController.fetchDetail(prediction);
    if (!mounted) return;

    if (detail == null) {
      _showSnack('Place not found.');
      return;
    }

    _searchTextController.text = prediction.description;
    _searchController.clear();
    await _showSearchMarker(LatLng(detail.lat, detail.lng));
  }

  Future<void> _showSearchMarker(LatLng position,
      {bool animate = true}) async {
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
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return ChoiceChip(
            label: Text(cat.label),
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
      CameraUpdate.newLatLngZoom(
        LatLng(place.lat, place.lng),
        16,
      ),
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
        _startDirections(place);
      },
    );
  }

  Future<void> _findNearbyFood({String? queryOverride}) async {
    if (_nearbyLoading) return;
    setState(() => _nearbyLoading = true);

    try {
      // Yeu cau bat GPS truoc khi tim.
      if (!LocationPreferenceService.enabled.value) {
        _showSnack('Hay bat GPS de tim quan.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Chua co quyen vi tri.');
        return;
      }

      LatLng? target = _lastLatLng;
      target ??= await _controller?.requestMyLocationLatLng();
      if (target == null) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
        target = LatLng(pos.latitude, pos.longitude);
      }
      debugPrint('SerpAPI search at ${target.latitude},${target.longitude}');
      if (target.latitude.abs() < 0.0001 &&
          target.longitude.abs() < 0.0001) {
        _showSnack('Vi tri GPS khong hop le.');
        return;
      }

      final rawQuery = queryOverride?.trim();
      final searchQuery = (rawQuery != null && rawQuery.isNotEmpty)
          ? rawQuery
          : _buildSerpQuery(_categories[_selectedCategory]);

      final cacheKey = _cacheKey(
        _selectedCategory,
        target,
        query: searchQuery,
      );
      final cached = _nearbyCache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.at) < _nearbyCacheTtl) {
        _nearbyPlaces
          ..clear()
          ..addAll(cached.places);
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
        _showSnack('Khong tim thay quan gan day.');
        return;
      }

      _nearbyPlaces
        ..clear()
        ..addAll(places);
      _nearbyCache[cacheKey] = _NearbyCacheEntry(DateTime.now(), places);
      setState(() {}); // Hien danh sach ngay ca khi marker chua ve.

      if (_styleReady) {
        _ensureNearbyLayer();
        await _nearbyLayer?.showPlaces(_nearbyPlaces, animate: true);
      }
    } on TimeoutException {
      _showSnack('Qua thoi gian lay vi tri.');
    } catch (e, st) {
      debugPrint('Loi tim quan: $e');
      debugPrint('$st');
      _showSnack('Loi tim quan: $e');
    } finally {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final loadFuture = _locationPrefs.load();
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
  }

  @override
  void dispose() {
    _stopLocationStream();
    _nearbyLayer?.clear();
    _puck?.dispose();
    _controller?.dispose();
    _toastTimer?.cancel();
    _navController.removeListener(_onNavChanged);
    _navController.dispose();
    _searchController.removeListener(_onSearchStateChanged);
    _searchController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers_outlined),
            onSelected: _selectStyle,
            itemBuilder: (context) {
              return List.generate(
                _styles.length,
                (index) => PopupMenuItem(
                  value: index,
                  child: Text(_styles[index].label),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: LocationPreferenceService.enabled,
            builder: (context, enabled, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (enabled) {
                  _startLocationStream();
                } else {
                  _stopLocationStream();
                  _clearUserMarker();
                }
              });

              return MapLibreMap(
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
                myLocationEnabled: enabled,
                myLocationTrackingMode: enabled
                    ? MyLocationTrackingMode.tracking
                    : MyLocationTrackingMode.none,
                // Keep the native blue dot; the custom puck is the pulsing image.
                myLocationRenderMode: MyLocationRenderMode.normal,
              );
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: SafeArea(
              child: Column(
                children: [
                  MapSearchBar(
                    controller: _searchTextController,
                    loading: _searchController.loading,
                    suggestions: _searchController.suggestions,
                    onQueryChanged: _searchController.onQueryChanged,
                    onClear: _clearSearch,
                    onSelect: _onSelectPrediction,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
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
              userLocation: _lastLatLng,
              onOpenDetail: (place) {
                _openPlaceDetail(place);
              },
              onDirections: (place) {
                _startDirections(place);
              },
            ),
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'nearby_food',
                  mini: true,
                  onPressed: _nearbyLoading ? null : _findNearbyFood,
                  child: _nearbyLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restaurant),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter',
                  mini: true,
                  onPressed: _recenterOnUser,
                  child: const Icon(Icons.navigation),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
