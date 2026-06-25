// lib/features/analytics/presentation/widgets/pie_chart_widget.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/analytics/data/analytics_repository.dart';

class AccessStatusPieChart extends StatefulWidget {
  final AnalyticsData data;

  const AccessStatusPieChart({super.key, required this.data});

  @override
  State<AccessStatusPieChart> createState() => _AccessStatusPieChartState();
}

class _AccessStatusPieChartState extends State<AccessStatusPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total    = widget.data.totalEvents;
    final granted  = widget.data.grantedCount;
    final unknown  = widget.data.unknownCount;
    final denied   = widget.data.deniedCount;

    final sections = <PieChartSectionData>[
      _section(
        index: 0,
        value: granted.toDouble(),
        color: OmniColors.neonGreen,
        title: 'ACCESS\nGRANTED',
      ),
      _section(
        index: 1,
        value: unknown.toDouble(),
        color: OmniColors.crimsonRed,
        title: 'SECURITY\nANOMALY',
      ),
      if (denied > 0)
        _section(
          index: 2,
          value: denied.toDouble(),
          color: OmniColors.amberWarning,
          title: 'ACCESS\nDENIED',
        ),
    ];

    // If all zeros, show a placeholder section
    final showEmpty = total == 0;
    final effectiveSections = showEmpty
        ? [
            PieChartSectionData(
              value: 1,
              color: OmniColors.bgBorder,
              radius: 50,
              title: '',
            )
          ]
        : sections;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OmniColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OmniColors.bgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ─────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.pie_chart_outline,
                  color: OmniColors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'ACCESS vs ANOMALIES',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: OmniColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          Text(
            'Last 30 days · $total total events',
            style: GoogleFonts.inter(fontSize: 11, color: OmniColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // ── Chart ────────────────────────────────────────────────────
              SizedBox(
                height: 160,
                width:  160,
                child: PieChart(
                  PieChartData(
                    sections:         effectiveSections,
                    centerSpaceRadius: 42,
                    sectionsSpace:    2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // ── Legend ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showEmpty) ...[
                      Text(
                        'NO DATA',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: OmniColors.textDisabled,
                          letterSpacing: 2,
                        ),
                      ),
                    ] else ...[
                      _LegendItem(
                        color: OmniColors.neonGreen,
                        label: 'Access Granted',
                        count: granted,
                        total: total,
                      ),
                      const SizedBox(height: 10),
                      _LegendItem(
                        color: OmniColors.crimsonRed,
                        label: 'Security Anomaly',
                        count: unknown,
                        total: total,
                      ),
                      if (denied > 0) ...[
                        const SizedBox(height: 10),
                        _LegendItem(
                          color: OmniColors.amberWarning,
                          label: 'Access Denied',
                          count: denied,
                          total: total,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section({
    required int    index,
    required double value,
    required Color  color,
    required String title,
  }) {
    final isTouched = index == _touchedIndex;
    return PieChartSectionData(
      value:       value,
      color:       color,
      radius:      isTouched ? 60 : 50,
      title:       '',
      borderSide: BorderSide(
        color: isTouched ? Colors.white.withAlpha(60) : Colors.transparent,
        width: isTouched ? 2 : 0,
      ),
    );
  }
}

// ─── Legend Item ──────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color  color;
  final String label;
  final int    count;
  final int    total;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: OmniColors.textSecondary,
                ),
              ),
              Text(
                '$count events · $pct%',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
