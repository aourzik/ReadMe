import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../library/screens/library_screen.dart';
import '../../loans/screens/loans_screen.dart';
import '../../../core/providers/app_providers.dart';
import '../../profile/screens/profile_screen.dart';
import '../../social/screens/friends_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl    = TextEditingController();
  bool _accept = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_accept) return;
    setState(() { _loading = true; _error = null; });
    try {
      await apiService.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _pwCtrl.text,
      );
      ref.invalidate(meProvider);
      ref.invalidate(booksProvider);
      ref.invalidate(loansProvider);
      ref.invalidate(borrowedLoansProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotifCountProvider);
      ref.invalidate(friendsListProvider);
      ref.invalidate(friendActivityProvider);
      ref.invalidate(bookClubsProvider);
      ref.invalidate(pendingRequestsProvider);
      if (mounted) context.go('/onboarding');
    } catch (e) {
      setState(() { _error = 'Une erreur est survenue. Vérifie tes informations.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeProvider).isDark;
    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final accent   = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: ink),
                ),
              ),
              const SizedBox(height: 24),
              Text('Bienvenue chez ReadMe', style: AppText.eyebrow(color: inkMuted).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 10),
              Text('Ouvrons ta première page.', style: AppText.displayMd(italic: true, color: ink)),
              const SizedBox(height: 8),
              Text('Quelques détails et ta bibliothèque est prête à accueillir ses livres.',
                  style: AppText.body(size: 13, color: inkMuted).copyWith(height: 1.5)),
              const SizedBox(height: 28),
              _Field(label: 'Ton nom', placeholder: 'Élise Mercier',
                  controller: _nameCtrl, isDark: isDark, icon: Icons.person_rounded),
              const SizedBox(height: 14),
              _Field(label: 'E-mail', placeholder: 'elise@mercier.fr',
                  controller: _emailCtrl, isDark: isDark, icon: Icons.bookmark_rounded,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _Field(label: 'Mot de passe', placeholder: '8 caractères minimum',
                  controller: _pwCtrl, isDark: isDark, icon: Icons.lock_outline_rounded,
                  obscure: true, hint: "Choisis quelque chose dont tu te souviendras — comme un titre."),
              const SizedBox(height: 18),
              // CGU checkbox
              GestureDetector(
                onTap: () => setState(() => _accept = !_accept),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: _accept ? accent : Colors.transparent,
                        border: Border.all(
                          color: _accept ? Colors.transparent : (isDark ? Colors.white30 : Colors.black26),
                          width: 1.5,
                        ),
                      ),
                      child: _accept ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "J'accepte les conditions d'utilisation et la politique de confidentialité.",
                        style: AppText.body(size: 11.5, color: inkSoft).copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppText.body(size: 12, color: AppColors.statusOverdue)),
              ],
              const SizedBox(height: 20),
              _SubmitButton(label: 'Créer mon compte', loading: _loading, isDark: isDark, onTap: _submit),
              const SizedBox(height: 40),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà inscrit·e ? ", style: AppText.body(size: 12.5, color: inkMuted)),
                    GestureDetector(
                      onTap: () => context.pushReplacement('/login'),
                      child: Text('Se connecter',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                          fontSize: 13.5, fontWeight: FontWeight.w500, color: ink,
                          decoration: TextDecoration.underline, decorationColor: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isDark;
  final IconData icon;
  final bool obscure;
  final String? hint;
  final TextInputType? keyboardType;
  const _Field({required this.label, required this.placeholder, required this.controller,
      required this.isDark, required this.icon, this.obscure = false, this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow(color: inkMuted).copyWith(fontSize: 10.5, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.5),
            boxShadow: AppShadows.soft(dark: isDark),
          ),
          child: Row(children: [
            const SizedBox(width: 16),
            Icon(icon, size: 16, color: inkMuted),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: controller, obscureText: obscure, keyboardType: keyboardType,
              style: AppText.body(size: 14, color: ink),
              decoration: InputDecoration(
                border: InputBorder.none, hintText: placeholder,
                hintStyle: AppText.body(size: 14, color: inkMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            )),
            const SizedBox(width: 16),
          ]),
        ),
        if (hint != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(hint!, style: AppText.body(size: 10.5, color: inkMuted)),
          ),
        ],
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool isDark;
  final VoidCallback onTap;
  const _SubmitButton({required this.label, required this.loading, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? AppColors.inkDark : AppColors.inkLight;
    final ink = isDark ? AppColors.bgDark : AppColors.bgLight;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadows.soft(dark: isDark)),
        child: loading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: ink)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label, style: AppText.body(size: 15, color: ink).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 15, color: ink),
              ]),
      ),
    );
  }
}
