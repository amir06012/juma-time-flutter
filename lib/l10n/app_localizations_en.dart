// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Juma Time';

  @override
  String get navMosques => 'Mosques';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navSilentMode => 'Silent Mode';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSectionLabel => 'Language';

  @override
  String get useSystemLanguage => 'System default';

  @override
  String get mosqueListTitle => 'Nearby mosques';

  @override
  String get turnOnLocationMosques => 'Turn on location to see nearby mosques.';

  @override
  String get locationPermissionRequiredMosques =>
      'Location permission is required to find nearby mosques.';

  @override
  String get turnOnInternetMosques => 'Turn on internet to see nearby mosques.';

  @override
  String get offlineShowingSample =>
      'No internet connection. Showing sample data.';

  @override
  String fetchErrorShowingSample(String error) {
    return 'Could not fetch live data ($error). Showing sample data.';
  }

  @override
  String get locationUnavailableOffline => 'Location unavailable (offline)';

  @override
  String get nearbyAreaFallback => 'Nearby area';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get turnOnLocationAction => 'Turn on location';

  @override
  String get grantLocationPermissionAction => 'Grant location permission';

  @override
  String get retryAction => 'Retry';

  @override
  String get noMosquesFoundNearby1km => 'No mosques found within 1 km.';

  @override
  String mosquesNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mosques nearby',
      one: '$count mosque nearby',
    );
    return '$_temp0';
  }

  @override
  String get locatingEllipsis => 'Locating…';

  @override
  String get qiblaDirectionTitle => 'Qibla Direction';

  @override
  String get turnOnLocationQibla =>
      'Turn on location to find the Qibla direction.';

  @override
  String get locationPermissionRequiredQibla =>
      'Location permission is required to find the Qibla direction.';

  @override
  String get couldNotGetLocation =>
      'Could not get your location. Please try again.';

  @override
  String get compassNotAvailable =>
      'Compass sensor not available on this device.';

  @override
  String get tryAgainAction => 'Try again';

  @override
  String get qiblaAligned => 'Aligned — you are facing the Qibla';

  @override
  String get qiblaRotatePrompt =>
      'Rotate your phone flat until the marker turns green';

  @override
  String get qiblaBearingLabel => 'QIBLA BEARING';

  @override
  String get fromTrueNorth => 'from true North';

  @override
  String get facingLabel => 'FACING';

  @override
  String get qiblaTip =>
      'Hold your phone flat, like a compass, and rotate slowly - away from metal objects and magnets for the most accurate reading.';

  @override
  String get silentModeTitle => 'Silent Mode';

  @override
  String silencedEntered(String name) {
    return '🔇 Silenced — entered $name';
  }

  @override
  String get restoredLeft => '🔊 Restored — left the mosque area';

  @override
  String nowAttributedTo(String name) {
    return 'ℹ️ Now attributed to $name';
  }

  @override
  String get defaultMosqueName => 'a mosque';

  @override
  String get locationAccessNeededTitle => 'Location access needed';

  @override
  String get locationAccessNeededMessage =>
      'Juma Time needs your location to find nearby mosques and detect when you enter one.';

  @override
  String get backgroundLocationNeededTitle => 'Background location needed';

  @override
  String get backgroundLocationNeededMessage =>
      'So entering a mosque is detected even with the app closed, choose \"Allow all the time\" on the next screen.';

  @override
  String get notificationsNeededTitle => 'Notifications needed';

  @override
  String get notificationsNeededMessage =>
      'Juma Time shows a notification while your ringer is silenced so you always know why.';

  @override
  String get dndAccessNeededTitle => 'Do Not Disturb access needed';

  @override
  String get dndAccessNeededMessage =>
      'Juma Time needs Do Not Disturb access to silence your ringer inside a mosque. Turn this on for Juma Time on the next screen.';

  @override
  String get deniedBeforeSuffix =>
      '\n\nYou\'ve denied this before, so please enable it from Settings.';

  @override
  String get openSettingsAction => 'Open Settings';

  @override
  String get allowAction => 'Allow';

  @override
  String get cancelAction => 'Cancel';

  @override
  String silencedNearMosque(String name) {
    return '🔇 Silenced near $name';
  }

  @override
  String get notAtSelectedMosque => 'Not currently at a selected mosque';

  @override
  String get noMosquesSelectedYet => 'No mosques selected yet';

  @override
  String silentModeWatchingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watching $count selected mosques',
      one: 'Watching $count selected mosque',
    );
    return '$_temp0';
  }

  @override
  String get silentModeSwitchTitle => 'Silent mode';

  @override
  String get silentModeSwitchSubtitle =>
      'Silences your phone only at the mosques you select below';

  @override
  String get selectMosquesAction => 'Select mosques';

  @override
  String get editSelectedMosquesAction => 'Edit selected mosques';

  @override
  String couldNotSaveSelectedMosques(String error) {
    return 'Could not save selected mosques: $error';
  }

  @override
  String get noMosquesSelectedOff =>
      'No mosques selected - silent mode is off until you pick at least one.';

  @override
  String silentModeWatchingCountForMode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watching $count selected mosques for silent mode.',
      one: 'Watching $count selected mosque for silent mode.',
    );
    return '$_temp0';
  }

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get selectMosquesTitle => 'Select Mosques';

  @override
  String couldNotLoadNearbyMosques(String error) {
    return 'Could not load nearby mosques ($error).';
  }

  @override
  String get noMosquesFoundNearby => 'No mosques found nearby.';

  @override
  String get saveAction => 'Save';

  @override
  String get selectMosquesInfoBanner =>
      'Your phone silences automatically the moment you enter a checked mosque, and unsilences the moment you leave.';

  @override
  String nearbyMosquesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nearby mosques',
      one: '$count nearby mosque',
    );
    return '$_temp0';
  }

  @override
  String selectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get nearestBadge => 'Nearest';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String get pleasePickTime => 'Please pick a time';

  @override
  String get jummahTimeRangeWarning =>
      'Jummah times are usually between 11 AM and 4 PM - please check';

  @override
  String get offlineTryAgain =>
      'No internet connection. Please try again once you\'re back online.';

  @override
  String get jummahTimeAdded => 'Jummah time added.';

  @override
  String failedToSubmit(String error) {
    return 'Failed to submit: $error';
  }

  @override
  String get jummahTimeLabel => 'Jummah time';

  @override
  String get secondJummahTimeLabel => 'Second Jummah time';

  @override
  String get tapToPick => 'Tap to pick';

  @override
  String get savingEllipsis => 'Saving...';

  @override
  String get pendingJummahTimesTitle => 'Pending Jummah times';

  @override
  String get noPendingSubmissions => 'No pending submissions.';

  @override
  String time1Label(String value) {
    return 'Time 1: $value';
  }

  @override
  String time2Label(String value) {
    return 'Time 2: $value';
  }

  @override
  String get approveAction => 'Approve';

  @override
  String get rejectAction => 'Reject';

  @override
  String get offlineCheckNetwork =>
      'No internet connection. Please check your network and try again.';

  @override
  String get accountNotAdmin => 'This account is not an admin.';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get adminLoginTitle => 'Admin login';

  @override
  String get adminEmailLabel => 'Admin email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signingInEllipsis => 'Signing in...';

  @override
  String get signInAction => 'Sign in';

  @override
  String get jummahTimeNotAdded => 'Jummah time not added yet';

  @override
  String get addAction => 'Add';

  @override
  String get secondTimeShort => '+ 2nd time';

  @override
  String distanceKmAway(String value) {
    return '$value km away';
  }

  @override
  String get getDirections => 'Get Directions';

  @override
  String get prayerTimesUnavailable => 'Prayer times unavailable';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';
}
