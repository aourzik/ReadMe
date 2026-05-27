import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDark;

    final bg      = isDark ? AppColors.bgDark      : AppColors.bgLight;
    final ink     = isDark ? AppColors.inkDark     : AppColors.inkLight;
    final inkSoft = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted= isDark ? AppColors.inkMutedDark: AppColors.inkMutedLight;
    final accent  = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Ambient blobs (simple opacity, no BackdropFilter needed)
          Positioned(
            top: 40, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            top: 200, left: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentSubtle.withOpacity(0.55),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LogoMark(isDark: isDark, size: 156),
                      const SizedBox(height: 28),
                      Text(
                        'ReadMe',
                        style: AppText.display(size: 56, italic: true, color: ink),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Ta bibliothèque, ton cercle de lectrices,\ntes prêts. Tenus avec soin.',
                          style: AppText.body(size: 14.5, color: inkSoft)
                              .copyWith(height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // CTAs
                Padding(
                  padding: EdgeInsets.only(
                    left: 24, right: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      _PrimaryButton(
                        label: 'Créer un compte',
                        isDark: isDark,
                        onTap: () => context.push('/register'),
                      ),
                      const SizedBox(height: 10),
                      _GhostButton(
                        label: "J'ai déjà un compte",
                        isDark: isDark,
                        onTap: () => context.push('/login'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "En continuant, tu acceptes nos conditions et notre politique de confidentialité.",
                        style: AppText.body(size: 10.5, color: inkMuted)
                            .copyWith(letterSpacing: 0.2),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _LogoMark extends StatelessWidget {
  final bool isDark;
  final double size;
  const _LogoMark({required this.isDark, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFDF6ED),
        boxShadow: isDark
            ? [
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 2, offset: const Offset(0, 1)),
                BoxShadow(color: Colors.black.withOpacity(0.4),  blurRadius: 28, offset: const Offset(0, 8)),
              ]
            : [
                BoxShadow(color: const Color(0x0A3C2814), blurRadius: 2, offset: const Offset(0, 1)),
                BoxShadow(color: const Color(0x143C2814), blurRadius: 28, offset: const Offset(0, 8)),
              ],
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
                fontSize: size * 0.45,
                color: const Color(0xFF1A1612),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? AppColors.inkDark  : AppColors.inkLight;
    final ink = isDark ? AppColors.bgDark   : AppColors.bgLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.soft(dark: isDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppText.body(size: 15, color: ink)
                .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 16, color: ink),
          ],
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink    = isDark ? AppColors.inkDark : AppColors.inkLight;
    final border = isDark
        ? Colors.white.withOpacity(0.16)
        : const Color(0xFF1A1612).withOpacity(0.16);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Text(label,
          style: AppText.body(size: 14, color: ink)
              .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
          textAlign: TextAlign.center),
      ),
    );
  }
}
