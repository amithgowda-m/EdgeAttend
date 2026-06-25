// lib/features/dashboard/data/dashboard_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnisense/core/constants/app_constants.dart';
import 'package:omnisense/features/dashboard/domain/models/event_log.dart';

/// Repository for Dashboard-level Firestore operations.
class DashboardRepository {
  final FirebaseFirestore _db;

  DashboardRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Live Event Feed ────────────────────────────────────────────────────────

  /// Real-time stream of the last [AppConstants.eventFeedLimit] events,
  /// ordered newest-first.
  Stream<List<EventLog>> watchEventFeed() {
    return _db
        .collection(AppConstants.eventsCollection)
        .orderBy(AppConstants.fieldTimestamp, descending: true)
        .limit(AppConstants.eventFeedLimit)
        .snapshots()
        .map((snap) => snap.docs.map(EventLog.fromFirestore).toList());
  }

  // ── Live Metrics ───────────────────────────────────────────────────────────

  /// Real-time count of members currently marked "Present".
  Stream<int> watchOccupancy() {
    return _db
        .collection(AppConstants.membersCollection)
        .where(AppConstants.fieldSessionStatus,
            isEqualTo: AppConstants.statusPresent)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Real-time count of "Unknown_Entity" events in the last 24 hours.
  Stream<int> watchActiveSecurityFlags() {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
    return _db
        .collection(AppConstants.eventsCollection)
        .where(AppConstants.fieldStatus,
            isEqualTo: AppConstants.statusUnknownEntity)
        .where(AppConstants.fieldTimestamp, isGreaterThan: since)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Initialize New Session ─────────────────────────────────────────────────

  /// Batch-updates ALL members, setting session_status to "Absent".
  /// Uses chunked batches (Firestore limit = 500 writes per batch).
  Future<void> initializeNewSession() async {
    final snap = await _db.collection(AppConstants.membersCollection).get();
    final docs  = snap.docs;

    const chunkSize = 400;
    for (var i = 0; i < docs.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = docs.sublist(
        i,
        (i + chunkSize) < docs.length ? i + chunkSize : docs.length,
      );
      for (final doc in chunk) {
        batch.update(doc.reference, {
          AppConstants.fieldSessionStatus: AppConstants.statusAbsent,
        });
      }
      await batch.commit();
    }
  }
}
