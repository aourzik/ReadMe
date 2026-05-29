import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/providers/app_providers.dart';

final _bookDetailProvider = FutureProvider.family<Book, String>(
  (ref, id) => apiService.getBook(id),
);
final _friendsProvider = FutureProvider<List<User>>((ref) => apiService.getFriends());

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _lendSheetOpen = false;
  bool _ratingSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider).isDark;
    final bookAsync = ref.watch(_bookDetailProvider(widget.bookId));

    final bg        = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink       = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft   = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface   = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border    = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (book) => Stack(
          children: [
            // ── Hero color wash ──
            Positioned(
              top: 0, left: 0, right: 0,
              height: 280,
              child: Container(
                color: _heroColor(book).withOpacity(0.5),
              ),
            ),
            // ── Gradient fadeout ──
            Positioned(
              top: 270, left: 0, right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, bg],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ──
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Nav row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SoftIconBtn(icon: Icons.chevron_left_rounded, isDark: isDark, onTap: () => context.pop()),
                          Row(children: [
                            _SoftIconBtn(
                              icon: book.isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              isDark: isDark,
                              color: book.isFavorite ? accent : null,
                              onTap: () async {
                                await apiService.updateBook(book.id, {'isFavorite': !book.isFavorite});
                                ref.invalidate(_bookDetailProvider(widget.bookId));
                                ref.invalidate(booksProvider);
                              },
                            ),
                            const SizedBox(width: 6),
                            _SoftIconBtn(
                              icon: Icons.delete_outline_rounded,
                              isDark: isDark,
                              onTap: () => _confirmDelete(context, book, ref),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    // Cover centered with slight tilt
                    Center(
                      child: Transform.rotate(
                        angle: -0.035,
                        child: BookCover(book: book, width: 150, height: 225, isDark: isDark),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title block
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(book.tags.join(' · ') + ' · ${book.year}',
                              style: AppText.eyebrow(color: inkMuted)),
                          const SizedBox(height: 8),
                          Text(book.title, style: AppText.displayMd(italic: true, color: ink),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          RichText(text: TextSpan(
                            style: AppText.body(size: 13, color: inkMuted),
                            children: [
                              const TextSpan(text: 'par '),
                              TextSpan(text: book.author, style: AppText.body(size: 13, color: inkSoft)
                                  .copyWith(fontWeight: FontWeight.w600)),
                            ],
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: surface, borderRadius: AppRadius.cardLg,
                          border: Border.all(color: border, width: 0.5),
                          boxShadow: AppShadows.soft(dark: isDark),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatCell(label: 'Note', value: book.rating.toStringAsFixed(1),
                                icon: Icons.star_rounded, iconColor: accentStrong, ink: ink, inkMuted: inkMuted),
                            Container(width: 0.5, height: 24, color: border),
                            _StatCell(label: 'Pages', value: '${book.pages}', ink: ink, inkMuted: inkMuted),
                            Container(width: 0.5, height: 24, color: border),
                            _StatCell(label: 'Ajouté', value: _formatDate(book.addedAt), ink: ink, inkMuted: inkMuted),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('À propos', style: AppText.eyebrow(color: inkMuted)),
                          const SizedBox(height: 8),
                          Text(book.description,
                              style: AppText.body(size: 14, color: inkSoft).copyWith(height: 1.55)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // space for CTA
                  ],
                ),
              ),
            ),

            // ── CTA buttons ──
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.6, 1.0],
                    colors: [bg, bg.withOpacity(0)],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 20, right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 14,
                  top: 14,
                ),
                child: Row(
                  children: [
                    // Note button
                    _OutlineBtn(
                      label: book.rating > 0
                          ? book.rating.toStringAsFixed(1)
                          : 'Noter',
                      icon: Icons.star_rounded,
                      isDark: isDark,
                      onTap: () => setState(() => _ratingSheetOpen = true),
                    ),
                    const SizedBox(width: 10),
                    // Prêter button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _lendSheetOpen = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: AppShadows.soft(dark: isDark),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 15, color: accentInk),
                              const SizedBox(width: 8),
                              Text('Prêter ce livre',
                                  style: AppText.body(size: 14, color: accentInk)
                                      .copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lend bottom sheet ──
            if (_lendSheetOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _lendSheetOpen = false),
                child: Container(color: Colors.black54),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _LendSheet(
                  book: book,
                  isDark: isDark,
                  onConfirm: () => setState(() => _lendSheetOpen = false),
                  onClose: () => setState(() => _lendSheetOpen = false),
                ),
              ),
            ],

            // ── Rating bottom sheet ──
            if (_ratingSheetOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _ratingSheetOpen = false),
                child: Container(color: Colors.black54),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _RatingSheet(
                  book: book,
                  isDark: isDark,
                  onSaved: (newRating) {
                    setState(() => _ratingSheetOpen = false);
                    ref.invalidate(_bookDetailProvider(widget.bookId));
                    ref.invalidate(booksProvider);
                  },
                  onClose: () => setState(() => _ratingSheetOpen = false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Book book, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce livre ?'),
        content: Text('« ${book.title} » sera retiré de ta bibliothèque.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await apiService.deleteBook(book.id);
    ref.invalidate(booksProvider);
    if (mounted) context.pop();
  }

  Color _heroColor(Book book) {
    if (book.coverUrl != null) return AppColors.accentRoseStrongLight;
    // Derive from title hash
    const colors = [Color(0xFF1A3340), Color(0xFFE9C4A3), Color(0xFFF5D3D7), Color(0xFF2D2418)];
    final hash = book.title.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = ['Jan.','Fév.','Mars','Avr.','Mai','Juin','Juil.','Août','Sep.','Oct.','Nov.','Déc.'];
    return months[dt.month - 1];
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  final Color? iconColor;
  final Color ink, inkMuted;
  const _StatCell({required this.label, required this.value, this.icon, this.iconColor,
      required this.ink, required this.inkMuted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(value, style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500, fontSize: 20, color: ink, height: 1)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppText.eyebrow(color: inkMuted).copyWith(fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}

class _SoftIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? color;
  const _SoftIconBtn({required this.icon, required this.isDark, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink     = isDark ? AppColors.inkDark : AppColors.inkLight;
    final border  = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
            border: Border.all(color: border, width: 0.5),
            boxShadow: AppShadows.soft(dark: isDark)),
        child: Icon(icon, size: 18, color: color ?? ink),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink    = isDark ? AppColors.inkDark : AppColors.inkLight;
    final border = isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 0.5)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 6),
            Text(label, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Rating bottom sheet ─────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final Book book;
  final bool isDark;
  final void Function(double) onSaved;
  final VoidCallback onClose;
  const _RatingSheet({required this.book, required this.isDark, required this.onSaved, required this.onClose});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  double _selected = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.book.rating > 0 ? widget.book.rating : 0;
  }

  Future<void> _save() async {
    if (_selected == 0) return;
    setState(() => _saving = true);
    try {
      await apiService.updateBook(widget.book.id, {'rating': _selected});
      widget.onSaved(_selected);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = widget.isDark;
    final bg        = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink       = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border    = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 32, offset: const Offset(0, -8))],
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
          ),
          Text('Ta note', style: AppText.eyebrow(color: inkMuted)),
          const SizedBox(height: 6),
          Text(widget.book.title,
              style: AppText.displaySm(italic: true, color: ink),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 28),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starValue = (i + 1).toDouble();
              final filled = _selected >= starValue;
              final halfFilled = !filled && _selected >= starValue - 0.5;
              return GestureDetector(
                onTap: () => setState(() => _selected = starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    halfFilled ? Icons.star_half_rounded
                        : filled ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 42,
                    color: filled || halfFilled ? accentStrong : border,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),
          Text(
            _selected == 0 ? 'Touche une étoile pour noter'
                : _selected <= 1 ? 'Décevant'
                : _selected <= 2 ? 'Pas terrible'
                : _selected <= 3 ? 'Correct'
                : _selected <= 4 ? 'Très bien'
                : 'Chef-d\'œuvre !',
            style: AppText.body(size: 13, color: _selected == 0 ? inkMuted : ink)
                .copyWith(fontStyle: FontStyle.italic),
          ),

          const SizedBox(height: 28),

          // CTA
          GestureDetector(
            onTap: (_selected > 0 && !_saving) ? _save : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _selected > 0 ? accent : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight),
                borderRadius: BorderRadius.circular(999),
              ),
              child: _saving
                  ? Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accentInk)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.star_rounded, size: 16,
                          color: _selected > 0 ? accentInk : inkMuted),
                      const SizedBox(width: 8),
                      Text('Enregistrer ma note',
                          style: AppText.body(size: 15,
                              color: _selected > 0 ? accentInk : inkMuted)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lend bottom sheet ────────────────────────────────────────────────────────

class _LendSheet extends ConsumerStatefulWidget {
  final Book book;
  final bool isDark;
  final VoidCallback onConfirm, onClose;
  const _LendSheet({required this.book, required this.isDark, required this.onConfirm, required this.onClose});

  @override
  ConsumerState<_LendSheet> createState() => _LendSheetState();
}

class _LendSheetState extends ConsumerState<_LendSheet> {
  String? _pickedFriendId;
  int _durationDays = 21;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    final friendsAsync = ref.watch(_friendsProvider);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 32, offset: const Offset(0, -8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(children: [
              Text('Prêter ce livre', style: AppText.eyebrow(color: inkMuted)),
              const SizedBox(height: 6),
              Text('à un ami…', style: AppText.displaySm(italic: true, color: ink)),
            ]),
          ),
          // Book preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 0.5)),
              child: Row(children: [
                BookCover(book: widget.book, width: 36, height: 54, isDark: isDark),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.book.title, style: TextStyle(fontFamily: 'CormorantGaramond',
                      fontStyle: FontStyle.italic, fontSize: 15, color: ink, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(widget.book.author, style: AppText.body(size: 11, color: inkMuted)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Friends list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(alignment: Alignment.centerLeft,
                child: Text('Destinataire', style: AppText.eyebrow(color: inkMuted))),
          ),
          const SizedBox(height: 8),
          friendsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(20),
                child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (friends) => Column(
              children: friends.take(4).map((f) {
                final isActive = _pickedFriendId == f.id;
                return GestureDetector(
                  onTap: () => setState(() => _pickedFriendId = f.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? accentSubtle : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      CircleAvatar(radius: 18, backgroundColor: accent,
                          child: Text(f.name.split(' ').map((w) => w[0]).take(2).join(''),
                              style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                                  fontSize: 14, color: accentInk))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.name, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                        Text('${f.bookCount} livres · ${f.friendCount} amis en commun',
                            style: AppText.body(size: 11, color: inkMuted)),
                      ])),
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? accentStrong : Colors.transparent,
                          border: Border.all(color: isActive ? Colors.transparent : border, width: 1.5),
                        ),
                        child: isActive ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Duration picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(alignment: Alignment.centerLeft,
                child: Text('Durée du prêt', style: AppText.eyebrow(color: inkMuted))),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                {14: '2 sem.'}, {21: '3 sem.'}, {30: '1 mois'}, {0: 'Sans limite'},
              ].expand((m) => m.entries).map((e) {
                final isActive = _durationDays == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _durationDays = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? accent : surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isActive ? Colors.transparent : border, width: 0.5),
                      ),
                      child: Text(e.value, style: AppText.body(size: 11.5,
                          color: isActive ? accentInk : ink).copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Confirm
          Padding(
            padding: EdgeInsets.only(left: 24, right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 12),
            child: GestureDetector(
              onTap: (_pickedFriendId != null && !_saving) ? () async {
                setState(() => _saving = true);
                try {
                  await apiService.createLoan(
                    bookId: widget.book.id,
                    partnerId: _pickedFriendId!,
                    dueDate: _durationDays > 0
                        ? DateTime.now().add(Duration(days: _durationDays))
                        : null,
                  );
                  ref.invalidate(loansProvider);
                  ref.invalidate(booksProvider);
                  widget.onConfirm();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e')));
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _pickedFriendId != null ? ink : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: AppShadows.soft(dark: isDark),
                ),
                child: _saving
                    ? Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: isDark ? AppColors.bgDark : AppColors.bgLight)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.swap_horiz_rounded, size: 16,
                            color: _pickedFriendId != null ? (isDark ? AppColors.bgDark : AppColors.bgLight) : inkMuted),
                        const SizedBox(width: 8),
                        Text('Confirmer le prêt', style: AppText.body(size: 15,
                            color: _pickedFriendId != null ? (isDark ? AppColors.bgDark : AppColors.bgLight) : inkMuted)
                            .copyWith(fontWeight: FontWeight.w600)),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
