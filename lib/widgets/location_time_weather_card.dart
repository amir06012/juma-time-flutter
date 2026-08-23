import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import 'circular_clock.dart';
import 'geometric_pattern.dart';

class LocationTimeWeatherCard extends StatelessWidget {
  final String locationName;
  final double? temperatureCelsius;

  const LocationTimeWeatherCard({
    super.key,
    required this.locationName,
    required this.temperatureCelsius,
  });

  /// Weekday + day + month name, in whatever language the app is currently
  /// set to - package:intl already ships the CLDR weekday/month names for
  /// every locale it supports, so there's no need to hand-translate them.
  String _formattedDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, d MMMM', locale).format(DateTime.now());
  }

  /// Umm al-Qura Hijri (Islamic lunar calendar) date - the calendar Jummah
  /// and other Islamic dates are actually reckoned by, alongside the
  /// Gregorian one above. The hijri package only outputs month names in
  /// English/Arabic transliteration, so this stays as-is regardless of app
  /// language, matching how Islamic calendar terms are commonly kept
  /// untranslated even in localized apps.
  String get _hijriDate {
    final hijri = HijriCalendar.fromDate(DateTime.now());
    return '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} AH';
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  IconData get _weatherIcon {
    final t = temperatureCelsius;
    if (t == null) return Icons.cloud_outlined;
    if (t >= 32) return Icons.wb_sunny;
    if (t >= 20) return Icons.wb_sunny_outlined;
    return Icons.cloud_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mehndiGreen, AppColors.mehndiGreenDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.mehndiGreen.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: GeometricPatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircularClock(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greeting(l10n),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'السلام عليكم',
                        style: AppFonts.arabic(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formattedDate(context),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hijriDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lightGold.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 15, color: AppColors.lightGold),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(_weatherIcon, size: 16, color: AppColors.lightGold),
                          const SizedBox(width: 4),
                          Text(
                            temperatureCelsius != null
                                ? '${temperatureCelsius!.toStringAsFixed(0)}°C'
                                : '--°C',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}