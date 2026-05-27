import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/library')) return 0;
    if (location.startsWith('/friends')) return 1;
    if (location.startsWith('/loans'))   return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDark;
    final location = GoRouterState.of(context).matchedLocation;
    final activeIndex = _locationToIndex(location);

    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final inkColor = isDark ? AppColors.inkDark : AppColors.inkLight;
    final accentColor = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF1A1612).withOpacity(0.08);

    final tabs = [
      _TabItem(icon: Icons.menu_book_rounded, label: 'Bibliothèque', path: '/library'),
      _TabItem(icon: Icons.group_rounded, label: 'Amis', path: '/friends'),
      _TabItem(icon: Icons.swap_horiz_rounded, label: 'Prêts', path: '/loans'),
      _TabItem(icon: Icons.person_rounded, label: 'Profil', path: '/profile'),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          child,
          // Bottom tab bar — pill style exact du design
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.7, 1.0],
                  colors: [bgColor, bgColor.withOpacity(0)],
                ),
              ),
              padding: EdgeInsets.only(
                left: 12, right: 12,
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 12,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor, width: 0.5),
                  boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
                ),
                child: Row(
                  children: tabs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tab = entry.value;
                    final isActive = i == activeIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => context.go(tab.path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isActive ? accentColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 20,
                                color: isActive ? accentInk : inkMuted,
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: isActive ? 14 : 0,
                                child: isActive
                                    ? Text(
                                        tab.label,
                                        style: AppText.eyebrow(
                                          color: accentInk,
                                        ).copyWith(fontSize: 9.5),
                                        textAlign: TextAlign.center,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
