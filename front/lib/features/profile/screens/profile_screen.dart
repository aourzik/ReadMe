import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';

final meProvider = FutureProvider<User>((ref) => apiService.getMe());

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = ref.watch(themeProvider).isDark;
    final themeNotif = ref.read(themeProvider.notifier);
    final meAsync   = ref.watch(meProvider);

    final bg         = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink        = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft    = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted   = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface    = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt    = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border     = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent     = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentInk  = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: meAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur profil: $e', textAlign: TextAlign.center)),
        data: (user) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),

            // Header row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text('@${user.handle ?? user.name.toLowerCase().replaceAll(' ', '.')}',
                        style: AppText.body(size: 13, color: inkSoft).copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    SizedBox(width: 38, height: 38, child: Icon(Icons.share_rounded, size: 18, color: ink)),
                    const SizedBox(width: 4),
                    // Theme toggle
                    GestureDetector(
                      onTap: themeNotif.toggleTheme,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: surfAlt),
                        child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 18, color: ink),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(width: 38, height: 38, child: Icon(Icons.settings_rounded, size: 18, color: ink)),
                  ],
                ),
              ),
            ),

            // Profile hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 43, backgroundColor: accent,
                      child: Text(
                        user.name.split(' ').map((w) => w[0]).take(2).join(''),
                        style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500, fontSize: 36, color: accentInk),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(user.name, style: AppText.displayMd(italic: true, color: ink)),
                    const SizedBox(height: 4),
                    Text(
                      'Bibliothèque ouverte aux amis${user.location != null ? ' · ${user.location}' : ''}',
                      style: AppText.body(size: 12.5, color: inkMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GhostBtn(label: 'Modifier', isDark: isDark, ink: ink, border: border),
                        const SizedBox(width: 8),
                        _SoftBtn(label: 'Partager', icon: Icons.share_rounded,
                            isDark: isDark, ink: ink, surfAlt: surfAlt),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface, borderRadius: AppRadius.cardLg,
                    border: Border.all(color: border, width: 0.5),
                    boxShadow: AppShadows.soft(dark: isDark),
                  ),
                  child: Row(
                    children: [
                      _StatCell(label: 'Livres', value: '${user.bookCount}', ink: ink, inkMuted: inkMuted),
                      Container(width: 0.5, height: 40, color: border),
                      _StatCell(label: 'Lus en 2026', value: '${user.booksReadThisYear ?? 0}', ink: ink, inkMuted: inkMuted),
                      Container(width: 0.5, height: 40, color: border),
                      _StatCell(label: 'Amis', value: '${user.friendCount}', ink: ink, inkMuted: inkMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),

            // Reading challenge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('Défi 2026', style: AppText.eyebrow(color: inkMuted)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [accent, (isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight)],
                    ),
                    borderRadius: AppRadius.cardLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        RichText(text: TextSpan(
                          style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                              fontSize: 28, fontWeight: FontWeight.w500, color: accentInk, height: 1),
                          children: [
                            TextSpan(text: '${user.booksReadThisYear ?? 0} '),
                            TextSpan(text: '/ 24 livres',
                                style: TextStyle(fontSize: 18, color: accentInk.withOpacity(0.6))),
                          ],
                        )),
                        Text(
                          '${((user.booksReadThisYear ?? 0) / 24 * 100).round()} %',
                          style: AppText.eyebrow(color: accentInk.withOpacity(0.7)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((user.booksReadThisYear ?? 0) / 24).clamp(0.0, 1.0),
                          backgroundColor: Colors.black.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(accentInk.withOpacity(0.85)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Tu lis en moyenne 1 livre toutes les 3 semaines. Continue !',
                          style: AppText.body(size: 11.5, color: accentInk.withOpacity(0.75))),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),

            // Favorite genres
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Genres préférés', style: AppText.eyebrow(color: inkMuted)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: (user.favoriteGenres.isNotEmpty
                      ? user.favoriteGenres
                      : ['Roman', 'Essai', 'Poésie', 'Voyage', 'Historique']
                  ).map((g) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 0.5),
                    ),
                    child: Text(g, style: AppText.body(size: 12, color: inkSoft).copyWith(fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ),
            ),

            // Logout
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () async {
                    await apiService.logout();
                    if (context.mounted) context.go('/welcome');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, size: 15, color: inkMuted),
                      const SizedBox(width: 8),
                      Text('Se déconnecter', style: AppText.body(size: 13, color: inkMuted)
                          .copyWith(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  final Color ink, inkMuted;
  const _StatCell({required this.label, required this.value, required this.ink, required this.inkMuted});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500, fontSize: 28, color: ink, height: 1)),
      const SizedBox(height: 5),
      Text(label, style: AppText.eyebrow(color: inkMuted).copyWith(fontSize: 10, letterSpacing: 1)),
    ]),
  );
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color ink, border;
  const _GhostBtn({required this.label, required this.isDark, required this.ink, required this.border});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.5)),
    child: Text(label, style: AppText.body(size: 13, color: ink).copyWith(fontWeight: FontWeight.w600)),
  );
}

class _SoftBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final Color ink, surfAlt;
  const _SoftBtn({required this.label, required this.icon, required this.isDark, required this.ink, required this.surfAlt});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    decoration: BoxDecoration(color: surfAlt, borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: ink),
      const SizedBox(width: 6),
      Text(label, style: AppText.body(size: 13, color: ink).copyWith(fontWeight: FontWeight.w600)),
    ]),
  );
}
