// lib/features/dashboard/presentation/widgets/live_metrics_box.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/dashboard/providers/dashboard_provider.dart';

class LiveMetricsBox extends ConsumerWidget {
  const LiveMetricsBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupancy     = ref.watch(occupancyProvider);
    final securityFlags = ref.watch(securityFlagsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OmniColors.bgBorder),
        boxShadow: [
          BoxShadow(
            color: OmniColors.neonGreen.withAlpha(18),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: OmniColors.neonGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE METRICS',
                style: OmniTextStyles.sectionHeader(context),
              ),
              const Spacer(),
              _PulsingDot(),
              const SizedBox(width: 6),
              Text(
                'REAL-TIME',
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  color: OmniColors.neonGreen,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Metric Cards ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label:    'TOTAL OCCUPANCY',
                  asyncVal: occupancy,
                  accent:   OmniColors.neonGreen,
                  icon:     Icons.people_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label:    'ACTIVE SECURITY FLAGS',
                  asyncVal: securityFlags,
                  accent:   OmniColors.crimsonRed,
                  icon:     Icons.warning_amber_outlined,
                  suffix:   ' / 24h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Individual Metric Card ────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String           label;
  final AsyncValue<int>  asyncVal;
  final Color            accent;
  final IconData         icon;
  final String           suffix;

  const _MetricCard({
    required this.label,
    required this.asyncVal,
    required this.accent,
    required this.icon,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OmniColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: OmniColors.textSecondary,
                    letterSpacing: 1.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          asyncVal.when(
            data: (value) => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.rajdhani(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1.0,
                  ),
                ),
                if (suffix.isNotEmpty)
                  Text(
                    suffix,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: OmniColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
            loading: () => SizedBox(
              height: 38,
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                ),
              ),
            ),
            error: (_, __) => Text(
              'ERR',
              style: GoogleFonts.rajdhani(
                fontSize: 28,
                color: OmniColors.crimsonRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing Live Indicator ────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: OmniColors.neonGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
