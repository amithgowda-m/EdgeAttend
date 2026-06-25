// lib/features/analytics/providers/analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omnisense/features/analytics/data/analytics_repository.dart';

/// Provides the singleton AnalyticsRepository.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

/// Fetches and provides aggregated analytics data.
/// Returns an [AsyncValue<AnalyticsData>].
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  return ref.watch(analyticsRepositoryProvider).fetchAnalytics();
});
