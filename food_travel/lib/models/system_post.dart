import 'package:cloud_firestore/cloud_firestore.dart';

class SystemPost {
  const SystemPost({
    required this.id,
    required this.slug,
    required this.titleVi,
    required this.titleEn,
    required this.summaryVi,
    required this.summaryEn,
    required this.contentVi,
    required this.contentEn,
    required this.categoryVi,
    required this.categoryEn,
    required this.coverImage,
    required this.status,
    required this.featured,
    required this.pinned,
    required this.tags,
    this.provinceCode34,
    this.provinceName34,
    this.regionCode,
    this.seoTitle,
    this.seoDescription,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String titleVi;
  final String titleEn;
  final String summaryVi;
  final String summaryEn;
  final String contentVi;
  final String contentEn;
  final String categoryVi;
  final String categoryEn;
  final String coverImage;
  final String status;
  final bool featured;
  final bool pinned;
  final List<String> tags;
  final String? provinceCode34;
  final String? provinceName34;
  final String? regionCode;
  final String? seoTitle;
  final String? seoDescription;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  bool get isPublished => status.toLowerCase() == 'published';

  String title(String languageCode) {
    if (languageCode == 'en' && titleEn.trim().isNotEmpty) return titleEn.trim();
    if (titleVi.trim().isNotEmpty) return titleVi.trim();
    return titleEn.trim();
  }

  String summary(String languageCode) {
    if (languageCode == 'en' && summaryEn.trim().isNotEmpty) return summaryEn.trim();
    if (summaryVi.trim().isNotEmpty) return summaryVi.trim();
    return summaryEn.trim();
  }

  String content(String languageCode) {
    if (languageCode == 'en' && contentEn.trim().isNotEmpty) return contentEn.trim();
    if (contentVi.trim().isNotEmpty) return contentVi.trim();
    return contentEn.trim();
  }

  String category(String languageCode) {
    if (languageCode == 'en' && categoryEn.trim().isNotEmpty) return categoryEn.trim();
    if (categoryVi.trim().isNotEmpty) return categoryVi.trim();
    return categoryEn.trim();
  }

  factory SystemPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawTags = data['tags'];
    final tags = <String>[];

    if (rawTags is List) {
      for (final item in rawTags) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) tags.add(value);
      }
    } else if (rawTags is String) {
      for (final item in rawTags.split(',')) {
        final value = item.trim();
        if (value.isNotEmpty) tags.add(value);
      }
    }

    String readNested(String key, String language) {
      final raw = data[key];
      if (raw is Map) {
        final value = raw[language];
        return value?.toString() ?? '';
      }
      return '';
    }

    return SystemPost(
      id: doc.id,
      slug: (data['slug'] ?? '').toString(),
      titleVi: readNested('title', 'vi'),
      titleEn: readNested('title', 'en'),
      summaryVi: readNested('summary', 'vi'),
      summaryEn: readNested('summary', 'en'),
      contentVi: readNested('content', 'vi'),
      contentEn: readNested('content', 'en'),
      categoryVi: readNested('category', 'vi'),
      categoryEn: readNested('category', 'en'),
      coverImage: (data['coverImage'] ?? '').toString(),
      status: (data['status'] ?? 'draft').toString(),
      featured: data['featured'] == true,
      pinned: data['pinned'] == true,
      tags: tags,
      provinceCode34: data['provinceCode34']?.toString(),
      provinceName34: data['provinceName34']?.toString(),
      regionCode: data['regionCode']?.toString(),
      seoTitle: data['seoTitle']?.toString(),
      seoDescription: data['seoDescription']?.toString(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null,
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] as Timestamp : null,
    );
  }
}
