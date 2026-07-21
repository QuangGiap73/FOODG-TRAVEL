import 'package:cloud_firestore/cloud_firestore.dart';

class ProvinceModel {
  final String id;
  final String name;
  final String code;
  final String imageUrl;
  final String? description;
  final String? descriptionEn;
  final List<String> imageUrls;
  final String? regionCode;
  final String? slug;
  final double? centerLat;
  final double? centerLng;
  final List<String> mergedFrom;
  final List<ProvincePlaceModel> places;
  final int legacyCount;
  final String status;

  const ProvinceModel({
    required this.id,
    required this.name,
    required this.code,
    required this.imageUrl,
    this.description,
    this.descriptionEn,
    this.imageUrls = const [],
    this.regionCode,
    this.slug,
    this.centerLat,
    this.centerLng,
    this.mergedFrom = const [],
    this.places = const [],
    this.legacyCount = 1,
    this.status = 'active',
  });

  factory ProvinceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urls = _toStringList(data['imageUrls']);
    final cover = (data['imageUrl'] ?? data['Img'] ?? '') as String;
    final regionRaw =
        (data['regionsCode'] ?? data['region_code'] ?? '') as String;
    final slugRaw = (data['slug'] ?? '') as String;
    return ProvinceModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      code: (data['code'] ??
              data['provinceCodeLabel'] ??
              data['province_code'] ??
              doc.id)
          as String,
      imageUrl: cover.isNotEmpty ? cover : (urls.isNotEmpty ? urls.first : ''),
      description: data['description'] as String?,
      descriptionEn: data['descriptionEn'] as String?,
      imageUrls: urls,
      regionCode: (data['regionCode'] ?? regionRaw).toString().trim().isEmpty
          ? null
          : (data['regionCode'] ?? regionRaw).toString(),
      slug: slugRaw.trim().isEmpty ? null : slugRaw,
      centerLat: _toDouble(data['centerLat'] ?? data['center_lat']),
      centerLng: _toDouble(data['centerLng'] ?? data['center_lng']),
      mergedFrom: _toStringList(data['mergedFrom']),
      places: _toPlaceList(data['places']),
      legacyCount: _toInt(data['legacyCount']) ?? 1,
      status: (data['status'] ?? 'active').toString(),
    );
  }

  ProvinceModel copyWith({
    String? id,
    String? name,
    String? code,
    String? imageUrl,
    String? description,
    String? descriptionEn,
    List<String>? imageUrls,
    String? regionCode,
    String? slug,
    double? centerLat,
    double? centerLng,
    List<String>? mergedFrom,
    List<ProvincePlaceModel>? places,
    int? legacyCount,
    String? status,
  }) {
    return ProvinceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      imageUrls: imageUrls ?? this.imageUrls,
      regionCode: regionCode ?? this.regionCode,
      slug: slug ?? this.slug,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      mergedFrom: mergedFrom ?? this.mergedFrom,
      places: places ?? this.places,
      legacyCount: legacyCount ?? this.legacyCount,
      status: status ?? this.status,
    );
  }

  ProvinceModel mergeDetailFrom(ProvinceModel detail) {
    return copyWith(
      description: _preferText(description, detail.description),
      descriptionEn: _preferText(descriptionEn, detail.descriptionEn),
      imageUrl: imageUrl.trim().isNotEmpty ? imageUrl : detail.imageUrl,
      imageUrls: imageUrls.isNotEmpty ? imageUrls : detail.imageUrls,
      places: places.isNotEmpty ? places : detail.places,
      centerLat: centerLat ?? detail.centerLat,
      centerLng: centerLng ?? detail.centerLng,
      regionCode: _preferText(regionCode, detail.regionCode),
      slug: _preferText(slug, detail.slug),
    );
  }

  ProvinceModel mergeHomeMediaFrom(ProvinceModel detail) {
    final detailImages = detail.imageUrls.isNotEmpty
        ? detail.imageUrls
        : (detail.imageUrl.trim().isNotEmpty
            ? <String>[detail.imageUrl]
            : const <String>[]);

    return copyWith(
      imageUrl: detailImages.isNotEmpty ? detailImages.first : imageUrl,
      imageUrls: detailImages.isNotEmpty ? detailImages : imageUrls,
      description: _preferText(description, detail.description),
      descriptionEn: _preferText(descriptionEn, detail.descriptionEn),
      places: places.isNotEmpty ? places : detail.places,
    );
  }

  static String? _preferText(String? primary, String? fallback) {
    final value = primary?.trim();
    if (value != null && value.isNotEmpty) return primary;
    final fallbackValue = fallback?.trim();
    return fallbackValue == null || fallbackValue.isEmpty ? primary : fallback;
  }

  static List<ProvincePlaceModel> _toPlaceList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (item) => ProvincePlaceModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((place) => place.displayName('vi').isNotEmpty)
        .toList();
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

class ProvincePlaceModel {
  final String nameVi;
  final String nameEn;
  final String imageUrl;
  final String slug;

  const ProvincePlaceModel({
    required this.nameVi,
    required this.nameEn,
    required this.imageUrl,
    required this.slug,
  });

  factory ProvincePlaceModel.fromMap(Map<String, dynamic> data) {
    return ProvincePlaceModel(
      nameVi: (data['nameVi'] ?? data['name'] ?? '').toString().trim(),
      nameEn: (data['nameEn'] ?? '').toString().trim(),
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '').toString().trim(),
      slug: (data['slug'] ?? '').toString().trim(),
    );
  }

  String displayName(String languageCode) {
    if (languageCode.toLowerCase().startsWith('en') && nameEn.isNotEmpty) {
      return nameEn;
    }
    return nameVi.isNotEmpty ? nameVi : nameEn;
  }
}
