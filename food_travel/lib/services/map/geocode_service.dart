import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/goong_secrets.dart';

// Goi Goong Geocode de lay ten tinh tu lat/lng.
class GeocodeService {
  Future<String?> reverseProvinceName(double lat, double lng) async {
    final uri = Uri.https('rsapi.goong.io', '/Geocode', {
      'latlng': '$lat,$lng',
      'api_key': goongPlacesApiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;

    // Duyet results -> address_components -> tim type cap tinh.
    final results = data['results'] as List? ?? [];
    for (final item in results) {
      final comps = item['address_components'] as List? ?? [];
      for (final comp in comps) {
        final types =
            (comp['types'] as List?)?.cast<String>() ?? const <String>[];
        if (types.contains('administrative_area_level_1')) {
          return comp['long_name'] as String?;
        }
      }
    }
    return null;
  }
}
