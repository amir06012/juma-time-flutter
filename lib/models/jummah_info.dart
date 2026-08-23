/// Represents the Firestore document for a single mosque's Jummah times.
///
/// Approved times (shown to everyone) live in jummahTime1/jummahTime2.
/// Newly submitted times sit in the pending* fields until an admin
/// approves them - so nothing unverified is ever shown to other users.
class JummahInfo {
  final String? jummahTime1;
  final String? jummahTime2;
  final String? pendingJummahTime1;
  final String? pendingJummahTime2;
  final bool hasPending;

  JummahInfo({
    this.jummahTime1,
    this.jummahTime2,
    this.pendingJummahTime1,
    this.pendingJummahTime2,
    this.hasPending = false,
  });

  bool get hasApprovedTimes => jummahTime1 != null || jummahTime2 != null;

  factory JummahInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return JummahInfo();
    return JummahInfo(
      jummahTime1: map['jummahTime1'] as String?,
      jummahTime2: map['jummahTime2'] as String?,
      pendingJummahTime1: map['pendingJummahTime1'] as String?,
      pendingJummahTime2: map['pendingJummahTime2'] as String?,
      hasPending: map['hasPending'] as bool? ?? false,
    );
  }
}
