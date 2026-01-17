import 'package:cloud_firestore/cloud_firestore.dart';

class DishModel {
  final String id;
  final String name;
  final String imageUrl;
  final String provinceCode;
  final String tag;
  final int spicyLevel;

  const DishModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.provinceCode,
    required this.tag,
    required this.spicyLevel,

  });
  factory DishModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DishModel(
      id: doc.id,
      name: (data['Name'] ?? data['name'] ?? '') as String,
      imageUrl: (data['Img'] ?? data['imageUrl'] ?? '') as String,
      provinceCode: (data['province_code'] ?? data['provinceCode'] ?? '') as String,
      tag: (data['category'] ?? data['Tags'] ?? '') as String,
      spicyLevel: (data['spicy_level'] as num?)?.toInt() ?? 0,
    );
  }
}