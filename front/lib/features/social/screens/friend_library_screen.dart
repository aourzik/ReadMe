// friend_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/book_card.dart';

final friendBooksProvider = FutureProvider.family<List<Book>, String>(
  (ref, userId) => apiService.getFriendBooks(userId),
);

class FriendLibraryScreen extends ConsumerWidget {
  final String userId;
  const FriendLibraryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider).isDark;
    final booksAsync = ref.watch(friendBooksProvider(userId));

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Erreur')),
          data: (books) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                              border: Border.all(color: border, width: 0.5)),
                          child: Icon(Icons.chevron_left_rounded, color: ink)),
                    ),
                    const Spacer(),
                    SizedBox(width: 38, height: 38, child: Icon(Icons.search_rounded, size: 18, color: ink)),
                    const SizedBox(width: 6),
                    SizedBox(width: 38, height: 38, child: Icon(Icons.more_horiz_rounded, size: 18, color: ink)),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 32, backgroundColor: accent,
                      child: Text('AM', style: TextStyle(fontFamily: 'CormorantGaramond',
                          fontStyle: FontStyle.italic, fontSize: 22, color: accentInk)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ami', style: AppText.displaySm(italic: true, color: ink)),
                      const SizedBox(height: 3),
                      Text('@ami · ${books.length} livres', style: AppText.body(size: 12, color: inkMuted)),
                    ])),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.swap_horiz_rounded, size: 13, color: accentInk),
                            const SizedBox(width: 6),
                            Text('Demander un prêt', style: AppText.body(size: 13, color: accentInk)
                                .copyWith(fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.black12)),
                      child: Text('Message', style: AppText.body(size: 13, color: ink).copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Sa bibliothèque', style: AppText.eyebrow(color: inkMuted)),
                    Text('${books.length} récents', style: AppText.body(size: 11, color: inkMuted)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => BookCard(book: books[i], isDark: isDark, compact: true),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
