// lib/features/dashboard/domain/models/event_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnisense/core/constants/app_constants.dart';

/// Data model for a single event log entry from the 'events' Firestore collection.
/// Schema mirrors the MQTT payload structure from gateway.py for seamless migration.
class EventLog {
  final String   docId;
  final String   memberId;
  final String   name;
  final DateTime timestamp;
  final String   status;
  final String   action;

  const EventLog({
    required this.docId,
    required this.memberId,
    required this.name,
    required this.timestamp,
    required this.status,
    required this.action,
  });

  bool get isGranted       => status == AppConstants.statusAccessGranted;
  bool get isUnknown       => status == AppConstants.statusUnknownEntity;
  bool get isDenied        => status == AppConstants.statusAccessDenied;

  factory EventLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime ts;
    final raw = data[AppConstants.fieldTimestamp];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return EventLog(
      docId:     doc.id,
      memberId:  (data[AppConstants.fieldMemberId] as String? ?? 'unknown').trim(),
      name:      (data[AppConstants.fieldName]     as String? ?? 'Unknown Entity').trim(),
      timestamp: ts,
      status:    (data[AppConstants.fieldStatus]   as String? ?? AppConstants.statusUnknownEntity).trim(),
      action:    (data[AppConstants.fieldAction]   as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    AppConstants.fieldMemberId:  memberId,
    AppConstants.fieldName:      name,
    AppConstants.fieldTimestamp: Timestamp.fromDate(timestamp),
    AppConstants.fieldStatus:    status,
    AppConstants.fieldAction:    action,
  };
}
