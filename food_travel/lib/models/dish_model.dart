import 'package:cloud_firestore/cloud_firestore.dart';

class DishModel {
  final String id;
  final String name;
  final String imageUrl;
  final String provinceCode;
  final String provinceName;
  final String regionCode;
  final String slug;
  final String tag;
  final int spicyLevel;
  final int satietyLevel;
  final String description;
  final String ingredients;
  final String instructions;
  final String originStory;
  final String bestTime;
  final String bestSeason;
  final String priceRange;
  final List<String> tags;

  const DishModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.provinceCode,
    required this.tag,
    required this.spicyLevel,
    this.provinceName = '',
    this.regionCode = '',
    this.slug = '',
    this.satietyLevel = 0,
    this.description = '',
    this.ingredients = '',
    this.instructions = '',
    this.originStory = '',
    this.bestTime = '',
    this.bestSeason = '',
    this.priceRange = '',
    this.tags = const [],


  });
  factory DishModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawTags = (data['Tags'] ?? data['tags'] ?? '') as String;
    final listTags = _toStringList(data['tags_list_vi'])..addAll(_splitTags(rawTags));
    return DishModel(
      id: doc.id,
      name: (data['Name'] ?? data['name'] ?? '') as String,
      imageUrl: (data['Img'] ?? data['imageUrl'] ?? '') as String,
      provinceCode: (data['province_code'] ?? data['provinceCode'] ?? '') as String,
      provinceName: (data['province_name_vi']?? data['province_name'] ?? data['province'] ?? '') as String,
      regionCode: (data['region_code'] ?? data['regionsCode'] ?? '') as String,
      slug: (data['slug'] ?? '') as String,
      tag: (data['category'] ?? data['Tags'] ?? '') as String,
      spicyLevel: (data['spicy_level'] as num?)?.toInt() ?? 0,
      satietyLevel: (data['satiety_level'] as num?)?.toInt() ?? 0,
      description: (data['description'] ?? '') as String,
      ingredients: (data['ingredients'] ?? '') as String,
      instructions: (data['instructions'] ?? '') as String,
      originStory: (data['origin_story'] ?? '') as String,
      bestTime: (data['Best_time'] ?? data['best_time'] ?? '') as String,
      bestSeason: (data['Best_season'] ?? data['best_season'] ?? '') as String,
      priceRange: (data['price_range'] ?? '') as String,
      tags: listTags,
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
  static List<String> _splitTags(String raw) {
    return raw 
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
