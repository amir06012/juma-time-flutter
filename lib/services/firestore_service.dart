import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/jummah_info.dart';

class FirestoreService {
  // Looked up lazily (and guarded) rather than as a field initializer, since
  // Firebase may not be configured in this checkout - see main.dart.
  CollectionReference<Map<String, dynamic>>? get _mosquesOrNull {
    try {
      return FirebaseFirestore.instance.collection('mosques');
    } catch (_) {
      return null;
    }
  }

  /// Live-updating Jummah info for one mosque - used to show approved
  /// times, "pending approval", or "not added yet" in real time. Falls back
  /// to an empty/default value when Firebase isn't available so the mosque
  /// list can still render with sample data.
  Stream<JummahInfo> watchJummahInfo(String placeId) {
    final mosques = _mosquesOrNull;
    if (mosques == null) return Stream.value(JummahInfo());
    return mosques
        .doc(placeId)
        .snapshots()
        .map((doc) => JummahInfo.fromMap(doc.data()))
        .handleError((_) {});
  }

  /// Called when any user submits Jummah times for a mosque. Times are
  /// written to "pending" fields only - they do NOT overwrite the live
  /// jummahTime1/jummahTime2 fields, so nothing unverified is shown to
  /// other users until an admin approves it.
  Future<void> submitJummahTimes({
    required String placeId,
    required String mosqueName,
    required String jummahTime1,
    String? jummahTime2,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('mosques').doc(placeId).set({
      'name': mosqueName,
      'pendingJummahTime1': jummahTime1,
      'pendingJummahTime2': jummahTime2,
      'pendingSubmittedBy': user?.uid ?? 'anonymous',
      'pendingSubmittedAt': FieldValue.serverTimestamp(),
      'hasPending': true,
    }, SetOptions(merge: true));
  }

  // ---- Admin-only operations. Firestore security rules restrict writes
  // that touch jummahTime1/jummahTime2/approvedAt to admin accounts only -
  // see the README for the exact rules to paste into your Firebase console.

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingSubmissions() {
    return FirebaseFirestore.instance
        .collection('mosques')
        .where('hasPending', isEqualTo: true)
        .snapshots();
  }

  Future<void> approvePending(String placeId) async {
    final mosques = FirebaseFirestore.instance.collection('mosques');
    final doc = await mosques.doc(placeId).get();
    final data = doc.data();
    if (data == null) return;
    await mosques.doc(placeId).update({
      'jummahTime1': data['pendingJummahTime1'],
      'jummahTime2': data['pendingJummahTime2'],
      'pendingJummahTime1': FieldValue.delete(),
      'pendingJummahTime2': FieldValue.delete(),
      'pendingSubmittedBy': FieldValue.delete(),
      'pendingSubmittedAt': FieldValue.delete(),
      'hasPending': false,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectPending(String placeId) async {
    await FirebaseFirestore.instance.collection('mosques').doc(placeId).update({
      'pendingJummahTime1': FieldValue.delete(),
      'pendingJummahTime2': FieldValue.delete(),
      'pendingSubmittedBy': FieldValue.delete(),
      'pendingSubmittedAt': FieldValue.delete(),
      'hasPending': false,
    });
  }
}
