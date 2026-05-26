import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../models/places_model.dart';

class NearbyPlacesLayer {
  NearbyPlacesLayer(this._controller);

  final MapLibreMapController _controller;
  final List<Symbol> _symbols = [];
  final Set<String> _imageNames = {};
  final Map<String, GoongNearbyPlace> _placeBySymbolId = {};

  Future<void> showPlaces(
    List<GoongNearbyPlace> places, {
    bool animate = true,
    double zoom = 14,
  }) async {
    await clear();
    if (places.isEmpty) return;

    for (var i = 0; i < places.length; i++) {
      final place = places[i];
      final latLng = LatLng(place.lat, place.lng);

      final imageName = 'nearby_photo_${place.id}_$i';
      final markerBytes = await _buildMarkerImage(place.photoUrl);
      await _controller.addImage(imageName, markerBytes);
      _imageNames.add(imageName);

      final symbol = await _controller.addSymbol(
        SymbolOptions(
          geometry: latLng,
          iconImage: imageName,
          iconSize: 1.8,
          iconAnchor: 'bottom',
          zIndex: 10,
        ),
      );
      _symbols.add(symbol);
      _placeBySymbolId[symbol.id] = place;
    }

    if (animate) {
      final first = places.first;
      await _controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(first.lat, first.lng),
          zoom,
        ),
      );
    }
  }

  Future<void> clear() async {
    for (final symbol in _symbols) {
      await _controller.removeSymbol(symbol);
    }
    _symbols.clear();

    // maplibre_gl 0.25.0 khong ho tro removeImage().
    // Anh style se duoc clear khi style reload; tai day chi clear danh sach local.
    _imageNames.clear();
    _placeBySymbolId.clear();
  }

  GoongNearbyPlace? placeForSymbol(Symbol symbol) {
    return _placeBySymbolId[symbol.id];
  }

  Future<Uint8List> _buildMarkerImage(String photoUrl) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const width = 84.0;
    const height = 108.0;
    const headCenter = ui.Offset(width / 2, 38);
    const headRadius = 28.0;
    const photoRadius = 19.0;

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x66000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    final redPaint = ui.Paint()..color = const ui.Color(0xFFE53935);
    final whiteStroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const ui.Color(0xFFFFFFFF);
    final pinTip = ui.Path()
      ..moveTo(headCenter.dx - 14, 58)
      ..quadraticBezierTo(headCenter.dx - 8, 78, headCenter.dx, 94)
      ..quadraticBezierTo(headCenter.dx + 8, 78, headCenter.dx + 14, 58)
      ..close();

    // Shadow cho cam giac "noi len".
    canvas.drawCircle(const ui.Offset(width / 2, 98), 10, shadowPaint);

    // Than pin (duoi nhon) + dau tron.
    canvas.drawPath(pinTip, redPaint);
    canvas.drawCircle(headCenter, headRadius, redPaint);
    canvas.drawCircle(headCenter, headRadius, whiteStroke);

    final image = await _loadNetworkImage(photoUrl);
    if (image != null) {
      final clip = ui.Path()
        ..addOval(
          ui.Rect.fromCircle(center: headCenter, radius: photoRadius),
        );
      canvas.save();
      canvas.clipPath(clip);
      final src = ui.Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final dst = ui.Rect.fromCircle(center: headCenter, radius: photoRadius);
      canvas.drawImageRect(image, src, dst, ui.Paint());
      canvas.restore();
      canvas.drawCircle(headCenter, photoRadius, whiteStroke);
    } else {
      final fallbackPaint = ui.Paint()..color = const ui.Color(0xFFFFCDD2);
      canvas.drawCircle(headCenter, photoRadius, fallbackPaint);
    }

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(width.toInt(), height.toInt());
    final png = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  }

  Future<ui.Image?> _loadNetworkImage(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;
    try {
      final data = await NetworkAssetBundle(Uri.parse(cleanUrl)).load('');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 48,
        targetHeight: 48,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
