import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerTimes {
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

class PrayerTimesService {
  /// Uses the free Aladhan API (no key required). 'method' 2 = ISNA, a
  /// common general-purpose calculation authority - change it if your
  /// users expect a different regional standard (e.g. method 1 = Karachi,
  /// commonly used across South Asia).
  Future<PrayerTimes> fetchToday({
    required double latitude,
    required double longitude,
    int method = 1,
  }) async {
    final today = DateTime.now();
    final dateStr = '${today.day.toString().padLeft(2, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-${today.year}';

    final uri = Uri.https('api.aladhan.com', '/v1/timings/$dateStr', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'method': '$method',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final timings = data['data']['timings'] as Map<String, dynamic>;

    return PrayerTimes(
      fajr: timings['Fajr'] as String,
      dhuhr: timings['Dhuhr'] as String,
      asr: timings['Asr'] as String,
      maghrib: timings['Maghrib'] as String,
      isha: timings['Isha'] as String,
    );
  }
}
