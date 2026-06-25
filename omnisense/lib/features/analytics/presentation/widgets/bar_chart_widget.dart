// lib/features/analytics/presentation/widgets/bar_chart_widget.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/core/utils/date_formatter.dart';
import 'package:omnisense/features/analytics/data/analytics_repository.dart';

class PeakHoursBarChart extends StatelessWidget {
  final AnalyticsData data;

  const PeakHoursBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.entryVolumeByHour.values.fold<int>(
          0, (a, b) => a > b ? a : b)
        .toDouble();
    final chartMaxY = (maxY + 2).clamp(5.0, double.infinity);

    // Show only every 3rd hour on x-axis to avoid crowding
    final barGroups = List.generate(24, (hour) {
      final count = data.entryVolumeByHour[hour]?.toDouble() ?? 0;
      return BarChartGroupData(
        x:        hour,
        barRods: [
          BarChartRodData(
            toY:      count,
            width:    10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            gradient: count > 0
                ? const LinearGradient(
                    colors: [OmniColors.neonGreen, OmniColors.neonGreenDim],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            color: count > 0 ? null : OmniColors.bgBorder,
          ),
        ],
      );
    });

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
          Row(
            children: [
              const Icon(Icons.bar_chart, color: OmniColors.neonGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'PEAK ENTRY VOLUMES BY HOUR',
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
            'Last ${30} days · 24h window',
            style: GoogleFonts.inter(fontSize: 11, color: OmniColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment:   BarChartAlignment.spaceAround,
                maxY:        chartMaxY,
                barGroups:   barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (chartMaxY / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: OmniColors.bgBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: OmniColors.bgBorder),
                    left:   BorderSide(color: OmniColors.bgBorder),
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (chartMaxY / 4).clamp(1, double.infinity),
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          color: OmniColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, _) {
                        final h = value.toInt();
                        // Show every 4 hours: 0, 4, 8, 12, 16, 20
                        if (h % 4 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormatter.hourLabel(h),
                            style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              color: OmniColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => OmniColors.bgCardHover,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${DateFormatter.hourLabel(group.x)}\n',
                      GoogleFonts.rajdhani(
                        color: OmniColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toInt()} entries',
                          style: GoogleFonts.rajdhani(
                            color: OmniColors.neonGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
