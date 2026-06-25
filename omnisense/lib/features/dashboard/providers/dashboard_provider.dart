// lib/features/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnisense/features/dashboard/data/dashboard_repository.dart';
import 'package:omnisense/features/dashboard/domain/models/event_log.dart';

/// Provides the singleton DashboardRepository.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Live stream of all recent events (newest first).
final eventFeedProvider = StreamProvider<List<EventLog>>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchEventFeed();
});

/// Live total occupancy count (members with status = Present).
final occupancyProvider = StreamProvider<int>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchOccupancy();
});

/// Live count of Unknown_Entity events in last 24 hours.
final securityFlagsProvider = StreamProvider<int>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchActiveSecurityFlags();
});

/// Notifier to handle the "Initialize New Session" batch write.
class SessionInitNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> initSession() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).initializeNewSession(),
    );
  }
}

final sessionInitProvider =
    AsyncNotifierProvider<SessionInitNotifier, void>(SessionInitNotifier.new);
