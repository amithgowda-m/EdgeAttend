// lib/features/analytics/data/analytics_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnisense/core/constants/app_constants.dart';
import 'package:omnisense/features/dashboard/domain/models/event_log.dart';

class AnalyticsData {
  /// Key = hour (0–23), Value = count of entries in that hour
  final Map<int, int> entryVolumeByHour;

  /// Counts per status type
  final int grantedCount;
  final int unknownCount;
  final int deniedCount;

  const AnalyticsData({
    required this.entryVolumeByHour,
    required this.grantedCount,
    required this.unknownCount,
    required this.deniedCount,
  });

  int get totalEvents => grantedCount + unknownCount + deniedCount;
}

/// Repository for Analytics Firestore queries.
class AnalyticsRepository {
  final FirebaseFirestore _db;

  AnalyticsRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Fetches events from the last [AppConstants.analyticsLookbackDays] days
  /// and returns aggregated [AnalyticsData].
  Future<AnalyticsData> fetchAnalytics() async {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(
        const Duration(days: AppConstants.analyticsLookbackDays),
      ),
    );

    final snap = await _db
        .collection(AppConstants.eventsCollection)
        .where(AppConstants.fieldTimestamp, isGreaterThan: since)
        .orderBy(AppConstants.fieldTimestamp)
        .get();

    final events = snap.docs.map(EventLog.fromFirestore).toList();

    // Aggregate entry volumes by hour
    final Map<int, int> byHour = {};
    for (var i = 0; i < 24; i++) {
      byHour[i] = 0;
    }

    int granted = 0;
    int unknown = 0;
    int denied  = 0;

    for (final e in events) {
      final hour = e.timestamp.toLocal().hour;
      byHour[hour] = (byHour[hour] ?? 0) + 1;

      if (e.isGranted) {
        granted++;
      } else if (e.isUnknown) {
        unknown++;
      } else if (e.isDenied) {
        denied++;
      }
    }

    return AnalyticsData(
      entryVolumeByHour: byHour,
      grantedCount:      granted,
      unknownCount:      unknown,
      deniedCount:       denied,
    );
  }
}
