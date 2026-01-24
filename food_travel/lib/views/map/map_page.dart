import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../controller/map/map_search_controller.dart';
import '../../config/goong_secrets.dart';
import '../../services/map/places_service.dart';
import '../../services/location_preference_service.dart';
import '../../widgets/user_location_puck.dart';
import 'widgets/map_search_bar.dart';

class _MapStyle {
  const _MapStyle(this.label, this.url);

  final String label;
  final String url;
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

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
  UserLocationPuck? _puck;
  StreamSubscription<Position>? _positionSub;
  bool _styleReady = false;
  bool _centeredOnUser = false;
  bool _pulseStarted = false;
  LatLng? _lastLatLng;
  Circle? _searchCircle;
  LatLng? _searchLatLng;

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  Future<void> _ensurePuckReady() async {
    if (!_styleReady || _controller == null) return;
    if (_puck != null) return;

    _puck = UserLocationPuck(_controller!);
    await _puck!.init();
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;

    // Style reload clears images/symbols, so we need to re-init the puck.
    await _ensurePuckReady();

    if (_lastLatLng != null) {
      await _updateUserMarker(_lastLatLng!);
    }

    if (_searchLatLng != null) {
      await _showSearchMarker(_searchLatLng!, animate: false);
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  @override
  void initState() {
    super.initState();
    _locationPrefs.load();
    _searchController = MapSearchController();
    _searchController.addListener(_onSearchStateChanged);
  }

  @override
  void dispose() {
    _stopLocationStream();
    _puck?.dispose();
    _controller?.dispose();
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
              child: MapSearchBar(
                controller: _searchTextController,
                loading: _searchController.loading,
                suggestions: _searchController.suggestions,
                onQueryChanged: _searchController.onQueryChanged,
                onClear: _clearSearch,
                onSelect: _onSelectPrediction,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
