import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FoodG Travel'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @personalMembership.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get personalMembership;

  /// No description provided for @personalStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get personalStore;

  /// No description provided for @personalHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get personalHome;

  /// No description provided for @personalGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get personalGuests;

  /// No description provided for @personalStatus.
  ///
  /// In en, this message translates to:
  /// **'My status'**
  String get personalStatus;

  /// No description provided for @personalChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get personalChangePassword;

  /// No description provided for @personalLanguage.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get personalLanguage;

  /// No description provided for @personalFreeWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Free withdrawal'**
  String get personalFreeWithdraw;

  /// No description provided for @signInToViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your profile.'**
  String get signInToViewProfile;

  /// No description provided for @personalSurvey.
  ///
  /// In en, this message translates to:
  /// **'Survey Form'**
  String get personalSurvey;

  /// No description provided for @surveyTitle.
  ///
  /// In en, this message translates to:
  /// **'Food preferences'**
  String get surveyTitle;

  /// No description provided for @surveyProvinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Province/City'**
  String get surveyProvinceLabel;

  /// No description provided for @surveyProvinceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your province'**
  String get surveyProvinceRequired;

  /// No description provided for @surveySpicyLevel.
  ///
  /// In en, this message translates to:
  /// **'Spicy level'**
  String get surveySpicyLevel;

  /// No description provided for @surveyFavoritesLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite foods (comma separated)'**
  String get surveyFavoritesLabel;

  /// No description provided for @surveyDislikesLabel.
  ///
  /// In en, this message translates to:
  /// **'Disliked ingredients (comma separated)'**
  String get surveyDislikesLabel;

  /// No description provided for @surveySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get surveySaveFailed;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view notifications.'**
  String get notificationsSignInRequired;

  /// No description provided for @notificationsSummaryNone.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsSummaryNone;

  /// No description provided for @notificationsSummaryUnread.
  ///
  /// In en, this message translates to:
  /// **'You have {count} unread notifications.'**
  String notificationsSummaryUnread(Object count);

  /// No description provided for @notificationsTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsTodayLabel;

  /// No description provided for @notificationTypeLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get notificationTypeLike;

  /// No description provided for @notificationTypeComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get notificationTypeComment;

  /// No description provided for @notificationLikeTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} liked your post'**
  String notificationLikeTitle(Object name);

  /// No description provided for @notificationCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} commented on your post'**
  String notificationCommentTitle(Object name);

  /// No description provided for @notificationMissingPost.
  ///
  /// In en, this message translates to:
  /// **'Post not found.'**
  String get notificationMissingPost;

  /// No description provided for @postDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postDetailTitle;

  /// No description provided for @postDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load post.'**
  String get postDetailLoadError;

  /// No description provided for @postDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post no longer exists.'**
  String get postDetailNotFound;

  /// No description provided for @actionLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get actionLike;

  /// No description provided for @actionComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get actionComment;

  /// No description provided for @commonUserFallback.
  ///
  /// In en, this message translates to:
  /// **'FoodG User'**
  String get commonUserFallback;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String timeMinutesAgo(Object count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String timeHoursAgo(Object count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String timeDaysAgo(Object count);

  /// No description provided for @timeOnDate.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String timeOnDate(Object date);

  /// No description provided for @homeProvinceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get homeProvinceUnknown;

  /// No description provided for @homeLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'You are in'**
  String get homeLocationLabel;

  /// No description provided for @homeLocationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Where are you now?'**
  String get homeLocationPrompt;

  /// No description provided for @homeProvincePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose province'**
  String get homeProvincePickerTitle;

  /// No description provided for @homeProvincePickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search province... (e.g., Ha Noi, DN, ...)'**
  String get homeProvincePickerSearchHint;

  /// No description provided for @homeProvinceNotFound.
  ///
  /// In en, this message translates to:
  /// **'No matching province found.'**
  String get homeProvinceNotFound;

  /// No description provided for @homeProvinceSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get homeProvinceSelected;

  /// No description provided for @homeMonthlyDestinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Destination of month {month}'**
  String homeMonthlyDestinationTitle(Object month);

  /// No description provided for @homeTodaySuggestionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load today\'s suggestions.'**
  String get homeTodaySuggestionError;

  /// No description provided for @homeProvinceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load province list.'**
  String get homeProvinceLoadError;

  /// No description provided for @homeProvinceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No provinces available.'**
  String get homeProvinceEmpty;

  /// No description provided for @homeProvinceNoImage.
  ///
  /// In en, this message translates to:
  /// **'No images for this province.'**
  String get homeProvinceNoImage;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search dishes, ingredients...'**
  String get homeSearchHint;

  /// No description provided for @homeSelectProvinceToSeeDishes.
  ///
  /// In en, this message translates to:
  /// **'Select a province to see dishes.'**
  String get homeSelectProvinceToSeeDishes;

  /// No description provided for @homeDishListLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dishes.'**
  String get homeDishListLoadError;

  /// No description provided for @homeDishNotFound.
  ///
  /// In en, this message translates to:
  /// **'No matching dishes found.'**
  String get homeDishNotFound;

  /// No description provided for @homeSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Must-try specialties'**
  String get homeSpecialtiesTitle;

  /// No description provided for @homeSpecialtiesCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get homeSpecialtiesCollapse;

  /// No description provided for @homeSpecialtiesSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSpecialtiesSeeAll;

  /// No description provided for @homeNearbyQuery.
  ///
  /// In en, this message translates to:
  /// **'restaurants'**
  String get homeNearbyQuery;

  /// No description provided for @homeNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get homeNearbyTitle;

  /// No description provided for @homeNearbyViewMap.
  ///
  /// In en, this message translates to:
  /// **'View map >>'**
  String get homeNearbyViewMap;

  /// No description provided for @homeNearbyEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see nearby places.'**
  String get homeNearbyEnableLocation;

  /// No description provided for @homeNearbyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data.'**
  String get homeNearbyLoadError;

  /// No description provided for @homeNearbyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching places found.'**
  String get homeNearbyEmpty;

  /// No description provided for @homeOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get homeOpenNow;

  /// No description provided for @homeClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get homeClosed;

  /// No description provided for @homeTodayEatTitle.
  ///
  /// In en, this message translates to:
  /// **'What to eat today?'**
  String get homeTodayEatTitle;

  /// No description provided for @homeTodayRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get homeTodayRefresh;

  /// No description provided for @homeDishFallback.
  ///
  /// In en, this message translates to:
  /// **'Dish'**
  String get homeDishFallback;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
