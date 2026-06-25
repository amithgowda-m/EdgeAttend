// lib/features/registry/providers/registry_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnisense/features/registry/data/registry_repository.dart';
import 'package:omnisense/features/registry/domain/models/member.dart';

/// Provides the singleton RegistryRepository.
final registryRepositoryProvider = Provider<RegistryRepository>((ref) {
  return RegistryRepository();
});

/// Live stream of all members.
final membersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(registryRepositoryProvider).watchAllMembers();
});

/// Notifier to handle toggling the is_flagged field on a member.
class FlagNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setFlagged({
    required String docId,
    required bool   isFlagged,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(registryRepositoryProvider).setFlaggedStatus(
            docId:     docId,
            isFlagged: isFlagged,
          ),
    );
  }
}

final flagNotifierProvider =
    AsyncNotifierProvider<FlagNotifier, void>(FlagNotifier.new);
