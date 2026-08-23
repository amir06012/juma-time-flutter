import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Answers "can this app actually reach the internet right now?".
///
/// `connectivity_plus` alone only reports whether the device is attached to
/// *some* network interface (wifi/cellular/ethernet) - that's true even for
/// a wifi network with no working upstream (captive portal, router with no
/// internet, etc.), so it isn't enough on its own. This service treats it as
/// a cheap first filter and follows up with a real HTTP reachability probe
/// before reporting "online".
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// True if the device is attached to a network interface AND a quick
  /// probe request actually gets a response.
  ///
  /// Errs on the side of "online" if the interface check itself throws for
  /// a reason unrelated to connectivity (e.g. an unsupported platform) -
  /// callers already fall back to sample data on any subsequent fetch
  /// failure, so a false positive here just costs one extra failed request
  /// rather than blocking the user from ever trying.
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) return false;
    } catch (_) {
      // Fall through to the real probe below rather than assuming offline.
    }
    return _probeReachability();
  }

  /// gstatic's generate_204 endpoint is tiny, fast, and used by Android
  /// itself for the same purpose - a 204 response means the request reached
  /// the real internet, not just a local captive-portal page.
  Future<bool> _probeReachability() async {
    try {
      final response = await http
          .head(Uri.https('www.gstatic.com', '/generate_204'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fires whenever the device's network attachment changes. This is a
  /// trigger to re-check [hasInternetConnection] and retry, not a
  /// reachability guarantee by itself - a "connected" event can still mean
  /// no real internet access.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
