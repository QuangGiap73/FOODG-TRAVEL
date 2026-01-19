import 'package:cloud_firestore/cloud_firestore.dart';

class ProvinceModel {
  final String id;
  final String name;
  final String code;
  final String imageUrl;
  final String? description;
  final List<String> imageUrls;
  final String? regionCode;
  final String? slug;
  final double? centerLat;
  final double? centerLng;

  const ProvinceModel({
    required this.id,
    required this.name,
    required this.code,
    required this.imageUrl,
    this.description,
    this.imageUrls = const [],
    this.regionCode,
    this.slug,
    this.centerLat,
    this.centerLng,
  });
  factory ProvinceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = _toStringList(data['imageUrls']);
    final cover = (data['imageUrl'] ?? data['Img'] ?? '') as String;
    final regionRaw = (data['regionsCode'] ?? data['region_code'] ?? '') as String;
    final slugRaw = (data['slug'] ?? '') as String;
    return ProvinceModel(
      id: doc.id,
      name: (data['name'] ?? data['name'] ?? '') as String,
      code: (data['code'] ?? data['province_code'] ?? doc.id) as String,
      imageUrl: cover.isNotEmpty ? cover : (urls.isNotEmpty ? urls.first : '') ,
      description: data['description'] as String?,
      imageUrls: urls,
      regionCode: regionRaw.trim().isEmpty ? null : regionRaw,
      slug: slugRaw.trim().isEmpty ? null : slugRaw,
      centerLat: _toDouble(data['centerLat'] ?? data['center_lat']),
      centerLng: _toDouble(data['centerLng'] ?? data['center_lng']),
    );
  }
  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value 
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
  static double? _toDouble(dynamic value){
    if (value is num) return value.toDouble();
    if(value is String) return double.tryParse(value);
    return null;
  }
}