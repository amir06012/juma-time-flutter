// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Juma Time';

  @override
  String get navMosques => 'मस्जिदें';

  @override
  String get navQibla => 'क़िबला';

  @override
  String get navSilentMode => 'साइलेंट मोड';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get languageSectionLabel => 'भाषा';

  @override
  String get useSystemLanguage => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get mosqueListTitle => 'आस-पास की मस्जिदें';

  @override
  String get turnOnLocationMosques =>
      'आस-पास की मस्जिदें देखने के लिए लोकेशन चालू करें।';

  @override
  String get locationPermissionRequiredMosques =>
      'आस-पास की मस्जिदें खोजने के लिए लोकेशन की अनुमति आवश्यक है।';

  @override
  String get turnOnInternetMosques =>
      'आस-पास की मस्जिदें देखने के लिए इंटरनेट चालू करें।';

  @override
  String get offlineShowingSample =>
      'कोई इंटरनेट कनेक्शन नहीं है। नमूना डेटा दिखाया जा रहा है।';

  @override
  String fetchErrorShowingSample(String error) {
    return 'लाइव डेटा प्राप्त नहीं हो सका ($error)। नमूना डेटा दिखाया जा रहा है।';
  }

  @override
  String get locationUnavailableOffline => 'लोकेशन उपलब्ध नहीं है (ऑफ़लाइन)';

  @override
  String get nearbyAreaFallback => 'आस-पास का क्षेत्र';

  @override
  String get locationUnavailable => 'लोकेशन उपलब्ध नहीं है';

  @override
  String get turnOnLocationAction => 'लोकेशन चालू करें';

  @override
  String get grantLocationPermissionAction => 'लोकेशन की अनुमति दें';

  @override
  String get retryAction => 'पुनः प्रयास करें';

  @override
  String get noMosquesFoundNearby1km => '1 किमी के भीतर कोई मस्जिद नहीं मिली।';

  @override
  String mosquesNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मस्जिदें पास में',
      one: '$count मस्जिद पास में',
    );
    return '$_temp0';
  }

  @override
  String get locatingEllipsis => 'लोकेशन खोजी जा रही है…';

  @override
  String get qiblaDirectionTitle => 'क़िबला दिशा';

  @override
  String get turnOnLocationQibla =>
      'क़िबला दिशा जानने के लिए लोकेशन चालू करें।';

  @override
  String get locationPermissionRequiredQibla =>
      'क़िबला दिशा जानने के लिए लोकेशन की अनुमति आवश्यक है।';

  @override
  String get couldNotGetLocation =>
      'आपकी लोकेशन प्राप्त नहीं हो सकी। कृपया पुनः प्रयास करें।';

  @override
  String get compassNotAvailable => 'इस डिवाइस पर कम्पास सेंसर उपलब्ध नहीं है।';

  @override
  String get tryAgainAction => 'पुनः प्रयास करें';

  @override
  String get qiblaAligned => 'संरेखित — आप क़िबला की ओर मुख कर रहे हैं';

  @override
  String get qiblaRotatePrompt =>
      'मार्कर के हरा होने तक अपने फ़ोन को सीधा घुमाएं';

  @override
  String get qiblaBearingLabel => 'क़िबला दिशा';

  @override
  String get fromTrueNorth => 'सच्चे उत्तर से';

  @override
  String get facingLabel => 'मुख की दिशा';

  @override
  String get qiblaTip =>
      'अपने फ़ोन को कम्पास की तरह सीधा पकड़ें और धीरे-धीरे घुमाएं - सबसे सटीक रीडिंग के लिए धातु की वस्तुओं और चुंबकों से दूर रहें।';

  @override
  String get silentModeTitle => 'साइलेंट मोड';

  @override
  String silencedEntered(String name) {
    return '🔇 साइलेंट किया गया — $name में प्रवेश किया';
  }

  @override
  String get restoredLeft => '🔊 बहाल किया गया — मस्जिद क्षेत्र से बाहर निकले';

  @override
  String nowAttributedTo(String name) {
    return 'ℹ️ अब $name से संबद्ध';
  }

  @override
  String get defaultMosqueName => 'एक मस्जिद';

  @override
  String get locationAccessNeededTitle => 'लोकेशन एक्सेस आवश्यक है';

  @override
  String get locationAccessNeededMessage =>
      'Juma Time को आस-पास की मस्जिदें खोजने और यह पता लगाने के लिए कि आप कब वहां प्रवेश करते हैं, आपकी लोकेशन चाहिए।';

  @override
  String get backgroundLocationNeededTitle => 'बैकग्राउंड लोकेशन आवश्यक है';

  @override
  String get backgroundLocationNeededMessage =>
      'ऐप बंद होने पर भी मस्जिद में प्रवेश का पता लगाने के लिए, अगली स्क्रीन पर \"हमेशा अनुमति दें\" चुनें।';

  @override
  String get notificationsNeededTitle => 'सूचनाएं आवश्यक हैं';

  @override
  String get notificationsNeededMessage =>
      'Juma Time आपकी रिंगर साइलेंट होने के दौरान एक सूचना दिखाता है ताकि आप हमेशा कारण जान सकें।';

  @override
  String get dndAccessNeededTitle => 'डू नॉट डिस्टर्ब एक्सेस आवश्यक है';

  @override
  String get dndAccessNeededMessage =>
      'मस्जिद के अंदर आपकी रिंगर साइलेंट करने के लिए Juma Time को डू नॉट डिस्टर्ब एक्सेस चाहिए। अगली स्क्रीन पर Juma Time के लिए इसे चालू करें।';

  @override
  String get deniedBeforeSuffix =>
      '\n\nआपने इसे पहले अस्वीकार किया है, इसलिए कृपया इसे सेटिंग्स से सक्षम करें।';

  @override
  String get openSettingsAction => 'सेटिंग्स खोलें';

  @override
  String get allowAction => 'अनुमति दें';

  @override
  String get cancelAction => 'रद्द करें';

  @override
  String silencedNearMosque(String name) {
    return '🔇 $name के पास साइलेंट है';
  }

  @override
  String get notAtSelectedMosque => 'फ़िलहाल किसी चयनित मस्जिद पर नहीं हैं';

  @override
  String get noMosquesSelectedYet => 'अभी तक कोई मस्जिद चयनित नहीं है';

  @override
  String silentModeWatchingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चयनित मस्जिदें देखी जा रही हैं',
      one: '$count चयनित मस्जिद देखी जा रही है',
    );
    return '$_temp0';
  }

  @override
  String get silentModeSwitchTitle => 'साइलेंट मोड';

  @override
  String get silentModeSwitchSubtitle =>
      'यह केवल नीचे चुनी गई मस्जिदों पर ही आपका फ़ोन साइलेंट करता है';

  @override
  String get selectMosquesAction => 'मस्जिदें चुनें';

  @override
  String get editSelectedMosquesAction => 'चयनित मस्जिदें संपादित करें';

  @override
  String couldNotSaveSelectedMosques(String error) {
    return 'चयनित मस्जिदें सहेजी नहीं जा सकीं: $error';
  }

  @override
  String get noMosquesSelectedOff =>
      'कोई मस्जिद चयनित नहीं है - जब तक आप कम से कम एक नहीं चुनते, साइलेंट मोड बंद रहेगा।';

  @override
  String silentModeWatchingCountForMode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'साइलेंट मोड के लिए $count चयनित मस्जिदें देखी जा रही हैं।',
      one: 'साइलेंट मोड के लिए $count चयनित मस्जिद देखी जा रही है।',
    );
    return '$_temp0';
  }

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get selectMosquesTitle => 'मस्जिदें चुनें';

  @override
  String couldNotLoadNearbyMosques(String error) {
    return 'आस-पास की मस्जिदें लोड नहीं हो सकीं ($error)।';
  }

  @override
  String get noMosquesFoundNearby => 'आस-पास कोई मस्जिद नहीं मिली।';

  @override
  String get saveAction => 'सहेजें';

  @override
  String get selectMosquesInfoBanner =>
      'जैसे ही आप किसी चयनित मस्जिद में प्रवेश करते हैं, आपका फ़ोन अपने आप साइलेंट हो जाता है, और जैसे ही आप बाहर निकलते हैं, वापस चालू हो जाता है।';

  @override
  String nearbyMosquesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पास की मस्जिदें',
      one: '$count पास की मस्जिद',
    );
    return '$_temp0';
  }

  @override
  String selectedCountLabel(int count) {
    return '$count चयनित';
  }

  @override
  String get nearestBadge => 'निकटतम';

  @override
  String distanceKm(String value) {
    return '$value किमी';
  }

  @override
  String get pleasePickTime => 'कृपया एक समय चुनें';

  @override
  String get jummahTimeRangeWarning =>
      'जुमा का समय आमतौर पर सुबह 11 बजे से शाम 4 बजे के बीच होता है - कृपया जांचें';

  @override
  String get offlineTryAgain =>
      'कोई इंटरनेट कनेक्शन नहीं है। कृपया ऑनलाइन होने पर पुनः प्रयास करें।';

  @override
  String get jummahTimeAdded => 'जुमा का समय जोड़ा गया।';

  @override
  String failedToSubmit(String error) {
    return 'सबमिट नहीं हो सका: $error';
  }

  @override
  String get jummahTimeLabel => 'जुमा का समय';

  @override
  String get secondJummahTimeLabel => 'दूसरे जुमा का समय';

  @override
  String get tapToPick => 'चुनने के लिए टैप करें';

  @override
  String get savingEllipsis => 'सहेजा जा रहा है...';

  @override
  String get pendingJummahTimesTitle => 'लंबित जुमा समय';

  @override
  String get noPendingSubmissions => 'कोई लंबित सबमिशन नहीं है।';

  @override
  String time1Label(String value) {
    return 'समय 1: $value';
  }

  @override
  String time2Label(String value) {
    return 'समय 2: $value';
  }

  @override
  String get approveAction => 'स्वीकृत करें';

  @override
  String get rejectAction => 'अस्वीकार करें';

  @override
  String get offlineCheckNetwork =>
      'कोई इंटरनेट कनेक्शन नहीं है। कृपया अपना नेटवर्क जांचें और पुनः प्रयास करें।';

  @override
  String get accountNotAdmin => 'यह खाता एडमिन नहीं है।';

  @override
  String get loginFailed => 'लॉगिन विफल रहा';

  @override
  String get adminLoginTitle => 'एडमिन लॉगिन';

  @override
  String get adminEmailLabel => 'एडमिन ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get signingInEllipsis => 'साइन इन हो रहा है...';

  @override
  String get signInAction => 'साइन इन करें';

  @override
  String get jummahTimeNotAdded => 'जुमा का समय अभी तक नहीं जोड़ा गया';

  @override
  String get addAction => 'जोड़ें';

  @override
  String get secondTimeShort => '+ दूसरा समय';

  @override
  String distanceKmAway(String value) {
    return '$value किमी दूर';
  }

  @override
  String get getDirections => 'दिशा-निर्देश पाएं';

  @override
  String get prayerTimesUnavailable => 'नमाज़ के समय उपलब्ध नहीं हैं';

  @override
  String get prayerFajr => 'फज्र';

  @override
  String get prayerDhuhr => 'ज़ुहर';

  @override
  String get prayerAsr => 'असर';

  @override
  String get prayerMaghrib => 'मग़रिब';

  @override
  String get prayerIsha => 'इशा';

  @override
  String get greetingMorning => 'सुप्रभात';

  @override
  String get greetingAfternoon => 'शुभ दोपहर';

  @override
  String get greetingEvening => 'शुभ संध्या';
}
