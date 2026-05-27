import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/book.dart';
import 'book_cover.dart';

class BookGridItem extends StatelessWidget {
  final Book book;
  final bool isDark;
  final VoidCallback? onTap;

  const BookGridItem({
    super.key,
    required this.book,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink        = isDark ? AppColors.inkDark             : AppColors.inkLight;
    final inkMuted   = isDark ? AppColors.inkMutedDark        : AppColors.inkMutedLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;

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
          Text(
            book.title,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: ink,
              height: 1.1,
              letterSpacing: -0.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  book.author,
                  style: AppText.body(size: 11, color: inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.star_rounded, size: 11, color: accentStrong),
              const SizedBox(width: 2),
              Text(
                book.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  color: accentStrong,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
