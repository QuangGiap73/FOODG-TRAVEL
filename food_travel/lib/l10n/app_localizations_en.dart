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

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSeeMore => 'See more';

  @override
  String get commonCollapse => 'Collapse';

  @override
  String get commonSend => 'Send';

  @override
  String get commonNo => 'No';

  @override
  String get commonClose => 'Close';

  @override
  String get commonUpdating => 'Updating';

  @override
  String get commentTitle => 'Comments';

  @override
  String get commentEmpty => 'No comments yet.';

  @override
  String get commentLoginRequired => 'Please sign in to comment.';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityTabNewest => 'Newest';

  @override
  String get communityTabTrending => 'Trending';

  @override
  String get communityTabNear => 'Nearby';

  @override
  String get communityTabProvince => 'By province';

  @override
  String get communityPostButton => 'Create post';

  @override
  String get communityLoadError => 'Unable to load posts.';

  @override
  String get communityEmptyNewest => 'No posts yet.';

  @override
  String get communityEmptyTrending => 'No trending posts yet.';

  @override
  String get communityEnableGps => 'Enable GPS to see nearby posts.';

  @override
  String get communityGpsLoading => 'Getting location...';

  @override
  String get communityEnableGpsButton => 'Enable GPS';

  @override
  String get communityEmptyNear => 'No nearby posts found.';

  @override
  String get communitySelectProvince => 'Select a province';

  @override
  String get communityChangeProvince => 'Change';

  @override
  String get communitySelectProvinceHint => 'Search province...';

  @override
  String get communityEmptyProvince => 'No posts for this province.';

  @override
  String get communityProvinceListEmpty => 'No provinces available.';

  @override
  String get communityDeleteTitle => 'Delete post';

  @override
  String get communityDeleteConfirm =>
      'Are you sure you want to delete this post?';

  @override
  String get communityMyPostsTitle => 'My posts';

  @override
  String get communityMyPostsLoginRequired =>
      'Please sign in to view your posts.';

  @override
  String get communityMyPostsLoadError => 'Unable to load your posts.';

  @override
  String get communityMyPostsEmpty => 'You haven\'t posted yet.';

  @override
  String get communityPostEmptyContent => 'Post content is empty.';

  @override
  String get postPickFromGallery => 'Choose from gallery';

  @override
  String get postPickFromCamera => 'Take a photo';

  @override
  String get postCreateTitle => 'Create post';

  @override
  String get postEditTitle => 'Edit post';

  @override
  String get postPublish => 'Post';

  @override
  String get postTextHint => 'Share your experience...';

  @override
  String get postUploading => 'Uploading...';

  @override
  String get postAddPlace => 'Add place';

  @override
  String get postPlaceSearchHint => 'Search place...';

  @override
  String get postPlaceSearchPrompt => 'Start typing to search.';

  @override
  String get postPlaceSearchEmpty => 'No places found.';

  @override
  String get postPlaceSearchError => 'Search failed. Try again.';

  @override
  String get postPlaceFallbackTitle => 'Nearby place';

  @override
  String get postPlaceFallbackAddress => 'Address updating';

  @override
  String postSubmitFailed(Object error) {
    return 'Post failed: $error';
  }

  @override
  String reviewSectionTitle(Object count) {
    return 'Reviews ($count)';
  }

  @override
  String get reviewWriteTitle => 'Write review';

  @override
  String get reviewEmpty => 'No reviews yet.';

  @override
  String get reviewDeleteTitle => 'Delete review';

  @override
  String get reviewDeleteConfirm =>
      'Are you sure you want to delete this review?';

  @override
  String get reviewDinedHere => 'Dined here';

  @override
  String reviewDinedHereWithDate(Object date) {
    return '$date - Dined here';
  }

  @override
  String reviewFromUserWithDate(Object date) {
    return '$date - User review';
  }

  @override
  String get favoritesLoginRequired => 'Please sign in to view favorites.';

  @override
  String get favoritesTitle => 'Saved';

  @override
  String get favoritesSubtitle => 'All your favorites';

  @override
  String get favoritesTabDishes => 'Dishes';

  @override
  String get favoritesTabPlaces => 'Places';

  @override
  String get favoritesFilterCentral => 'Central';

  @override
  String get favoritesFilterSpicy => 'Spicy';

  @override
  String get favoritesFilterBudget => 'Budget';

  @override
  String get favoritesFilterBreakfast => 'Breakfast';

  @override
  String get favoritesLoadError => 'Unable to load favorites.';

  @override
  String get favoritePlacesLoadError => 'Unable to load saved places.';

  @override
  String get favoritePlacesEmpty => 'No saved places yet.';

  @override
  String get favoritePlaceCategoryFallback => 'Local cuisine';

  @override
  String get favoritePlaceNoRating => 'No rating';

  @override
  String get favoritePlaceAddressFallback => 'Address updating';

  @override
  String get favoriteDishesLoadError => 'Unable to load saved dishes.';

  @override
  String get favoriteDishesEmpty => 'No saved dishes yet.';

  @override
  String get favoriteSpicyNone => 'Not spicy';

  @override
  String favoriteSpicyLevel(Object count) {
    return 'Spicy level $count';
  }

  @override
  String get favoriteProvinceUpdating => 'Updating province...';

  @override
  String get regionNorth => 'Northern';

  @override
  String get regionCentral => 'Central';

  @override
  String get regionSouth => 'Southern';

  @override
  String get placeNameFallback => 'Place';

  @override
  String get placeAddressUpdating => 'Address updating';

  @override
  String get placeNoPhone => 'No phone number';

  @override
  String get placeCallNow => 'Call now';

  @override
  String get placeCallAction => 'Call';

  @override
  String get placeReserve => 'Reserve';

  @override
  String get placeInvite => 'Invite';

  @override
  String get placeSchedule => 'Plan';

  @override
  String get placePricePerPerson => '/person';

  @override
  String get placeDistanceUpdating => 'Distance updating';

  @override
  String placeDistanceAway(Object distance) {
    return '$distance away';
  }

  @override
  String get placeOpenHoursUpdating => 'Hours updating';

  @override
  String placeClosesAt(Object time) {
    return 'Closes at $time';
  }

  @override
  String get placeCategoryFallback => 'Local cuisine';

  @override
  String get placeNoRating => 'No rating';

  @override
  String get placeMenuMustTry => 'Must-try';

  @override
  String get placeMenuFull => 'Full menu';

  @override
  String get placeMenuUpdating => 'Menu updating';

  @override
  String get placeInfoTitle => 'Place info';

  @override
  String get placeOpenHoursLabel => 'Open hours';

  @override
  String get amenityAirConditioner => 'Air conditioner';

  @override
  String get amenityBankTransfer => 'Bank transfer';

  @override
  String get amenityFreeParking => 'Free parking';

  @override
  String get mapSearchHint => 'Search place...';

  @override
  String get mapCategoryRestaurants => 'Restaurants';

  @override
  String get mapCategoryCafe => 'Cafe';

  @override
  String get mapCategorySnack => 'Snacks';

  @override
  String get mapCategoryFastFood => 'Fast food';

  @override
  String get mapCategorySeafood => 'Seafood';

  @override
  String get mapStyleNormal => 'Normal';

  @override
  String get mapStyleHighlight => 'Highlight';

  @override
  String get mapStyleSatellite => 'Satellite';

  @override
  String get mapEnableLocation => 'Please enable location.';

  @override
  String get mapLocationUnavailable => 'Location not available yet.';

  @override
  String get mapPlaceNotFound => 'Place not found.';

  @override
  String get mapEnableGpsToSearch => 'Enable GPS to search nearby.';

  @override
  String get mapPermissionDenied => 'Location permission denied.';

  @override
  String get mapGpsInvalid => 'Invalid GPS location.';

  @override
  String get mapNearbyNotFound => 'No nearby places found.';

  @override
  String get mapLocationTimeout => 'Location request timed out.';

  @override
  String mapSearchError(Object error) {
    return 'Search error: $error';
  }

  @override
  String get mapDirectionsError => 'Unable to get directions.';

  @override
  String get mapOpenNow => 'Open now';

  @override
  String get mapClosed => 'Closed';

  @override
  String get mapDirections => 'Directions';

  @override
  String mapNearbyPlacesTitle(Object count) {
    return 'Nearby places ($count)';
  }

  @override
  String mapEtaMinutes(Object minutes) {
    return '~$minutes min';
  }

  @override
  String get mapSortDistance => 'Distance';

  @override
  String get mapOpenMap => 'Open map';

  @override
  String get mapNoCoordinates => 'No coordinates';

  @override
  String get mapPlaceFallbackName => 'Nearby place';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderUnknown => 'Unknown';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileNameLabel => 'Full name';

  @override
  String get profileNameRequired => 'Please enter your name';

  @override
  String get profileGenderLabel => 'Gender';

  @override
  String get profileGenderHint => 'Select gender';

  @override
  String get profileDobLabel => 'Date of birth';

  @override
  String get profilePhoneLabel => 'Phone';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileAvatarTitle => 'Avatar';

  @override
  String get profileAvatarUploadFailed => 'Upload failed';

  @override
  String get personalLocation => 'Location';

  @override
  String get logoutTitle => 'Sign out';

  @override
  String get logoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get logoutAction => 'Sign out';

  @override
  String get themeSettingsTitle => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get locationSettingsTitle => 'Location';

  @override
  String get locationSettingsDescription =>
      'Enable location to show on the map.';

  @override
  String get locationEnable => 'Enable location';

  @override
  String get locationOpenSettings => 'Open GPS settings';

  @override
  String get locationOpenAppSettings => 'Open app settings';

  @override
  String get locationError => 'Location error.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordSuccess => 'Password changed successfully.';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordCurrentRequired => 'Please enter current password';

  @override
  String get changePasswordNewRequired => 'Please enter new password';

  @override
  String get changePasswordNewTooShort =>
      'New password must be at least 6 characters';

  @override
  String get changePasswordConfirmRequired => 'Please confirm new password';

  @override
  String get changePasswordMismatch => 'Passwords do not match';

  @override
  String get changePasswordErrorMissingFields => 'Please fill in all fields.';

  @override
  String get changePasswordErrorMismatch => 'Passwords do not match.';

  @override
  String get changePasswordErrorTooShort =>
      'New password must be at least 6 characters.';

  @override
  String get changePasswordErrorWrongCurrent =>
      'Current password is incorrect.';

  @override
  String get changePasswordErrorWeak => 'New password is too weak.';

  @override
  String get changePasswordErrorRequiresLogin =>
      'Please sign in again and try.';

  @override
  String get changePasswordErrorNoUser => 'Not signed in.';

  @override
  String get changePasswordErrorNoPasswordProvider =>
      'Google sign-in account cannot change password.';

  @override
  String get changePasswordErrorUnknown => 'Password change failed.';

  @override
  String get authLoginTitle => 'Welcome back!';

  @override
  String get authLoginSubtitle => 'Login to your food account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Please enter email';

  @override
  String get authEmailInvalid => 'Invalid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Please enter password';

  @override
  String get authLoginAction => 'Login';

  @override
  String get authOr => 'or';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authRegisterAction => 'Register';

  @override
  String get authLoginFailed => 'Login failed';

  @override
  String get authLoginUserNotFound => 'Account not found';

  @override
  String get authLoginWrongPassword => 'Incorrect password';

  @override
  String get authGoogleFailed => 'Google sign-in failed';

  @override
  String get authGoogleAccountExists =>
      'Account exists with a different sign-in method';

  @override
  String get authGoogleInvalidCredential => 'Invalid Google credential';

  @override
  String authError(Object error) {
    return 'Error: $error';
  }

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle =>
      'Join and explore tasty places around you.';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameRequired => 'Please enter your name';

  @override
  String get authPhoneOptionalLabel => 'Phone (optional)';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordRequired => 'Please confirm password';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authPasswordTooWeak => 'Password is too weak (min 6 characters)';

  @override
  String get authRegisterSuccess => 'Registration successful';

  @override
  String get authRegisterFailed => 'Registration failed';

  @override
  String get authRegisterEmailInUse => 'Email is already in use';

  @override
  String get authRegisterUserMissing => 'Unable to get newly created account';

  @override
  String get provinceLoadError => 'Unable to load province.';

  @override
  String get provinceNotFound => 'Province not found.';

  @override
  String get provinceIntroTitle => 'Introduction';

  @override
  String get provinceNoDescription => 'No description yet.';

  @override
  String get provinceSpecialtiesTitle => 'Featured specialties';

  @override
  String get provinceDishesLoadError => 'Unable to load dishes.';

  @override
  String get provinceNoDishes => 'No dishes for this province.';

  @override
  String get dishNotFound => 'Dish not found.';

  @override
  String get dishLoginToSave => 'Please sign in to save.';

  @override
  String get dishShareTodo => 'Share coming soon.';

  @override
  String get routeMissingProvinceId => 'Missing province id';

  @override
  String get routeMissingDishId => 'Missing dish id';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get commonBack => 'Back';

  @override
  String get reviewAlreadyTitle => 'Review already exists';

  @override
  String get reviewAlreadyMessage =>
      'You already reviewed this place. Edit it?';

  @override
  String get reviewEditConfirm => 'Edit review';

  @override
  String get reviewHint => 'Share your experience...';
}
