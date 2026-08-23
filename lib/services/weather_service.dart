import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherInfo {
  final double temperatureCelsius;
  WeatherInfo({required this.temperatureCelsius});
}

class WeatherService {
  /// Uses Open-Meteo (no API key required) for current temperature.
  Future<WeatherInfo> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current_weather': 'true',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current_weather'] as Map<String, dynamic>;
    return WeatherInfo(
      temperatureCelsius: (current['temperature'] as num).toDouble(),
    );
  }
}