import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../config/goong_secrets.dart';
import '../../services/location_preference_service.dart';

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
  // Keep a style list to switch between normal/highlight/satellite.
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

  int _styleIndex = 1; // Default to Highlight (known to work).
  String get _styleUrl => _styles[_styleIndex].url;

  MapLibreMapController? _controller;
  final _locationPrefs = LocationPreferenceService();
  Circle? _userCircle;
  bool _styleReady = false;
  bool _centeredOnUser = false;
  UserLocation? _lastLocation;

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  void _onStyleLoaded() {
    _styleReady = true;

    // Re-draw the marker after style changes.
    if (_lastLocation != null) {
      _updateUserMarker(_lastLocation!);
    }
  }

  void _onUserLocationUpdated(UserLocation location) {
    _lastLocation = location;
    _updateUserMarker(location);
  }

  Future<void> _updateUserMarker(UserLocation location) async {
    if (!_styleReady || _controller == null) return;

    final pos = location.position;

    // Center once when we get the first valid location.
    if (!_centeredOnUser) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(pos, 15),
      );
      _centeredOnUser = true;
    }

    // Draw a clear blue circle so the location is easy to see.
    if (_userCircle == null) {
      _userCircle = await _controller!.addCircle(
        CircleOptions(
          geometry: pos,
          circleRadius: 10,
          circleColor: '#2F80ED',
          circleOpacity: 0.9,
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ),
      );
    } else {
      await _controller!.updateCircle(
        _userCircle!,
        CircleOptions(geometry: pos),
      );
    }
  }

  Future<void> _clearUserMarker() async {
    if (_controller == null || _userCircle == null) return;
    await _controller!.removeCircle(_userCircle!);
    _userCircle = null;
    _lastLocation = null;
    _centeredOnUser = false;
  }

  void _selectStyle(int index) {
    if (index == _styleIndex) return;
    setState(() {
      _styleIndex = index;
      _styleReady = false;
      _userCircle = null;
      _centeredOnUser = false;
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

    var target = _lastLocation?.position;
    target ??= await _controller!.requestMyLocationLatLng();

    if (target == null) {
      _showSnack('Location not available yet.');
      return;
    }

    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(target, 16),
    );
  }

  @override
  void initState() {
    super.initState();
    _locationPrefs.load();
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
              if (!enabled && _userCircle != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _clearUserMarker();
                });
              }

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
                // Keep the default blue dot; we also draw a clearer circle.
                myLocationRenderMode: MyLocationRenderMode.normal,
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter button (triangle arrow).
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
