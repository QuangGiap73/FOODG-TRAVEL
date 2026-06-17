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
  final List<String> mergedFrom;
  final int legacyCount;
  final String status;

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
    this.mergedFrom = const [],
    this.legacyCount = 1,
    this.status = 'active',
  });

  factory ProvinceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = _toStringList(data['imageUrls']);
    final cover = (data['imageUrl'] ?? data['Img'] ?? '') as String;
    final regionRaw = (data['regionsCode'] ?? data['region_code'] ?? '') as String;
    final slugRaw = (data['slug'] ?? '') as String;
    return ProvinceModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      code: (data['code'] ?? data['province_code'] ?? doc.id) as String,
      imageUrl: cover.isNotEmpty ? cover : (urls.isNotEmpty ? urls.first : ''),
      description: data['description'] as String?,
      imageUrls: urls,
      regionCode: (data['regionCode'] ?? regionRaw).toString().trim().isEmpty
          ? null
          : (data['regionCode'] ?? regionRaw).toString(),
      slug: slugRaw.trim().isEmpty ? null : slugRaw,
      centerLat: _toDouble(data['centerLat'] ?? data['center_lat']),
      centerLng: _toDouble(data['centerLng'] ?? data['center_lng']),
      mergedFrom: _toStringList(data['mergedFrom']),
      legacyCount: _toInt(data['legacyCount']) ?? 1,
      status: (data['status'] ?? 'active').toString(),
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

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
