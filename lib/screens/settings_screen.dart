import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';
import '../utils/constants.dart';

/// Lets the user pick the app's display language, or fall back to whatever
/// language the device itself is set to. The choice is persisted by
/// [LocaleController] and applies instantly across every screen - no
/// restart needed.
class SettingsScreen extends StatelessWidget {
  final LocaleController localeController;

  const SettingsScreen({super.key, required this.localeController});

  /// Each supported language's own name, in its own script - shown as-is
  /// regardless of the app's current language, same as most apps' language
  /// pickers (so a user who ended up in the wrong language can still find
  /// their way back).
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          final selected = localeController.locale;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  l10n.languageSectionLabel,
                  style: AppFonts.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.richBlack,
                  ),
                ),
              ),
              RadioListTile<Locale?>(
                title: Text(l10n.useSystemLanguage),
                value: null,
                groupValue: selected,
                activeColor: AppColors.mehndiGreen,
                onChanged: (value) => localeController.setLocale(value),
              ),
              for (final locale in kSupportedLocales)
                RadioListTile<Locale?>(
                  title: Text(_languageNames[locale.languageCode] ?? locale.languageCode),
                  value: locale,
                  groupValue: selected,
                  activeColor: AppColors.mehndiGreen,
                  onChanged: (value) => localeController.setLocale(value),
                ),
            ],
          );
        },
      ),
    );
  }
}
