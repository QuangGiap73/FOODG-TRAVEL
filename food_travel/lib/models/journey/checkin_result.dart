class JourneyCheckinResult {
  const JourneyCheckinResult({
    required this.success,
    required this.checkinId,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.provinceCode,
    required this.provinceName,
    required this.distanceMeters,
    required this.pointsEarned,
    required this.totalPoints,
    required this.level,
    required this.currentStreak,
    required this.totalCheckins,
    required this.longestStreak,
    required this.uniquePlacesCount,
    required this.uniqueProvincesCount,
    required this.isNewPlace,
    required this.isNewProvince,
    required this.source,
    required this.verificationType,
  });
  final bool success;
  // thong tin checkin vua tao
   // Thong tin check-in vua tao
  final String checkinId;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final String provinceCode;
  final String provinceName;

  // Khoang cach tu user den quan
  final double distanceMeters;

  // Thuong tra ve tu server
  final int pointsEarned;
  final int totalPoints;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalCheckins;
  final int uniquePlacesCount;
  final int uniqueProvincesCount;

  // Co phai place moi / tinh moi khong
  final bool isNewPlace;
  final bool isNewProvince;

  // Nguon check-in va kieu xac thuc
  final String source;
  final String verificationType;

  factory JourneyCheckinResult.fromMap(Map<String, dynamic> map) {
    return JourneyCheckinResult(
      success: map['success'] == true,
      checkinId: (map['checkinId'] ?? '').toString(),
      placeId: (map['placeId'] ?? '').toString(),
      placeName: (map['placeName'] ?? '').toString(),
      placeAddress: (map['placeAddress'] ?? '').toString(),
      provinceCode: (map['provinceCode'] ?? '').toString(),
      provinceName: (map['provinceName'] ?? '').toString(),
      distanceMeters: _toDouble(map['distanceMeters']),
      pointsEarned: _toInt(map['pointsEarned']),
      totalPoints: _toInt(map['totalPoints']),
      level: _toInt(map['level'], fallback: 1),
      currentStreak: _toInt(map['currentStreak']),
      longestStreak: _toInt(map['longestStreak']),
      totalCheckins: _toInt(map['totalCheckins']),
      uniquePlacesCount: _toInt(map['uniquePlacesCount']),
      uniqueProvincesCount: _toInt(map['uniqueProvincesCount']),
      isNewPlace: map['isNewPlace'] == true,
      isNewProvince: map['isNewProvince'] == true,
      source: (map['source'] ?? 'gps').toString(),
      verificationType: (map['verificationType'] ?? 'gps').toString(),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}