import 'package:cloud_firestore/cloud_firestore.dart';

import 'journey_schema.dart';

class JourneyCheckin {
  const JourneyCheckin({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.provinceCode,
    required this.provinceName,
    required this.userLat,
    required this.userLng,
    required this.placeLat,
    required this.placeLng,
    required this.distanceMeters,
    required this.pointsEarned,
    this.placeImageUrl,
    this.districtName,
    this.placeType = 'restaurant',
    this.verificationType = 'gps',
    this.photoUrl,
    this.isNewPlace = false,
    this.isNewProvince = false,
    this.source = 'gps',
    this.status = 'active',
    this.createdAt,
  });

  final String id;

  final String placeId;
  final String placeName;
  final String placeAddress;

  final String provinceCode;
  final String provinceName;

  final double userLat;
  final double userLng;
  final double placeLat;
  final double placeLng;
  final double distanceMeters;

  final int pointsEarned;

  final String? placeImageUrl;
  final String? districtName;

  /// restaurant, cafe, street_food...
  final String placeType;

  /// gps, gps_photo
  final String verificationType;

  /// Ảnh user chụp khi check-in, nếu có.
  final String? photoUrl;

  final bool isNewPlace;
  final bool isNewProvince;

  /// gps, manual_search, nearby_suggest...
  final String source;

  /// active, deleted, rejected
  final String status;

  final Timestamp? createdAt;

  factory JourneyCheckin.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return JourneyCheckin.fromMap(doc.data(), id: doc.id);
  }

  factory JourneyCheckin.fromMap(
    Map<String, dynamic>? map, {
    String? id,
  }) {
    final data = map ?? const <String, dynamic>{};

    return JourneyCheckin(
      id: id ?? (data[JourneyCheckinFields.id] ?? '').toString(),
      placeId: (data[JourneyCheckinFields.placeId] ?? '').toString(),
      placeName: (data[JourneyCheckinFields.placeName] ?? '').toString(),
      placeAddress: (data[JourneyCheckinFields.placeAddress] ?? '').toString(),
      provinceCode: (data[JourneyCheckinFields.provinceCode] ?? '').toString(),
      provinceName: (data[JourneyCheckinFields.provinceName] ?? '').toString(),
      userLat: _toDouble(data[JourneyCheckinFields.userLat]),
      userLng: _toDouble(data[JourneyCheckinFields.userLng]),
      placeLat: _toDouble(data[JourneyCheckinFields.placeLat]),
      placeLng: _toDouble(data[JourneyCheckinFields.placeLng]),
      distanceMeters: _toDouble(data[JourneyCheckinFields.distanceMeters]),
      pointsEarned: _toInt(data[JourneyCheckinFields.pointsEarned]),
      placeImageUrl: _toNullableString(data[JourneyCheckinFields.placeImageUrl]),
      districtName: _toNullableString(data[JourneyCheckinFields.districtName]),
      placeType: (data[JourneyCheckinFields.placeType] ?? 'restaurant').toString(),
      verificationType:
          (data[JourneyCheckinFields.verificationType] ?? 'gps').toString(),
      photoUrl: _toNullableString(data[JourneyCheckinFields.photoUrl]),
      isNewPlace: data[JourneyCheckinFields.isNewPlace] == true,
      isNewProvince: data[JourneyCheckinFields.isNewProvince] == true,
      source: (data[JourneyCheckinFields.source] ?? 'gps').toString(),
      status: (data[JourneyCheckinFields.status] ?? 'active').toString(),
      createdAt: _toTimestamp(data[JourneyCheckinFields.createdAt]),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      JourneyCheckinFields.placeId: placeId,
      JourneyCheckinFields.placeName: placeName,
      JourneyCheckinFields.placeAddress: placeAddress,
      JourneyCheckinFields.provinceCode: provinceCode,
      JourneyCheckinFields.provinceName: provinceName,
      JourneyCheckinFields.userLat: userLat,
      JourneyCheckinFields.userLng: userLng,
      JourneyCheckinFields.placeLat: placeLat,
      JourneyCheckinFields.placeLng: placeLng,
      JourneyCheckinFields.distanceMeters: distanceMeters,
      JourneyCheckinFields.pointsEarned: pointsEarned,
      JourneyCheckinFields.placeImageUrl: placeImageUrl,
      JourneyCheckinFields.districtName: districtName,
      JourneyCheckinFields.placeType: placeType,
      JourneyCheckinFields.verificationType: verificationType,
      JourneyCheckinFields.photoUrl: photoUrl,
      JourneyCheckinFields.isNewPlace: isNewPlace,
      JourneyCheckinFields.isNewProvince: isNewProvince,
      JourneyCheckinFields.source: source,
      JourneyCheckinFields.status: status,
      JourneyCheckinFields.createdAt: createdAt,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  JourneyCheckin copyWith({
    String? id,
    String? placeId,
    String? placeName,
    String? placeAddress,
    String? provinceCode,
    String? provinceName,
    double? userLat,
    double? userLng,
    double? placeLat,
    double? placeLng,
    double? distanceMeters,
    int? pointsEarned,
    String? placeImageUrl,
    String? districtName,
    String? placeType,
    String? verificationType,
    String? photoUrl,
    bool? isNewPlace,
    bool? isNewProvince,
    String? source,
    String? status,
    Timestamp? createdAt,
  }) {
    return JourneyCheckin(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      placeLat: placeLat ?? this.placeLat,
      placeLng: placeLng ?? this.placeLng,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      placeImageUrl: placeImageUrl ?? this.placeImageUrl,
      districtName: districtName ?? this.districtName,
      placeType: placeType ?? this.placeType,
      verificationType: verificationType ?? this.verificationType,
      photoUrl: photoUrl ?? this.photoUrl,
      isNewPlace: isNewPlace ?? this.isNewPlace,
      isNewProvince: isNewProvince ?? this.isNewProvince,
      source: source ?? this.source,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
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

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return text;
  }
}
