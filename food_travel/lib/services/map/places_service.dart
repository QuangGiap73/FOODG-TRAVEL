import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

import '../../config/goong_secrets.dart';

class GoongPrediction {
  final String placeId;
  final String description;

  // tao object
  const GoongPrediction({required this.placeId, required this.description});
  // chuyen json sang object
  factory GoongPrediction.fromJson(Map<String, dynamic> json) {
    return GoongPrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
// modal chi tiet 1 dia diem
class GoongPlaceDetail {
  final double lat;
  final double lng;
  final String name;

  const GoongPlaceDetail({
    required this.lat,
    required this.lng,
    required this.name,
  });
}
// user gõ , lấy danh sách gợi ý
class GoongPlacesService {
  Future<List<GoongPrediction>> autocomplete(String input) async {
    final uri = Uri.https('rsapi.goong.io','/Place/AutoComplete',{
      'input' : input,
      'api_key' : goongPlacesApiKey,
    });
    final res = await http.get(uri);
    if(res.statusCode != 200) return [];
    // kiem tra status
    final data = jsonDecode(res.body) as Map<String,dynamic>;
    if (data['status'] != 'OK') return [];
    // Lấy predictions và map sang model
    final items = (data['predictions'] as List?) ?? [];
    return items
        .map((e) => GoongPrediction.fromJson(e as Map<String, dynamic>))
        .where((e) => e.placeId.isNotEmpty)
        .toList();
  }
  // user chọn 1 gợi ý → lấy tọa độ chi tiết.
  Future<GoongPlaceDetail?> placeDetail(String placeId) async {
    final uri = Uri.https('rsapi.goong.io','/Place/Detail',{
      'place_id' : placeId,
      'api_key': goongPlacesApiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;

    final result = data['result'] as Map<String, dynamic>? ?? {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
    final loc = geometry['location'] as Map<String, dynamic>? ?? {};
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GoongPlaceDetail(
      lat: lat,
      lng: lng,
      name: result['name'] as String? ?? '',
    );
  }
}