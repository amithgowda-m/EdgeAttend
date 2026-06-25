// lib/features/dashboard/presentation/widgets/event_feed_tile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/constants/app_constants.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/core/utils/date_formatter.dart';
import 'package:omnisense/features/dashboard/domain/models/event_log.dart';

class EventFeedTile extends StatelessWidget {
  final EventLog event;
  final bool     isFirst;

  const EventFeedTile({
    super.key,
    required this.event,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final (accent, bgColor, icon, statusLabel) = _resolveStyle();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(50), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Accent bar ─────────────────────────────────────────────────
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Icon ───────────────────────────────────────────────────────
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: accent.withAlpha(22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withAlpha(60)),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 12),
            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: OmniColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(label: statusLabel, color: accent),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          event.memberId.toUpperCase(),
                          style: GoogleFonts.robotoMono(
                            fontSize: 10,
                            color: OmniColors.cyanAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: OmniColors.textDisabled,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormatter.relative(event.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: OmniColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Timestamp ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                DateFormatter.timeOnly(event.timestamp),
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: OmniColors.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData, String) _resolveStyle() {
    switch (event.status) {
      case AppConstants.statusAccessGranted:
        return (
          OmniColors.neonGreen,
          OmniColors.neonGreen.withAlpha(10),
          Icons.check_circle_outline,
          'GRANTED',
        );
      case AppConstants.statusUnknownEntity:
        return (
          OmniColors.crimsonRed,
          OmniColors.crimsonRed.withAlpha(12),
          Icons.warning_amber_outlined,
          'UNKNOWN',
        );
      case AppConstants.statusAccessDenied:
        return (
          OmniColors.amberWarning,
          OmniColors.amberWarning.withAlpha(10),
          Icons.block_outlined,
          'DENIED',
        );
      default:
        return (
          OmniColors.textSecondary,
          OmniColors.bgCard,
          Icons.radio_button_unchecked,
          event.status,
        );
    }
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color  color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GoogleFonts.rajdhani(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
