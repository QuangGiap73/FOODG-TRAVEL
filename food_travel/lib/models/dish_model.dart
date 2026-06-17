import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DishModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> imageUrls;
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
  final Map<String, String> nameI18n;
  final Map<String, String> descriptionI18n;
  final Map<String, String> categoryI18n;
  final Map<String, String> ingredientsI18n;
  final Map<String, String> instructionsI18n;
  final Map<String, String> originStoryI18n;
  final Map<String, String> bestTimeI18n;
  final Map<String, String> bestSeasonI18n;
  final Map<String, String> priceRangeI18n;
  final Map<String, String> tagsI18n;
  final Map<String, String> provinceI18n;
  final Map<String, String> regionI18n;
  final String provinceCode34;
  final String provinceName34;
  final String legacyProvinceCode;

  const DishModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.imageUrls = const [],
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
    this.nameI18n = const {'vi': '', 'en': ''},
    this.descriptionI18n = const {'vi': '', 'en': ''},
    this.categoryI18n = const {'vi': '', 'en': ''},
    this.ingredientsI18n = const {'vi': '', 'en': ''},
    this.instructionsI18n = const {'vi': '', 'en': ''},
    this.originStoryI18n = const {'vi': '', 'en': ''},
    this.bestTimeI18n = const {'vi': '', 'en': ''},
    this.bestSeasonI18n = const {'vi': '', 'en': ''},
    this.priceRangeI18n = const {'vi': '', 'en': ''},
    this.tagsI18n = const {'vi': '', 'en': ''},
    this.provinceI18n = const {'vi': '', 'en': ''},
    this.regionI18n = const {'vi': '', 'en': ''},
    this.provinceCode34 = '',
    this.provinceName34 = '',
    this.legacyProvinceCode = '',
  });

  factory DishModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final languageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final nameI18n = _toI18n(data['Name'] ?? data['name'] ?? '');
    final descriptionI18n = _toI18n(data['description'] ?? '');
    final categoryI18n = _toI18n(data['category'] ?? '');
    final ingredientsI18n = _toI18n(data['ingredients'] ?? '');
    final instructionsI18n = _toI18n(data['instructions'] ?? '');
    final originStoryI18n = _toI18n(data['origin_story'] ?? '');
    final bestTimeI18n = _toI18n(data['Best_time'] ?? data['best_time'] ?? '');
    final bestSeasonI18n =
        _toI18n(data['Best_season'] ?? data['best_season'] ?? '');
    final priceRangeI18n = _toI18n(data['price_range'] ?? '');
    final tagsI18n = _toI18n(data['Tags'] ?? data['tags'] ?? '');
    final provinceCode34 = _asString(data['provinceCode34'] ?? '');
    final provinceName34 = _asString(data['provinceName34'] ?? '');
    final legacyProvinceCode = _asString(data['legacyProvinceCode'] ?? '');
    final provinceI18n = _toI18n(
      data['province_code'] ??
          data['provinceCode'] ??
          data['province_name_vi'] ??
          data['province_name'] ??
          data['province'] ??
          '',
    );
    final regionI18n = _toI18n(data['region_code'] ?? data['regionsCode'] ?? '');

    final imageList = _toStringList(data['Images'] ?? data['images'] ?? const []);
    final imageUrl = _asString(data['Img'] ?? data['img'] ?? data['imageUrl'] ?? '');
    final rawTags = tagsI18n['vi'] ?? '';
    final listTags = _toStringList(data['tags_list_vi'])..addAll(_splitTags(rawTags));

    return DishModel(
      id: doc.id,
      name: _pickLang(nameI18n, languageCode),
      imageUrl: imageUrl,
      imageUrls: _mergeImages(imageUrl, imageList),
      provinceCode: provinceCode34.isNotEmpty
          ? provinceCode34
          : _pickLang(provinceI18n, languageCode),
      provinceName: _asString(
        data['provinceName34'] ??
            data['province_name_vi'] ??
            data['province_name'] ??
            data['province'] ??
            '',
      ),
      regionCode: _pickLang(regionI18n, languageCode),
      slug: _asString(data['slug'] ?? ''),
      tag: _pickLang(categoryI18n, languageCode),
      spicyLevel: (data['spicy_level'] as num?)?.toInt() ?? 0,
      satietyLevel: (data['satiety_level'] as num?)?.toInt() ?? 0,
      description: _pickLang(descriptionI18n, languageCode),
      ingredients: _pickLang(ingredientsI18n, languageCode),
      instructions: _pickLang(instructionsI18n, languageCode),
      originStory: _pickLang(originStoryI18n, languageCode),
      bestTime: _pickLang(bestTimeI18n, languageCode),
      bestSeason: _pickLang(bestSeasonI18n, languageCode),
      priceRange: _pickLang(priceRangeI18n, languageCode),
      tags: listTags,
      nameI18n: nameI18n,
      descriptionI18n: descriptionI18n,
      categoryI18n: categoryI18n,
      ingredientsI18n: ingredientsI18n,
      instructionsI18n: instructionsI18n,
      originStoryI18n: originStoryI18n,
      bestTimeI18n: bestTimeI18n,
      bestSeasonI18n: bestSeasonI18n,
      priceRangeI18n: priceRangeI18n,
      tagsI18n: tagsI18n,
      provinceI18n: provinceI18n,
      regionI18n: regionI18n,
      provinceCode34: provinceCode34,
      provinceName34: provinceName34,
      legacyProvinceCode: legacyProvinceCode,
    );
  }

  String textByLang(Map<String, String> i18n, String languageCode) {
    return _pickLang(i18n, languageCode);
  }

  String getName(String languageCode) => _pickLang(nameI18n, languageCode);
  String getDescription(String languageCode) =>
      _pickLang(descriptionI18n, languageCode);
  String getCategory(String languageCode) => _pickLang(categoryI18n, languageCode);
  String getIngredients(String languageCode) =>
      _pickLang(ingredientsI18n, languageCode);
  String getInstructions(String languageCode) =>
      _pickLang(instructionsI18n, languageCode);
  String getOriginStory(String languageCode) =>
      _pickLang(originStoryI18n, languageCode);
  String getBestTime(String languageCode) => _pickLang(bestTimeI18n, languageCode);
  String getBestSeason(String languageCode) =>
      _pickLang(bestSeasonI18n, languageCode);
  String getPriceRange(String languageCode) =>
      _pickLang(priceRangeI18n, languageCode);
  String getTagsText(String languageCode) => _pickLang(tagsI18n, languageCode);
  String getProvince(String languageCode) => _pickLang(provinceI18n, languageCode);
  String getRegion(String languageCode) => _pickLang(regionI18n, languageCode);

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static Map<String, String> _toI18n(dynamic value) {
    if (value is Map) {
      return {
        'vi': _asString(value['vi']),
        'en': _asString(value['en']),
      };
    }
    final text = _asString(value);
    return {'vi': text, 'en': ''};
  }

  static String _pickLang(Map<String, String> i18n, String languageCode) {
    final vi = (i18n['vi'] ?? '').trim();
    final en = (i18n['en'] ?? '').trim();
    if (languageCode.toLowerCase().startsWith('en')) {
      return en.isNotEmpty ? en : vi;
    }
    return vi.isNotEmpty ? vi : en;
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

  static List<String> _mergeImages(String primary, List<String> list) {
    final out = <String>[];
    void addIf(String v) {
      final s = v.trim();
      if (s.isEmpty || out.contains(s)) return;
      out.add(s);
    }
    addIf(primary);
    for (final v in list) {
      addIf(v);
    }
    return out;
  }
}
