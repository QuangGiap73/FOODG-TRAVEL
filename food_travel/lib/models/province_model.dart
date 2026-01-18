import 'package:cloud_firestore/cloud_firestore.dart';

class ProvinceModel {
  final String id;
  final String name;
  final String code;
  final String imageUrl;
  final String? description;
  final List<String> imageUrls;

  const ProvinceModel({
    required this.id,
    required this.name,
    required this.code,
    required this.imageUrl,
    this.description,
    this.imageUrls = const [],
  });
  factory ProvinceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = _toStringList(data['imageUrls']);
    final cover = (data['imageUrl'] ?? data['Img'] ?? '') as String;
    return ProvinceModel(
      id: doc.id,
      name: (data['name'] ?? data['name'] ?? '') as String,
      code: (data['code'] ?? data['province_code'] ?? doc.id) as String,
      imageUrl: cover.isNotEmpty ? cover : (urls.isNotEmpty ? urls.first : '') ,
      description: data['description'] as String?,
      imageUrls: urls,
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
}