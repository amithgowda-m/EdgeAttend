// lib/features/registry/domain/models/member.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnisense/core/constants/app_constants.dart';

/// Data model for a registered personnel member.
/// Document ID = Firestore auto-ID; member_id field holds the human-readable ID.
class Member {
  final String docId;
  final String memberId;
  final String name;
  final String sessionStatus;
  final bool   isFlagged;

  const Member({
    required this.docId,
    required this.memberId,
    required this.name,
    required this.sessionStatus,
    required this.isFlagged,
  });

  bool get isPresent => sessionStatus == AppConstants.statusPresent;
  bool get isAbsent  => sessionStatus == AppConstants.statusAbsent;

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      docId:         doc.id,
      memberId:      (data[AppConstants.fieldMemberId]      as String? ?? '').trim(),
      name:          (data[AppConstants.fieldName]          as String? ?? 'Unknown').trim(),
      sessionStatus: (data[AppConstants.fieldSessionStatus] as String? ?? AppConstants.statusAbsent).trim(),
      isFlagged:     (data[AppConstants.fieldIsFlagged]     as bool?   ?? false),
    );
  }

  Map<String, dynamic> toFirestore() => {
    AppConstants.fieldMemberId:      memberId,
    AppConstants.fieldName:          name,
    AppConstants.fieldSessionStatus: sessionStatus,
    AppConstants.fieldIsFlagged:     isFlagged,
  };

  Member copyWith({
    String? docId,
    String? memberId,
    String? name,
    String? sessionStatus,
    bool?   isFlagged,
  }) {
    return Member(
      docId:         docId         ?? this.docId,
      memberId:      memberId      ?? this.memberId,
      name:          name          ?? this.name,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      isFlagged:     isFlagged     ?? this.isFlagged,
    );
  }

  @override
  String toString() =>
      'Member(id: $memberId, name: $name, status: $sessionStatus, flagged: $isFlagged)';
}
