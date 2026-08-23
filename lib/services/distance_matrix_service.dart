import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mosque.dart';

/// Real road-route distances via Google's Distance Matrix API - matching
/// what Google Maps itself shows. Unlike [LocationService.distanceKm]
/// (great-circle "as the crow flies", always a straight line), this follows
/// actual roads, which is almost always further and is what users compare
/// against when they look the same mosque up in Google Maps.
class DistanceMatrixService {
  final String apiKey;
  DistanceMatrixService(this.apiKey);

  /// Returns a map of [Mosque.placeId] -> driving distance in km. Any
  /// mosque Google couldn't compute a route for - or the whole request
  /// failing/timing out - simply isn't in the returned map; this never
  /// throws, so callers should fall back to straight-line distance for
  /// anything missing rather than treating this as fatal to the load.
  Future<Map<String, double>> drivingDistancesKm({
    required double originLat,
    required double originLng,
    required List<Mosque> destinations,
  }) async {
    if (destinations.isEmpty) return {};

    try {
      // One request handles every destination at once (pipe-separated)
      // instead of one call per mosque - Google allows up to 25 per
      // request, above this app's own nearby-mosque result cap.
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/distancematrix/json',
        {
          'origins': '$originLat,$originLng',
          'destinations': destinations
              .map((m) => '${m.latitude},${m.longitude}')
              .join('|'),
          'mode': 'driving',
          'key': apiKey,
        },
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return {};

      final rows = data['rows'] as List<dynamic>?;
      final elements = (rows == null || rows.isEmpty)
          ? null
          : (rows.first as Map<String, dynamic>)['elements'] as List<dynamic>?;
      if (elements == null || elements.length != destinations.length) {
        return {};
      }

      final result = <String, double>{};
      for (var i = 0; i < destinations.length; i++) {
        final element = elements[i] as Map<String, dynamic>;
        if (element['status'] != 'OK') continue;
        final meters = (element['distance']['value'] as num).toDouble();
        result[destinations[i].placeId] = meters / 1000.0;
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}
