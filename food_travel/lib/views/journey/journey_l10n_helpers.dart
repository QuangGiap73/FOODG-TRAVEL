import '../../l10n/app_localizations.dart';
import '../../models/journey/mission_model.dart';

String journeyMissionTitle(AppLocalizations t, JourneyMission mission) {
  switch (_journeyMissionKey(mission)) {
    case 'favorite_any_place':
      return _missionText(
        t,
        vi: 'Lưu 1 quán yêu thích',
        en: 'Save 1 favorite place',
      );
    case 'first_checkin_before_9am':
      return _missionText(
        t,
        vi: 'Check-in đầu ngày trước 9 giờ',
        en: 'Check in before 9 AM',
      );
    case 'evening_checkin_after_18h':
      return _missionText(
        t,
        vi: 'Check-in buổi tối sau 18 giờ',
        en: 'Check in after 6 PM',
      );
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
    case 'earn_30_points_in_day':
      return _missionText(
        t,
        vi: 'Tích lũy 30 điểm trong ngày',
        en: 'Earn 30 points today',
      );
    case 'revisit_a_place':
      return _missionText(
        t,
        vi: 'Quay lại quán đã từng check-in',
        en: 'Revisit a checked-in place',
      );
    default:
      return mission.title;
  }
}

String journeyMissionDescription(AppLocalizations t, JourneyMission mission) {
  switch (_journeyMissionKey(mission)) {
    case 'favorite_any_place':
      return _missionText(
        t,
        vi: 'Đánh dấu yêu thích một quán ăn bất kỳ.',
        en: 'Add any restaurant to your favorites.',
      );
    case 'first_checkin_before_9am':
      return _missionText(
        t,
        vi: 'Hoàn thành lượt check-in đầu tiên trước 9 giờ sáng.',
        en: 'Complete your first check-in before 9 AM.',
      );
    case 'evening_checkin_after_18h':
      return _missionText(
        t,
        vi: 'Ghé quán và check-in sau 18 giờ.',
        en: 'Visit a restaurant and check in after 6 PM.',
      );
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
    case 'earn_30_points_in_day':
      return _missionText(
        t,
        vi: 'Kiếm tổng cộng ít nhất 30 điểm check-in trong hôm nay.',
        en: 'Earn at least 30 check-in points today.',
      );
    case 'revisit_a_place':
      return _missionText(
        t,
        vi: 'Check-in lại một quán bạn đã ghé trước đó.',
        en: 'Check in again at a place you previously visited.',
      );
    default:
      return mission.description;
  }
}

String _journeyMissionKey(JourneyMission mission) {
  const supportedKeys = {
    'favorite_any_place',
    'first_checkin_before_9am',
    'evening_checkin_after_18h',
    'checkin_new_place',
    'try_vietnamese_food',
    'save_wishlist_place',
    'checkin_high_rating_place',
    'unlock_new_province',
    'earn_30_points_in_day',
    'revisit_a_place',
  };
  final type = mission.type.trim().toLowerCase();
  if (supportedKeys.contains(type)) return type;

  // Một số document cũ chưa lưu field `type`, nhưng document id vẫn là mã
  // nhiệm vụ chuẩn. Dùng id làm fallback để chuỗi Firestore không lọt ra UI.
  final id = mission.id.trim().toLowerCase();
  return supportedKeys.contains(id) ? id : type;
}

String _missionText(
  AppLocalizations t, {
  required String vi,
  required String en,
}) {
  return t.localeName.toLowerCase().startsWith('vi') ? vi : en;
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
  'province_explorer': 'Mở khóa thêm các tỉnh thành mới trên bản đồ Việt Nam.',
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
