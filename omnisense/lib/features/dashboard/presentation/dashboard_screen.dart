// lib/features/dashboard/presentation/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/core/utils/date_formatter.dart';
import 'package:omnisense/features/dashboard/presentation/widgets/event_feed_tile.dart';
import 'package:omnisense/features/dashboard/presentation/widgets/live_metrics_box.dart';
import 'package:omnisense/features/dashboard/providers/dashboard_provider.dart';
import 'package:omnisense/shared/widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventFeed = ref.watch(eventFeedProvider);
    final sessionInit = ref.watch(sessionInitProvider);

    return Scaffold(
      backgroundColor: OmniColors.bgSurface,
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Live Metrics Box ───────────────────────────────────────────────
          const LiveMetricsBox(),

          const SizedBox(height: 16),

          // ── Initialize Session Button ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SessionInitButton(sessionInit: sessionInit, ref: ref),
          ),

          const SizedBox(height: 16),

          // ── Feed Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.stream, color: OmniColors.cyanAccent, size: 14),
                const SizedBox(width: 8),
                Text(
                  'LIVE EVENT FEED',
                  style: OmniTextStyles.sectionHeader(context),
                ),
                const Spacer(),
                eventFeed.when(
                  data: (events) => Text(
                    '${events.length} EVENTS',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      color: OmniColors.textDisabled,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Live Event Stream ─────────────────────────────────────────────
          Expanded(
            child: eventFeed.when(
              data: (events) {
                if (events.isEmpty) {
                  return _EmptyFeed();
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: events.length,
                  itemBuilder: (_, i) => EventFeedTile(
                    event:   events[i],
                    isFirst: i == 0,
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: OmniColors.neonGreen),
              ),
              error: (err, _) => _ErrorState(message: err.toString()),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: OmniColors.bgDeep,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: OmniColors.textSecondary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Text(
            'COMMAND HUD',
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: OmniColors.textPrimary,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: OmniColors.neonGreen.withAlpha(20),
              border: Border.all(color: OmniColors.neonGreen.withAlpha(80)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.rajdhani(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: OmniColors.neonGreen,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Text(
              DateFormatter.timeOnly(DateTime.now()),
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: OmniColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: OmniColors.bgBorder, height: 1),
      ),
    );
  }
}

// ─── Initialize Session Button ─────────────────────────────────────────────────
class _SessionInitButton extends StatelessWidget {
  final AsyncValue<void> sessionInit;
  final WidgetRef        ref;

  const _SessionInitButton({
    required this.sessionInit,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = sessionInit.isLoading;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              // Confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: OmniColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: OmniColors.bgBorder),
                  ),
                  title: Text(
                    'INITIALIZE NEW SESSION?',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: OmniColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  content: Text(
                    'This will mark ALL members as "Absent" in Firestore. '
                    'Use this before a new meeting or session begins.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: OmniColors.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.rajdhani(
                          color: OmniColors.textSecondary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: OmniColors.neonGreen,
                      ),
                      child: Text(
                        'INITIALIZE',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: OmniColors.textOnAccent,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(sessionInitProvider.notifier).initSession();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: OmniColors.neonGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Session initialized — all members set to Absent.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: OmniColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1A2A1A), Color(0xFF111A11)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? OmniColors.bgCard : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLoading
                ? OmniColors.bgBorder
                : OmniColors.neonGreen.withAlpha(100),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: OmniColors.neonGreen,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'INITIALIZING SESSION…',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: OmniColors.textSecondary,
                  letterSpacing: 2.5,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.play_circle_outline,
                color: OmniColors.neonGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'INITIALIZE NEW SESSION',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: OmniColors.neonGreen,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '— RESET ALL TO ABSENT',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  color: OmniColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty Feed ────────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stream, color: OmniColors.bgBorder, size: 48),
          const SizedBox(height: 12),
          Text(
            'NO EVENTS YET',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: OmniColors.textDisabled,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Events will appear here in real time',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: OmniColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: OmniColors.crimsonRed, size: 40),
            const SizedBox(height: 12),
            Text(
              'STREAM ERROR',
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                color: OmniColors.crimsonRed,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: OmniColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
