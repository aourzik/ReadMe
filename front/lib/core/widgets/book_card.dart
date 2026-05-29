import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/book.dart';
import 'book_cover.dart';

/// BookCard — rectangle, couverture à gauche (1/3), info à droite (2/3).
/// Exactement comme défini dans le design.
class BookCard extends StatelessWidget {
  final Book book;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;
  final bool compact;

  const BookCard({
    super.key,
    required this.book,
    this.isDark = false,
    this.onTap,
    this.onMarkRead,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 14.0;
    final coverW = compact ? 64.0 : 76.0;
    final coverH = coverW * 1.5;

    final bgColor   = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final inkColor  = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft   = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border    = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF1A1612).withOpacity(0.08);
    final accent       = isDark ? AppColors.accentRoseDark       : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentInk    = isDark ? AppColors.accentRoseInkDark    : AppColors.accentRoseInkLight;
    final surfAlt   = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.card,
          border: Border.all(color: border, width: 0.5),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(book: book, width: coverW, height: coverH, isDark: isDark),
                      SizedBox(width: pad),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: AppText.displayBook(italic: true, color: inkColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${book.author} · ${book.year}',
                              style: AppText.label(color: inkMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!compact) ...[
                              const SizedBox(height: 6),
                              Text(
                                book.description,
                                style: AppText.body(size: 11.5, color: inkSoft).copyWith(height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (book.tags.isNotEmpty)
                                  Flexible(child: _Tag(label: book.tags[0], surfAlt: surfAlt, inkSoft: inkSoft)),
                                if (book.tags.length > 1) ...[
                                  const SizedBox(width: 6),
                                  Flexible(child: _Tag(label: book.tags[1], surfAlt: surfAlt, inkSoft: inkSoft)),
                                ],
                                const Spacer(),
                                _RatingBadge(rating: book.rating, accent: accentStrong, isDark: isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (onMarkRead != null) ...[
                    SizedBox(height: pad * 0.8),
                    GestureDetector(
                      onTap: onMarkRead,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: surfAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.check_rounded, size: 13, color: inkSoft),
                          const SizedBox(width: 6),
                          Text('J\'ai terminé ce livre',
                              style: AppText.body(size: 12, color: inkSoft)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Badge prêt
            if (book.lentTo != null)
              Positioned(
                top: pad, right: pad,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 10, color: accentInk),
                      const SizedBox(width: 4),
                      Text(
                        book.lentTo!,
                        style: AppText.body(size: 9.5, color: accentInk).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color surfAlt;
  final Color inkSoft;
  const _Tag({required this.label, required this.surfAlt, required this.inkSoft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: surfAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppText.body(size: 10, color: inkSoft).copyWith(
        fontWeight: FontWeight.w500, letterSpacing: 0.15,
      ), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  final Color accent;
  final bool isDark;
  const _RatingBadge({required this.rating, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 12, color: accent),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
      ],
    );
  }
}
