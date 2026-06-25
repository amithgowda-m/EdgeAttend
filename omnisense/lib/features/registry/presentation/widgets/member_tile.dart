// lib/features/registry/presentation/widgets/member_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/constants/app_constants.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/registry/domain/models/member.dart';
import 'package:omnisense/features/registry/providers/registry_provider.dart';

class MemberTile extends ConsumerWidget {
  final Member member;

  const MemberTile({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();
    final statusLabel = member.isPresent
        ? AppConstants.statusPresent.toUpperCase()
        : AppConstants.statusAbsent.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: OmniColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: member.isFlagged
              ? OmniColors.crimsonRed.withAlpha(80)
              : OmniColors.bgBorder,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Left accent bar ────────────────────────────────────────────
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Avatar ────────────────────────────────────────────────────
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withAlpha(60), width: 1.5),
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Name & ID ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OmniColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isFlagged) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.block,
                            color: OmniColors.crimsonRed,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          member.memberId.toUpperCase(),
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: OmniColors.cyanAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusChip(label: statusLabel, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Revoke Access Switch ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'REVOKE',
                    style: GoogleFonts.rajdhani(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: member.isFlagged
                          ? OmniColors.crimsonRed
                          : OmniColors.textDisabled,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Switch(
                    value:   member.isFlagged,
                    onChanged: (val) async {
                      await ref
                          .read(flagNotifierProvider.notifier)
                          .setFlagged(docId: member.docId, isFlagged: val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor() {
    if (member.isFlagged) return OmniColors.crimsonRed;
    if (member.isPresent) return OmniColors.neonGreen;
    return OmniColors.textSecondary;
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final Color  color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(70)),
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
