import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/models/loan.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/book_card.dart';
import '../../../core/widgets/book_grid_item.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/library_top_bar.dart';
import '../../../core/providers/app_providers.dart';
import '../../profile/screens/profile_screen.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

enum LibraryLayout { list, grid }
final layoutProvider  = StateProvider<LibraryLayout>((ref) => LibraryLayout.list);
final filterProvider  = StateProvider<String>((ref) => 'Tout');
final searchProvider  = StateProvider<String>((ref) => '');

// ─── Screen ───────────────────────────────────────────────────────────────────

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState      = ref.watch(themeProvider);
    final isDark          = themeState.isDark;
    final layout          = ref.watch(layoutProvider);
    final filter          = ref.watch(filterProvider);
    final search          = ref.watch(searchProvider);
    final booksAsync      = ref.watch(booksProvider);
    final unreadAsync     = ref.watch(unreadNotifCountProvider);
    final borrowedAsync   = ref.watch(borrowedLoansProvider);

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
          final borrowed = borrowedAsync.valueOrNull ?? [];
          // Filtrage statut + recherche texte
          final filtered = _filterBooks(books, filter, search);
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
                  unreadCount: unreadAsync.valueOrNull ?? 0,
                  onBell: () async {
                    await context.push('/notifications');
                    ref.invalidate(unreadNotifCountProvider);
                  },
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _SearchBar(
                    isDark: isDark,
                    value: search,
                    onChanged: (v) => ref.read(searchProvider.notifier).state = v,
                    onClear: () => ref.read(searchProvider.notifier).state = '',
                  ),
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

              // Count + layout toggle (masqué pour "Empruntés")
              if (filter != 'Empruntés')
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

              // Contenu principal
              if (filter == 'Empruntés')
                _BorrowedSection(
                  isDark: isDark,
                  loans: borrowed,
                  onRendre: (loan) {
                    ref.invalidate(borrowedLoansProvider);
                    ref.invalidate(booksProvider);
                    ref.invalidate(loansProvider);
                    ref.invalidate(unreadNotifCountProvider);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('« ${loan.book.title} » marqué comme rendu.'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ));
                  },
                )
              else if (layout == LibraryLayout.list)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => BookCard(
                      book: filtered[i],
                      isDark: isDark,
                      onTap: () => context.push('/library/book/${filtered[i].id}'),
                      onMarkRead: filtered[i].status == ReadStatus.reading
                          ? () async {
                              await apiService.updateBook(filtered[i].id, {'status': 'read'});
                              ref.invalidate(booksProvider);
                              ref.invalidate(meProvider);
                            }
                          : null,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.crossAxisExtent;
                      final cols = w >= 900 ? 4 : w >= 600 ? 3 : 2;
                      return SliverGrid.count(
                        crossAxisCount: cols,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.6,
                        children: filtered.map((b) => BookGridItem(
                          book: b,
                          isDark: isDark,
                          onTap: () => context.push('/library/book/${b.id}'),
                        )).toList(),
                      );
                    },
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

  List<Book> _filterBooks(List<Book> books, String filter, String search) {
    var result = books;
    // Filtre par statut
    switch (filter) {
      case 'En cours':  result = result.where((b) => b.status == ReadStatus.reading).toList(); break;
      case 'Lus':       result = result.where((b) => b.status == ReadStatus.read).toList(); break;
      case 'Souhaités': result = result.where((b) => b.status == ReadStatus.wishlist).toList(); break;
      case 'Prêtés':    result = result.where((b) => b.lentTo != null).toList(); break;
    }
    // Filtre par texte
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      result = result.where((b) =>
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q),
      ).toList();
    }
    return result;
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

class _SearchBar extends StatefulWidget {
  final bool isDark;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.isDark,
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SearchBar old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface  = widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink      = widget.isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = widget.isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border   = widget.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final hasText  = widget.value.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasText ? AppColors.accentRoseLight.withOpacity(0.5) : border,
          width: 0.5,
        ),
        boxShadow: AppShadows.soft(dark: widget.isDark),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: hasText ? AppColors.accentRoseLight : inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              style: AppText.body(size: 13.5, color: ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                hintText: 'Chercher un titre, un auteur…',
                hintStyle: AppText.body(size: 13.5, color: inkMuted),
              ),
            ),
          ),
          if (hasText) ...[
            GestureDetector(
              onTap: () { _ctrl.clear(); widget.onClear(); },
              child: Icon(Icons.close_rounded, size: 16, color: inkMuted),
            ),
          ] else ...[
            Container(width: 1, height: 16, color: border),
            const SizedBox(width: 10),
            Icon(Icons.qr_code_scanner_rounded, size: 16, color: inkMuted),
          ],
        ],
      ),
    );
  }
}

class _BorrowedSection extends StatelessWidget {
  final bool isDark;
  final List<Loan> loans;
  final void Function(Loan loan) onRendre;
  const _BorrowedSection({required this.isDark, required this.loans, required this.onRendre});

  @override
  Widget build(BuildContext context) {
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;

    if (loans.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text('Aucun livre emprunté pour l\'instant.',
              style: AppText.body(size: 13, color: inkMuted)),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: loans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _BorrowedLoanCard(
          loan: loans[i],
          isDark: isDark,
          onRendre: () => onRendre(loans[i]),
        ),
      ),
    );
  }
}

class _BorrowedLoanCard extends StatefulWidget {
  final Loan loan;
  final bool isDark;
  final VoidCallback onRendre;
  const _BorrowedLoanCard({required this.loan, required this.isDark, required this.onRendre});

  @override
  State<_BorrowedLoanCard> createState() => _BorrowedLoanCardState();
}

class _BorrowedLoanCardState extends State<_BorrowedLoanCard> {
  bool _loading = false;

  Future<void> _rendre() async {
    setState(() => _loading = true);
    try {
      await apiService.returnLoan(widget.loan.id);
      widget.onRendre();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating));
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan     = widget.loan;
    final isDark   = widget.isDark;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    final String dueDateText;
    if (loan.isOverdue) {
      dueDateText = 'En retard';
    } else if (loan.dueDate != null) {
      dueDateText = 'Retour le ${_fmt(loan.dueDate!)}';
    } else {
      dueDateText = '∞';
    }
    final dueDateColor = loan.isOverdue ? AppColors.statusOverdue
        : loan.isUrgent ? AppColors.statusWishlist
        : inkMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface, borderRadius: AppRadius.card,
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: loan.book.coverUrl != null
              ? Image.network(loan.book.coverUrl!, width: 44, height: 66, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _CoverPlaceholder(isDark: isDark))
              : _CoverPlaceholder(isDark: isDark),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loan.book.title, style: TextStyle(fontFamily: 'CormorantGaramond',
              fontStyle: FontStyle.italic, fontSize: 15, color: ink, height: 1.1)),
          const SizedBox(height: 2),
          Text(loan.book.author, style: AppText.body(size: 11.5, color: inkMuted)),
          const SizedBox(height: 6),
          Row(children: [
            CircleAvatar(radius: 9, backgroundColor: accent,
                child: Text(
                  loan.partner.name.split(' ').map((w) => w[0]).take(2).join(''),
                  style: TextStyle(fontFamily: 'CormorantGaramond',
                      fontSize: 8, fontStyle: FontStyle.italic, color: accentInk),
                )),
            const SizedBox(width: 6),
            Text('de ${loan.partner.name.split(' ').first}',
                style: AppText.body(size: 11, color: inkMuted)),
            const SizedBox(width: 8),
            Text(dueDateText, style: AppText.body(size: 11, color: dueDateColor)),
          ]),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _loading ? null : _rendre,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
            child: _loading
                ? SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accentInk))
                : Text('Rendre', style: AppText.body(size: 11, color: accentInk)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _CoverPlaceholder extends StatelessWidget {
  final bool isDark;
  const _CoverPlaceholder({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final surfAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    return Container(width: 44, height: 66, color: surfAlt);
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
