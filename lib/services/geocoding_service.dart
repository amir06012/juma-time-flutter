import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Uses OpenStreetMap's Nominatim (no API key required) to turn
  /// coordinates into a human-readable place name. Nominatim's usage policy
  /// requires a descriptive User-Agent identifying the calling app.
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'json',
      'zoom': '10',
    });

    final response = await http
        .get(uri, headers: {'User-Agent': 'MosqueFinderApp/1.0'})
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    return (address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county']) as String?;
  }
}