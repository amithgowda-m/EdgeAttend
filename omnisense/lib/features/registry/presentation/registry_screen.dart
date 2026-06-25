// lib/features/registry/presentation/registry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnisense/core/theme/app_theme.dart';
import 'package:omnisense/features/registry/domain/models/member.dart';
import 'package:omnisense/features/registry/presentation/widgets/member_tile.dart';
import 'package:omnisense/features/registry/providers/registry_provider.dart';
import 'package:omnisense/shared/widgets/app_drawer.dart';

class RegistryScreen extends ConsumerStatefulWidget {
  const RegistryScreen({super.key});

  @override
  ConsumerState<RegistryScreen> createState() => _RegistryScreenState();
}

class _RegistryScreenState extends ConsumerState<RegistryScreen> {
  String _searchQuery = '';
  String _filter      = 'ALL'; // ALL | PRESENT | ABSENT | FLAGGED

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: OmniColors.bgSurface,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Search + Filter Bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: OmniColors.bgDeep,
            child: Column(
              children: [
                // Search
                TextField(
                  style: GoogleFonts.inter(
                    color: OmniColors.textPrimary, fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText:    'Search by name or ID…',
                    prefixIcon:  const Icon(Icons.search, size: 18),
                    fillColor:   OmniColors.bgCard,
                    filled:      true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:   const BorderSide(color: OmniColors.bgBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:   const BorderSide(color: OmniColors.bgBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:   const BorderSide(
                        color: OmniColors.neonGreen, width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label:     'ALL',
                        selected:  _filter == 'ALL',
                        onTap:     () => setState(() => _filter = 'ALL'),
                        color:     OmniColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:     'PRESENT',
                        selected:  _filter == 'PRESENT',
                        onTap:     () => setState(() => _filter = 'PRESENT'),
                        color:     OmniColors.neonGreen,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:     'ABSENT',
                        selected:  _filter == 'ABSENT',
                        onTap:     () => setState(() => _filter = 'ABSENT'),
                        color:     OmniColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:     'FLAGGED',
                        selected:  _filter == 'FLAGGED',
                        onTap:     () => setState(() => _filter = 'FLAGGED'),
                        color:     OmniColors.crimsonRed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: OmniColors.bgBorder, height: 1),

          // ── Member List ────────────────────────────────────────────────────
          Expanded(
            child: membersAsync.when(
              data: (members) {
                final filtered = _applyFilters(members);
                if (filtered.isEmpty) {
                  return _EmptyRegistry(
                    hasSearch: _searchQuery.isNotEmpty || _filter != 'ALL',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => MemberTile(member: filtered[i]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: OmniColors.neonGreen),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading registry:\n$err',
                  style: GoogleFonts.inter(
                    color: OmniColors.crimsonRed, fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Member> _applyFilters(List<Member> all) {
    return all.where((m) {
      // Text search
      final q = _searchQuery;
      final matchSearch = q.isEmpty ||
          m.name.toLowerCase().contains(q) ||
          m.memberId.toLowerCase().contains(q);

      // Status filter
      final matchFilter = switch (_filter) {
        'PRESENT' => m.isPresent && !m.isFlagged,
        'ABSENT'  => m.isAbsent  && !m.isFlagged,
        'FLAGGED' => m.isFlagged,
        _         => true,
      };

      return matchSearch && matchFilter;
    }).toList();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: OmniColors.bgDeep,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: OmniColors.textSecondary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'MEMBER REGISTRY',
        style: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: OmniColors.textPrimary,
          letterSpacing: 3.0,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: OmniColors.bgBorder, height: 1),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String   label;
  final bool     selected;
  final VoidCallback onTap;
  final Color    color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color:  selected ? color.withAlpha(30) : OmniColors.bgCard,
          border: Border.all(
            color: selected ? color : OmniColors.bgBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? color : OmniColors.textDisabled,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─── Empty Registry ───────────────────────────────────────────────────────────
class _EmptyRegistry extends StatelessWidget {
  final bool hasSearch;
  const _EmptyRegistry({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.badge_outlined,
            color: OmniColors.bgBorder,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'NO MATCHING MEMBERS' : 'REGISTRY EMPTY',
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              color: OmniColors.textDisabled,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearch
                ? 'Try a different search or filter'
                : 'Add member documents to the Firestore members collection',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: OmniColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
