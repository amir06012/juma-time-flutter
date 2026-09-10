import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/mosque.dart';

/// A transition event surfaced from the native geofencing side while the
/// Flutter engine happens to be alive (foreground or background - not
/// after the process has been killed, at which point the native
/// notification is the only feedback the user sees).
class MosqueSilentModeEvent {
  final String type; // 'enter' | 'exit' | 'update'
  final String? placeId;
  final String? name;

  const MosqueSilentModeEvent({required this.type, this.placeId, this.name});

  factory MosqueSilentModeEvent.fromMap(Map<dynamic, dynamic> map) {
    return MosqueSilentModeEvent(
      type: map['type'] as String? ?? 'update',
      placeId: map['placeId'] as String?,
      name: map['name'] as String?,
    );
  }
}

/// A mosque currently registered as a geofence natively - i.e. one the user
/// has already selected for silent mode, as opposed to a candidate the
/// picker screen is merely offering.
class RegisteredMosque {
  final String placeId;
  final String name;
  final double latitude;
  final double longitude;

  const RegisteredMosque({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// Result of a [SilentModeService.syncSelectedMosques] call.
class SyncResult {
  final int added;
  final int removed;
  final int total;
  final String? error;

  const SyncResult({
    required this.added,
    required this.removed,
    required this.total,
    this.error,
  });

  bool get hasError => error != null;
}

/// Coordinates the "silence my phone inside a mosque I picked" feature:
/// hands the user's selected mosques' placeId/lat/lng to the native Android
/// geofencing side over a MethodChannel, then exposes transition events +
/// status back to the UI.
///
/// This service itself never decides *which* mosques - that's entirely the
/// caller's job (see SelectSilentModeMosquesScreen, which lists nearby
/// mosques for the user to check/uncheck). Once picked, detection of
/// actually entering/exiting one is still done natively, on-device, from
/// real GPS dwell time.
class SilentModeService {
  static const _methodChannel = MethodChannel('mosque_finder/geofencing');
  static const _eventChannel = EventChannel('mosque_finder/geofencing/events');

  Stream<MosqueSilentModeEvent>? _events;

  Stream<MosqueSilentModeEvent> get events {
    _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((e) => MosqueSilentModeEvent.fromMap(e as Map));
    return _events!;
  }

  Future<bool> hasFineLocation() => Permission.locationWhenInUse.isGranted;

  Future<bool> hasBackgroundLocation() => Permission.locationAlways.isGranted;

  Future<bool> isNotificationPolicyAccessGranted() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isNotificationPolicyAccessGranted') ?? false;
    } on PlatformException catch (e) {
      debugPrint('isNotificationPolicyAccessGranted failed: $e');
      return false;
    }
  }

  /// Opens the system "Do Not Disturb access" settings screen - there's no
  /// runtime permission dialog for this one, it's a special-access setting
  /// the user has to grant manually.
  Future<void> openNotificationPolicySettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationPolicySettings');
    } on PlatformException catch (e) {
      debugPrint('openNotificationPolicySettings failed: $e');
    }
  }

  Future<bool> isAutomationEnabled() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isAutomationEnabled') ?? true;
    } on PlatformException {
      return true;
    }
  }

  Future<void> setAutomationEnabled(bool enabled) async {
    try {
      await _methodChannel.invokeMethod('setAutomationEnabled', enabled);
    } on PlatformException catch (e) {
      debugPrint('setAutomationEnabled failed: $e');
    }
  }

  /// The phone's actual current ringer mode - `'silent'`, `'vibrate'`, or
  /// `'normal'` - read live from AudioManager rather than assumed from
  /// geofence state. That state can lie (DND access revoked after the fact,
  /// or the user flipping the ringer back manually), so this is the only
  /// way to show the user ground truth instead of just "we think you're at
  /// a mosque".
  Future<String> getRingerMode() async {
    try {
      return await _methodChannel.invokeMethod<String>('getRingerMode') ?? 'normal';
    } on PlatformException catch (e) {
      debugPrint('getRingerMode failed: $e');
      return 'normal';
    }
  }

  /// The mosque currently attributed as "the one you're at", or null.
  Future<Map<String, String>?> getActiveMosque() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('getActiveMosque');
      if (result == null) return null;
      return {
        'placeId': result['placeId'] as String? ?? '',
        'name': result['name'] as String? ?? '',
      };
    } on PlatformException catch (e) {
      debugPrint('getActiveMosque failed: $e');
      return null;
    }
  }

  Future<int> getRegisteredMosqueCount() async {
    try {
      return await _methodChannel.invokeMethod<int>('getRegisteredMosqueCount') ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  /// The mosques the user has already selected for silent mode - used to
  /// pre-check them when the picker screen reopens.
  Future<List<RegisteredMosque>> getRegisteredMosques() async {
    try {
      final result = await _methodChannel.invokeListMethod<dynamic>('getRegisteredMosques');
      if (result == null) return [];
      return result.map((m) {
        final map = (m as Map).cast<String, dynamic>();
        return RegisteredMosque(
          placeId: map['placeId'] as String? ?? '',
          name: map['name'] as String? ?? '',
          latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint('getRegisteredMosques failed: $e');
      return [];
    }
  }

  /// Registers exactly [selectedMosques] as geofences, replacing whatever
  /// was registered before - the native side diffs against the previous
  /// set and only adds/removes the difference. This is how mosque
  /// selection is saved; call it with the full picked set every time it
  /// changes, not just once at initial setup.
  Future<SyncResult> syncSelectedMosques(List<Mosque> selectedMosques) async {
    final payload = selectedMosques
        .map((m) => {
              'placeId': m.placeId,
              'name': m.name,
              'latitude': m.latitude,
              'longitude': m.longitude,
            })
        .toList();

    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'registerGeofences',
        payload,
      );
      return SyncResult(
        added: result?['added'] as int? ?? 0,
        removed: result?['removed'] as int? ?? 0,
        total: result?['total'] as int? ?? selectedMosques.length,
      );
    } on PlatformException catch (e) {
      debugPrint('registerGeofences failed: $e');
      return SyncResult(added: 0, removed: 0, total: 0, error: e.message ?? e.code);
    }
  }

  /// Debug-only: drives the exact same native code path a real DWELL
  /// transition would (silencing + prefs bookkeeping + the same event this
  /// service's [events] stream emits for a real one), without needing mock
  /// GPS or the 90s loiter delay. Requires at least one mosque already
  /// selected via [syncSelectedMosques]. Returns the mosque it simulated
  /// entering, or null on failure (see debugPrint for why - no mosque
  /// selected, or this was somehow called from a release build where the
  /// native side refuses it).
  ///
  /// This only proves the silencing mechanics work (permissions, DND,
  /// AudioManager, notifications) - it can't simulate Play Services' own
  /// location evaluation, so it's not a substitute for a real or
  /// mock-location device test of detection itself.
  Future<Map<String, String>?> debugSimulateEnter() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('debugSimulateEnter');
      if (result == null) return null;
      return {
        'placeId': result['placeId'] as String? ?? '',
        'name': result['name'] as String? ?? '',
      };
    } on PlatformException catch (e) {
      debugPrint('debugSimulateEnter failed: $e');
      return null;
    }
  }

  /// Debug-only counterpart to [debugSimulateEnter] - simulates the EXIT
  /// transition (restores the ringer, clears active-mosque state).
  Future<void> debugSimulateExit() async {
    try {
      await _methodChannel.invokeMethod('debugSimulateExit');
    } on PlatformException catch (e) {
      debugPrint('debugSimulateExit failed: $e');
    }
  }

  Future<void> clearGeofences() async {
    try {
      await _methodChannel.invokeMethod('clearGeofences');
    } on PlatformException catch (e) {
      debugPrint('clearGeofences failed: $e');
    }
  }
}
