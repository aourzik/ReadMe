import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });

    try {
      await apiService.forgotPassword(email: _emailCtrl.text.trim());
      if (mounted) {
        context.push('/reset-password', extra: _emailCtrl.text.trim());
      }
    } catch (e) {
      setState(() => _error = "Une erreur est survenue. Réessaie.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeProvider).isDark;
    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

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
                    color: surface,
                    border: Border.all(color: border, width: 0.5),
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: ink),
                ),
              ),
              const SizedBox(height: 32),
              Text('Mot de passe oublié', style: AppText.eyebrow(color: inkMuted).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 10),
              Text('On t\'envoie un code.', style: AppText.displayMd(italic: true, color: ink)),
              const SizedBox(height: 8),
              Text(
                'Entre ton adresse e-mail et tu recevras un code à 6 chiffres valable 15 minutes.',
                style: AppText.body(size: 13, color: inkMuted).copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),

              // Email field
              Text('Adresse e-mail', style: AppText.eyebrow(color: inkMuted).copyWith(fontSize: 10.5, letterSpacing: 1.2)),
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
                    Icon(Icons.mail_outline_rounded, size: 16, color: inkMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: AppText.body(size: 14, color: ink),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'elise@mercier.fr',
                          hintStyle: AppText.body(size: 14, color: inkMuted),
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: AppText.body(size: 12, color: AppColors.statusOverdue)),
              ],

              const SizedBox(height: 24),

              // Bouton
              GestureDetector(
                onTap: _loading ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.inkDark : AppColors.inkLight,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: AppShadows.soft(dark: isDark),
                  ),
                  child: _loading
                      ? Center(child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: isDark ? AppColors.bgDark : AppColors.bgLight)))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Envoyer le code',
                                style: AppText.body(size: 15,
                                    color: isDark ? AppColors.bgDark : AppColors.bgLight)
                                    .copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(Icons.send_rounded, size: 15,
                                color: isDark ? AppColors.bgDark : AppColors.bgLight),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
