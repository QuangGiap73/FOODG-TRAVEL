import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../config/goong_secrets.dart';
import '../../services/location_preference_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapLibreMapController? _controller;
  final _locationPrefs = LocationPreferenceService();

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  void _zoomIn() {
    _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _controller?.animateCamera(CameraUpdate.zoomOut());
  }
  @override
  void initState() {
    super.initState();
    _locationPrefs.load();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Dùng style tồn tại (highlight / satellite)
    final styleUrl =
        'https://tiles.goong.io/assets/goong_map_highlight.json?api_key=$goongMapApiKey';
    // Nếu muốn vệ tinh:
    // final styleUrl =
    //     'https://tiles.goong.io/assets/goong_satellite.json?api_key=$goongMapApiKey';

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: LocationPreferenceService.enabled,
            builder: (context, enabled, _) {
              return MapLibreMap(
                styleString: styleUrl,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(21.0278, 105.8342),
                  zoom: 12,
                ),
                onMapCreated: _onMapCreated,
                zoomGesturesEnabled: true,
                myLocationEnabled: enabled,
                myLocationTrackingMode: enabled
                    ? MyLocationTrackingMode.tracking
                    : MyLocationTrackingMode.none,
              );
            },
          ),

          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
