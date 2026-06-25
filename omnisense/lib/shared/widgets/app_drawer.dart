// lib/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.maybeWhen(
      data: (user) => user?.email ?? 'Admin',
      orElse: () => 'Admin',
    );

    return Drawer(
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width:   double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: const BoxDecoration(
              color: OmniColors.bgDeep,
              border: Border(
                bottom: BorderSide(color: OmniColors.bgBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: OmniColors.neonGreen, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: OmniColors.neonGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'OMNISENSE',
                  style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: OmniColors.textPrimary,
                    letterSpacing: 3.0,
                  ),
                ),
                Text(
                  'COMMAND CENTER',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: OmniColors.neonGreen,
                    letterSpacing: 3.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.circle, color: OmniColors.neonGreen, size: 8),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        userEmail,
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: OmniColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Navigation Items ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon:  Icons.dashboard_outlined,
                  label: 'COMMAND HUD',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                ),
                _DrawerItem(
                  icon:  Icons.badge_outlined,
                  label: 'MEMBER REGISTRY',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/registry');
                  },
                ),
                _DrawerItem(
                  icon:  Icons.bar_chart_outlined,
                  label: 'ANALYTICS',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/analytics');
                  },
                ),
                const Divider(color: OmniColors.bgBorder, height: 24),
                _DrawerItem(
                  icon:  Icons.info_outline,
                  label: 'SYSTEM INFO',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'OmniSense Command Center',
                      applicationVersion: 'v1.0.0',
                      applicationLegalese: '© 2024 EdgeAttend IoT',
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Sign Out ───────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: OmniColors.bgBorder)),
            ),
            child: _DrawerItem(
              icon:  Icons.logout,
              label: 'SIGN OUT',
              iconColor: OmniColors.crimsonRed,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Item ───────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final VoidCallback onTap;
  final Color     iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = OmniColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OmniColors.textSecondary,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
