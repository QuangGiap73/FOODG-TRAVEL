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
  /// **'Membership'**
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
