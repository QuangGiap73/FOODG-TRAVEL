import 'package:cloud_firestore/cloud_firestore.dart';

import 'journey_schema.dart';

class JourneyBadge {
  const JourneyBadge({
    required this.badgeId,
    required this.title,
    required this.description,
    required this.iconKey,
    this.progress = 0,
    this.currentValue = 0,
    this.targetValue = 1,
    this.unlockedAt,
    this.updatedAt,
  });

  final String badgeId;
  final String title;
  final String description;
  final String iconKey;

  /// Progress nên dùng dạng 0.0 -> 1.0
  final double progress;

  /// Ví dụ: đã check-in 3 quán
  final int currentValue;

  /// Ví dụ: cần check-in 5 quán
  final int targetValue;

  final Timestamp? unlockedAt;
  final Timestamp? updatedAt;

  bool get isUnlocked => unlockedAt != null || progress >= 1.0;

  factory JourneyBadge.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return JourneyBadge.fromMap(doc.data(), id: doc.id);
  }

  factory JourneyBadge.fromMap(
    Map<String, dynamic>? map, {
    String? id,
  }) {
    final data = map ?? const <String, dynamic>{};

    return JourneyBadge(
      badgeId: id ?? (data[JourneyBadgeFields.badgeId] ?? '').toString(),
      title: (data[JourneyBadgeFields.title] ?? '').toString(),
      description: (data[JourneyBadgeFields.description] ?? '').toString(),
      iconKey: (data[JourneyBadgeFields.iconKey] ?? '').toString(),
      progress: _toDouble(data[JourneyBadgeFields.progress]),
      currentValue: _toInt(data[JourneyBadgeFields.currentValue]),
      targetValue: _toInt(data[JourneyBadgeFields.targetValue], fallback: 1),
      unlockedAt: _toTimestamp(data[JourneyBadgeFields.unlockedAt]),
      updatedAt: _toTimestamp(data[JourneyBadgeFields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      JourneyBadgeFields.badgeId: badgeId,
      JourneyBadgeFields.title: title,
      JourneyBadgeFields.description: description,
      JourneyBadgeFields.iconKey: iconKey,
      JourneyBadgeFields.progress: progress,
      JourneyBadgeFields.currentValue: currentValue,
      JourneyBadgeFields.targetValue: targetValue,
      JourneyBadgeFields.unlockedAt: unlockedAt,
      JourneyBadgeFields.updatedAt: updatedAt,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  JourneyBadge copyWith({
    String? badgeId,
    String? title,
    String? description,
    String? iconKey,
    double? progress,
    int? currentValue,
    int? targetValue,
    Timestamp? unlockedAt,
    Timestamp? updatedAt,
  }) {
    return JourneyBadge(
      badgeId: badgeId ?? this.badgeId,
      title: title ?? this.title,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static Timestamp? _toTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }
}
