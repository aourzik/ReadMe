import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterChipRow extends StatelessWidget {
  final bool isDark;
  final String active;
  final ValueChanged<String> onChange;

  static const filters = ['Tout', 'En cours', 'Lus', 'Souhaités', 'Prêtés'];

  const FilterChipRow({
    super.key,
    required this.isDark,
    required this.active,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final ink     = isDark ? AppColors.inkDark      : AppColors.inkLight;
    final inkSoft = isDark ? AppColors.inkSoftDark  : AppColors.inkSoftLight;
    final border  = isDark
        ? Colors.white.withOpacity(0.16)
        : Colors.black.withOpacity(0.16);
    final bg      = isDark ? AppColors.bgDark       : AppColors.bgLight;

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
                  border: Border.all(
                    color: isActive ? Colors.transparent : border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  f,
                  style: AppText.body(
                    size: 12,
                    color: isActive ? bg : inkSoft,
                  ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
