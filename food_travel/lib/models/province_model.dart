import 'package:cloud_firestore/cloud_firestore.dart';

class ProvinceModel {
  final String id;
  final String name;
  final String code;
  final String imageUrl;
  final String? description;

  const ProvinceModel({
    required this.id,
    required this.name,
    required this.code,
    required this.imageUrl,
    this.description,
  });
  factory ProvinceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProvinceModel(
      id: doc.id,
      name: (data['name'] ?? data['name'] ?? '') as String,
      code: (data['code'] ?? data['province_code'] ?? doc.id) as String,
      imageUrl: (data['imageUrl'] ?? data['Img'] ?? '') as String,
      description: data['description'] as String?,
    );
  }
}