import '../../l10n/app_localizations.dart';
import '../../models/journey/mission_model.dart';

String journeyMissionTitle(AppLocalizations t, JourneyMission mission) {
  switch (mission.type) {
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
  switch (mission.type) {
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
