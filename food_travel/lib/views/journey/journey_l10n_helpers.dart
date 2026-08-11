import '../../l10n/app_localizations.dart';
import '../../models/journey/mission_model.dart';

String journeyMissionTitle(AppLocalizations t, JourneyMission mission) {
  switch (_journeyMissionKey(mission)) {
    case 'checkin_new_place':
      return t.journeyMissionCheckinNewPlaceTitle;
    case 'try_vietnamese_food':
      return t.journeyMissionTryVietnameseFoodTitle;
    case 'save_wishlist_place':
      return t.journeyMissionSaveWishlistPlaceTitle;
    case 'checkin_high_rating_place':
      return t.journeyMissionHighRatingPlaceTitle;
    case 'unlock_new_province':
      return t.journeyMissionUnlockProvinceTitle;
    default:
      return mission.title;
  }
}

String journeyMissionDescription(AppLocalizations t, JourneyMission mission) {
  switch (_journeyMissionKey(mission)) {
    case 'checkin_new_place':
      return t.journeyMissionCheckinNewPlaceDescription;
    case 'try_vietnamese_food':
      return t.journeyMissionTryVietnameseFoodDescription;
    case 'save_wishlist_place':
      return t.journeyMissionSaveWishlistPlaceDescription;
    case 'checkin_high_rating_place':
      return t.journeyMissionHighRatingPlaceDescription;
    case 'unlock_new_province':
      return t.journeyMissionUnlockProvinceDescription;
    default:
      return mission.description;
  }
}

String _journeyMissionKey(JourneyMission mission) {
  const supportedKeys = {
    'checkin_new_place',
    'try_vietnamese_food',
    'save_wishlist_place',
    'checkin_high_rating_place',
    'unlock_new_province',
  };
  final type = mission.type.trim().toLowerCase();
  if (supportedKeys.contains(type)) return type;

  // Một số document cũ chưa lưu field `type`, nhưng document id vẫn là mã
  // nhiệm vụ chuẩn. Dùng id làm fallback để chuỗi Firestore không lọt ra UI.
  final id = mission.id.trim().toLowerCase();
  return supportedKeys.contains(id) ? id : type;
}

String journeyBadgeTitle(
  String languageCode,
  String badgeId, {
  required String fallback,
}) {
  final texts = languageCode == 'vi' ? _badgeTitlesVi : _badgeTitlesEn;
  return texts[badgeId] ?? fallback;
}

String journeyBadgeDescription(
  String languageCode,
  String badgeId, {
  required String fallback,
}) {
  final texts =
      languageCode == 'vi' ? _badgeDescriptionsVi : _badgeDescriptionsEn;
  return texts[badgeId] ?? fallback;
}

const Map<String, String> _badgeTitlesVi = {
  'first_bite': 'Miếng đầu tiên',
  'food_explorer': 'Nhà khám phá ẩm thực',
  'district_hunter': 'Thợ săn quận huyện',
  'province_explorer': 'Nhà khám phá tỉnh thành',
};

const Map<String, String> _badgeDescriptionsVi = {
  'first_bite': 'Check-in lần đầu tiên trong hành trình ẩm thực.',
  'food_explorer': 'Khám phá nhiều quán khác nhau trên hành trình.',
  'district_hunter': 'Đi qua nhiều quận huyện để mở rộng bản đồ trải nghiệm.',
  'province_explorer':
      'Mở khóa thêm các tỉnh thành mới trên bản đồ Việt Nam.',
};

const Map<String, String> _badgeTitlesEn = {
  'first_bite': 'First Bite',
  'food_explorer': 'Food Explorer',
  'district_hunter': 'District Hunter',
  'province_explorer': 'Province Explorer',
};

const Map<String, String> _badgeDescriptionsEn = {
  'first_bite': 'Complete your first check-in on the food journey.',
  'food_explorer': 'Discover different places throughout your journey.',
  'district_hunter': 'Visit multiple districts to expand your experience map.',
  'province_explorer': 'Unlock new provinces on the map of Vietnam.',
};

String journeyMissionActionText(AppLocalizations t, String type) {
  switch (type) {
    case 'checkin_new_place':
    case 'checkin_any_place':
      return t.journeyActionExploreNow;
    case 'save_wishlist_place':
      return t.journeyActionFindPlaceToSave;
    case 'try_vietnamese_food':
      return t.journeyActionFindVietnameseDish;
    default:
      return t.journeyActionStartMission;
  }
}
