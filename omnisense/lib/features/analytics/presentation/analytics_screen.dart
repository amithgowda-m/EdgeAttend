// lib/features/analytics/presentation/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/constants/app_constants.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/analytics/presentation/widgets/bar_chart_widget.dart';
import 'package:omnisense/features/analytics/presentation/widgets/pie_chart_widget.dart';
import 'package:omnisense/features/analytics/providers/analytics_provider.dart';
import 'package:omnisense/shared/widgets/app_drawer.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: OmniColors.bgSurface,
      appBar: _buildAppBar(ref),
      drawer: const AppDrawer(),
      body: analyticsAsync.when(
        data: (data) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Stats Summary Row ────────────────────────────────────────────
            _StatsSummaryRow(data: data),
            const SizedBox(height: 16),

            // ── Bar Chart ────────────────────────────────────────────────────
            PeakHoursBarChart(data: data),
            const SizedBox(height: 16),

            // ── Pie Chart ────────────────────────────────────────────────────
            AccessStatusPieChart(data: data),
            const SizedBox(height: 16),

            // ── Footer Note ──────────────────────────────────────────────────
            Center(
              child: Text(
                'Data sourced from Firestore "events" collection · '
                'Last ${AppConstants.analyticsLookbackDays} days',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: OmniColors.textDisabled,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: OmniColors.neonGreen),
              SizedBox(height: 16),
              Text(
                'Querying event analytics…',
                style: TextStyle(color: OmniColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: OmniColors.crimsonRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  'ANALYTICS ERROR',
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OmniColors.crimsonRed,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: OmniColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon:    const Icon(Icons.refresh, size: 16),
                  label:   const Text('RETRY'),
                  onPressed: () => ref.invalidate(analyticsProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WidgetRef ref) {
    return AppBar(
      backgroundColor: OmniColors.bgDeep,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: OmniColors.textSecondary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'ANALYTICS',
        style: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: OmniColors.textPrimary,
          letterSpacing: 3.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: OmniColors.textSecondary, size: 20),
          tooltip: 'Refresh analytics',
          onPressed: () => ref.invalidate(analyticsProvider),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: OmniColors.bgBorder, height: 1),
      ),
    );
  }
}

// ─── Stats Summary Row ─────────────────────────────────────────────────────────
class _StatsSummaryRow extends StatelessWidget {
  final dynamic data; // AnalyticsData

  const _StatsSummaryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon:  Icons.check_circle_outline,
            label: 'GRANTED',
            value: '${data.grantedCount}',
            color: OmniColors.neonGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon:  Icons.warning_amber_outlined,
            label: 'ANOMALIES',
            value: '${data.unknownCount}',
            color: OmniColors.crimsonRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon:  Icons.event_note_outlined,
            label: 'TOTAL',
            value: '${data.totalEvents}',
            color: OmniColors.cyanAccent,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: OmniColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 9,
              color: OmniColors.textSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
