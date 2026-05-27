import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  final _steps = const [
    _OnboardingStep(
      eyebrow: 'Étape 1 sur 3',
      title: 'Tes livres,\nenfin chez toi.',
      body: 'Recense ta bibliothèque comme on tient un journal. Chaque livre que tu possèdes, à portée de main.',
      artType: OnboardingArt.spines,
    ),
    _OnboardingStep(
      eyebrow: 'Étape 2 sur 3',
      title: 'Un cercle\nde lectrices.',
      body: "Ajoute tes amies, partage ton catalogue, découvre ce qu'elles lisent en ce moment.",
      artType: OnboardingArt.avatars,
    ),
    _OnboardingStep(
      eyebrow: 'Étape 3 sur 3',
      title: 'Prête sans\nrien perdre.',
      body: 'Suis qui a quoi, quand, et combien de temps. Plus jamais de "à qui j\'avais bien pu prêter ça ?".',
      artType: OnboardingArt.swap,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider).isDark;
    final s = _steps[_step];

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border   = isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Logo badge
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFDF6ED),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5)),
                    child: ClipOval(child: Image.asset('assets/images/logo_readme.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 14),
                  // Progress dots
                  Row(children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 5),
                    width: i == _step ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _step ? ink : border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ))),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/library'),
                    child: Text('Passer', style: AppText.body(size: 12, color: inkMuted).copyWith(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            // Art
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _OnboardingArtWidget(artType: s.artType, isDark: isDark,
                  ink: ink, inkMuted: inkMuted, accent: accent, accentInk: accentInk),
            ),

            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.eyebrow, style: AppText.eyebrow(color: inkMuted)),
                    const SizedBox(height: 14),
                    Text(
                      s.title,
                      style: AppText.display(size: 40, italic: true, color: ink).copyWith(
                        height: 1.0, letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(s.body, style: AppText.body(size: 14.5, color: inkSoft).copyWith(height: 1.55)),
                  ],
                ),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: GestureDetector(
                onTap: () {
                  if (_step < 2) {
                    setState(() => _step++);
                  } else {
                    context.go('/library');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ink, borderRadius: BorderRadius.circular(999),
                    boxShadow: AppShadows.soft(dark: isDark),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      _step < 2 ? 'Continuer' : 'Commencer',
                      style: AppText.body(size: 15, color: isDark ? AppColors.bgDark : AppColors.bgLight)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16,
                        color: isDark ? AppColors.bgDark : AppColors.bgLight),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Art widgets ─────────────────────────────────────────────────────────────

enum OnboardingArt { spines, avatars, swap }

class _OnboardingStep {
  final String eyebrow, title, body;
  final OnboardingArt artType;
  const _OnboardingStep({required this.eyebrow, required this.title, required this.body, required this.artType});
}

class _OnboardingArtWidget extends StatelessWidget {
  final OnboardingArt artType;
  final bool isDark;
  final Color ink, inkMuted, accent, accentInk;
  const _OnboardingArtWidget({required this.artType, required this.isDark,
      required this.ink, required this.inkMuted, required this.accent, required this.accentInk});

  @override
  Widget build(BuildContext context) {
    switch (artType) {
      case OnboardingArt.spines:
        return _SpinesArt();
      case OnboardingArt.avatars:
        return _AvatarsArt(accent: accent, accentInk: accentInk, ink: inkMuted);
      case OnboardingArt.swap:
        return _SwapArt(accent: accent, accentInk: accentInk, ink: ink, inkMuted: inkMuted);
    }
  }
}

class _SpinesArt extends StatelessWidget {
  final spines = const [
    (h: 180.0, w: 28.0, bg: Color(0xFF1A3340), label: Color(0xFFE9C4A3)),
    (h: 200.0, w: 32.0, bg: Color(0xFFE9C4A3), label: Color(0xFF3A2410)),
    (h: 170.0, w: 26.0, bg: Color(0xFFF5D3D7), label: Color(0xFF5A2030)),
    (h: 210.0, w: 34.0, bg: Color(0xFF2D2418), label: Color(0xFFE9C4A3)),
    (h: 160.0, w: 24.0, bg: Color(0xFF7EC8C0), label: Color(0xFF0A3D62)),
    (h: 190.0, w: 30.0, bg: Color(0xFFC9A87A), label: Color(0xFF3A2410)),
    (h: 175.0, w: 28.0, bg: Color(0xFFFDF6ED), label: Color(0xFF1A1612)),
  ];
  const _SpinesArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: spines.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return Transform.rotate(
            angle: (i.isOdd ? 0.01 : -0.01),
            child: Container(
              width: s.w, height: s.h,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: s.bg, borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 6))],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AvatarsArt extends StatelessWidget {
  final Color accent, accentInk, ink;
  const _AvatarsArt({required this.accent, required this.accentInk, required this.ink});

  @override
  Widget build(BuildContext context) {
    final avatars = [
      (x: 50.0, y: 30.0, name: 'CA', color: const Color(0xFFE9C4A3), size: 64.0),
      (x: 180.0, y: 60.0, name: 'LM', color: const Color(0xFFF5D3D7), size: 56.0),
      (x: 130.0, y: 130.0, name: 'IDS', color: const Color(0xFF7EC8C0), size: 72.0),
      (x: 20.0, y: 140.0, name: 'TB', color: const Color(0xFFC9A87A), size: 50.0),
      (x: 240.0, y: 150.0, name: 'YB', color: const Color(0xFF2C3E50), size: 54.0),
    ];
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: avatars.map((a) => Positioned(
          left: a.x, top: a.y,
          child: CircleAvatar(
            radius: a.size / 2, backgroundColor: a.color,
            child: Text(a.name.substring(0, 1), style: TextStyle(fontFamily: 'CormorantGaramond',
                fontStyle: FontStyle.italic, fontSize: a.size * 0.4, color: Colors.white.withOpacity(0.9))),
          ),
        )).toList(),
      ),
    );
  }
}

class _SwapArt extends StatelessWidget {
  final Color accent, accentInk, ink, inkMuted;
  const _SwapArt({required this.accent, required this.accentInk, required this.ink, required this.inkMuted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 28, backgroundColor: accent,
                child: Text('Toi', style: TextStyle(fontFamily: 'CormorantGaramond',
                    fontStyle: FontStyle.italic, fontSize: 16, color: accentInk))),
            const SizedBox(height: 8),
            Text('Toi', style: AppText.body(size: 11, color: inkMuted)),
          ]),
          const SizedBox(width: 20),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Mini book
            Container(width: 60, height: 90,
                decoration: BoxDecoration(color: const Color(0xFF1A3340), borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))])),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
              child: Row(children: [
                Icon(Icons.swap_horiz_rounded, size: 11, color: accentInk),
                const SizedBox(width: 4),
                Text('En prêt', style: AppText.body(size: 10, color: accentInk)
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ]),
            ),
          ]),
          const SizedBox(width: 20),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 28, backgroundColor: const Color(0xFFE9C4A3),
                child: Text('CA', style: TextStyle(fontFamily: 'CormorantGaramond',
                    fontStyle: FontStyle.italic, fontSize: 18, color: Colors.white.withOpacity(0.8)))),
            const SizedBox(height: 8),
            Text('Camille', style: AppText.body(size: 11, color: inkMuted)),
          ]),
        ],
      ),
    );
  }
}
