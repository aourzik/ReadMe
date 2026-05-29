import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book_club.dart';
import '../../../core/services/api_service.dart';
import 'friends_screen.dart';

final _clubDetailProvider = FutureProvider.family<BookClub, String>(
  (ref, id) => apiService.getBookClub(id),
);

class BookClubDetailScreen extends ConsumerStatefulWidget {
  final String clubId;
  const BookClubDetailScreen({super.key, required this.clubId});

  @override
  ConsumerState<BookClubDetailScreen> createState() => _BookClubDetailScreenState();
}

class _BookClubDetailScreenState extends ConsumerState<BookClubDetailScreen> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeProvider).isDark;
    final clubAsync = ref.watch(_clubDetailProvider(widget.clubId));

    final bg        = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink       = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft   = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface   = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt   = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border    = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (club) {
          final meetingDates = club.meetings.map((m) => _dayKey(m.date)).toSet();
          final isCreator = true; // TODO: comparer avec userId courant

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Nav ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                              border: Border.all(color: border, width: 0.5)),
                          child: Icon(Icons.chevron_left_rounded, size: 22, color: ink),
                        ),
                      ),
                      const Spacer(),
                      if (isCreator)
                        GestureDetector(
                          onTap: () => _showEditSheet(context, club, isDark, ink, inkMuted, surface, border, accent, accentInk),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: surfAlt, borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: border, width: 0.5),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.edit_rounded, size: 13, color: inkSoft),
                              const SizedBox(width: 6),
                              Text('Modifier', style: AppText.body(size: 12, color: inkSoft)
                                  .copyWith(fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),

                // ── Title ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Book club', style: AppText.eyebrow(color: inkMuted)),
                      const SizedBox(height: 6),
                      Text(club.name, style: AppText.display(size: 34, italic: true, color: ink)),
                      if (club.theme != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentSubtle, borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(club.theme!, style: AppText.body(size: 12, color: ink)
                              .copyWith(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ]),
                  ),
                ),

                // ── Calendrier ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text('Dates de réunion', style: AppText.eyebrow(color: inkMuted)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface, borderRadius: AppRadius.cardLg,
                        border: Border.all(color: border, width: 0.5),
                        boxShadow: AppShadows.soft(dark: isDark),
                      ),
                      child: Column(children: [
                        // Nav mois
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                          child: Row(children: [
                            Text(_monthLabel(_focusedMonth),
                                style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            _NavBtn(icon: Icons.chevron_left_rounded, color: inkMuted,
                                onTap: () => setState(() => _focusedMonth =
                                    DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
                            _NavBtn(icon: Icons.chevron_right_rounded, color: inkMuted,
                                onTap: () => setState(() => _focusedMonth =
                                    DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
                          ]),
                        ),
                        _CalendarGrid(
                          year: _focusedMonth.year,
                          month: _focusedMonth.month,
                          meetingDays: meetingDates,
                          isDark: isDark,
                          ink: ink, inkMuted: inkMuted, accent: accent,
                          accentStrong: accentStrong, accentInk: accentInk,
                          onDayTap: (day) => _toggleMeeting(club, day),
                        ),
                      ]),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Membres ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(children: [
                      Text('${club.members.length} membre${club.members.length > 1 ? 's' : ''}',
                          style: AppText.eyebrow(color: inkMuted)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddMembersSheet(context, club, isDark,
                            ink, inkMuted, surface, surfAlt, border, accent, accentInk),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: surfAlt,
                            border: Border.all(color: border, width: 0.5),
                          ),
                          child: Icon(Icons.person_add_rounded, size: 14, color: inkMuted),
                        ),
                      ),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: club.members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final m = club.members[i];
                      final initials = m.name.split(' ').map((w) => w[0]).take(2).join('');
                      final isClubCreator = m.id == club.createdBy.id;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surface, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border, width: 0.5),
                          boxShadow: AppShadows.soft(dark: isDark),
                        ),
                        child: Row(children: [
                          CircleAvatar(radius: 20, backgroundColor: accent,
                              child: Text(initials, style: TextStyle(fontFamily: 'CormorantGaramond',
                                  fontStyle: FontStyle.italic, fontSize: 16, color: accentInk))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.name, style: AppText.body(size: 14, color: ink)
                                .copyWith(fontWeight: FontWeight.w600)),
                            if (m.handle != null)
                              Text('@${m.handle}', style: AppText.body(size: 11.5, color: inkMuted)),
                          ])),
                          if (isClubCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentSubtle, borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('Créateur', style: AppText.body(size: 10, color: ink)
                                  .copyWith(fontWeight: FontWeight.w600)),
                            ),
                        ]),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMembersSheet(BuildContext context, BookClub club, bool isDark,
      Color ink, Color inkMuted, Color surface, Color surfAlt,
      Color border, Color accent, Color accentInk) {
    final existingIds = club.members.map((m) => m.id).toSet();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddMembersSheet(
        clubId: club.id,
        existingMemberIds: existingIds,
        isDark: isDark,
        ink: ink, inkMuted: inkMuted, surface: surface,
        surfAlt: surfAlt, border: border, accent: accent, accentInk: accentInk,
        onAdded: () {
          ref.invalidate(_clubDetailProvider(widget.clubId));
          ref.invalidate(bookClubsProvider);
        },
      ),
    );
  }

  Future<void> _toggleMeeting(BookClub club, DateTime day) async {
    final key = _dayKey(day);
    final existing = club.meetings.where((m) => _dayKey(m.date) == key).firstOrNull;
    if (existing != null) {
      await apiService.deleteBookClubMeeting(club.id, existing.id);
    } else {
      await apiService.addBookClubMeeting(club.id, day);
    }
    ref.invalidate(_clubDetailProvider(widget.clubId));
    ref.invalidate(bookClubsProvider);
  }

  void _showEditSheet(BuildContext context, BookClub club, bool isDark,
      Color ink, Color inkMuted, Color surface, Color border, Color accent, Color accentInk) {
    final nameCtrl  = TextEditingController(text: club.name);
    final themeCtrl = TextEditingController(text: club.theme ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
              Text('Modifier le club', style: AppText.displaySm(italic: true, color: ink)),
              const SizedBox(height: 20),
              Text('Nom', style: AppText.eyebrow(color: inkMuted)),
              const SizedBox(height: 8),
              _EditField(ctrl: nameCtrl, hint: 'Nom du club', isDark: isDark,
                  surface: surface, border: border, ink: ink, inkMuted: inkMuted),
              const SizedBox(height: 16),
              Text('Thème', style: AppText.eyebrow(color: inkMuted)),
              const SizedBox(height: 8),
              _EditField(ctrl: themeCtrl, hint: 'Thème de lecture (optionnel)', isDark: isDark,
                  surface: surface, border: border, ink: ink, inkMuted: inkMuted),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  await apiService.updateBookClub(club.id,
                      name: nameCtrl.text.trim(), theme: themeCtrl.text.trim());
                  ref.invalidate(_clubDetailProvider(widget.clubId));
                  ref.invalidate(bookClubsProvider);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                  child: Text('Enregistrer', textAlign: TextAlign.center,
                      style: AppText.body(size: 15, color: accentInk).copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  String _monthLabel(DateTime dt) {
    const months = ['Janvier','Février','Mars','Avril','Mai','Juin',
        'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Calendrier ────────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final int year, month;
  final Set<String> meetingDays;
  final bool isDark;
  final Color ink, inkMuted, accent, accentStrong, accentInk;
  final void Function(DateTime) onDayTap;

  const _CalendarGrid({
    required this.year, required this.month, required this.meetingDays,
    required this.isDark, required this.ink, required this.inkMuted,
    required this.accent, required this.accentStrong, required this.accentInk,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Offset: lundi=0, dimanche=6
    final startOffset = (firstDay.weekday - 1) % 7;
    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Jours de la semaine
        Row(
          children: dayLabels.map((d) => Expanded(
            child: Center(child: Text(d, style: AppText.eyebrow(color: inkMuted))),
          )).toList(),
        ),
        const SizedBox(height: 8),

        // Grille
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();
            final day = index - startOffset + 1;
            final date = DateTime(year, month, day);
            final key = '${date.year}-${date.month}-${date.day}';
            final isMeeting = meetingDays.contains(key);
            final isToday = _isToday(date);

            return GestureDetector(
              onTap: () => onDayTap(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMeeting ? accentStrong : Colors.transparent,
                  border: isToday && !isMeeting ? Border.all(color: accent, width: 1.5) : null,
                ),
                child: Center(
                  child: Text('$day', style: AppText.body(size: 12,
                      color: isMeeting ? accentInk : isToday ? accent : ink)
                      .copyWith(fontWeight: isMeeting || isToday ? FontWeight.w700 : FontWeight.w400)),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20, color: color)),
  );
}

class _AddMembersSheet extends ConsumerStatefulWidget {
  final String clubId;
  final Set<String> existingMemberIds;
  final bool isDark;
  final Color ink, inkMuted, surface, surfAlt, border, accent, accentInk;
  final VoidCallback onAdded;

  const _AddMembersSheet({
    required this.clubId, required this.existingMemberIds, required this.isDark,
    required this.ink, required this.inkMuted, required this.surface,
    required this.surfAlt, required this.border, required this.accent,
    required this.accentInk, required this.onAdded,
  });

  @override
  ConsumerState<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends ConsumerState<_AddMembersSheet> {
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: widget.border, borderRadius: BorderRadius.circular(2)))),
          Text('Ajouter des membres', style: AppText.displaySm(italic: true, color: widget.ink)),
          const SizedBox(height: 16),
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (friends) {
              final invitable = friends.where((f) => !widget.existingMemberIds.contains(f.id)).toList();
              if (invitable.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Tous tes amis sont déjà membres.',
                      style: AppText.body(size: 13, color: widget.inkMuted)),
                );
              }
              return Wrap(
                spacing: 8, runSpacing: 8,
                children: invitable.map((f) {
                  final isSelected = _selected.contains(f.id);
                  return GestureDetector(
                    onTap: () => setState(() =>
                        isSelected ? _selected.remove(f.id) : _selected.add(f.id)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.accent : widget.surfAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : widget.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isSelected) ...[
                          Icon(Icons.check_rounded, size: 12, color: widget.accentInk),
                          const SizedBox(width: 6),
                        ],
                        Text(f.name.split(' ').first,
                            style: AppText.body(size: 13,
                                color: isSelected ? widget.accentInk : widget.ink)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: (_selected.isEmpty || _saving) ? null : () async {
              setState(() => _saving = true);
              try {
                await apiService.addBookClubMembers(widget.clubId, _selected.toList());
                widget.onAdded();
                if (context.mounted) Navigator.pop(context);
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _selected.isNotEmpty ? widget.accent : widget.surfAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: _saving
                  ? Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentInk)))
                  : Text(
                      _selected.isEmpty
                          ? 'Sélectionne des amis'
                          : 'Ajouter ${_selected.length} membre${_selected.length > 1 ? 's' : ''}',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 15,
                          color: _selected.isNotEmpty ? widget.accentInk : widget.inkMuted)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool isDark;
  final Color surface, border, ink, inkMuted;

  const _EditField({required this.ctrl, required this.hint, required this.isDark,
      required this.surface, required this.border, required this.ink, required this.inkMuted});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: surface.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border, width: 0.5),
    ),
    child: TextField(
      controller: ctrl,
      style: AppText.body(size: 14, color: ink),
      decoration: InputDecoration(
        border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
        hintText: hint, hintStyle: AppText.body(size: 14, color: inkMuted),
      ),
    ),
  );
}
