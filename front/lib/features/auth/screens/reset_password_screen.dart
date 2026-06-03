import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/api_service.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _pwCtrl   = TextEditingController();
  final _pw2Ctrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  Future<void> _submit() async {
    if (_codeCtrl.text.length != 6) {
      setState(() => _error = 'Le code doit contenir 6 chiffres.');
      return;
    }
    if (_pwCtrl.text.length < 8) {
      setState(() => _error = 'Le mot de passe doit faire au moins 8 caractères.');
      return;
    }
    if (_pwCtrl.text != _pw2Ctrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await apiService.resetPassword(
        email: widget.email,
        code: _codeCtrl.text.trim(),
        password: _pwCtrl.text,
      );
      setState(() => _success = 'Mot de passe mis à jour !');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _error = 'Code invalide ou expiré. Réessaie.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
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
                    shape: BoxShape.circle, color: surface,
                    border: Border.all(color: border, width: 0.5),
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: ink),
                ),
              ),
              const SizedBox(height: 32),
              Text('Nouveau mot de passe', style: AppText.eyebrow(color: inkMuted).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 10),
              Text('Presque fini.', style: AppText.displayMd(italic: true, color: ink)),
              const SizedBox(height: 8),
              Text(
                'Entre le code reçu à ${widget.email} et choisis ton nouveau mot de passe.',
                style: AppText.body(size: 13, color: inkMuted).copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),

              // Code
              _buildLabel('Code à 6 chiffres', inkMuted),
              const SizedBox(height: 6),
              _buildField(
                controller: _codeCtrl,
                hint: '000000',
                icon: Icons.lock_clock_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                ink: ink, inkMuted: inkMuted, surface: surface,
                border: border, isDark: isDark,
              ),
              const SizedBox(height: 14),

              // Nouveau mdp
              _buildLabel('Nouveau mot de passe', inkMuted),
              const SizedBox(height: 6),
              _buildField(
                controller: _pwCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 16, color: inkMuted),
                  ),
                ),
                ink: ink, inkMuted: inkMuted, surface: surface,
                border: border, isDark: isDark,
              ),
              const SizedBox(height: 14),

              // Confirme mdp
              _buildLabel('Confirme le mot de passe', inkMuted),
              const SizedBox(height: 6),
              _buildField(
                controller: _pw2Ctrl,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                ink: ink, inkMuted: inkMuted, surface: surface,
                border: border, isDark: isDark,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppText.body(size: 12, color: AppColors.statusOverdue)),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                Text(_success!, style: AppText.body(size: 12, color: const Color(0xFF4CAF50))),
              ],

              const SizedBox(height: 24),

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
                            Text('Changer mon mot de passe',
                                style: AppText.body(size: 15,
                                    color: isDark ? AppColors.bgDark : AppColors.bgLight)
                                    .copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(Icons.check_rounded, size: 15,
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

  Widget _buildLabel(String text, Color color) =>
      Text(text, style: AppText.eyebrow(color: color).copyWith(fontSize: 10.5, letterSpacing: 1.2));

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color ink,
    required Color inkMuted,
    required Color surface,
    required Color border,
    required bool isDark,
    bool obscure = false,
    TextInputType? keyboardType,
    int? maxLength,
    Widget? suffix,
  }) {
    return Container(
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
              maxLength: maxLength,
              style: AppText.body(size: 14, color: ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                counterText: '',
                hintStyle: AppText.body(size: 14, color: inkMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (suffix != null) suffix else const SizedBox(width: 16),
        ],
      ),
    );
  }
}
