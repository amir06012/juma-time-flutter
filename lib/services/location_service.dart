import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Distinguishes *why* location isn't available so the UI can prompt with
/// the right action (enable the OS location service vs. grant/re-grant the
/// app permission) instead of a single generic "not available" message.
enum LocationAccess {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationService {
  /// Cheap, side-effect-free check of just the OS location toggle - unlike
  /// [checkAccess], this never prompts for permission, so it's safe to poll
  /// repeatedly (e.g. to detect the user flipping the toggle back on).
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Cheap, side-effect-free check of just the app permission - like
  /// [isServiceEnabled], this never prompts (unlike [checkAccess]), so it's
  /// safe to poll to detect the user granting permission from Settings.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Checks (and, for a first-time "denied" state, actively requests)
  /// location access, without yet reading a position.
  Future<LocationAccess> checkAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAccess.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationAccess.permissionDenied;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationAccess.permissionDeniedForever;
    }
    return LocationAccess.granted;
  }

  /// Returns the device's current position, or null if permission/service
  /// is unavailable *or* a fresh fix couldn't be read at all (timed out
  /// with no cached position to fall back to either). Call [checkAccess]
  /// first if you need to know *why* to show the right prompt to the user -
  /// and if you've already done so and know access is granted, call
  /// [getPosition] directly instead to skip this redundant re-check (it
  /// noticeably adds up on every reload).
  Future<Position?> getCurrentPosition() async {
    if (await checkAccess() != LocationAccess.granted) return null;
    try {
      return await getPosition();
    } on TimeoutException {
      // A fresh fix can take a while (or never come) with poor signal -
      // fall back to whatever was last cached rather than leaving the
      // caller with an unhandled exception.
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Reads a position without re-checking service/permission first - only
  /// call this once you already know access is granted (e.g. right after
  /// [checkAccess] returned [LocationAccess.granted]).
  ///
  /// Uses "medium" accuracy (~100m, resolved from wifi/cell towers) rather
  /// than "high" (GPS-precise, but can take many seconds for a first fix,
  /// especially indoors) - finding mosques/qibla direction/nearby geofences
  /// doesn't need GPS-level precision, so this trades accuracy we don't
  /// need for a much faster result. [timeLimit] caps the wait instead of
  /// leaving the caller hanging if a fix never comes.
  Future<Position> getPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  /// Accurate great-circle distance in kilometers between two points.
  double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }
}
