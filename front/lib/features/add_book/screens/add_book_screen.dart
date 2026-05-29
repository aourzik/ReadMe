import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/widgets/book_cover.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _searchResultsProvider = FutureProvider<List<GoogleBookResult>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  if (query.isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 400));
  return googleBooksService.search(query);
});

final _suggestionsProvider = FutureProvider<List<GoogleBookResult>>((ref) async {
  return googleBooksService.getSuggestions();
});

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _searchCtrl = TextEditingController();
  GoogleBookResult? _picked;
  ReadStatus _status = ReadStatus.wishlist;
  bool _saving = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(_searchQueryProvider.notifier).state = _searchCtrl.text;
      if (_searchCtrl.text.isNotEmpty && _showSuggestions) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  Future<void> _save() async {
    if (_picked == null) return;
    setState(() => _saving = true);
    try {
      final book = Book(
        id: '',
        title: _picked!.title,
        author: _picked!.author,
        year: _picked!.year ?? DateTime.now().year,
        pages: _picked!.pages ?? 0,
        description: _picked!.description ?? '',
        coverUrl: _picked!.coverUrl,
        googleBooksId: _picked!.googleId,
        tags: _picked!.categories.take(2).toList(),
        status: _status,
        addedAt: DateTime.now(),
      );
      await apiService.addBook(book);
      if (mounted) {
        context.pop();
        ref.invalidate(booksProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  void _onBarcodeDetected(String isbn) {
    _searchCtrl.text = isbn;
    ref.read(_searchQueryProvider.notifier).state = isbn;
    setState(() => _showSuggestions = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = ref.watch(themeProvider).isDark;
    final results = ref.watch(_searchResultsProvider);
    final suggestions = ref.watch(_suggestionsProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt  = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    // Determine what to show in the results area
    final showingSuggestions = _showSuggestions && _searchCtrl.text.isEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                          border: Border.all(color: border, width: 0.5)),
                      child: Icon(Icons.close_rounded, size: 18, color: ink),
                    ),
                  ),
                  const Spacer(),
                  Text('Ajouter un livre',
                      style: AppText.body(size: 13, color: inkSoft).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            // ── Tagline ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Que lis-tu en ce moment ?', style: AppText.displayMd(italic: true, color: ink)),
                  const SizedBox(height: 6),
                  Text('Cherche un titre, scanne un code-barres ou découvre des suggestions.',
                      style: AppText.body(size: 12.5, color: inkMuted).copyWith(height: 1.4)),
                ],
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border, width: 0.5),
                  boxShadow: AppShadows.soft(dark: isDark),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, size: 16, color: inkMuted),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    style: AppText.body(size: 13.5, color: ink),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Titre, auteur, ISBN…',
                      hintStyle: AppText.body(size: 13.5, color: inkMuted),
                      isDense: true, contentPadding: EdgeInsets.zero,
                    ),
                  )),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        ref.read(_searchQueryProvider.notifier).state = '';
                        setState(() => _showSuggestions = false);
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: inkMuted),
                    ),
                ]),
              ),
            ),

            // ── Quick action pills ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(children: [
                _QuickBtn(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Code-barres',
                  isDark: isDark,
                  active: false,
                  onTap: () => _showBarcodeScanSheet(context, isDark, ink, inkMuted, bg),
                ),
                const SizedBox(width: 8),
                _QuickBtn(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Suggestions',
                  isDark: isDark,
                  active: showingSuggestions,
                  accent: accent,
                  accentInk: accentInk,
                  onTap: () => setState(() => _showSuggestions = !_showSuggestions),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: border, height: 1),
            ),
            const SizedBox(height: 8),

            // ── Results / Suggestions ──
            Expanded(
              child: showingSuggestions
                  ? _buildSuggestions(suggestions, ink, inkMuted, accentSubtle, accentStrong, surfAlt)
                  : _buildSearchResults(results, ink, inkMuted, accentSubtle, accentStrong, surfAlt),
            ),

            // ── Status selector + Save CTA ──
            if (_picked != null) ...[
              Divider(color: border, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text('Statut :', style: AppText.body(size: 12, color: inkMuted)),
                    const SizedBox(width: 10),
                    ...ReadStatus.values.map((s) {
                      final label = s == ReadStatus.reading ? 'En cours'
                          : s == ReadStatus.read ? 'Lu' : 'Souhaité';
                      final isActive = _status == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _status = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive ? ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: isActive ? Colors.transparent : border, width: 0.5),
                            ),
                            child: Text(label, style: AppText.body(size: 11.5,
                                color: isActive ? (isDark ? AppColors.bgDark : AppColors.bgLight) : inkSoft)
                                .copyWith(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 12),
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(999),
                      boxShadow: AppShadows.soft(dark: isDark),
                    ),
                    child: _saving
                        ? Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: accentInk)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_rounded, size: 16, color: accentInk),
                            const SizedBox(width: 8),
                            Text('Ajouter à ma bibliothèque',
                                style: AppText.body(size: 15, color: accentInk).copyWith(fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<GoogleBookResult>> results, Color ink, Color inkMuted,
      Color accentSubtle, Color accentStrong, Color surfAlt) {
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur recherche: $e',
          style: AppText.body(size: 12, color: inkMuted), textAlign: TextAlign.center)),
      data: (books) {
        if (books.isEmpty && _searchCtrl.text.isNotEmpty) {
          return Center(child: Text('Aucun résultat', style: AppText.body(size: 14, color: inkMuted)));
        }
        if (books.isEmpty) return const SizedBox.shrink();
        return _bookList(books, ink, inkMuted, accentSubtle, accentStrong, surfAlt, showCount: true);
      },
    );
  }

  Widget _buildSuggestions(AsyncValue<List<GoogleBookResult>> suggestions, Color ink, Color inkMuted,
      Color accentSubtle, Color accentStrong, Color surfAlt) {
    return suggestions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text('Impossible de charger les suggestions',
          style: AppText.body(size: 13, color: inkMuted))),
      data: (books) => _bookList(books, ink, inkMuted, accentSubtle, accentStrong, surfAlt,
          header: 'Tendances littéraires'),
    );
  }

  Widget _bookList(List<GoogleBookResult> books, Color ink, Color inkMuted,
      Color accentSubtle, Color accentStrong, Color surfAlt, {bool showCount = false, String? header}) {
    final isDark = ref.watch(themeProvider).isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            header ?? '${books.length} résultats',
            style: AppText.eyebrow(color: inkMuted),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final r = books[i];
              final isActive = _picked?.googleId == r.googleId;
              final mockBook = Book(
                id: r.googleId, title: r.title, author: r.author,
                year: r.year ?? 0, pages: r.pages ?? 0, coverUrl: r.coverUrl,
              );
              return GestureDetector(
                onTap: () => setState(() => _picked = isActive ? null : r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? accentSubtle : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    BookCover(book: mockBook, width: 44, height: 66, isDark: isDark),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, style: TextStyle(fontFamily: 'CormorantGaramond',
                          fontStyle: FontStyle.italic, fontWeight: FontWeight.w500,
                          fontSize: 16, color: ink, height: 1.1, letterSpacing: -0.1)),
                      const SizedBox(height: 3),
                      Text('${r.author}${r.year != null ? ' · ${r.year}' : ''}',
                          style: AppText.body(size: 12, color: inkMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    const SizedBox(width: 8),
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? accentStrong : surfAlt,
                      ),
                      child: Icon(
                        isActive ? Icons.check_rounded : Icons.add_rounded,
                        size: 14,
                        color: isActive ? Colors.white : inkMuted,
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBarcodeScanSheet(BuildContext context, bool isDark, Color ink, Color inkMuted, Color bg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BarcodeScanSheet(
        isDark: isDark,
        onDetected: (isbn) {
          Navigator.pop(context);
          _onBarcodeDetected(isbn);
        },
      ),
    );
  }
}

// ── Barcode scanner sheet ─────────────────────────────────────────────────────

class _BarcodeScanSheet extends StatefulWidget {
  final bool isDark;
  final void Function(String isbn) onDetected;
  const _BarcodeScanSheet({required this.isDark, required this.onDetected});

  @override
  State<_BarcodeScanSheet> createState() => _BarcodeScanSheetState();
}

class _BarcodeScanSheetState extends State<_BarcodeScanSheet> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _detected = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink    = widget.isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = widget.isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border = widget.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              Text('Scanner un code-barres', style: AppText.eyebrow(color: inkMuted)),
              const SizedBox(height: 4),
              Text('Vise l\'ISBN au dos du livre', style: AppText.displaySm(italic: true, color: ink)),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: _ctrl,
                  onDetect: (capture) {
                    if (_detected) return;
                    final barcode = capture.barcodes.firstOrNull;
                    final raw = barcode?.rawValue;
                    if (raw == null) return;
                    // Accept EAN-13 / ISBN-13 / ISBN-10
                    if (raw.length >= 10) {
                      _detected = true;
                      widget.onDetected(raw);
                    }
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Text(
              'Assure-toi que le code-barres est bien éclairé',
              style: AppText.body(size: 12, color: inkMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action button ───────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool active;
  final Color? accent;
  final Color? accentInk;
  final VoidCallback? onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    this.active = false,
    this.accent,
    this.accentInk,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink    = isDark ? AppColors.inkDark : AppColors.inkLight;
    final border = isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16);
    final bgColor = active && accent != null ? accent! : Colors.transparent;
    final fgColor = active && accentInk != null ? accentInk! : ink;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? Colors.transparent : border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 6),
            Text(label, style: AppText.body(size: 12, color: fgColor).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
