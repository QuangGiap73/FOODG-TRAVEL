import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/goong_secrets.dart';

String buildGoongPhotoUrl(String reference, {int maxWidth = 400}) {
  final encoded = Uri.encodeQueryComponent(reference); // tránh các kí tự đặc biệt
  return 'https://rsapi.goong.io/Place/Photo'
      '?maxwidth=$maxWidth&photoreference=$encoded&api_key=$goongPlacesApiKey';
}

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
  final String address;
  final String placeId;
  final String photoUrl;

  const GoongPlaceDetail({
    required this.lat,
    required this.lng,
    required this.name,
    this.address = '',
    this.placeId = '',
    this.photoUrl = '',
  });
}
// user gõ , lấy danh sách gợi ý
class GoongPlacesService {
  Future<List<GoongPrediction>> autocomplete(
    String input, {
    double? lat,
    double? lng,
    int radius = 5000,
  }) async {
    final params = <String, String>{
      'input': input,
      'api_key': goongPlacesApiKey,
    };
    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      params['radius'] = radius.toString();
    }
    final uri = Uri.https('rsapi.goong.io','/Place/AutoComplete', params);
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
      'fields' : 'place_id,name,formatted_address,geometry,photos',
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

    final address = (result['formatted_address'] ??
            result['vicinity'] ??
            '')
        .toString();
    final photos = result['photos'] as List?;
    String photoUrl = '';
    if (photos != null && photos.isNotEmpty) {
      final first = photos.first;
      if (first is Map) {
        final ref = first['photo_reference']?.toString();
        if (ref != null && ref.isNotEmpty) {
          photoUrl = buildGoongPhotoUrl(ref);
        }
      }
    }

    return GoongPlaceDetail(
      lat: lat,
      lng: lng,
      name: result['name'] as String? ?? '',
      address: address,
      placeId: result['place_id'] as String? ?? placeId,
      photoUrl: photoUrl,
    );
  }
}
