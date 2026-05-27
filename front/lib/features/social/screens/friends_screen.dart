import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';

final friendsListProvider = FutureProvider<List<User>>((ref) => apiService.getFriends());

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = ref.watch(themeProvider).isDark;
    final friendsAsync = ref.watch(friendsListProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;
    final surfAlt  = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;

    // Mock activity feed (à brancher sur API)
    final activity = [
      _Activity(who: 'Camille', action: 'a fini de lire', target: 'Atlas des Mers Intérieures', time: 'il y a 2h', color: const Color(0xFFE9C4A3)),
      _Activity(who: 'Inès', action: 'a noté ★★★★★', target: "L'Hiver Tient Bon", time: 'hier', color: const Color(0xFF7EC8C0)),
      _Activity(who: 'Tom', action: 'a rejoint le club', target: "Lectures d'été", time: '2 jours', color: const Color(0xFFC9A87A)),
      _Activity(who: 'Léa', action: 'recommande', target: 'Nuit Claire', time: '3 jours', color: const Color(0xFFF5D3D7), isRec: true),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Cercle', style: AppText.body(size: 13, color: inkSoft).copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _IconBtn(icon: Icons.search_rounded, ink: ink),
                    const SizedBox(width: 6),
                    _AccentIconBtn(icon: Icons.person_add_rounded, accent: accent, accentInk: accentInk),
                  ]),
                  const SizedBox(height: 8),
                  friendsAsync.when(
                    loading: () => Text('—', style: AppText.eyebrow(color: inkMuted)),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (f) => Text('${f.length} amis · 3 demandes en attente',
                        style: AppText.eyebrow(color: inkMuted)),
                  ),
                  const SizedBox(height: 4),
                  Text('Mes amies & amis', style: AppText.display(size: 34, italic: true, color: ink)),
                ],
              ),
            ),
          ),

          // Activity feed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('Activité récente', style: AppText.eyebrow(color: inkMuted)),
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
                child: Column(
                  children: activity.asMap().entries.map((entry) {
                    final i = entry.key;
                    final a = entry.value;
                    return Column(
                      children: [
                        if (i > 0) Container(height: 0.5, color: border,
                            margin: const EdgeInsets.only(left: 60)),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 18, backgroundColor: a.color,
                              child: Text(a.who[0], style: TextStyle(fontFamily: 'CormorantGaramond',
                                  fontStyle: FontStyle.italic, fontSize: 16,
                                  color: Colors.white.withOpacity(0.9))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                RichText(text: TextSpan(style: AppText.body(size: 12.5, color: inkSoft).copyWith(height: 1.35),
                                  children: [
                                    TextSpan(text: a.who, style: AppText.body(size: 12.5, color: ink).copyWith(fontWeight: FontWeight.w600)),
                                    TextSpan(text: ' ${a.action} '),
                                    TextSpan(text: a.target, style: TextStyle(fontFamily: 'CormorantGaramond',
                                        fontStyle: FontStyle.italic, fontSize: 13.5, color: ink, fontWeight: FontWeight.w500)),
                                  ],
                                )),
                                const SizedBox(height: 3),
                                Text(a.time, style: AppText.body(size: 10.5, color: inkMuted).copyWith(letterSpacing: 0.2)),
                              ]),
                            ),
                            if (a.isRec) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                              child: Text('+ Ajouter', style: AppText.body(size: 11, color: accentInk).copyWith(fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Friends list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Bibliothèques', style: AppText.eyebrow(color: inkMuted)),
            ),
          ),
          friendsAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (friends) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final f = friends[i];
                  return GestureDetector(
                    onTap: () => context.push('/friends/${f.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 0.5),
                        boxShadow: AppShadows.soft(dark: isDark),
                      ),
                      child: Row(children: [
                        // Avatar with ring
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 0, spreadRadius: 2),
                                BoxShadow(color: bg, blurRadius: 0, spreadRadius: 1, offset: Offset.zero)],
                          ),
                          child: CircleAvatar(
                            radius: 22, backgroundColor: accent,
                            child: Text(f.name.split(' ').map((w) => w[0]).take(2).join(''),
                                style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                                    fontSize: 18, color: accentInk)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.name, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${f.bookCount} livres · ${f.friendCount} amis en commun',
                              style: AppText.body(size: 11.5, color: inkMuted)),
                          if (f.handle != null) ...[
                            const SizedBox(height: 5),
                            Row(children: [
                              Icon(Icons.menu_book_rounded, size: 11, color: accentStrong),
                              const SizedBox(width: 5),
                              Text(f.handle!, style: TextStyle(fontFamily: 'CormorantGaramond',
                                  fontStyle: FontStyle.italic, fontSize: 12, color: inkSoft)),
                            ]),
                          ],
                        ])),
                        Icon(Icons.chevron_right_rounded, size: 16, color: inkMuted),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),

          // Book clubs (mock)
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Mes book clubs', style: AppText.eyebrow(color: inkMuted)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _ClubCard(name: "Lectures d'été", members: 14, book: 'Un Été Sans Toi',
                      host: 'Léa', color: const Color(0xFFF5D3D7), isDark: isDark,
                      ink: ink, inkMuted: inkMuted, surface: surface, border: border, accentInk: accentInk),
                  const SizedBox(width: 12),
                  _ClubCard(name: 'Cercle Nord', members: 8, book: "L'Hiver Tient Bon",
                      host: 'Sacha', color: const Color(0xFF2C3E50), isDark: isDark,
                      ink: ink, inkMuted: inkMuted, surface: surface, border: border, accentInk: accentInk),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _Activity {
  final String who, action, target, time;
  final Color color;
  final bool isRec;
  const _Activity({required this.who, required this.action, required this.target, required this.time, required this.color, this.isRec = false});
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color ink;
  const _IconBtn({required this.icon, required this.ink});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: ink));
}

class _AccentIconBtn extends StatelessWidget {
  final IconData icon;
  final Color accent, accentInk;
  const _AccentIconBtn({required this.icon, required this.accent, required this.accentInk});
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
    child: Icon(icon, size: 18, color: accentInk),
  );
}

class _ClubCard extends StatelessWidget {
  final String name, book, host;
  final int members;
  final Color color;
  final bool isDark;
  final Color ink, inkMuted, surface, border, accentInk;
  const _ClubCard({required this.name, required this.members, required this.book,
      required this.host, required this.color, required this.isDark, required this.ink,
      required this.inkMuted, required this.surface, required this.border, required this.accentInk});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface, borderRadius: AppRadius.cardLg,
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(name[0],
                style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500, fontSize: 26, color: ink.withOpacity(0.7)))),
          ),
          const SizedBox(height: 10),
          Text(name, style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
              fontSize: 17, color: ink, fontWeight: FontWeight.w500, height: 1.1, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Text('$members membres · $host', style: AppText.body(size: 11.5, color: inkMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.35), borderRadius: BorderRadius.circular(8)),
            child: Text('Lecture : $book', style: AppText.body(size: 11, color: ink).copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
