import 'dart:math';
import 'package:maplibre_gl/maplibre_gl.dart';

// tính năng realtime navigation mà KHÔNG tốn Directions API.
class RouteUtils {
  // do khoang cach 2 diem
  static double distanceMeters(LatLng a, LatLng b) { // công thức chuẩn tính khoảng cách Haversine
      const r = 6371000.0; // r cua trai dat
      // chuyen do thanh radian
      final dLat = _degToRad(b.latitude - a.latitude);
      final dLng = _degToRad(b.longitude - a.longitude);
      final lat1 = _degToRad(a.latitude);
      final lat2 = _degToRad(b.latitude);
      // công thức tính khoáng cách haversine
      final h = sin(dLat / 2) * sin(dLat /2) +
          cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
      final c = 2 * atan2(sqrt(h), sqrt(1 - h));
      return r * c;
  }
  // Tinh bearing (huong di) tu a -> b
  static double bearing(LatLng a, LatLng b){
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    // cong thuc tinh
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final brng = atan2(y, x);
    return (brng * 180 / pi + 360 ) % 360;
  }
  // Khoang cach tu 1 diem den polyline
  static double distanceToRoute(LatLng p, List<LatLng> route) {
    if(route.length < 2) return 999999;

    double minDist = double.infinity;
    for(var i =0; i< route.length - 1;i++){
      final d = _distancePointToSegment(p, route[i], route[i + 1]);
      if(d < minDist) minDist = d;
    }
    return minDist;
  }
  // tinh khoang cach tu diem den doan 
  static double _distancePointToSegment(LatLng p, LatLng a, LatLng b){
    // chuyen doi qua he toa do tam thoi
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final dx = bx - ax;
    final dy = by - ay;
    if (dx == 0 && dy == 0){
      return distanceMeters(p, a);
    }
    // timf hinh chieu
    final t = (( px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    final clamped = t.clamp(0, 1);
    final proj = LatLng(ay + clamped * dy, ax + clamped * dx);

    return distanceMeters(p, proj);
  }

  // Doi do sang radian
  static double _degToRad(double d) => d * pi / 180.0;
  
}
