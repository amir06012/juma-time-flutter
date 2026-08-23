import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/mosque.dart';

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

  // Shared across every PlacesService instance (they all hit the same API
  // with the same key) rather than per-instance, so a screen that asks for
  // nearby mosques shortly after another screen already did - e.g. opening
  // the Silent Mode mosque picker right after browsing the main nearby
  // list - reuses that same result instead of spending a second Places API
  // call (and a second wait) on virtually the same query. This is also
  // exactly why the picker should show "the same list": it now literally
  // is the same fetch when the cache is still fresh.
  static List<Mosque>? _cachedResults;
  static double? _cachedLat;
  static double? _cachedLng;
  static int? _cachedRadiusMeters;
  static DateTime? _cachedAt;
  // True if [_cachedResults] is every mosque Places had within the radius
  // (fewer exist than were asked for), not just the first `maxResults` of
  // more that were available - lets a cached area with e.g. only 5 mosques
  // still satisfy a maxResults: 20 request from cache instead of being
  // wrongly treated as "not enough" and re-fetched every time.
  static bool _cachedExhausted = false;

  static const _cacheTtl = Duration(minutes: 5);
  // Treat the origin as "the same place" if it moved less than this -
  // GPS readings themselves wobble by tens of meters, but this also avoids
  // serving a stale list once the user has actually gone somewhere new.
  static const _cacheMoveThresholdMeters = 300;

  /// Fetches up to [maxResults] mosques within [radiusMeters] of the given
  /// point - or returns the still-fresh result of the last call for
  /// (roughly) the same point/radius instead of hitting the network again.
  ///
  /// Uses Text Search (query: "mosque") rather than Nearby Search: Nearby
  /// Search never returns a full address (only a short `vicinity` like
  /// "Main Street, City"), while Text Search's results include
  /// `formatted_address` - so this is what lets [Mosque.address] show the
  /// full address, in the same single request instead of an extra Place
  /// Details call per mosque. Results are filtered to Google's own
  /// mosque/place-of-worship types afterwards, as a safety net against text
  /// search occasionally matching something only mentioning "mosque".
  Future<List<Mosque>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
    int maxResults = 20,
  }) async {
    if (_hasFreshCache(latitude, longitude, radiusMeters, maxResults)) {
      return _cachedResults!.take(maxResults).toList();
    }

    final (results, exhausted) = await _fetchFromApi(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      maxResults: maxResults,
    );

    _cachedResults = results;
    _cachedLat = latitude;
    _cachedLng = longitude;
    _cachedRadiusMeters = radiusMeters;
    _cachedAt = DateTime.now();
    _cachedExhausted = exhausted;

    return results;
  }

  bool _hasFreshCache(
      double latitude, double longitude, int radiusMeters, int maxResults) {
    final cached = _cachedResults;
    final cachedAt = _cachedAt;
    final cachedLat = _cachedLat;
    final cachedLng = _cachedLng;
    if (cached == null || cachedAt == null || cachedLat == null || cachedLng == null) {
      return false;
    }
    // A previous call asking for fewer results than this one may not have
    // paged far enough to satisfy this request - don't serve a truncated
    // cache as if it were complete, unless that previous call already knows
    // it saw every mosque Places had (see [_cachedExhausted]).
    if (cached.length < maxResults && !_cachedExhausted) return false;
    if (_cachedRadiusMeters != radiusMeters) return false;
    if (DateTime.now().difference(cachedAt) > _cacheTtl) return false;
    final movedMeters = Geolocator.distanceBetween(latitude, longitude, cachedLat, cachedLng);
    return movedMeters < _cacheMoveThresholdMeters;
  }

  /// Google returns at most 20 results per page, so this pages through
  /// next_page_token as needed - each extra page costs a mandatory 2s wait
  /// (Google requires it before a next_page_token becomes valid), so
  /// [maxResults] defaults to exactly one page's worth to keep a normal
  /// load fast; raise it deliberately if you want more than 20 results and
  /// are fine paying that cost.
  ///
  /// Returns the results plus whether that was *every* mosque Places had
  /// within the radius, rather than a page cut short by [maxResults] with
  /// more still available - see [_cachedExhausted].
  Future<(List<Mosque>, bool)> _fetchFromApi({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required int maxResults,
  }) async {
    final List<Mosque> results = [];
    String? nextPageToken;
    var exhausted = true;

    do {
      final uri = nextPageToken == null
          ? Uri.https(
              'maps.googleapis.com',
              '/maps/api/place/textsearch/json',
              {
                'query': 'mosque',
                'location': '$latitude,$longitude',
                'radius': '$radiusMeters',
                'key': apiKey,
              },
            )
          : Uri.https(
              'maps.googleapis.com',
              '/maps/api/place/textsearch/json',
              {
                'pagetoken': nextPageToken,
                'key': apiKey,
              },
            );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        // A failed page fetch means this result set might be missing real
        // mosques, not that the area genuinely only has this many - don't
        // let it be cached as if it were the complete picture.
        exhausted = false;
        break;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw Exception(
          'Places API error: ${data['status']} ${data['error_message'] ?? ''}',
        );
      }

      final pageResults = (data['results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((r) {
        final types = (r['types'] as List<dynamic>? ?? []).cast<String>();
        return types.contains('mosque') || types.contains('place_of_worship');
      });
      results.addAll(pageResults.map(Mosque.fromPlacesJson));

      final apiNextPageToken = data['next_page_token'] as String?;
      if (apiNextPageToken != null && results.length < maxResults) {
        nextPageToken = apiNextPageToken;
        // Google requires a short delay before a next_page_token is valid.
        await Future.delayed(const Duration(seconds: 2));
      } else {
        nextPageToken = null;
        // Genuinely exhausted only if Google itself had no further page -
        // if it did but we stopped anyway because maxResults was reached,
        // this result set is a truncated view, not the complete area.
        exhausted = apiNextPageToken == null;
      }
    } while (nextPageToken != null && results.length < maxResults);

    return (results.take(maxResults).toList(), exhausted);
  }
}
