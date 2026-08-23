import 'package:firebase_database/firebase_database.dart';
import '../models/jummah_info.dart';

/// Stores Jummah times per mosque (keyed by Google Place ID) in Firebase
/// Realtime Database. Submissions are written straight to the live
/// jummahTime1/jummahTime2 fields and shown immediately - unlike
/// FirestoreService, this intentionally skips the pending/admin-approval
/// step. That older verification workflow (FirestoreService,
/// AdminApprovalScreen, AdminLoginScreen) is left in the codebase in case
/// verification needs to come back later; it's just not used for this.
class RealtimeJummahService {
  DatabaseReference? get _mosquesOrNull {
    try {
      return FirebaseDatabase.instance.ref('mosques');
    } catch (_) {
      return null;
    }
  }

  Stream<JummahInfo> watchJummahInfo(String placeId) {
    final mosques = _mosquesOrNull;
    if (mosques == null) return Stream.value(JummahInfo());
    return mosques
        .child(placeId)
        .onValue
        .map((event) {
          final raw = event.snapshot.value;
          if (raw is! Map) return JummahInfo();
          return JummahInfo.fromMap(Map<String, dynamic>.from(raw));
        })
        .handleError((_) {});
  }

  /// Writes one Jummah time slot (1 or 2) for a mosque. Merges into the
  /// existing node rather than overwriting it, so adding the second time
  /// doesn't clobber the first.
  Future<void> submitJummahTime({
    required String placeId,
    required String mosqueName,
    required int slot,
    required String time,
  }) async {
    assert(slot == 1 || slot == 2);
    await FirebaseDatabase.instance.ref('mosques').child(placeId).update({
      'name': mosqueName,
      'jummahTime$slot': time,
    });
  }
}