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

final _loginLoadingProvider = StateProvider<bool>((ref) => false);
final _loginErrorProvider   = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: '');
  final _pwCtrl    = TextEditingController(text: '');

  Future<void> _submit() async {
    ref.read(_loginLoadingProvider.notifier).state = true;
    ref.read(_loginErrorProvider.notifier).state = null;
    try {
      await apiService.login(email: _emailCtrl.text, password: _pwCtrl.text);
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
      if (mounted) context.go('/library');
    } catch (e) {
      ref.read(_loginErrorProvider.notifier).state = 'Email ou mot de passe incorrect.';
    } finally {
      ref.read(_loginLoadingProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeProvider).isDark;
    final loading  = ref.watch(_loginLoadingProvider);
    final error    = ref.watch(_loginErrorProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseStrongLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
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
              const SizedBox(height: 32),
              // Header
              Text('Bon retour parmi nous', style: AppText.eyebrow(color: inkMuted).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 10),
              Text('Te revoilà, lectrice.', style: AppText.displayMd(italic: true, color: ink)),
              const SizedBox(height: 8),
              Text("Tes livres t'attendent là où tu les avais laissés.",
                  style: AppText.body(size: 13, color: inkMuted).copyWith(height: 1.5)),
              const SizedBox(height: 32),
              // Fields
              _AuthField(label: 'Adresse e-mail', placeholder: 'elise@mercier.fr',
                  controller: _emailCtrl, isDark: isDark,
                  icon: Icons.bookmark_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _AuthField(label: 'Mot de passe', placeholder: '••••••••',
                  controller: _pwCtrl, isDark: isDark,
                  icon: Icons.lock_outline_rounded, obscure: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Oublié ?', style: AppText.body(size: 12, color: inkSoft).copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error, style: AppText.body(size: 12, color: AppColors.statusOverdue)),
              ],
              const SizedBox(height: 16),
              // Submit
              _ActionButton(
                label: 'Me connecter',
                loading: loading,
                isDark: isDark,
                onTap: _submit,
              ),
              const SizedBox(height: 24),
              // Divider
              Row(children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: AppText.body(size: 11, color: inkMuted).copyWith(letterSpacing: 0.4)),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              ]),
              const SizedBox(height: 16),
              _SocialButton(label: 'Continuer avec Apple', isDark: isDark),
              const SizedBox(height: 8),
              _SocialButton(label: 'Continuer avec Google', isDark: isDark),
              const SizedBox(height: 40),
              // Switch
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Pas encore membre ? ", style: AppText.body(size: 12.5, color: inkMuted)),
                    GestureDetector(
                      onTap: () => context.pushReplacement('/register'),
                      child: Text('Créer un compte',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontStyle: FontStyle.italic,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: ink,
                          decoration: TextDecoration.underline,
                          decorationColor: ink,
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

class _AuthField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isDark;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.isDark,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow(color: inkMuted).copyWith(
          fontSize: 10.5, letterSpacing: 1.2,
        )),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.5),
            boxShadow: AppShadows.soft(dark: isDark),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, size: 16, color: inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  style: AppText.body(size: 14, color: ink),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: placeholder,
                    hintStyle: AppText.body(size: 14, color: inkMuted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.loading, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? AppColors.inkDark : AppColors.inkLight;
    final ink = isDark ? AppColors.bgDark : AppColors.bgLight;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.soft(dark: isDark),
        ),
        child: loading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: ink)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppText.body(size: 15, color: ink).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: ink),
                ],
              ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SocialButton({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final border = isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.16);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(label, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
    );
  }
}
