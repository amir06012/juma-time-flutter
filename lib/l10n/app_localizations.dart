import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi')
  ];

  /// The app's name, shown as the window/task title.
  ///
  /// In en, this message translates to:
  /// **'Juma Time'**
  String get appTitle;

  /// No description provided for @navMosques.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get navMosques;

  /// No description provided for @navQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get navQibla;

  /// No description provided for @navSilentMode.
  ///
  /// In en, this message translates to:
  /// **'Silent Mode'**
  String get navSilentMode;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionLabel;

  /// No description provided for @useSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get useSystemLanguage;

  /// No description provided for @mosqueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby mosques'**
  String get mosqueListTitle;

  /// No description provided for @turnOnLocationMosques.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see nearby mosques.'**
  String get turnOnLocationMosques;

  /// No description provided for @locationPermissionRequiredMosques.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to find nearby mosques.'**
  String get locationPermissionRequiredMosques;

  /// No description provided for @turnOnInternetMosques.
  ///
  /// In en, this message translates to:
  /// **'Turn on internet to see nearby mosques.'**
  String get turnOnInternetMosques;

  /// No description provided for @offlineShowingSample.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Showing sample data.'**
  String get offlineShowingSample;

  /// No description provided for @fetchErrorShowingSample.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch live data ({error}). Showing sample data.'**
  String fetchErrorShowingSample(String error);

  /// No description provided for @locationUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable (offline)'**
  String get locationUnavailableOffline;

  /// No description provided for @nearbyAreaFallback.
  ///
  /// In en, this message translates to:
  /// **'Nearby area'**
  String get nearbyAreaFallback;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @turnOnLocationAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get turnOnLocationAction;

  /// No description provided for @grantLocationPermissionAction.
  ///
  /// In en, this message translates to:
  /// **'Grant location permission'**
  String get grantLocationPermissionAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @noMosquesFoundNearby1km.
  ///
  /// In en, this message translates to:
  /// **'No mosques found within 1 km.'**
  String get noMosquesFoundNearby1km;

  /// No description provided for @mosquesNearbyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} mosque nearby} other{{count} mosques nearby}}'**
  String mosquesNearbyCount(int count);

  /// No description provided for @locatingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locatingEllipsis;

  /// No description provided for @qiblaDirectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblaDirectionTitle;

  /// No description provided for @turnOnLocationQibla.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to find the Qibla direction.'**
  String get turnOnLocationQibla;

  /// No description provided for @locationPermissionRequiredQibla.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to find the Qibla direction.'**
  String get locationPermissionRequiredQibla;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Please try again.'**
  String get couldNotGetLocation;

  /// No description provided for @compassNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Compass sensor not available on this device.'**
  String get compassNotAvailable;

  /// No description provided for @tryAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainAction;

  /// No description provided for @qiblaAligned.
  ///
  /// In en, this message translates to:
  /// **'Aligned — you are facing the Qibla'**
  String get qiblaAligned;

  /// No description provided for @qiblaRotatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Rotate your phone flat until the marker turns green'**
  String get qiblaRotatePrompt;

  /// No description provided for @qiblaBearingLabel.
  ///
  /// In en, this message translates to:
  /// **'QIBLA BEARING'**
  String get qiblaBearingLabel;

  /// No description provided for @fromTrueNorth.
  ///
  /// In en, this message translates to:
  /// **'from true North'**
  String get fromTrueNorth;

  /// No description provided for @facingLabel.
  ///
  /// In en, this message translates to:
  /// **'FACING'**
  String get facingLabel;

  /// No description provided for @qiblaTip.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat, like a compass, and rotate slowly - away from metal objects and magnets for the most accurate reading.'**
  String get qiblaTip;

  /// No description provided for @silentModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Silent Mode'**
  String get silentModeTitle;

  /// No description provided for @silencedEntered.
  ///
  /// In en, this message translates to:
  /// **'🔇 Silenced — entered {name}'**
  String silencedEntered(String name);

  /// No description provided for @restoredLeft.
  ///
  /// In en, this message translates to:
  /// **'🔊 Restored — left the mosque area'**
  String get restoredLeft;

  /// No description provided for @nowAttributedTo.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ Now attributed to {name}'**
  String nowAttributedTo(String name);

  /// No description provided for @defaultMosqueName.
  ///
  /// In en, this message translates to:
  /// **'a mosque'**
  String get defaultMosqueName;

  /// No description provided for @locationAccessNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Location access needed'**
  String get locationAccessNeededTitle;

  /// No description provided for @locationAccessNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Juma Time needs your location to find nearby mosques and detect when you enter one.'**
  String get locationAccessNeededMessage;

  /// No description provided for @backgroundLocationNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Background location needed'**
  String get backgroundLocationNeededTitle;

  /// No description provided for @backgroundLocationNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'So entering a mosque is detected even with the app closed, choose \"Allow all the time\" on the next screen.'**
  String get backgroundLocationNeededMessage;

  /// No description provided for @notificationsNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications needed'**
  String get notificationsNeededTitle;

  /// No description provided for @notificationsNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Juma Time shows a notification while your ringer is silenced so you always know why.'**
  String get notificationsNeededMessage;

  /// No description provided for @dndAccessNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb access needed'**
  String get dndAccessNeededTitle;

  /// No description provided for @dndAccessNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'Juma Time needs Do Not Disturb access to silence your ringer inside a mosque. Turn this on for Juma Time on the next screen.'**
  String get dndAccessNeededMessage;

  /// No description provided for @deniedBeforeSuffix.
  ///
  /// In en, this message translates to:
  /// **'\n\nYou\'ve denied this before, so please enable it from Settings.'**
  String get deniedBeforeSuffix;

  /// No description provided for @openSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsAction;

  /// No description provided for @allowAction.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allowAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @silencedNearMosque.
  ///
  /// In en, this message translates to:
  /// **'🔇 Silenced near {name}'**
  String silencedNearMosque(String name);

  /// No description provided for @notAtSelectedMosque.
  ///
  /// In en, this message translates to:
  /// **'Not currently at a selected mosque'**
  String get notAtSelectedMosque;

  /// No description provided for @noMosquesSelectedYet.
  ///
  /// In en, this message translates to:
  /// **'No mosques selected yet'**
  String get noMosquesSelectedYet;

  /// No description provided for @silentModeWatchingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Watching {count} selected mosque} other{Watching {count} selected mosques}}'**
  String silentModeWatchingCount(int count);

  /// No description provided for @silentModeSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Silent mode'**
  String get silentModeSwitchTitle;

  /// No description provided for @silentModeSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Silences your phone only at the mosques you select below'**
  String get silentModeSwitchSubtitle;

  /// No description provided for @selectMosquesAction.
  ///
  /// In en, this message translates to:
  /// **'Select mosques'**
  String get selectMosquesAction;

  /// No description provided for @editSelectedMosquesAction.
  ///
  /// In en, this message translates to:
  /// **'Edit selected mosques'**
  String get editSelectedMosquesAction;

  /// No description provided for @couldNotSaveSelectedMosques.
  ///
  /// In en, this message translates to:
  /// **'Could not save selected mosques: {error}'**
  String couldNotSaveSelectedMosques(String error);

  /// No description provided for @noMosquesSelectedOff.
  ///
  /// In en, this message translates to:
  /// **'No mosques selected - silent mode is off until you pick at least one.'**
  String get noMosquesSelectedOff;

  /// No description provided for @silentModeWatchingCountForMode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Watching {count} selected mosque for silent mode.} other{Watching {count} selected mosques for silent mode.}}'**
  String silentModeWatchingCountForMode(int count);

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @selectMosquesTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Mosques'**
  String get selectMosquesTitle;

  /// No description provided for @couldNotLoadNearbyMosques.
  ///
  /// In en, this message translates to:
  /// **'Could not load nearby mosques ({error}).'**
  String couldNotLoadNearbyMosques(String error);

  /// No description provided for @noMosquesFoundNearby.
  ///
  /// In en, this message translates to:
  /// **'No mosques found nearby.'**
  String get noMosquesFoundNearby;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @selectMosquesInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Your phone silences automatically the moment you enter a checked mosque, and unsilences the moment you leave.'**
  String get selectMosquesInfoBanner;

  /// No description provided for @nearbyMosquesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} nearby mosque} other{{count} nearby mosques}}'**
  String nearbyMosquesCount(int count);

  /// No description provided for @selectedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCountLabel(int count);

  /// No description provided for @nearestBadge.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearestBadge;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKm(String value);

  /// No description provided for @pleasePickTime.
  ///
  /// In en, this message translates to:
  /// **'Please pick a time'**
  String get pleasePickTime;

  /// No description provided for @jummahTimeRangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Jummah times are usually between 11 AM and 4 PM - please check'**
  String get jummahTimeRangeWarning;

  /// No description provided for @offlineTryAgain.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again once you\'re back online.'**
  String get offlineTryAgain;

  /// No description provided for @jummahTimeAdded.
  ///
  /// In en, this message translates to:
  /// **'Jummah time added.'**
  String get jummahTimeAdded;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error}'**
  String failedToSubmit(String error);

  /// No description provided for @jummahTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Jummah time'**
  String get jummahTimeLabel;

  /// No description provided for @secondJummahTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Second Jummah time'**
  String get secondJummahTimeLabel;

  /// No description provided for @tapToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick'**
  String get tapToPick;

  /// No description provided for @savingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingEllipsis;

  /// No description provided for @pendingJummahTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Jummah times'**
  String get pendingJummahTimesTitle;

  /// No description provided for @noPendingSubmissions.
  ///
  /// In en, this message translates to:
  /// **'No pending submissions.'**
  String get noPendingSubmissions;

  /// No description provided for @time1Label.
  ///
  /// In en, this message translates to:
  /// **'Time 1: {value}'**
  String time1Label(String value);

  /// No description provided for @time2Label.
  ///
  /// In en, this message translates to:
  /// **'Time 2: {value}'**
  String time2Label(String value);

  /// No description provided for @approveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveAction;

  /// No description provided for @rejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectAction;

  /// No description provided for @offlineCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get offlineCheckNetwork;

  /// No description provided for @accountNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'This account is not an admin.'**
  String get accountNotAdmin;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @adminLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin login'**
  String get adminLoginTitle;

  /// No description provided for @adminEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin email'**
  String get adminEmailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signingInEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingInEllipsis;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @jummahTimeNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Jummah time not added yet'**
  String get jummahTimeNotAdded;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @secondTimeShort.
  ///
  /// In en, this message translates to:
  /// **'+ 2nd time'**
  String get secondTimeShort;

  /// No description provided for @distanceKmAway.
  ///
  /// In en, this message translates to:
  /// **'{value} km away'**
  String distanceKmAway(String value);

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @prayerTimesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer times unavailable'**
  String get prayerTimesUnavailable;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
