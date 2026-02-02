import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:food_travel/config/goong_secrets.dart';
import 'package:food_travel/services/map/places_service.dart';

class PlaceMenuItem {
  const PlaceMenuItem({
    required this.name,
    this.price = '',
    this.photoUrl = '',
    this.badge = '',
  });

  final String name;
  final String price;
  final String photoUrl;
  final String badge;
}

class GoongNearbyPlace {
  final String id;
  final String serpDataId;
  final String name;
  final String address;
  final String district;
  final double lat;
  final double lng;
  final String photoUrl;
  final List<String> photoUrls;
  final double? rating;
  final int? reviewCount;
  final String? price;
  final String? phone;
  final String? category;
  final bool? isOpen;
  final String? closingTime;
  final List<String> openingHours;
  final List<String> amenities;
  final List<PlaceMenuItem> mustTryItems;

  const GoongNearbyPlace({
    required this.id,
    this.serpDataId = '',
    required this.name,
    required this.address,
    this.district = '',
    required this.lat,
    required this.lng,
    this.photoUrl = '',
    this.photoUrls = const [],
    this.rating,
    this.reviewCount,
    this.price,
    this.phone,
    this.category,
    this.isOpen,
    this.closingTime,
    this.openingHours = const [],
    this.amenities = const [],
    this.mustTryItems = const [],
  });

  factory GoongNearbyPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? const {};
    final location = geometry['location'] as Map<String, dynamic>? ?? const {};
    final lat = _parseDouble(location['lat']);
    final lng = _parseDouble(location['lng']);

    return GoongNearbyPlace(
      id: (json['place_id'] ?? '').toString(),
      serpDataId: (json['place_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['vicinity'] ?? json['formatted_address'] ?? '').toString(),
      lat: lat,
      lng: lng,
      photoUrl: _photoUrlFromJson(json),
      photoUrls: _photoUrlsFromJson(json),
      category: _categoryFromJson(json),
    );
  }

  // Chuyen du lieu serpapi ve cung 1 form nearbyplace
  factory GoongNearbyPlace.fromSerpApi(Map<String, dynamic> json) {
    final coords = json['gps_coordinates'] as Map<String, dynamic>? ?? const {};
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

    final photos = _serpPhotoUrlsFromJson(json);
    return GoongNearbyPlace(
      id: _serpIdFromJson(json),
      serpDataId: _serpDataIdFromJson(json),
      name: _stringValue(json['title'] ?? json['name']),
      address: _stringValue(
        json['address'] ?? json['formatted_address'] ?? json['vicinity'],
      ),
      district: _stringValue(json['district'] ?? json['neighborhood']),
      lat: lat,
      lng: lng,
      photoUrl: photos.isNotEmpty ? photos.first : _serpPhotoUrlFromJson(json),
      photoUrls: photos,
      rating: _toDoubleOrNull(json['rating']),
      reviewCount: _toIntOrNull(
        json['reviews'] ?? json['review_count'] ?? json['reviews_count'],
      ),
      price: _stringOrNull(
        json['price'] ??
            json['price_level'] ??
            json['price_range'] ??
            json['per_person'],
      ),
      phone: _stringOrNull(
        json['phone'] ?? json['phone_number'] ?? json['formatted_phone_number'],
      ),
      category: _categoryFromJson(json),
      isOpen: _openFromJson(json),
      closingTime: _closingTimeFromJson(json),
      openingHours: _openingHoursFromJson(json),
      amenities: _amenitiesFromJson(json),
      mustTryItems: const [],
    );
  }
}

// Lay anh tu Goong
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

List<String> _photoUrlsFromJson(Map<String, dynamic> json) {
  final photos = json['photos'] as List?;
  if (photos == null || photos.isEmpty) return const [];
  final urls = <String>[];
  for (final item in photos) {
    if (item is Map) {
      final ref = item['photo_reference']?.toString();
      if (ref != null && ref.isNotEmpty) {
        urls.add(buildGoongPhotoUrl(ref));
      }
    }
  }
  return urls;
}

String _serpIdFromJson(Map<String, dynamic> json) {
  final raw =
      json['place_id'] ?? json['data_id'] ?? json['cid'] ?? json['id'];
  return raw == null ? '' : raw.toString();
}

String _serpDataIdFromJson(Map<String, dynamic> json) {
  final raw = json['data_id'] ?? json['place_id'] ?? json['cid'];
  return raw == null ? '' : raw.toString();
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
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

List<String> _serpPhotoUrlsFromJson(Map<String, dynamic> json) {
  final urls = <String>[];

  void addIfString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      urls.add(value.trim());
    }
  }

  try {
    addIfString(
      json['thumbnail'] ??
          json['thumbnail_url'] ??
          json['image'] ??
          json['photo'],
    );

    final photos = json['photos'];
    if (photos is List) {
      for (final item in photos) {
        if (item is String) {
          addIfString(item);
        } else if (item is Map) {
          addIfString(
            item['thumbnail'] ?? item['thumbnail_url'] ?? item['image'],
          );
        }
      }
    }

    final images = json['images'];
    if (images is List) {
      for (final item in images) {
        if (item is String) {
          addIfString(item);
        } else if (item is Map) {
          addIfString(
            item['thumbnail'] ?? item['thumbnail_url'] ?? item['image'],
          );
        }
      }
    }
  } catch (_) {
    // Neu du lieu loi thi bo qua, tra ve danh sach hien co
  }

  final seen = <String>{};
  return urls.where((e) => seen.add(e)).toList();
}

List<String> _openingHoursFromJson(Map<String, dynamic> json) {
  try {
    final hours = json['hours'];
    if (hours is Map) {
      final weekdays = hours['weekdays'];
      if (weekdays is List) {
        final lines = weekdays
            .map((e) => _cleanOpenHourText(e.toString()))
            .where((e) => e.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) return lines;
      }
      final text = hours['opening_hours'] ?? hours['open_hours'];
      if (text is List) {
        final lines = text
            .map((e) => _cleanOpenHourText(e.toString()))
            .where((e) => e.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) return lines;
      }
      if (text is String && text.trim().isNotEmpty) {
        final clean = _cleanOpenHourText(text);
        if (clean.isNotEmpty) return [clean];
      }
    }

    final raw = json['opening_hours'] ?? json['hours'] ?? json['open_hours'];
    if (raw is List) {
      return raw
          .map((e) => _cleanOpenHourText(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final clean = _cleanOpenHourText(raw);
      if (clean.isNotEmpty) return [clean];
    }
  } catch (_) {
    // Neu du lieu loi thi tra ve danh sach rong
  }
  return const [];
}

String _cleanOpenHourText(String raw) {
  return raw
      .replaceAll('{', '')
      .replaceAll('}', '')
      .replaceAll('[', '')
      .replaceAll(']', '')
      .replaceAll('"', '')
      .replaceAll("'", '')
      .replaceAll(' ,', ',')
      .trim();
}

List<String> _amenitiesFromJson(Map<String, dynamic> json) {
  try {
    final raw = json['amenities'] ?? json['features'] ?? json['services'];
    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  } catch (_) {
    // Neu du lieu loi thi tra ve danh sach rong
  }
  return const [];
}

String? _categoryFromJson(Map<String, dynamic> json) {
  final direct = json['type'] ?? json['category'];
  if (direct is String && direct.trim().isNotEmpty) {
    return direct.trim();
  }
  final categories = json['categories'];
  if (categories is List && categories.isNotEmpty) {
    final first = categories.first;
    if (first is String && first.trim().isNotEmpty) {
      return first.trim();
    }
    if (first != null) {
      final text = first.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  final types = json['types'];
  if (types is List && types.isNotEmpty) {
    final first = types.first;
    if (first is String && first.trim().isNotEmpty) {
      return first.trim();
    }
  }
  return null;
}

bool? _openFromJson(Map<String, dynamic> json) {
  final hours = json['hours'];
  if (hours is Map && hours['open_now'] is bool) {
    return hours['open_now'] as bool;
  }
  final raw = json['open_state'] ?? json['open_now'] ?? json['is_open'];
  if (raw is bool) return raw;
  if (raw is String) {
    final lower = raw.toLowerCase();
    if (lower.contains('open')) return true;
    if (lower.contains('close')) return false;
  }
  return null;
}

String? _closingTimeFromJson(Map<String, dynamic> json) {
  final hours = json['hours'];
  if (hours is Map) {
    final raw =
        hours['closes_at'] ?? hours['closing_time'] ?? hours['close_time'];
    final text = _stringOrNull(raw);
    if (text != null) return text;
  }
  return _stringOrNull(json['closing_time'] ?? json['closes_at']);
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
  return null;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

// Tim quan an gan vi tri nguoi dung
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
        final key = p.id.isNotEmpty ? p.id : '${p.name}-${p.lat}-${p.lng}';
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
        final key = p.id.isNotEmpty ? p.id : '${p.name}-${p.lat}-${p.lng}';
        dedup[key] = p;
      }
      return dedup.values.toList();
    } catch (e) {
      debugPrint('Goong TextSearch error: $e');
      return [];
    }
  }
}

