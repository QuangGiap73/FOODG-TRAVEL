import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/goong_secrets.dart';
import '../../models/places_model.dart';

class SerpApiPlacesService {
  Future<List<GoongNearbyPlace>> searchNearby({
    required double lat,
    required double lng,
    required String query,
    int radius = 3000,
    int limit = 12,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final params = <String, String>{
      'engine': 'google_maps',
      'api_key': serpapiKey,
      'q': trimmedQuery,
      'll': '@$lat,$lng,15z',
      'radius': radius.toString(),
      'hl': 'vi',
      'gl': 'vn',
    };

    final uri = Uri.https('serpapi.com', '/search.json', params);

    try {
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('SerpAPI http=${res.statusCode} body=${res.body}');
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = _extractResults(data);
      if (items.isEmpty) return [];

      final dedup = <String, GoongNearbyPlace>{};
      for (final item in items) {
        if (item is! Map) continue;
        final place =
            GoongNearbyPlace.fromSerpApi(Map<String, dynamic>.from(item));
        if (place.name.isEmpty || place.lat == 0 || place.lng == 0) {
          continue;
        }
        final key = place.id.isNotEmpty
            ? place.id
            : '${place.name}-${place.lat}-${place.lng}';
        if (dedup.containsKey(key)) continue;
        dedup[key] = place;
        if (dedup.length >= limit) break;
      }
      return dedup.values.toList();
    } catch (e) {
      debugPrint('SerpAPI error: $e');
      return [];
    }
  }

  List<dynamic> _extractResults(Map<String, dynamic> data) {
    final candidates = [
      data['local_results'],
      data['place_results'],
      data['places'],
      data['organic_results'],
    ];
    for (final candidate in candidates) {
      if (candidate is List) return candidate;
      if (candidate is Map) return [candidate];
    }
    return const [];
  }
}
