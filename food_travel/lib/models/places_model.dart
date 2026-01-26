import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:food_travel/config/goong_secrets.dart';
import 'package:food_travel/services/map/places_service.dart';

class GoongNearbyPlace {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String photoUrl;

  const GoongNearbyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl = '',
  });

  factory GoongNearbyPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? const {};
    final location = geometry['location'] as Map<String, dynamic>? ?? const {};
    final lat = _parseDouble(location['lat']);
    final lng = _parseDouble(location['lng']);

    return GoongNearbyPlace(
      id: (json['place_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['vicinity'] ?? json['formatted_address'] ?? '').toString(),
      lat: lat,
      lng: lng,
      photoUrl: _photoUrlFromJson(json),
    );
  }
// chuyển dữ liệu serpapi về cùng 1 form nearbyplace
  factory GoongNearbyPlace.fromSerpApi(Map<String, dynamic> json) {
    final coords = json['gps_coordinates'] as Map<String, dynamic>? ?? const {};
    // vì serpapi trả dữ liệu không ổn định , nên dưới đây là thứ tự ưu tiên.
    final lat = _parseDouble(
      coords['latitude'] ??
          coords['lat'] ??
          json['latitude'] ??
          json['lat'],
    );
    final lng = _parseDouble(
      coords['longitude'] ??
          coords['lng'] ??
          json['longitude'] ??
          json['lng'],
    );
  // ép kiểu, do dùng 2 API nên ưu tiên title trước name.
    return GoongNearbyPlace(
      id: _serpIdFromJson(json),
      name: _stringValue(json['title'] ?? json['name']),
      address: _stringValue(
        json['address'] ?? json['formatted_address'] ?? json['vicinity'],
      ),
      lat: lat,
      lng: lng,
      photoUrl: _serpPhotoUrlFromJson(json),
    );
  }
}
// lấy ảnh từ goong
String _photoUrlFromJson(Map<String, dynamic> json) {
  final photos = json['photos'] as List?;
  if (photos == null || photos.isEmpty) return '';
  final first = photos.first;
  if (first is Map) {
    final ref = first['photo_reference']?.toString();
    if (ref != null && ref.isNotEmpty) {
      return buildGoongPhotoUrl(ref);
    }
  }
  return '';
}

String _serpIdFromJson(Map<String, dynamic> json) {
  final raw =
      json['place_id'] ?? json['data_id'] ?? json['cid'] ?? json['id'];
  return raw == null ? '' : raw.toString();
}

String _serpPhotoUrlFromJson(Map<String, dynamic> json) {
  final direct =
      json['thumbnail'] ?? json['thumbnail_url'] ?? json['image'] ?? json['photo'];
  if (direct is String) return direct;

  final photos = json['photos'];
  if (photos is List && photos.isNotEmpty) {
    final first = photos.first;
    if (first is String) return first;
    if (first is Map) {
      final url =
          first['thumbnail'] ?? first['thumbnail_url'] ?? first['image'];
      if (url is String) return url;
    }
  }

  final images = json['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first is String) return first;
    if (first is Map) {
      final url =
          first['thumbnail'] ?? first['thumbnail_url'] ?? first['image'];
      if (url is String) return url;
    }
  }

  return '';
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
// tìm quán ăn gần vị trí người dùng 
extension GoongNearbyApi on GoongPlacesService {
  Future<List<GoongNearbyPlace>> nearbySearch({
    required double lat,
    required double lng,
    String? keyword,
    String? type,
    int radius = 3000,
  }) async {
    final params = <String, String>{
      'location': '$lat,$lng',
      'radius': radius.toString(),
      'language': 'vi',
      'api_key': goongPlacesApiKey,
    };
    final cleanKeyword = keyword?.trim();
    if (cleanKeyword != null && cleanKeyword.isNotEmpty) {
      params['keyword'] = cleanKeyword;
    }
    final cleanType = type?.trim();
    if (cleanType != null && cleanType.isNotEmpty) {
      params['type'] = cleanType;
    }
    if (!params.containsKey('keyword') && !params.containsKey('type')) {
      debugPrint('Goong NearbySearch skipped (no keyword/type).');
      return [];
    }

    final uri = Uri.https('rsapi.goong.io', '/Place/NearbySearch', params);

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        debugPrint(
          'Goong NearbySearch http=${res.statusCode} body=${res.body}',
        );
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      final items = (data['results'] as List?) ?? const [];
      debugPrint(
        'Goong NearbySearch status=$status results=${items.length}',
      );
      if (status == 'ZERO_RESULTS') {
        debugPrint('Goong NearbySearch ZERO_RESULTS');
        return [];
      }
      if (status != 'OK') {
        final message = (data['error_message'] ?? '').toString();
        debugPrint('Goong NearbySearch status=$status $message');
        return [];
      }

      final list = items
          .map((e) => GoongNearbyPlace.fromJson(e as Map<String, dynamic>))
          .where((e) => e.name.isNotEmpty && e.lat != 0 && e.lng != 0)
          .toList();

      // Giu duy nhat theo place_id.
      final dedup = <String, GoongNearbyPlace>{};
      for (final p in list) {
        final key =
            p.id.isNotEmpty ? p.id : '${p.name}-${p.lat}-${p.lng}';
        dedup[key] = p;
      }
      return dedup.values.toList();
    } catch (e) {
      debugPrint('Goong NearbySearch error: $e');
      return [];
    }
  }

  Future<List<GoongNearbyPlace>> textSearch({
    required String query,
    double? lat,
    double? lng,
    int radius = 5000,
  }) async {
    final params = <String, String>{
      'query': query,
      'language': 'vi',
      'api_key': goongPlacesApiKey,
    };
    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      params['radius'] = radius.toString();
    }

    final uri = Uri.https('rsapi.goong.io', '/Place/TextSearch', params);
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        debugPrint(
          'Goong TextSearch http=${res.statusCode} body=${res.body}',
        );
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();
      final items = (data['results'] as List?) ?? const [];
      debugPrint(
        'Goong TextSearch status=$status results=${items.length}',
      );
      if (status == 'ZERO_RESULTS') {
        debugPrint('Goong TextSearch ZERO_RESULTS');
        return [];
      }
      if (status != 'OK') {
        final message = (data['error_message'] ?? '').toString();
        debugPrint('Goong TextSearch status=$status $message');
        return [];
      }

      final list = items
          .map((e) => GoongNearbyPlace.fromJson(e as Map<String, dynamic>))
          .where((e) => e.name.isNotEmpty && e.lat != 0 && e.lng != 0)
          .toList();

      // Giu duy nhat theo place_id.
      final dedup = <String, GoongNearbyPlace>{};
      for (final p in list) {
        final key =
            p.id.isNotEmpty ? p.id : '${p.name}-${p.lat}-${p.lng}';
        dedup[key] = p;
      }
      return dedup.values.toList();
    } catch (e) {
      debugPrint('Goong TextSearch error: $e');
      return [];
    }
  }
}
