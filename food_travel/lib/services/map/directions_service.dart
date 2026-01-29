import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../config/goong_secrets.dart';
import '../../models/route_info.dart';
class DirectionsService {
  // lay chi duong
  Future<RouteInfo?> fetchRoute({
    required LatLng origin, // diem bat dau
    required LatLng destination, // diem ket thuc
    String mode = 'bike',
  }) async {
    // Goong directions api
    final url =
        'https://rsapi.goong.io/Direction?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&vehicle=$mode&api_key=$goongPlacesApiKey';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      // Log loi de de debug khi directions fail
      // ignore: avoid_print
      print('Directions error ${res.statusCode}: ${res.body}');
      return null;
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Log nhanh neu can kiem tra format response
    // ignore: avoid_print
    // print('Directions raw: $data');
    final routes = (data['routes'] as List?) ?? []; // lay roter dau tien
    if (routes.isEmpty) {
      // ignore: avoid_print
      print('Directions: routes empty');
      return null;
    }

    final first = routes.first as Map<String, dynamic>;
    final legs = (first['legs'] as List?) ?? [];
    if( legs.isEmpty) return null;

    final leg0 = legs.first as Map<String, dynamic>;
    final distance = (leg0['distance']?['value'] as num?)?.toDouble() ?? 0;
    final duration = (leg0['duration']?['value'] as num?)?.toDouble() ?? 0;

    // lay polyline tu overview duong di
    final overview = first['overview_polyline'] as Map<String, dynamic>? ?? {};
    final polyStr = (overview['points'] ?? '').toString();
    final points = _decodePolyline(polyStr);
     return RouteInfo(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
    );
    
  }
  // giai ma polyline Google/goong
  // API Directions không trả về danh sách tọa độ trực tiếp vì quá nặng.
// Thay //vao do, no trả ve 1 chuỗi  (polyline) đã được nén.
  List<LatLng> _decodePolyline(String poly) {
    final list = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;
// doc tung diem
    while (index < poly.length) {
      // giai ma vi do
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      // giai ma kinh do
      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      list.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return list;
  }
}
