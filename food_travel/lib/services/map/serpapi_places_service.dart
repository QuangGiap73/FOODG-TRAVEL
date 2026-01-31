import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/goong_secrets.dart';
import '../../models/places_model.dart';

class SerpApiPlacesService {
  // Model review don gian tu SerpAPI
  // Chi su dung trong UI chi tiet quan
  // (khong can luu DB)
  static const _defaultReviewLimit = 6;

  Future<List<SerpApiReview>> fetchReviews({
    required String dataId,
    int limit = _defaultReviewLimit,
  }) async {
    final trimmed = dataId.trim();
    if (trimmed.isEmpty) return const [];

    final params = <String, String>{
      'engine': 'google_maps_reviews',
      'api_key': serpapiKey,
      'data_id': trimmed,
      'hl': 'vi',
      'gl': 'vn',
    };
    final uri = Uri.https('serpapi.com', '/search.json', params);
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('SerpAPI reviews http=${res.statusCode} body=${res.body}');
        return const [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['reviews'];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => SerpApiReview.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.text.isNotEmpty)
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('SerpAPI reviews error: $e');
      return const [];
    }
  }
  Future<List<GoongNearbyPlace>> searchNearby({
    required double lat,
    required double lng,
    required String query,
    int radius = 3000,
    int limit = 12,
  }) async {
    // chuan hoa input
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
    // tranh treo app
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('SerpAPI http=${res.statusCode} body=${res.body}');
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = _extractResults(data); // boc tach du lieu tu serpapi
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

  // Lay thong tin chi tiet (uu tien serpapi), fallback ve seed neu khong co.
  Future<GoongNearbyPlace?> fetchPlaceDetail(GoongNearbyPlace seed) async {
    final query = [
      seed.name.trim(),
      seed.address.trim(),
    ].where((e) => e.isNotEmpty).join(' ');
    if (query.isEmpty) return seed;

    final params = <String, String>{
      'engine': 'google_maps',
      'api_key': serpapiKey,
      'q': query,
      'hl': 'vi',
      'gl': 'vn',
    };
    if (seed.lat != 0 && seed.lng != 0) {
      params['ll'] = '@${seed.lat},${seed.lng},15z';
    }

    final uri = Uri.https('serpapi.com', '/search.json', params);
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('SerpAPI detail http=${res.statusCode} body=${res.body}');
        return seed;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = _extractResults(data);
      if (items.isEmpty) return seed;

      final first = items.first;
      if (first is! Map) return seed;
      final detail =
          GoongNearbyPlace.fromSerpApi(Map<String, dynamic>.from(first));
      return _mergePlace(seed, detail);
    } catch (e) {
      debugPrint('SerpAPI detail error: $e');
      return seed;
    }
  }

  GoongNearbyPlace _mergePlace(GoongNearbyPlace seed, GoongNearbyPlace detail) {
    final mergedPhotos = detail.photoUrls.isNotEmpty
        ? detail.photoUrls
        : seed.photoUrls;
    final mainPhoto = detail.photoUrl.isNotEmpty
        ? detail.photoUrl
        : (mergedPhotos.isNotEmpty ? mergedPhotos.first : seed.photoUrl);

    return GoongNearbyPlace(
      id: detail.id.isNotEmpty ? detail.id : seed.id,
      serpDataId: detail.serpDataId.isNotEmpty
          ? detail.serpDataId
          : seed.serpDataId,
      name: detail.name.isNotEmpty ? detail.name : seed.name,
      address: detail.address.isNotEmpty ? detail.address : seed.address,
      lat: detail.lat != 0 ? detail.lat : seed.lat,
      lng: detail.lng != 0 ? detail.lng : seed.lng,
      photoUrl: mainPhoto,
      photoUrls: mergedPhotos,
      rating: detail.rating ?? seed.rating,
      reviewCount: detail.reviewCount ?? seed.reviewCount,
      price: detail.price ?? seed.price,
      phone: detail.phone ?? seed.phone,
      category: detail.category ?? seed.category,
      isOpen: detail.isOpen ?? seed.isOpen,
      closingTime: detail.closingTime ?? seed.closingTime,
    );
  }
}

class SerpApiReview {
  const SerpApiReview({
    required this.user,
    required this.rating,
    required this.text,
    required this.dateText,
  });

  final String user;
  final double rating;
  final String text;
  final String dateText;

  factory SerpApiReview.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] ??
            json['author_name'] ??
            json['name'] ??
            '')
        .toString();
    final ratingRaw = json['rating'];
    final rating = ratingRaw is num
        ? ratingRaw.toDouble()
        : double.tryParse(ratingRaw?.toString() ?? '') ?? 0;
    final text = (json['snippet'] ??
            json['text'] ??
            json['content'] ??
            '')
        .toString();
    final dateText = (json['date'] ??
            json['relative_date'] ??
            json['published_time'] ??
            '')
        .toString();
    return SerpApiReview(
      user: user,
      rating: rating,
      text: text,
      dateText: dateText,
    );
  }
}
