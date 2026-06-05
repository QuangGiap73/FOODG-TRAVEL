import 'package:cloud_firestore/cloud_firestore.dart';

import 'journey_schema.dart';

class JourneyProvinceProgress {
  const JourneyProvinceProgress({
    required this.provinceCode,
    required this.provinceName,
    this.checkinCount = 0,
    this.uniquePlacesCount = 0,
    this.districtsCount = 0,
    this.totalPoints = 0,
    this.isDiscovered = false,
    this.firstCheckinAt,
    this.lastCheckinAt,
    this.updatedAt,
  });

  final String provinceCode;
  final String provinceName;

  /// Tổng số lần check-in trong tỉnh/thành này.
  final int checkinCount;

  /// Số quán khác nhau đã check-in trong tỉnh/thành này.
  final int uniquePlacesCount;

  /// Số quận/huyện khác nhau đã đi qua.
  final int districtsCount;

  /// Tổng điểm kiếm được từ tỉnh/thành này.
  final int totalPoints;

  /// Đã khám phá tỉnh/thành này chưa.
  final bool isDiscovered;

  final Timestamp? firstCheckinAt;
  final Timestamp? lastCheckinAt;
  final Timestamp? updatedAt;

  factory JourneyProvinceProgress.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return JourneyProvinceProgress.fromMap(
      doc.data(),
      fallbackProvinceCode: doc.id,
    );
  }

  factory JourneyProvinceProgress.fromMap(
    Map<String, dynamic>? map, {
    String? fallbackProvinceCode,
  }) {
    final data = map ?? const <String, dynamic>{};

    final checkinCount = _toInt(data[JourneyProvinceFields.checkinCount]);

    return JourneyProvinceProgress(
      provinceCode:
          (data[JourneyProvinceFields.provinceCode] ?? fallbackProvinceCode ?? '')
              .toString(),
      provinceName: (data[JourneyProvinceFields.provinceName] ?? '').toString(),
      checkinCount: checkinCount,
      uniquePlacesCount: _toInt(data[JourneyProvinceFields.uniquePlacesCount]),
      districtsCount: _toInt(data[JourneyProvinceFields.districtsCount]),
      totalPoints: _toInt(data[JourneyProvinceFields.totalPoints]),
      isDiscovered:
          data[JourneyProvinceFields.isDiscovered] == true || checkinCount > 0,
      firstCheckinAt: _toTimestamp(data[JourneyProvinceFields.firstCheckinAt]),
      lastCheckinAt: _toTimestamp(data[JourneyProvinceFields.lastCheckinAt]),
      updatedAt: _toTimestamp(data[JourneyProvinceFields.updatedAt]),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      JourneyProvinceFields.provinceCode: provinceCode,
      JourneyProvinceFields.provinceName: provinceName,
      JourneyProvinceFields.checkinCount: checkinCount,
      JourneyProvinceFields.uniquePlacesCount: uniquePlacesCount,
      JourneyProvinceFields.districtsCount: districtsCount,
      JourneyProvinceFields.totalPoints: totalPoints,
      JourneyProvinceFields.isDiscovered: isDiscovered,
      JourneyProvinceFields.firstCheckinAt: firstCheckinAt,
      JourneyProvinceFields.lastCheckinAt: lastCheckinAt,
      JourneyProvinceFields.updatedAt: updatedAt,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  JourneyProvinceProgress copyWith({
    String? provinceCode,
    String? provinceName,
    int? checkinCount,
    int? uniquePlacesCount,
    int? districtsCount,
    int? totalPoints,
    bool? isDiscovered,
    Timestamp? firstCheckinAt,
    Timestamp? lastCheckinAt,
    Timestamp? updatedAt,
  }) {
    return JourneyProvinceProgress(
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      checkinCount: checkinCount ?? this.checkinCount,
      uniquePlacesCount: uniquePlacesCount ?? this.uniquePlacesCount,
      districtsCount: districtsCount ?? this.districtsCount,
      totalPoints: totalPoints ?? this.totalPoints,
      isDiscovered: isDiscovered ?? this.isDiscovered,
      firstCheckinAt: firstCheckinAt ?? this.firstCheckinAt,
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Timestamp? _toTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }
}
