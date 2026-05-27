import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LibraryTopBar extends StatelessWidget {
  final bool isDark;
  final int totalBooks;
  final int reading;
  final int lent;
  final VoidCallback onAdd;

  const LibraryTopBar({
    super.key,
    required this.isDark,
    required this.totalBooks,
    required this.reading,
    required this.lent,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final ink       = isDark ? AppColors.inkDark       : AppColors.inkLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark  : AppColors.inkMutedLight;
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;
    final border    = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFDF6ED),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_readme.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          fontSize: 28,
                          color: const Color(0xFF1A1612),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Bell
              SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.notifications_none_rounded, size: 18, color: ink),
              ),
              const SizedBox(width: 6),
              // Add
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: accentInk),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$totalBooks livres · $reading en cours · $lent prêtés',
            style: AppText.eyebrow(color: inkMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Ma bibliothèque',
            style: AppText.display(size: 34, italic: true, color: ink),
          ),
        ],
      ),
    );
  }
}
