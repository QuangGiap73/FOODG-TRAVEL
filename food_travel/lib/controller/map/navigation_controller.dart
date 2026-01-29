// Directions 1 lần + stream GPS + chỉ reroute khi lệch tuyến
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/route_info.dart';
import '../../services/map/directions_service.dart';
import '../../services/map/route_utils.dart';

class NavigationController extends ChangeNotifier {
  NavigationController(): _directions = DirectionsService();

  final DirectionsService _directions;
  // router hien tai
  RouteInfo? _route;
  RouteInfo? get route => _route;
  // diem den
  LatLng? _destination;
  LatLng? get destination => _destination;
  // vi tri hien tai
  LatLng? _current;
  LatLng? get current => _current;
  // cooldown reroute Tránh gọi API liên tục khi GPS nhiễu
  DateTime? _lastRerouteAt;
  bool _navigating = false;

  // bo loc nhieu gps, dem so lan lech lien tiep
  int _offRouteHits = 0;
  // Stream postition 
  StreamSubscription<Position>? _posSub;
  String? _lastError;
  String? get lastError => _lastError;

  void clearError() {
    _lastError = null;
  }

  // bat dau dan duong
  Future<bool> startNavigation(LatLng dest) async {
    try {
      // kiem tra quyen vi tri
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _lastError = 'Chua co quyen vi tri.';
        notifyListeners();
        return false;
      }

      _destination = dest;
      _navigating = true;
      _offRouteHits = 0;
      notifyListeners();

      // lay vi tri hien tai
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _current = LatLng(pos.latitude, pos.longitude);

      // goi direction 1 lan
      _route = await _directions.fetchRoute(
        origin: _current!,
        destination: _destination!,
      );

      if (_route == null) {
        _lastError = 'Khong lay duoc chi duong.';
        notifyListeners();
        return false;
      }

      notifyListeners();
      // bat stream vi tri realtime
      _startPositionStream();
      return true;
    } catch (e) {
      _lastError = 'Loi chi duong: $e';
      notifyListeners();
      return false;
    }
  }
  Future<void> stopNavigation() async {
    _navigating = false;
    _route = null;
    _destination = null;
    _current = null;
    _offRouteHits = 0;
    await _posSub?.cancel();
    _posSub = null;
    notifyListeners();
  }
  void _startPositionStream() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((pos){
      _onPositionUpdate(LatLng(pos.latitude, pos.longitude));
    });
  }
  Future<void> _onPositionUpdate(LatLng pos) async {
    if(!_navigating || _destination == null) return;
    _current = pos;

    // kiem tra lech route
    if(_route != null){
      final dist = RouteUtils.distanceToRoute(pos, _route!.points);

      if(dist > 50){
        _offRouteHits++;
      }else {
        _offRouteHits = 0;
      }
      final now = DateTime.now();
      final inCooldown = _lastRerouteAt != null &&
        now.difference(_lastRerouteAt!).inSeconds < 20;
      // neu lech nhieu lan va khong trong cooldown -> reroute
      if(_offRouteHits >=3 && !inCooldown){
        _offRouteHits = 0;
        _lastRerouteAt = now;

        final newRoute = await _directions.fetchRoute(
          origin: pos,
          destination: _destination!,
        );
        if (newRoute != null) {
          _route = newRoute;
        }
      }
    }
    notifyListeners();
  }
}
