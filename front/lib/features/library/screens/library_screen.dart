import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/book_card.dart';
import '../../../core/widgets/book_grid_item.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/library_top_bar.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final booksProvider = FutureProvider<List<Book>>((ref) => apiService.getMyBooks());

enum LibraryLayout { list, grid }
final layoutProvider = StateProvider<LibraryLayout>((ref) => LibraryLayout.list);
final filterProvider  = StateProvider<String>((ref) => 'Tout');

// ─── Screen ───────────────────────────────────────────────────────────────────

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark     = themeState.isDark;
    final layout     = ref.watch(layoutProvider);
    final filter     = ref.watch(filterProvider);
    final booksAsync = ref.watch(booksProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt  = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: booksAsync.when(
        loading: () => _buildSkeleton(isDark),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (books) {
          // Filtrage
          final filtered = _filterBooks(books, filter);
          final stats = (
            total: books.length,
            reading: books.where((b) => b.status == ReadStatus.reading).length,
            lent: books.where((b) => b.lentTo != null).length,
          );

          return CustomScrollView(
            slivers: [
              // Safe area top
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),

              // Top bar
              SliverToBoxAdapter(
                child: LibraryTopBar(
                  isDark: isDark,
                  totalBooks: stats.total,
                  reading: stats.reading,
                  lent: stats.lent,
                  onAdd: () => context.push('/library/add'),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _SearchBar(isDark: isDark),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: FilterChipRow(
                  isDark: isDark,
                  active: filter,
                  onChange: (f) => ref.read(filterProvider.notifier).state = f,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Count + layout toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                        style: AppText.body(size: 11.5, color: inkMuted).copyWith(letterSpacing: 0.2),
                      ),
                      const Spacer(),
                      // Layout toggle
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: surfAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            _LayoutToggleButton(
                              icon: Icons.view_list_rounded,
                              active: layout == LibraryLayout.list,
                              isDark: isDark,
                              onTap: () => ref.read(layoutProvider.notifier).state = LibraryLayout.list,
                            ),
                            _LayoutToggleButton(
                              icon: Icons.grid_view_rounded,
                              active: layout == LibraryLayout.grid,
                              isDark: isDark,
                              onTap: () => ref.read(layoutProvider.notifier).state = LibraryLayout.grid,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Book list or grid
              if (layout == LibraryLayout.list)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => BookCard(
                      book: filtered[i],
                      isDark: isDark,
                      onTap: () => context.push('/library/book/${filtered[i].id}'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.6,
                    children: filtered.map((b) => BookGridItem(
                      book: b,
                      isDark: isDark,
                      onTap: () => context.push('/library/book/${b.id}'),
                    )).toList(),
                  ),
                ),

              // Bottom padding for tab bar
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  List<Book> _filterBooks(List<Book> books, String filter) {
    switch (filter) {
      case 'En cours':  return books.where((b) => b.status == ReadStatus.reading).toList();
      case 'Lus':       return books.where((b) => b.status == ReadStatus.read).toList();
      case 'Souhaités': return books.where((b) => b.status == ReadStatus.wishlist).toList();
      case 'Prêtés':    return books.where((b) => b.lentTo != null).toList();
      default:          return books;
    }
  }

  Widget _buildSkeleton(bool isDark) {
    final surfAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(4, (_) => Container(
          height: 120, margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: surfAlt, borderRadius: AppRadius.card),
        )),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool isDark;
  const _SearchBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: inkMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Chercher un titre, un auteur…',
            style: AppText.body(size: 13.5, color: inkMuted),
          )),
          Container(width: 1, height: 16, color: border),
          const SizedBox(width: 10),
          Icon(Icons.qr_code_scanner_rounded, size: 16, color: inkMuted),
        ],
      ),
    );
  }
}

class _LayoutToggleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _LayoutToggleButton({required this.icon, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30, height: 26,
        decoration: BoxDecoration(
          color: active ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active ? AppShadows.soft(dark: isDark) : null,
        ),
        child: Icon(icon, size: 14, color: active ? ink : inkMuted),
      ),
    );
  }
}
