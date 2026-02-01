import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../config/goong_secrets.dart';

class PlaceMiniMapCard extends StatefulWidget {
  const PlaceMiniMapCard({
    super.key,
    required this.cardBg,
    required this.borderColor,
    required this.lat,
    required this.lng,
  });

  final Color cardBg;
  final Color borderColor;
  final double lat;
  final double lng;

  @override
  State<PlaceMiniMapCard> createState() => _PlaceMiniMapCardState();
}

class _PlaceMiniMapCardState extends State<PlaceMiniMapCard> {
  MapLibreMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    if (widget.lat == 0 || widget.lng == 0) return;
    controller.addCircle(
      CircleOptions(
        geometry: LatLng(widget.lat, widget.lng),
        circleColor: '#FF6A00',
        circleRadius: 6,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lat == 0 || widget.lng == 0) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.borderColor),
        ),
        child: const Center(
          child: Text('Khong co toa do'),
        ),
      );
    }

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            MapLibreMap(
              styleString:
                  'https://tiles.goong.io/assets/goong_map_web.json?api_key=$goongMapApiKey',
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.lat, widget.lng),
                zoom: 15.2,
              ),
              onMapCreated: _onMapCreated,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationEnabled: false,
              compassEnabled: false,
              attributionButtonMargins: const Point(0, -1000),
              logoViewMargins: const Point(0, -1000),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place, size: 16, color: Color(0xFFFF6A00)),
                    SizedBox(width: 6),
                    Text('Mo ban do', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
