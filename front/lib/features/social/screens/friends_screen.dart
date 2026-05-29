import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/models/book.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/book_club.dart';
import '../../../core/services/api_service.dart';
import '../../library/screens/library_screen.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final friendsListProvider = FutureProvider<List<User>>((ref) => apiService.getFriends());
final friendActivityProvider = FutureProvider<List<Activity>>((ref) => apiService.getFriendActivity());
final bookClubsProvider = FutureProvider<List<BookClub>>((ref) => apiService.getBookClubs());
final pendingRequestsProvider = FutureProvider<List<FriendRequest>>((ref) => apiService.getPendingRequests());

// ── Screen ───────────────────────────────────────────────────────────────────

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _searchOpen = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark        = ref.watch(themeProvider).isDark;
    final friendsAsync  = ref.watch(friendsListProvider);
    final activityAsync = ref.watch(friendActivityProvider);
    final clubsAsync    = ref.watch(bookClubsProvider);
    final requestsAsync = ref.watch(pendingRequestsProvider);

    final bg         = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink        = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft    = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted   = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface    = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt    = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border     = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent     = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;
    final accentInk  = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    final pendingCount = requestsAsync.valueOrNull?.length ?? 0;

    // Filtrage inline de la liste d'amis
    final allFriends = friendsAsync.valueOrNull ?? [];
    final displayedFriends = _searchQuery.isEmpty
        ? allFriends
        : allFriends.where((f) =>
            f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (f.handle?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
            .toList();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),

          // ── Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Cercle', style: AppText.body(size: 13, color: inkSoft).copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    // Loupe → recherche dans la liste d'amis
                    GestureDetector(
                      onTap: () => setState(() {
                        _searchOpen = !_searchOpen;
                        if (!_searchOpen) _searchQuery = '';
                      }),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _searchOpen ? surfAlt : Colors.transparent,
                        ),
                        child: Icon(Icons.search_rounded, size: 18, color: ink),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // "+" → page de recherche d'amis
                    GestureDetector(
                      onTap: () => context.push('/friends/add'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                            child: Icon(Icons.person_add_rounded, size: 18, color: accentInk),
                          ),
                          if (pendingCount > 0)
                            Positioned(
                              top: -2, right: -2,
                              child: Container(
                                width: 16, height: 16,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: accentStrong),
                                child: Center(child: Text('$pendingCount',
                                    style: AppText.body(size: 9, color: Colors.white)
                                        .copyWith(fontWeight: FontWeight.w700))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),

                  // Barre de recherche inline
                  if (_searchOpen) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: surface, borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: border, width: 0.5),
                      ),
                      child: Row(children: [
                        Icon(Icons.search_rounded, size: 14, color: inkMuted),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: AppText.body(size: 13, color: ink),
                          decoration: InputDecoration(
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                            hintText: 'Chercher dans mes amis…',
                            hintStyle: AppText.body(size: 13, color: inkMuted),
                          ),
                        )),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _searchQuery = ''),
                            child: Icon(Icons.close_rounded, size: 14, color: inkMuted),
                          ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 8),
                  friendsAsync.when(
                    loading: () => Text('—', style: AppText.eyebrow(color: inkMuted)),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (f) => Text(
                      '${f.length} ami${f.length > 1 ? 's' : ''}'
                      '${pendingCount > 0 ? ' · $pendingCount demande${pendingCount > 1 ? 's' : ''} en attente' : ''}',
                      style: AppText.eyebrow(color: inkMuted),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Mes amies & amis', style: AppText.display(size: 34, italic: true, color: ink)),
                ],
              ),
            ),
          ),

          // ── Activité récente ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text('Activité récente', style: AppText.eyebrow(color: inkMuted)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: activityAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) => const SizedBox.shrink(),
                data: (activities) => activities.isEmpty
                    ? _EmptyActivity(ink: inkMuted)
                    : _ActivityFeed(
                        activities: activities,
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        ink: ink,
                        inkSoft: inkSoft,
                        inkMuted: inkMuted,
                        accent: accent,
                        accentInk: accentInk,
                        onAdd: (activity) async {
                          if (activity.book == null) return;
                          try {
                            await apiService.addBook(
                              _activityBookToBook(activity),
                            );
                            ref.invalidate(booksProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('«${activity.book!.title}» ajouté !')),
                              );
                            }
                          } catch (_) {}
                        },
                      ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Liste d'amis ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _searchQuery.isNotEmpty
                    ? '${displayedFriends.length} résultat${displayedFriends.length > 1 ? 's' : ''}'
                    : 'Mes amis',
                style: AppText.eyebrow(color: inkMuted),
              ),
            ),
          ),
          friendsAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (_) => displayedFriends.isEmpty
                ? SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _searchQuery.isNotEmpty ? 'Aucun ami trouvé.' : 'Aucun ami pour l\'instant.',
                      style: AppText.body(size: 13, color: inkMuted),
                    ),
                  ))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: displayedFriends.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _FriendCard(
                        friend: displayedFriends[i],
                        isDark: isDark,
                        ink: ink, inkSoft: inkSoft, inkMuted: inkMuted,
                        surface: surface, border: border, accent: accent,
                        accentStrong: accentStrong, accentInk: accentInk, bg: bg,
                      ),
                    ),
                  ),
          ),

          // ── Book clubs ──
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Mes book clubs', style: AppText.eyebrow(color: inkMuted)),
            ),
          ),
          SliverToBoxAdapter(
            child: clubsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (clubs) => clubs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => context.push('/friends/bookclub/new'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accentSubtle,
                            borderRadius: AppRadius.cardLg,
                            border: Border.all(color: accent.withOpacity(0.3), width: 0.5),
                          ),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                              child: Icon(Icons.menu_book_rounded, size: 20, color: accentInk),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Créer un book club', style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text('Lis avec tes amis, fixez des dates de réunion.',
                                  style: AppText.body(size: 12, color: inkMuted).copyWith(height: 1.3)),
                            ])),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: inkMuted),
                          ]),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: clubs.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          if (i == clubs.length) {
                            return GestureDetector(
                              onTap: () => context.push('/friends/bookclub/new'),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: accentSubtle,
                                  borderRadius: AppRadius.cardLg,
                                  border: Border.all(color: accent.withOpacity(0.3), width: 0.5),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_rounded, size: 24, color: accent),
                                  const SizedBox(height: 8),
                                  Text('Nouveau', style: AppText.body(size: 11, color: accent).copyWith(fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () => context.push('/friends/bookclub/${clubs[i].id}'),
                            child: _ClubCard(
                              club: clubs[i], isDark: isDark,
                              ink: ink, inkMuted: inkMuted, surface: surface, border: border,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Book _activityBookToBook(Activity activity) {
    final b = activity.book!;
    return Book(
      id: '', title: b.title, author: b.author,
      year: b.year ?? DateTime.now().year,
      googleBooksId: b.googleBooksId, coverUrl: b.coverUrl,
    );
  }
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

class _EmptyActivity extends StatelessWidget {
  final Color ink;
  const _EmptyActivity({required this.ink});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(child: Text('Aucune activité récente.',
        style: AppText.body(size: 13, color: ink))),
  );
}

class _ActivityFeed extends StatelessWidget {
  final List<Activity> activities;
  final bool isDark;
  final Color surface, border, ink, inkSoft, inkMuted, accent, accentInk;
  final void Function(Activity) onAdd;

  const _ActivityFeed({
    required this.activities, required this.isDark,
    required this.surface, required this.border,
    required this.ink, required this.inkSoft, required this.inkMuted,
    required this.accent, required this.accentInk, required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final shown = activities.take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: surface, borderRadius: AppRadius.cardLg,
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: Column(
        children: shown.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final initials = a.user.name.split(' ').map((w) => w[0]).take(2).join('');
          final avatarColor = _colorForName(a.user.name);
          return Column(
            children: [
              if (i > 0) Container(height: 0.5, color: border, margin: const EdgeInsets.only(left: 60)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18, backgroundColor: avatarColor,
                    child: Text(initials, style: TextStyle(fontFamily: 'CormorantGaramond',
                        fontStyle: FontStyle.italic, fontSize: 14, color: Colors.white.withOpacity(0.9))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      RichText(text: TextSpan(
                        style: AppText.body(size: 12.5, color: inkSoft).copyWith(height: 1.35),
                        children: [
                          TextSpan(text: a.user.name.split(' ').first,
                              style: AppText.body(size: 12.5, color: ink).copyWith(fontWeight: FontWeight.w600)),
                          TextSpan(text: ' ${a.actionLabel} '),
                          if (a.book != null)
                            TextSpan(text: a.book!.title, style: TextStyle(fontFamily: 'CormorantGaramond',
                                fontStyle: FontStyle.italic, fontSize: 13.5, color: ink, fontWeight: FontWeight.w500)),
                        ],
                      )),
                      const SizedBox(height: 3),
                      Text(_timeAgo(a.createdAt), style: AppText.body(size: 10.5, color: inkMuted).copyWith(letterSpacing: 0.2)),
                    ]),
                  ),
                  if (a.showAddButton && a.book != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onAdd(a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                        child: Text('+ Ajouter', style: AppText.body(size: 11, color: accentInk).copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _colorForName(String name) {
    const colors = [
      Color(0xFFE9C4A3), Color(0xFF7EC8C0), Color(0xFFC9A87A),
      Color(0xFFF5D3D7), Color(0xFF9AAF8A), Color(0xFFD4A5AB),
    ];
    final h = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[h % colors.length];
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    return 'il y a ${diff.inDays ~/ 7} sem.';
  }
}

class _FriendCard extends StatelessWidget {
  final User friend;
  final bool isDark;
  final Color ink, inkSoft, inkMuted, surface, border, accent, accentStrong, accentInk, bg;

  const _FriendCard({
    required this.friend, required this.isDark,
    required this.ink, required this.inkSoft, required this.inkMuted,
    required this.surface, required this.border, required this.accent,
    required this.accentStrong, required this.accentInk, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final initials = friend.name.split(' ').map((w) => w[0]).take(2).join('');
    return GestureDetector(
      onTap: () => context.push('/friends/${friend.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 0.5),
          boxShadow: AppShadows.soft(dark: isDark),
        ),
        child: Row(children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.5), blurRadius: 0, spreadRadius: 2),
                BoxShadow(color: bg, blurRadius: 0, spreadRadius: 1),
              ],
            ),
            child: CircleAvatar(
              radius: 22, backgroundColor: accent,
              child: Text(initials, style: TextStyle(fontFamily: 'CormorantGaramond',
                  fontStyle: FontStyle.italic, fontSize: 18, color: accentInk)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(friend.name, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${friend.bookCount} livre${friend.bookCount > 1 ? 's' : ''} · ${friend.friendCount} ami${friend.friendCount > 1 ? 's' : ''}',
                style: AppText.body(size: 11.5, color: inkMuted)),
            if (friend.handle != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.alternate_email_rounded, size: 10, color: accentStrong),
                const SizedBox(width: 4),
                Text(friend.handle!, style: AppText.body(size: 11, color: inkSoft)),
              ]),
            ],
          ])),
          Icon(Icons.chevron_right_rounded, size: 16, color: inkMuted),
        ]),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final BookClub club;
  final bool isDark;
  final Color ink, inkMuted, surface, border;

  const _ClubCard({
    required this.club, required this.isDark,
    required this.ink, required this.inkMuted,
    required this.surface, required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForName(club.name);
    final nextMeeting = club.meetings
        .where((m) => m.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface, borderRadius: AppRadius.cardLg,
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(club.name[0],
              style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500, fontSize: 26, color: ink.withOpacity(0.7)))),
        ),
        const SizedBox(height: 10),
        Text(club.name, style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
            fontSize: 17, color: ink, fontWeight: FontWeight.w500, height: 1.1, letterSpacing: -0.2),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('${club.members.length} membre${club.members.length > 1 ? 's' : ''}',
            style: AppText.body(size: 11.5, color: inkMuted)),
        const Spacer(),
        if (club.theme != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.35), borderRadius: BorderRadius.circular(8)),
            child: Text(club.theme!, style: AppText.body(size: 11, color: ink).copyWith(fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        else if (nextMeeting.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
            child: Text('Prochaine : ${_formatDate(nextMeeting.first.date)}',
                style: AppText.body(size: 11, color: ink).copyWith(fontWeight: FontWeight.w500)),
          ),
      ]),
    );
  }

  Color _colorForName(String name) {
    const colors = [Color(0xFFF5D3D7), Color(0xFFE9C4A3), Color(0xFFCFD9C5), Color(0xFFD4A5AB)];
    final h = name.codeUnits.fold(0, (a, b) => a + b);
    return colors[h % colors.length];
  }

  String _formatDate(DateTime dt) {
    const months = ['jan.','fév.','mars','avr.','mai','juin','juil.','août','sep.','oct.','nov.','déc.'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
