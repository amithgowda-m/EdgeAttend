// lib/features/registry/data/registry_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omnisense/core/constants/app_constants.dart';
import 'package:omnisense/features/registry/domain/models/member.dart';

/// Repository for Member Registry Firestore operations.
class RegistryRepository {
  final FirebaseFirestore _db;

  RegistryRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Real-time stream of all members, sorted by member_id.
  Stream<List<Member>> watchAllMembers() {
    return _db
        .collection(AppConstants.membersCollection)
        .orderBy(AppConstants.fieldMemberId)
        .snapshots()
        .map((snap) => snap.docs.map(Member.fromFirestore).toList());
  }

  /// Toggle the is_flagged field for a specific member document.
  Future<void> setFlaggedStatus({
    required String docId,
    required bool   isFlagged,
  }) async {
    await _db
        .collection(AppConstants.membersCollection)
        .doc(docId)
        .update({AppConstants.fieldIsFlagged: isFlagged});
  }
}
