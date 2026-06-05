/// Shared Firestore schema for the Food Journey feature.
///
/// Keep these names stable so both Flutter and Cloud Functions use the same
/// collection / field contract.
abstract class JourneyCollections {
  static const String journeyRoot = 'journey';
  static const String summary = 'summary';
  static const String checkins = 'checkins';
  static const String provinces = 'provinces';
  static const String badges = 'badges';
  static const String missions = 'missions';

  const JourneyCollections._();
}

/// Firestore path pattern used by Journey:
/// users/{uid}/journey/summary
/// users/{uid}/journey/summary/checkins/{checkinId}
/// users/{uid}/journey/summary/provinces/{provinceCode}
/// users/{uid}/journey/summary/badges/{badgeId}
/// users/{uid}/journey/summary/missions/{missionId}
abstract class JourneyDocumentIds {
  static const String summary = 'summary';

  const JourneyDocumentIds._();
}

abstract class JourneyStatsFields {
  static const String totalPoints = 'totalPoints';
  static const String level = 'level';
  static const String currentStreak = 'currentStreak';
  static const String longestStreak = 'longestStreak';
  static const String totalCheckins = 'totalCheckins';
  static const String uniquePlacesCount = 'uniquePlacesCount';
  static const String uniqueProvincesCount = 'uniqueProvincesCount';
  static const String lastActiveDate = 'lastActiveDate';
  static const String lastActiveAt = 'lastActiveAt';
  static const String lastCheckinAt = 'lastCheckinAt';
  static const String updatedAt = 'updatedAt';

  const JourneyStatsFields._();
}

abstract class JourneyCheckinFields {
  static const String id = 'id';
  static const String placeId = 'placeId';
  static const String placeName = 'placeName';
  static const String placeAddress = 'placeAddress';
  static const String provinceCode = 'provinceCode';
  static const String provinceName = 'provinceName';
  static const String userLat = 'userLat';
  static const String userLng = 'userLng';
  static const String placeLat = 'placeLat';
  static const String placeLng = 'placeLng';
  static const String distanceMeters = 'distanceMeters';
  static const String pointsEarned = 'pointsEarned';
  static const String placeImageUrl = 'placeImageUrl';
  static const String districtName = 'districtName';
  static const String placeType = 'placeType';
  static const String verificationType = 'verificationType';
  static const String photoUrl = 'photoUrl';
  static const String isNewPlace = 'isNewPlace';
  static const String isNewProvince = 'isNewProvince';
  static const String source = 'source';
  static const String status = 'status';
  static const String createdAt = 'createdAt';

  const JourneyCheckinFields._();
}

abstract class JourneyProvinceFields {
  static const String provinceCode = 'provinceCode';
  static const String provinceName = 'provinceName';
  static const String checkinCount = 'checkinCount';
  static const String uniquePlacesCount = 'uniquePlacesCount';
  static const String districtsCount = 'districtsCount';
  static const String totalPoints = 'totalPoints';
  static const String isDiscovered = 'isDiscovered';
  static const String firstCheckinAt = 'firstCheckinAt';
  static const String lastCheckinAt = 'lastCheckinAt';
  static const String updatedAt = 'updatedAt';

  const JourneyProvinceFields._();
}

abstract class JourneyBadgeFields {
  static const String badgeId = 'badgeId';
  static const String title = 'title';
  static const String description = 'description';
  static const String iconKey = 'iconKey';
  static const String progress = 'progress';
  static const String currentValue = 'currentValue';
  static const String targetValue = 'targetValue';
  static const String unlockedAt = 'unlockedAt';
  static const String updatedAt = 'updatedAt';

  const JourneyBadgeFields._();
}

abstract class JourneyMissionFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String description = 'description';
  static const String type = 'type';
  static const String targetCount = 'targetCount';
  static const String currentCount = 'currentCount';
  static const String rewardPoints = 'rewardPoints';
  static const String iconKey = 'iconKey';
  static const String date = 'date';
  static const String isCompleted = 'isCompleted';
  static const String isClaimed = 'isClaimed';
  static const String createdAt = 'createdAt';
  static const String completedAt = 'completedAt';
  static const String claimedAt = 'claimedAt';
  static const String dueAt = 'dueAt';
  static const String updatedAt = 'updatedAt';

  const JourneyMissionFields._();
}
