import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/book.dart';

/// BookCover — couverture de livre.
/// Si l'URL Google Books est disponible → image réseau.
/// Sinon → couverture typographique générée (como dans le design).
class BookCover extends StatelessWidget {
  final Book book;
  final double width;
  final double height;
  final bool isDark;

  const BookCover({
    super.key,
    required this.book,
    this.width = 76,
    this.height = 114,
    this.isDark = false,
  });

  // Palette de couleurs basées sur le titre (déterministe)
  static _CoverPalette _paletteFor(Book book) {
    final palettes = [
      _CoverPalette(bg: const Color(0xFF1A3340), ink: const Color(0xFFE9C4A3)),
      _CoverPalette(bg: const Color(0xFFE9C4A3), ink: const Color(0xFF3A2410)),
      _CoverPalette(bg: const Color(0xFFF5D3D7), ink: const Color(0xFF5A2030), italic: true),
      _CoverPalette(bg: const Color(0xFF2D2418), ink: const Color(0xFFE9C4A3)),
      _CoverPalette(bg: const Color(0xFF7EC8C0), ink: const Color(0xFF0A3D62)),
      _CoverPalette(bg: const Color(0xFFC9A87A), ink: const Color(0xFF3A2410)),
      _CoverPalette(bg: const Color(0xFFFDF6ED), ink: const Color(0xFF1A1612), italic: true),
      _CoverPalette(bg: const Color(0xFF0A3D62), ink: const Color(0xFFF0E1C9)),
    ];
    final hash = book.title.codeUnits.fold(0, (a, b) => a + b);
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: book.coverUrl!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildTypoCover(),
          errorWidget: (_, __, ___) => _buildTypoCover(),
        ),
      );
    }
    return _buildTypoCover();
  }

  Widget _buildTypoCover() {
    final palette = _paletteFor(book);
    final fontSize = (width * 0.13).clamp(8.0, 14.0);
    final authorSize = (width * 0.08).clamp(6.0, 11.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left spine shadow
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.22),
                  ],
                ),
              ),
            ),
          ),
          // Title + author
          Padding(
            padding: EdgeInsets.all(width * 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: fontSize,
                    fontStyle: palette.italic ? FontStyle.italic : FontStyle.normal,
                    fontWeight: FontWeight.w500,
                    color: palette.ink,
                    height: 1.05,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  book.author.split(' ').last.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: authorSize,
                    fontWeight: FontWeight.w500,
                    color: palette.ink.withOpacity(0.75),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPalette {
  final Color bg;
  final Color ink;
  final bool italic;
  const _CoverPalette({required this.bg, required this.ink, this.italic = false});
}
