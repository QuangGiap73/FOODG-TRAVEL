import 'package:cloud_firestore/cloud_firestore.dart';

import 'journey_schema.dart';

class JourneyStats {
  const JourneyStats({
    this.totalPoints = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCheckins = 0,
    this.uniquePlacesCount = 0,
    this.uniqueProvincesCount = 0,
    this.lastActiveDate,
    this.lastActiveAt,
    this.lastCheckinAt,
    this.updatedAt,
  });

  final int totalPoints;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalCheckins;
  final int uniquePlacesCount;
  final int uniqueProvincesCount;

  /// Dạng yyyy-MM-dd, ví dụ: 2026-06-04
  /// Dùng để tính streak theo ngày cho dễ và ổn định hơn.
  final String? lastActiveDate;

  final Timestamp? lastActiveAt;
  final Timestamp? lastCheckinAt;
  final Timestamp? updatedAt;

  factory JourneyStats.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};

    return JourneyStats(
      totalPoints: _toInt(data[JourneyStatsFields.totalPoints]),
      level: _toInt(data[JourneyStatsFields.level], fallback: 1),
      currentStreak: _toInt(data[JourneyStatsFields.currentStreak]),
      longestStreak: _toInt(data[JourneyStatsFields.longestStreak]),
      totalCheckins: _toInt(data[JourneyStatsFields.totalCheckins]),
      uniquePlacesCount: _toInt(data[JourneyStatsFields.uniquePlacesCount]),
      uniqueProvincesCount:
          _toInt(data[JourneyStatsFields.uniqueProvincesCount]),
      lastActiveDate: data[JourneyStatsFields.lastActiveDate] is String
          ? data[JourneyStatsFields.lastActiveDate] as String
          : null,
      lastActiveAt: _toTimestamp(data[JourneyStatsFields.lastActiveAt]),
      lastCheckinAt: _toTimestamp(data[JourneyStatsFields.lastCheckinAt]),
      updatedAt: _toTimestamp(data[JourneyStatsFields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      JourneyStatsFields.totalPoints: totalPoints,
      JourneyStatsFields.level: level,
      JourneyStatsFields.currentStreak: currentStreak,
      JourneyStatsFields.longestStreak: longestStreak,
      JourneyStatsFields.totalCheckins: totalCheckins,
      JourneyStatsFields.uniquePlacesCount: uniquePlacesCount,
      JourneyStatsFields.uniqueProvincesCount: uniqueProvincesCount,
      JourneyStatsFields.lastActiveDate: lastActiveDate,
      JourneyStatsFields.lastActiveAt: lastActiveAt,
      JourneyStatsFields.lastCheckinAt: lastCheckinAt,
      JourneyStatsFields.updatedAt: updatedAt,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  JourneyStats copyWith({
    int? totalPoints,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? totalCheckins,
    int? uniquePlacesCount,
    int? uniqueProvincesCount,
    String? lastActiveDate,
    Timestamp? lastActiveAt,
    Timestamp? lastCheckinAt,
    Timestamp? updatedAt,
  }) {
    return JourneyStats(
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCheckins: totalCheckins ?? this.totalCheckins,
      uniquePlacesCount: uniquePlacesCount ?? this.uniquePlacesCount,
      uniqueProvincesCount: uniqueProvincesCount ?? this.uniqueProvincesCount,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
