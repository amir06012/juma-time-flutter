import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/mosque.dart';
import '../models/jummah_info.dart';
import '../services/connectivity_service.dart';
import '../services/distance_matrix_service.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';
import '../services/prayer_times_service.dart';
import '../services/weather_service.dart';
import '../services/geocoding_service.dart';
import '../utils/constants.dart';
import '../widgets/mosque_card.dart';
import '../widgets/prayer_times_bar.dart';
import '../widgets/location_time_weather_card.dart';
import 'add_jummah_sheet.dart';
import '../services/realtime_jummah_service.dart';

class MosqueListScreen extends StatefulWidget {
  const MosqueListScreen({super.key});

  @override
  State<MosqueListScreen> createState() => _MosqueListScreenState();
}

class _MosqueListScreenState extends State<MosqueListScreen>
    with WidgetsBindingObserver {
  final _locationService = LocationService();
  final _connectivityService = ConnectivityService();
  final _placesService = PlacesService(ApiKeys.googlePlacesApiKey);
  final _distanceMatrixService = DistanceMatrixService(ApiKeys.googlePlacesApiKey);
  final _prayerTimesService = PrayerTimesService();
  final _jummahService = RealtimeJummahService();
  final _weatherService = WeatherService();
  final _geocodingService = GeocodingService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _locationPollTimer;
  // Guards [_retryIfBackOnline] against overlapping calls: the connectivity
  // stream, the poll timer, and app-resume can all fire within the same
  // moment, and each does a couple of `await`s before deciding to call
  // [_load]. Without this lock, two of them can both pass the "nothing's
  // loading yet" check and both end up calling [_load] (and, inside it,
  // requesting location permission) at the same time - that's what showed
  // up as two progress/permission dialogs stacked on top of each other.
  bool _isCheckingAvailability = false;

  // Fallback content shown when location/Places/prayer-time fetches aren't
  // available (no API key configured, no internet, etc.) so the UI can
  // still be reviewed instead of showing a blank/error-only screen.
  static const _sampleLatitude = 21.4225;
  static const _sampleLongitude = 39.8262;
  static final _sampleMosques = [
    Mosque(
      placeId: 'sample-1',
      name: 'Al-Noor Mosque',
      address: '12 Main Street',
      latitude: _sampleLatitude + 0.003,
      longitude: _sampleLongitude + 0.002,
    ),
    Mosque(
      placeId: 'sample-2',
      name: 'Masjid Al-Falah',
      address: '48 Market Road',
      latitude: _sampleLatitude - 0.004,
      longitude: _sampleLongitude + 0.006,
    ),
    Mosque(
      placeId: 'sample-3',
      name: 'Islamic Center Mosque',
      address: '7 Green Avenue',
      latitude: _sampleLatitude + 0.006,
      longitude: _sampleLongitude - 0.005,
    ),
  ];
  static final _samplePrayerTimes = PrayerTimes(
    fajr: '05:15',
    dhuhr: '13:00',
    asr: '16:30',
    maghrib: '19:45',
    isha: '21:00',
  );

  List<Mosque> _mosques = [];
  // Real road-distance per mosque.placeId from DistanceMatrixService, so it
  // matches what Google Maps shows instead of straight-line distance.
  // Mosques missing from this map (API failure/timeout, or offline/sample
  // data) fall back to LocationService.distanceKm - see
  // [_distanceKmFor].
  Map<String, double> _mosqueDistances = {};
  double? _userLat;
  double? _userLng;
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String? _notice;
  bool _usingSampleData = false;
  LocationAccess? _locationAccess;
  bool _isOffline = false;
  String? _locationName;
  double? _temperatureCelsius;

  // Jummah streams are memoized per mosque instead of being created inline
  // in build(), since StreamBuilder must be given a stable Stream instance
  // across rebuilds - recreating it on every build re-subscribes to a fresh
  // stream each time.
  //
  // IMPORTANT: the stream returned by FirestoreService.watchJummahInfo() may
  // be single-subscription (e.g. a Stream.value(...) fallback when Firebase
  // isn't configured). If *anything* ever ends up listening to the same
  // cached instance twice - a second StreamBuilder, a rebuild path that
  // doesn't go through putIfAbsent as expected, hot reload, etc. - that
  // throws "Bad state: Stream has already been listened to." Converting to
  // a broadcast stream here makes it safe to listen to multiple times no
  // matter what FirestoreService does internally. See the StreamBuilder
  // class docs on flutter.dev/testing/errors.
  final Map<String, Stream<JummahInfo>> _jummahStreams = {};

  // A plain broadcast stream never replays events that already fired before
  // a listener subscribes. ListView(children: ...) builds/disposes each
  // card's StreamBuilder lazily as it scrolls in and out of view, and the
  // parent screen isn't rebuilt by scrolling alone - so a card that scrolls
  // off-screen and back gets a brand-new StreamBuilder that resubscribes
  // from scratch and misses everything emitted while it was gone. Stream
  // .multi lets every individual subscribe (first-time or after being
  // recreated) synthesize the latest cached value before forwarding live
  // updates, so a card always shows current data the instant it's rebuilt.
  final Map<String, JummahInfo> _jummahLatest = {};

  Stream<JummahInfo> _jummahStreamFor(String placeId) {
    return _jummahStreams.putIfAbsent(placeId, () {
      final source =
          _jummahService.watchJummahInfo(placeId).asBroadcastStream();
      source.listen((info) => _jummahLatest[placeId] = info);
      return Stream<JummahInfo>.multi((controller) {
        final cached = _jummahLatest[placeId];
        if (cached != null) controller.add(cached);
        final subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // The device can flip between offline and online while this screen is
    // open (leaving a building's wifi, a train tunnel, etc.). Re-check
    // reachability whenever the network attachment changes and quietly
    // retry the live fetch so the user doesn't have to pull-to-refresh
    // manually once they're back online.
    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((_) => _retryIfBackOnline());
    // The OS location toggle/permission has no change-stream to listen to,
    // so poll for it too - this covers flipping it from the quick-settings
    // tray without ever leaving the app (didChangeAppLifecycleState below
    // won't fire for that, since the app never actually backgrounds).
    _locationPollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _retryIfBackOnline());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _locationPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The other common flow: user leaves to the OS Settings app to flip
    // location on or grant the permission, then comes straight back - check
    // immediately instead of waiting up to 3s for the next poll tick.
    if (state == AppLifecycleState.resumed) _retryIfBackOnline();
  }

  // Location has no change-stream (unlike connectivity), so this is called
  // from the poll timer and app-resume too - cheap local checks, no network
  // calls, when nothing is actually wrong.
  Future<void> _retryIfBackOnline() async {
    if (!mounted || _isLoading || _isCheckingAvailability) return;
    final needsInternetRetry = _isOffline;
    final needsLocationRetry =
        _locationAccess != null && _locationAccess != LocationAccess.granted;
    if (!needsInternetRetry && !needsLocationRetry) return;

    _isCheckingAvailability = true;
    try {
      if (needsLocationRetry) {
        final stillBlocked = switch (_locationAccess!) {
          LocationAccess.serviceDisabled =>
            !await _locationService.isServiceEnabled(),
          LocationAccess.permissionDenied ||
          LocationAccess.permissionDeniedForever =>
            !await _locationService.hasPermission(),
          LocationAccess.granted => false,
        };
        if (stillBlocked) return;
      }
      if (needsInternetRetry &&
          !await _connectivityService.hasInternetConnection()) {
        return; // still offline
      }
      if (!mounted || _isLoading) return; // re-check after the awaits above
      _load();
    } finally {
      _isCheckingAvailability = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _notice = null;
      _usingSampleData = false;
      _locationAccess = null;
      _isOffline = false;
      _jummahStreams.clear();
      _mosqueDistances = {};
    });

    // Connectivity and location access don't depend on each other, so check
    // both at once instead of one after the other - this alone shaves a
    // couple of seconds off a slow load.
    final checks = await Future.wait([
      _connectivityService.hasInternetConnection(),
      _locationService.checkAccess(),
    ]);
    _isOffline = !(checks[0] as bool);
    final access = checks[1] as LocationAccess;
    _locationAccess = access;

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      if (access != LocationAccess.granted) {
        _showNothing(switch (access) {
          LocationAccess.serviceDisabled =>
          l10n.turnOnLocationMosques,
          LocationAccess.permissionDenied ||
          LocationAccess.permissionDeniedForever =>
          l10n.locationPermissionRequiredMosques,
          LocationAccess.granted => '',
        });
      } else if (_isOffline) {
        // Internet is checked before reading a position so an offline
        // device isn't left waiting on a GPS fix it can't use anyway.
        _showNothing(l10n.turnOnInternetMosques);
      } else {
        // Access is already confirmed granted above, so this skips
        // getCurrentPosition()'s redundant internal re-check.
        final position = await _locationService.getPosition();
        _userLat = position.latitude;
        _userLng = position.longitude;

        // Mosques/prayer-times (critical - failure here falls back to
        // sample data) and location-name/weather (best-effort, handles its
        // own failures) don't depend on each other, so all start together.
        // Road distances depend on the mosque list itself, so that call is
        // fired as soon as mosques come back rather than waiting on
        // everything else too.
        final mosquesFuture = _placesService.fetchNearbyMosques(
          latitude: _userLat!,
          longitude: _userLng!,
        );
        final prayerTimesFuture = _prayerTimesService.fetchToday(
          latitude: _userLat!,
          longitude: _userLng!,
        );
        final extraFuture = _loadLocationAndWeather();

        _mosques = await mosquesFuture;
        final distancesFuture = _distanceMatrixService.drivingDistancesKm(
          originLat: _userLat!,
          originLng: _userLng!,
          destinations: _mosques,
        );

        _prayerTimes = await prayerTimesFuture;
        _mosqueDistances = await distancesFuture;
        await extraFuture;
      }
    } catch (e) {
      _useSampleData(_isOffline
          ? l10n.offlineShowingSample
          : l10n.fetchErrorShowingSample(e.toString()));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadLocationAndWeather() async {
    if (_userLat == null || _userLng == null) return;
    final l10n = AppLocalizations.of(context)!;
    if (_isOffline) {
      _locationName ??= l10n.locationUnavailableOffline;
      return;
    }
    try {
      final results = await Future.wait<Object?>([
        _geocodingService.reverseGeocode(
          latitude: _userLat!,
          longitude: _userLng!,
        ),
        _weatherService.fetchCurrent(
          latitude: _userLat!,
          longitude: _userLng!,
        ),
      ]);
      _locationName = (results[0] as String?) ?? l10n.nearbyAreaFallback;
      _temperatureCelsius = (results[1] as WeatherInfo).temperatureCelsius;
    } catch (_) {
      _locationName ??= l10n.locationUnavailable;
    }
  }

  void _useSampleData(String notice) {
    _notice = notice;
    _usingSampleData = true;
    _userLat ??= _sampleLatitude;
    _userLng ??= _sampleLongitude;
    _mosques = _sampleMosques;
    _prayerTimes = _samplePrayerTimes;
  }

  /// Used instead of [_useSampleData] when location or internet is off:
  /// shows no mosques at all rather than sample ones, since sample data
  /// would look like a real (if short) result. [_retryIfBackOnline] reloads
  /// the real list automatically the moment the user turns either back on.
  void _showNothing(String notice) {
    _notice = notice;
    _usingSampleData = false;
    _mosques = [];
    _prayerTimes = null;
  }

  Future<void> _resolveLocationAccess() async {
    switch (_locationAccess) {
      case LocationAccess.serviceDisabled:
        await _locationService.openLocationSettings();
        break;
      case LocationAccess.permissionDenied:
      case LocationAccess.permissionDeniedForever:
        await _locationService.openAppSettings();
        break;
      case LocationAccess.granted:
      case null:
        break;
    }
    // The user grants access in a system settings screen, not inside this
    // app, so re-check once they switch back to it rather than immediately.
    await _load();
  }

  /// Real driving distance from [DistanceMatrixService] when available
  /// (matches Google Maps); falls back to straight-line distance for any
  /// mosque it didn't cover (API failure/timeout, offline, sample data).
  double _distanceKmFor(Mosque mosque) {
    if (_userLat == null || _userLng == null) return 0;
    return _mosqueDistances[mosque.placeId] ??
        _locationService.distanceKm(
            _userLat!, _userLng!, mosque.latitude, mosque.longitude);
  }

  List<Mosque> _sortedMosquesByDistance() {
    if (_userLat == null || _userLng == null) return _mosques;
    final sorted = [..._mosques];
    sorted.sort((a, b) => _distanceKmFor(a).compareTo(_distanceKmFor(b)));
    return sorted;
  }

  void _openAddJummah(Mosque mosque, int slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddJummahSheet(
        mosque: mosque,
        jummahService: _jummahService,
        slot: slot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mosqueListTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            LocationTimeWeatherCard(
              locationName: _locationName ?? l10n.locatingEllipsis,
              temperatureCelsius: _temperatureCelsius,
            ),
            if (_notice != null)
              Container(
                width: double.infinity,
                color: _usingSampleData
                    ? Colors.amber.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(_notice!, textAlign: TextAlign.center),
                    if (_locationAccess != null &&
                        _locationAccess != LocationAccess.granted) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _resolveLocationAccess,
                        child: Text(
                          _locationAccess ==
                              LocationAccess.serviceDisabled
                              ? l10n.turnOnLocationAction
                              : l10n.grantLocationPermissionAction,
                        ),
                      ),
                    ] else if (_isOffline) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retryAction),
                      ),
                    ],
                  ],
                ),
              ),
            PrayerTimesBar(times: _prayerTimes),
            if (_mosques.isEmpty && _notice == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noMosquesFoundNearby1km),
              ),
            if (_mosques.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Text(
                      l10n.mosquesNearbyCount(_mosques.length),
                      style: AppFonts.heading(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.richBlack,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.tune, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ..._sortedMosquesByDistance().asMap().entries.map((entry) {
              final index = entry.key;
              final mosque = entry.value;
              final distanceKm = _distanceKmFor(mosque);
              return StreamBuilder<JummahInfo>(
                stream: _jummahStreamFor(mosque.placeId),
                initialData: _jummahLatest[mosque.placeId],
                builder: (context, snapshot) {
                  final jummahInfo = snapshot.data ?? JummahInfo();
                  return MosqueCard(
                    mosque: mosque,
                    distanceKm: distanceKm,
                    jummahInfo: jummahInfo,
                    isNearest: index == 0 && _mosques.length > 1,
                    onAddJummahTap: (slot) => _openAddJummah(mosque, slot),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}