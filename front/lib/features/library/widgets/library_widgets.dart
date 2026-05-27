import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/book.dart';
import '../../../core/widgets/book_cover.dart';

// ─── Library Top Bar ─────────────────────────────────────────────────────────

class LibraryTopBar extends StatelessWidget {
  final bool isDark;
  final int totalBooks, reading, lent;
  final VoidCallback onAdd;
  const LibraryTopBar({super.key, required this.isDark, required this.totalBooks,
      required this.reading, required this.lent, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo badge
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFDF6ED),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: ClipOval(child: Image.asset('assets/images/logo_readme.png', fit: BoxFit.cover)),
              ),
              const Spacer(),
              // Bell
              _IconBtn(icon: Icons.notifications_none_rounded, isDark: isDark),
              const SizedBox(width: 6),
              // Add button
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: accent,
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: accentInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalBooks livres · $reading en cours · $lent prêtés',
            style: AppText.eyebrow(color: inkMuted),
          ),
          const SizedBox(height: 4),
          Text('Ma bibliothèque', style: AppText.display(size: 34, italic: true, color: ink)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  const _IconBtn({required this.icon, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 18, color: ink)),
    );
  }
}

// ─── Filter Chip Row ──────────────────────────────────────────────────────────

class FilterChipRow extends StatelessWidget {
  final bool isDark;
  final String active;
  final ValueChanged<String> onChange;
  static const filters = ['Tout', 'En cours', 'Lus', 'Souhaités', 'Prêtés'];

  const FilterChipRow({super.key, required this.isDark, required this.active, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final ink    = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft= isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final border = isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16);
    final bg     = isDark ? AppColors.bgDark : AppColors.bgLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isActive = active == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChange(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isActive ? Colors.transparent : border, width: 0.5),
                ),
                child: Text(f, style: AppText.body(size: 12, color: isActive ? bg : inkSoft)
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Book Grid Item ───────────────────────────────────────────────────────────

class BookGridItem extends StatelessWidget {
  final Book book;
  final bool isDark;
  final VoidCallback? onTap;
  const BookGridItem({super.key, required this.book, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink    = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted= isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final accent = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BookCover(
              book: book,
              width: double.infinity,
              height: double.infinity,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(book.title,
            style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500, fontSize: 15, color: ink, height: 1.1,
                letterSpacing: -0.15),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(book.author,
                style: AppText.body(size: 11, color: inkMuted),
                overflow: TextOverflow.ellipsis,
              )),
              Icon(Icons.star_rounded, size: 11, color: accent),
              const SizedBox(width: 2),
              Text(book.rating.toStringAsFixed(1),
                style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                    fontSize: 11, color: accent, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
