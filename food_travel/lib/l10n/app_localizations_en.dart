// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FoodG Travel';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get english => 'English';

  @override
  String get save => 'Save';

  @override
  String get personalMembership => 'My posts';

  @override
  String get personalStore => 'Store';

  @override
  String get personalHome => 'Home';

  @override
  String get personalGuests => 'Guests';

  @override
  String get personalStatus => 'My status';

  @override
  String get personalChangePassword => 'Change password';

  @override
  String get personalLanguage => 'Languages';

  @override
  String get personalFreeWithdraw => 'Free withdrawal';

  @override
  String get signInToViewProfile => 'Please sign in to view your profile.';

  @override
  String get personalSurvey => 'Survey Form';

  @override
  String get surveyTitle => 'Food preferences';

  @override
  String get surveyProvinceLabel => 'Province/City';

  @override
  String get surveyProvinceRequired => 'Please enter your province';

  @override
  String get surveySpicyLevel => 'Spicy level';

  @override
  String get surveyFavoritesLabel => 'Favorite foods (comma separated)';

  @override
  String get surveyDislikesLabel => 'Disliked ingredients (comma separated)';

  @override
  String get surveySaveFailed => 'Save failed';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsLoadError => 'Unable to load notifications.';

  @override
  String get notificationsSignInRequired =>
      'Please sign in to view notifications.';

  @override
  String get notificationsSummaryNone => 'You\'re all caught up.';

  @override
  String notificationsSummaryUnread(Object count) {
    return 'You have $count unread notifications.';
  }

  @override
  String get notificationsTodayLabel => 'Today';

  @override
  String get notificationTypeLike => 'Like';

  @override
  String get notificationTypeComment => 'Comment';

  @override
  String notificationLikeTitle(Object name) {
    return '$name liked your post';
  }

  @override
  String notificationCommentTitle(Object name) {
    return '$name commented on your post';
  }

  @override
  String get notificationMissingPost => 'Post not found.';

  @override
  String get postDetailTitle => 'Post';

  @override
  String get postDetailLoadError => 'Unable to load post.';

  @override
  String get postDetailNotFound => 'Post no longer exists.';

  @override
  String get actionLike => 'Like';

  @override
  String get actionComment => 'Comment';

  @override
  String get commonUserFallback => 'FoodG User';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(Object count) {
    return '$count minutes ago';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count hours ago';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String timeOnDate(Object date) {
    return 'on $date';
  }

  @override
  String get homeProvinceUnknown => 'Where are you?';

  @override
  String get homeLocationLabel => 'You are in';

  @override
  String get homeLocationPrompt => 'Where are you now?';

  @override
  String get homeProvincePickerTitle => 'Choose province';

  @override
  String get homeProvincePickerSearchHint =>
      'Search province... (e.g., Ha Noi, DN, ...)';

  @override
  String get homeProvinceNotFound => 'No matching province found.';

  @override
  String get homeProvinceSelected => 'Selected';

  @override
  String homeMonthlyDestinationTitle(Object month) {
    return 'Destination of month $month';
  }

  @override
  String get homeTodaySuggestionError => 'Unable to load today\'s suggestions.';

  @override
  String get homeProvinceLoadError => 'Unable to load province list.';

  @override
  String get homeProvinceEmpty => 'No provinces available.';

  @override
  String get homeProvinceNoImage => 'No images for this province.';

  @override
  String get homeSearchHint => 'Search dishes, ingredients...';

  @override
  String get homeSelectProvinceToSeeDishes =>
      'Select a province to see dishes.';

  @override
  String get homeDishListLoadError => 'Unable to load dishes.';

  @override
  String get homeDishNotFound => 'No matching dishes found.';

  @override
  String get homeSpecialtiesTitle => 'Must-try specialties';

  @override
  String get homeSpecialtiesCollapse => 'Collapse';

  @override
  String get homeSpecialtiesSeeAll => 'See all';

  @override
  String get homeNearbyQuery => 'restaurants';

  @override
  String get homeNearbyTitle => 'Nearby places';

  @override
  String get homeNearbyViewMap => 'View map >>';

  @override
  String get homeNearbyEnableLocation =>
      'Enable location to see nearby places.';

  @override
  String get homeNearbyLoadError => 'Unable to load data.';

  @override
  String get homeNearbyEmpty => 'No matching places found.';

  @override
  String get homeOpenNow => 'Open';

  @override
  String get homeClosed => 'Closed';

  @override
  String get homeTodayEatTitle => 'What to eat today?';

  @override
  String get homeTodayRefresh => 'Refresh';

  @override
  String get homeDishFallback => 'Dish';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navMap => 'Map';

  @override
  String get navSaved => 'Saved';

  @override
  String get navProfile => 'Profile';
}
