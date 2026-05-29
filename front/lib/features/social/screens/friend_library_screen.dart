import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/models/loan.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/book_card.dart';
import '../../../core/providers/app_providers.dart';
import 'friends_screen.dart';

final friendBooksProvider = FutureProvider.family<List<Book>, String>(
  (ref, userId) => apiService.getFriendBooks(userId),
);

class FriendLibraryScreen extends ConsumerWidget {
  final String userId;
  const FriendLibraryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark     = ref.watch(themeProvider).isDark;
    final booksAsync = ref.watch(friendBooksProvider(userId));
    final friendsAsync = ref.watch(friendsListProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    // Find the friend in the cached list
    final friend = friendsAsync.whenOrNull(
      data: (list) => list.where((f) => f.id == userId).firstOrNull,
    );

    final friendName    = friend?.name ?? '…';
    final friendHandle  = friend?.handle;
    final initials      = friendName == '…' ? '?' :
        friendName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join('');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Erreur')),
          data: (books) => CustomScrollView(
            slivers: [
              // Nav
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(width: 38, height: 38,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                              border: Border.all(color: border, width: 0.5)),
                          child: Icon(Icons.chevron_left_rounded, color: ink)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _confirmRemoveFriend(context, ref, friendName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.person_remove_outlined, size: 13, color: inkMuted),
                          const SizedBox(width: 6),
                          Text('Retirer', style: AppText.body(size: 12, color: inkMuted)
                              .copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),

              // Profile header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 32, backgroundColor: accent,
                      child: Text(initials, style: TextStyle(fontFamily: 'CormorantGaramond',
                          fontStyle: FontStyle.italic, fontSize: 22, color: accentInk)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(friendName, style: AppText.displaySm(italic: true, color: ink)),
                      const SizedBox(height: 3),
                      Text(
                        '${friendHandle != null ? '@$friendHandle · ' : ''}${books.length} livre${books.length != 1 ? 's' : ''}',
                        style: AppText.body(size: 12, color: inkMuted),
                      ),
                    ])),
                  ]),
                ),
              ),

              // Action buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showBorrowSheet(context, ref, books, isDark,
                            ink, inkMuted, surface,
                            isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight,
                            border, accent, accentInk),
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
                    GestureDetector(
                      onTap: () => context.push('/messages/$userId', extra: friendName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black12)),
                        child: Text('Message', style: AppText.body(size: 13, color: ink)
                            .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),

              // Library header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Sa bibliothèque', style: AppText.eyebrow(color: inkMuted)),
                    Text('${books.length} livre${books.length != 1 ? 's' : ''}',
                        style: AppText.body(size: 11, color: inkMuted)),
                  ]),
                ),
              ),

              if (books.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Text('Aucun livre dans sa bibliothèque.',
                        style: AppText.body(size: 13, color: inkMuted)),
                  ),
                )
              else
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

  void _showBorrowSheet(BuildContext context, WidgetRef ref, List<Book> books,
      bool isDark, Color ink, Color inkMuted, Color surface, Color surfAlt,
      Color border, Color accent, Color accentInk) {
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cet ami n\'a aucun livre disponible.'),
            behavior: SnackBarBehavior.floating));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BorrowSheet(
        books: books,
        giverId: userId,
        isDark: isDark,
        ink: ink, inkMuted: inkMuted, surface: surface,
        surfAlt: surfAlt, border: border, accent: accent, accentInk: accentInk,
        onBorrowed: () => ref.invalidate(loansProvider),
      ),
    );
  }

  Future<void> _confirmRemoveFriend(
      BuildContext context, WidgetRef ref, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cet ami ?'),
        content: Text('$name sera retiré de ta liste d\'amis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await apiService.removeFriend(userId);
    ref.invalidate(friendsListProvider);
    if (context.mounted) context.pop();
  }
}

class _BorrowSheet extends StatefulWidget {
  final List<Book> books;
  final String giverId;
  final bool isDark;
  final Color ink, inkMuted, surface, surfAlt, border, accent, accentInk;
  final VoidCallback onBorrowed;

  const _BorrowSheet({
    required this.books, required this.giverId, required this.isDark,
    required this.ink, required this.inkMuted, required this.surface,
    required this.surfAlt, required this.border, required this.accent,
    required this.accentInk, required this.onBorrowed,
  });

  @override
  State<_BorrowSheet> createState() => _BorrowSheetState();
}

class _BorrowSheetState extends State<_BorrowSheet> {
  String? _selectedBookId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
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
          Text('Demander un prêt', style: AppText.displaySm(italic: true, color: widget.ink)),
          const SizedBox(height: 6),
          Text('Sélectionne le livre que tu veux emprunter.',
              style: AppText.body(size: 12.5, color: widget.inkMuted).copyWith(height: 1.4)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.books.length,
              itemBuilder: (context, i) {
                final book = widget.books[i];
                final isSelected = _selectedBookId == book.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBookId = book.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? widget.accent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? widget.accent : widget.border, width: isSelected ? 1.5 : 0.5),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(book.title, style: TextStyle(fontFamily: 'CormorantGaramond',
                            fontStyle: FontStyle.italic, fontSize: 15, color: widget.ink, height: 1.1)),
                        Text(book.author, style: AppText.body(size: 11.5, color: widget.inkMuted)),
                      ])),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: widget.accent, size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: (_selectedBookId == null || _saving) ? null : () async {
              setState(() => _saving = true);
              try {
                await apiService.borrowBook(bookId: _selectedBookId!, giverId: widget.giverId);
                widget.onBorrowed();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _selectedBookId != null ? widget.accent : widget.surfAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              child: _saving
                  ? Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentInk)))
                  : Text(
                      _selectedBookId == null ? 'Sélectionne un livre' : 'Confirmer l\'emprunt',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 15,
                          color: _selectedBookId != null ? widget.accentInk : widget.inkMuted)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
