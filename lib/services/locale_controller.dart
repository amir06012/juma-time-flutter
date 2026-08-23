import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app ships translations for. Keep in sync with the ARB
/// files in lib/l10n and the `supportedLocales` list in main.dart.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('hi'),
];

/// Holds the user's chosen app language and persists it across restarts.
///
/// `null` means "follow the device's system language" (falling back to
/// English if the device language isn't one of [kSupportedLocales]) -
/// that's the default until the user picks a language explicitly in
/// Settings.
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) {
      _locale = kSupportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => kSupportedLocales.first,
      );
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
