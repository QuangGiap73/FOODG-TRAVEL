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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get commonSeeMore;

  /// No description provided for @commonCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get commonCollapse;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get commonUpdating;

  /// No description provided for @noticeSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get noticeSuccessTitle;

  /// No description provided for @noticePostCreated.
  ///
  /// In en, this message translates to:
  /// **'Post published successfully.'**
  String get noticePostCreated;

  /// No description provided for @noticePostUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated successfully.'**
  String get noticePostUpdated;

  /// No description provided for @noticePostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted.'**
  String get noticePostDeleted;

  /// No description provided for @commentTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentTitle;

  /// No description provided for @commentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get commentEmpty;

  /// No description provided for @commentLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to comment.'**
  String get commentLoginRequired;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get commentHint;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communityTabNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get communityTabNewest;

  /// No description provided for @communityTabTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get communityTabTrending;

  /// No description provided for @communityTabNear.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get communityTabNear;

  /// No description provided for @communityTabProvince.
  ///
  /// In en, this message translates to:
  /// **'By province'**
  String get communityTabProvince;

  /// No description provided for @communityPostButton.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get communityPostButton;

  /// No description provided for @communityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load posts.'**
  String get communityLoadError;

  /// No description provided for @communityEmptyNewest.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get communityEmptyNewest;

  /// No description provided for @communityEmptyTrending.
  ///
  /// In en, this message translates to:
  /// **'No trending posts yet.'**
  String get communityEmptyTrending;

  /// No description provided for @communityEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS to see nearby posts.'**
  String get communityEnableGps;

  /// No description provided for @communityGpsLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get communityGpsLoading;

  /// No description provided for @communityEnableGpsButton.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS'**
  String get communityEnableGpsButton;

  /// No description provided for @communityEmptyNear.
  ///
  /// In en, this message translates to:
  /// **'No nearby posts found.'**
  String get communityEmptyNear;

  /// No description provided for @communitySelectProvince.
  ///
  /// In en, this message translates to:
  /// **'Select a province'**
  String get communitySelectProvince;

  /// No description provided for @communityChangeProvince.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get communityChangeProvince;

  /// No description provided for @communitySelectProvinceHint.
  ///
  /// In en, this message translates to:
  /// **'Search province...'**
  String get communitySelectProvinceHint;

  /// No description provided for @communityEmptyProvince.
  ///
  /// In en, this message translates to:
  /// **'No posts for this province.'**
  String get communityEmptyProvince;

  /// No description provided for @communityProvinceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No provinces available.'**
  String get communityProvinceListEmpty;

  /// No description provided for @communityDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get communityDeleteTitle;

  /// No description provided for @communityDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get communityDeleteConfirm;

  /// No description provided for @communityMyPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get communityMyPostsTitle;

  /// No description provided for @communityMyPostsLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your posts.'**
  String get communityMyPostsLoginRequired;

  /// No description provided for @communityMyPostsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your posts.'**
  String get communityMyPostsLoadError;

  /// No description provided for @communityMyPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted yet.'**
  String get communityMyPostsEmpty;

  /// No description provided for @communityPostEmptyContent.
  ///
  /// In en, this message translates to:
  /// **'Post content is empty.'**
  String get communityPostEmptyContent;

  /// No description provided for @postPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get postPickFromGallery;

  /// No description provided for @postPickFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get postPickFromCamera;

  /// No description provided for @postCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get postCreateTitle;

  /// No description provided for @postEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get postEditTitle;

  /// No description provided for @postPublish.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postPublish;

  /// No description provided for @postTextHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get postTextHint;

  /// No description provided for @postUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get postUploading;

  /// No description provided for @postAddPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get postAddPlace;

  /// No description provided for @postPlaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search place...'**
  String get postPlaceSearchHint;

  /// No description provided for @postPlaceSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search.'**
  String get postPlaceSearchPrompt;

  /// No description provided for @postPlaceSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No places found.'**
  String get postPlaceSearchEmpty;

  /// No description provided for @postPlaceSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Try again.'**
  String get postPlaceSearchError;

  /// No description provided for @postPlaceFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby place'**
  String get postPlaceFallbackTitle;

  /// No description provided for @postPlaceFallbackAddress.
  ///
  /// In en, this message translates to:
  /// **'Address updating'**
  String get postPlaceFallbackAddress;

  /// No description provided for @postSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Post failed: {error}'**
  String postSubmitFailed(Object error);

  /// No description provided for @reviewSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String reviewSectionTitle(Object count);

  /// No description provided for @reviewWriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get reviewWriteTitle;

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get reviewEmpty;

  /// No description provided for @reviewDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete review'**
  String get reviewDeleteTitle;

  /// No description provided for @reviewDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this review?'**
  String get reviewDeleteConfirm;

  /// No description provided for @reviewDinedHere.
  ///
  /// In en, this message translates to:
  /// **'Dined here'**
  String get reviewDinedHere;

  /// No description provided for @reviewDinedHereWithDate.
  ///
  /// In en, this message translates to:
  /// **'{date} - Dined here'**
  String reviewDinedHereWithDate(Object date);

  /// No description provided for @reviewFromUserWithDate.
  ///
  /// In en, this message translates to:
  /// **'{date} - User review'**
  String reviewFromUserWithDate(Object date);

  /// No description provided for @favoritesLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view favorites.'**
  String get favoritesLoginRequired;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get favoritesTitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All your favorites'**
  String get favoritesSubtitle;

  /// No description provided for @favoritesTabDishes.
  ///
  /// In en, this message translates to:
  /// **'Dishes'**
  String get favoritesTabDishes;

  /// No description provided for @favoritesTabPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get favoritesTabPlaces;

  /// No description provided for @favoritesFilterCentral.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get favoritesFilterCentral;

  /// No description provided for @favoritesFilterSpicy.
  ///
  /// In en, this message translates to:
  /// **'Spicy'**
  String get favoritesFilterSpicy;

  /// No description provided for @favoritesFilterBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get favoritesFilterBudget;

  /// No description provided for @favoritesFilterBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get favoritesFilterBreakfast;

  /// No description provided for @favoritesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load favorites.'**
  String get favoritesLoadError;

  /// No description provided for @favoritePlacesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load saved places.'**
  String get favoritePlacesLoadError;

  /// No description provided for @favoritePlacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet.'**
  String get favoritePlacesEmpty;

  /// No description provided for @favoritePlaceCategoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Local cuisine'**
  String get favoritePlaceCategoryFallback;

  /// No description provided for @favoritePlaceNoRating.
  ///
  /// In en, this message translates to:
  /// **'No rating'**
  String get favoritePlaceNoRating;

  /// No description provided for @favoritePlaceAddressFallback.
  ///
  /// In en, this message translates to:
  /// **'Address updating'**
  String get favoritePlaceAddressFallback;

  /// No description provided for @favoriteDishesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load saved dishes.'**
  String get favoriteDishesLoadError;

  /// No description provided for @favoriteDishesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved dishes yet.'**
  String get favoriteDishesEmpty;

  /// No description provided for @favoriteSpicyNone.
  ///
  /// In en, this message translates to:
  /// **'Not spicy'**
  String get favoriteSpicyNone;

  /// No description provided for @favoriteSpicyLevel.
  ///
  /// In en, this message translates to:
  /// **'Spicy level {count}'**
  String favoriteSpicyLevel(Object count);

  /// No description provided for @favoriteProvinceUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating province...'**
  String get favoriteProvinceUpdating;

  /// No description provided for @regionNorth.
  ///
  /// In en, this message translates to:
  /// **'Northern'**
  String get regionNorth;

  /// No description provided for @regionCentral.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get regionCentral;

  /// No description provided for @regionSouth.
  ///
  /// In en, this message translates to:
  /// **'Southern'**
  String get regionSouth;

  /// No description provided for @placeNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeNameFallback;

  /// No description provided for @placeAddressUpdating.
  ///
  /// In en, this message translates to:
  /// **'Address updating'**
  String get placeAddressUpdating;

  /// No description provided for @placeNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get placeNoPhone;

  /// No description provided for @placeCallNow.
  ///
  /// In en, this message translates to:
  /// **'Call now'**
  String get placeCallNow;

  /// No description provided for @placeCallAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get placeCallAction;

  /// No description provided for @placeReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get placeReserve;

  /// No description provided for @placeInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get placeInvite;

  /// No description provided for @placeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get placeSchedule;

  /// No description provided for @placePricePerPerson.
  ///
  /// In en, this message translates to:
  /// **'/person'**
  String get placePricePerPerson;

  /// No description provided for @placeDistanceUpdating.
  ///
  /// In en, this message translates to:
  /// **'Distance updating'**
  String get placeDistanceUpdating;

  /// No description provided for @placeDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String placeDistanceAway(Object distance);

  /// No description provided for @placeOpenHoursUpdating.
  ///
  /// In en, this message translates to:
  /// **'Hours updating'**
  String get placeOpenHoursUpdating;

  /// No description provided for @placeClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes at {time}'**
  String placeClosesAt(Object time);

  /// No description provided for @placeCategoryFallback.
  ///
  /// In en, this message translates to:
  /// **'Local cuisine'**
  String get placeCategoryFallback;

  /// No description provided for @placeNoRating.
  ///
  /// In en, this message translates to:
  /// **'No rating'**
  String get placeNoRating;

  /// No description provided for @placeMenuMustTry.
  ///
  /// In en, this message translates to:
  /// **'Must-try'**
  String get placeMenuMustTry;

  /// No description provided for @placeMenuFull.
  ///
  /// In en, this message translates to:
  /// **'Full menu'**
  String get placeMenuFull;

  /// No description provided for @placeMenuUpdating.
  ///
  /// In en, this message translates to:
  /// **'Menu updating'**
  String get placeMenuUpdating;

  /// No description provided for @placeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Place info'**
  String get placeInfoTitle;

  /// No description provided for @placeOpenHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Open hours'**
  String get placeOpenHoursLabel;

  /// No description provided for @amenityAirConditioner.
  ///
  /// In en, this message translates to:
  /// **'Air conditioner'**
  String get amenityAirConditioner;

  /// No description provided for @amenityBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get amenityBankTransfer;

  /// No description provided for @amenityFreeParking.
  ///
  /// In en, this message translates to:
  /// **'Free parking'**
  String get amenityFreeParking;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search place...'**
  String get mapSearchHint;

  /// No description provided for @mapCategoryRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get mapCategoryRestaurants;

  /// No description provided for @mapCategoryCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get mapCategoryCafe;

  /// No description provided for @mapCategorySnack.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get mapCategorySnack;

  /// No description provided for @mapCategoryFastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast food'**
  String get mapCategoryFastFood;

  /// No description provided for @mapCategorySeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get mapCategorySeafood;

  /// No description provided for @mapStyleNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get mapStyleNormal;

  /// No description provided for @mapStyleHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get mapStyleHighlight;

  /// No description provided for @mapStyleSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapStyleSatellite;

  /// No description provided for @mapEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enable location.'**
  String get mapEnableLocation;

  /// No description provided for @mapLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available yet.'**
  String get mapLocationUnavailable;

  /// No description provided for @mapPlaceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Place not found.'**
  String get mapPlaceNotFound;

  /// No description provided for @mapEnableGpsToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS to search nearby.'**
  String get mapEnableGpsToSearch;

  /// No description provided for @mapPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get mapPermissionDenied;

  /// No description provided for @mapGpsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid GPS location.'**
  String get mapGpsInvalid;

  /// No description provided for @mapNearbyNotFound.
  ///
  /// In en, this message translates to:
  /// **'No nearby places found.'**
  String get mapNearbyNotFound;

  /// No description provided for @mapLocationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Location request timed out.'**
  String get mapLocationTimeout;

  /// No description provided for @mapSearchError.
  ///
  /// In en, this message translates to:
  /// **'Search error: {error}'**
  String mapSearchError(Object error);

  /// No description provided for @mapDirectionsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to get directions.'**
  String get mapDirectionsError;

  /// No description provided for @mapOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get mapOpenNow;

  /// No description provided for @mapClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get mapClosed;

  /// No description provided for @mapDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapDirections;

  /// No description provided for @mapNearbyPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby places ({count})'**
  String mapNearbyPlacesTitle(Object count);

  /// No description provided for @mapEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String mapEtaMinutes(Object minutes);

  /// No description provided for @mapSortDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get mapSortDistance;

  /// No description provided for @mapOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get mapOpenMap;

  /// No description provided for @mapNoCoordinates.
  ///
  /// In en, this message translates to:
  /// **'No coordinates'**
  String get mapNoCoordinates;

  /// No description provided for @mapPlaceFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Nearby place'**
  String get mapPlaceFallbackName;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get genderUnknown;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileNameLabel;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get profileNameRequired;

  /// No description provided for @profileGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGenderLabel;

  /// No description provided for @profileGenderHint.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get profileGenderHint;

  /// No description provided for @profileDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileDobLabel;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get profileAvatarTitle;

  /// No description provided for @profileAvatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get profileAvatarUploadFailed;

  /// No description provided for @personalLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get personalLocation;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logoutConfirm;

  /// No description provided for @logoutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutAction;

  /// No description provided for @themeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeSettingsTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @locationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSettingsTitle;

  /// No description provided for @locationSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable location to show on the map.'**
  String get locationSettingsDescription;

  /// No description provided for @locationEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get locationEnable;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open GPS settings'**
  String get locationOpenSettings;

  /// No description provided for @locationOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get locationOpenAppSettings;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location error.'**
  String get locationError;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter current password'**
  String get changePasswordCurrentRequired;

  /// No description provided for @changePasswordNewRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter new password'**
  String get changePasswordNewRequired;

  /// No description provided for @changePasswordNewTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get changePasswordNewTooShort;

  /// No description provided for @changePasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm new password'**
  String get changePasswordConfirmRequired;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordErrorMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get changePasswordErrorMissingFields;

  /// No description provided for @changePasswordErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get changePasswordErrorMismatch;

  /// No description provided for @changePasswordErrorTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters.'**
  String get changePasswordErrorTooShort;

  /// No description provided for @changePasswordErrorWrongCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get changePasswordErrorWrongCurrent;

  /// No description provided for @changePasswordErrorWeak.
  ///
  /// In en, this message translates to:
  /// **'New password is too weak.'**
  String get changePasswordErrorWeak;

  /// No description provided for @changePasswordErrorRequiresLogin.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again and try.'**
  String get changePasswordErrorRequiresLogin;

  /// No description provided for @changePasswordErrorNoUser.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get changePasswordErrorNoUser;

  /// No description provided for @changePasswordErrorNoPasswordProvider.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in account cannot change password.'**
  String get changePasswordErrorNoPasswordProvider;

  /// No description provided for @changePasswordErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Password change failed.'**
  String get changePasswordErrorUnknown;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your food account'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get authPasswordRequired;

  /// No description provided for @authLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginAction;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterAction;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get authLoginFailed;

  /// No description provided for @authLoginUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get authLoginUserNotFound;

  /// No description provided for @authLoginWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authLoginWrongPassword;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get authGoogleFailed;

  /// No description provided for @authGoogleAccountExists.
  ///
  /// In en, this message translates to:
  /// **'Account exists with a different sign-in method'**
  String get authGoogleAccountExists;

  /// No description provided for @authGoogleInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid Google credential'**
  String get authGoogleInvalidCredential;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String authError(Object error);

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join and explore tasty places around you.'**
  String get authRegisterSubtitle;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get authFullNameRequired;

  /// No description provided for @authPhoneOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get authPhoneOptionalLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (min 6 characters)'**
  String get authPasswordTooWeak;

  /// No description provided for @authRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get authRegisterSuccess;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get authRegisterFailed;

  /// No description provided for @authRegisterEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'Email is already in use'**
  String get authRegisterEmailInUse;

  /// No description provided for @authRegisterUserMissing.
  ///
  /// In en, this message translates to:
  /// **'Unable to get newly created account'**
  String get authRegisterUserMissing;

  /// No description provided for @provinceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load province.'**
  String get provinceLoadError;

  /// No description provided for @provinceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Province not found.'**
  String get provinceNotFound;

  /// No description provided for @provinceIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get provinceIntroTitle;

  /// No description provided for @provinceNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description yet.'**
  String get provinceNoDescription;

  /// No description provided for @provinceSpecialtiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured specialties'**
  String get provinceSpecialtiesTitle;

  /// No description provided for @provinceDishesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dishes.'**
  String get provinceDishesLoadError;

  /// No description provided for @provinceNoDishes.
  ///
  /// In en, this message translates to:
  /// **'No dishes for this province.'**
  String get provinceNoDishes;

  /// No description provided for @dishNotFound.
  ///
  /// In en, this message translates to:
  /// **'Dish not found.'**
  String get dishNotFound;

  /// No description provided for @dishLoginToSave.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to save.'**
  String get dishLoginToSave;

  /// No description provided for @dishShareTodo.
  ///
  /// In en, this message translates to:
  /// **'Share coming soon.'**
  String get dishShareTodo;

  /// No description provided for @routeMissingProvinceId.
  ///
  /// In en, this message translates to:
  /// **'Missing province id'**
  String get routeMissingProvinceId;

  /// No description provided for @routeMissingDishId.
  ///
  /// In en, this message translates to:
  /// **'Missing dish id'**
  String get routeMissingDishId;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @reviewAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Review already exists'**
  String get reviewAlreadyTitle;

  /// No description provided for @reviewAlreadyMessage.
  ///
  /// In en, this message translates to:
  /// **'You already reviewed this place. Edit it?'**
  String get reviewAlreadyMessage;

  /// No description provided for @reviewEditConfirm.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get reviewEditConfirm;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get reviewHint;
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
