import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/prayer_times_service.dart';

class PrayerTimesBar extends StatelessWidget {
  final PrayerTimes? times;

  const PrayerTimesBar({super.key, required this.times});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (times == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(l10n.prayerTimesUnavailable),
      );
    }

    final entries = <String, String>{
      l10n.prayerFajr: times!.fajr,
      l10n.prayerDhuhr: times!.dhuhr,
      l10n.prayerAsr: times!.asr,
      l10n.prayerMaghrib: times!.maghrib,
      l10n.prayerIsha: times!.isha,
    };

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: entries.entries.map((e) {
          return Column(
            children: [
              Text(
                e.key,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(e.value.split(' ').first, style: const TextStyle(fontSize: 13)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
