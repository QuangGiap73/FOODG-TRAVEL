import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';

class UserLocationPuck {
  UserLocationPuck(this.controller);

  final MapLibreMapController controller;

  Symbol? _dot;
  Symbol? _pulse;
  Timer? _timer;
  bool _grow = false;

  // Call once after the map style is loaded.
  Future<void> init() async {
    final dotBytes = await rootBundle.load('assets/map/anh1_vitri1.png');
    final pulseBytes = await rootBundle.load('assets/map/anh1_vitri2.png');

    await controller.addImage('user_dot', dotBytes.buffer.asUint8List());
    await controller.addImage('user_pulse', pulseBytes.buffer.asUint8List());
  }

  // Update the user location marker position.
  Future<void> setPosition(LatLng position) async {
    _dot ??= await controller.addSymbol(SymbolOptions(
      geometry: position,
      iconImage: 'user_dot',
      iconSize: 0.7,
      iconAnchor: 'center',
    ));

    _pulse ??= await controller.addSymbol(SymbolOptions(
      geometry: position,
      iconImage: 'user_pulse',
      iconSize: 1.2,
      iconAnchor: 'center',
    ));

    await controller.updateSymbol(_dot!, SymbolOptions(geometry: position));
    await controller.updateSymbol(_pulse!, SymbolOptions(geometry: position));
  }

  // Start a simple pulse animation by resizing the outer image.
  void startPulse() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 650), (_) async {
      if (_pulse == null) return;

      _grow = !_grow;
      final size = _grow ? 1.6 : 1.2;
      await controller.updateSymbol(_pulse!, SymbolOptions(iconSize: size));
    });
  }

  void stopPulse() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stopPulse();
    if (_dot != null) await controller.removeSymbol(_dot!);
    if (_pulse != null) await controller.removeSymbol(_pulse!);
    _dot = null;
    _pulse = null;
  }
}
