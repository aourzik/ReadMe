import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import 'friends_screen.dart';

class CreateBookClubScreen extends ConsumerStatefulWidget {
  const CreateBookClubScreen({super.key});
  @override
  ConsumerState<CreateBookClubScreen> createState() => _CreateBookClubScreenState();
}

class _CreateBookClubScreenState extends ConsumerState<CreateBookClubScreen> {
  final _nameCtrl  = TextEditingController();
  final _themeCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _themeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final club = await apiService.createBookClub(
        name: _nameCtrl.text.trim(),
        theme: _themeCtrl.text.trim().isEmpty ? null : _themeCtrl.text.trim(),
        memberIds: _selectedIds.toList(),
      );
      if (mounted) {
        ref.invalidate(bookClubsProvider);
        context.pushReplacement('/friends/bookclub/${club.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeProvider).isDark;
    final friendsAsync = ref.watch(friendsListProvider);

    final bg        = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink       = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft   = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface   = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt   = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border    = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    final canCreate = _nameCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                        border: Border.all(color: border, width: 0.5)),
                    child: Icon(Icons.close_rounded, size: 18, color: ink),
                  ),
                ),
                const Spacer(),
                Text('Nouveau book club', style: AppText.body(size: 13, color: inkSoft)
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                const Spacer(),
                const SizedBox(width: 38),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Crée ton cercle de lecture', style: AppText.displayMd(italic: true, color: ink)),
                  const SizedBox(height: 6),
                  Text('Donne un nom, un thème, puis invite tes amis.',
                      style: AppText.body(size: 12.5, color: inkMuted).copyWith(height: 1.4)),
                  const SizedBox(height: 28),

                  // Nom
                  Text('Nom du club', style: AppText.eyebrow(color: inkMuted)),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: _nameCtrl,
                    hint: 'Ex : Lectures d\'été',
                    isDark: isDark, surface: surface, border: border, ink: ink, inkMuted: inkMuted,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Thème
                  Text('Thème de lecture', style: AppText.eyebrow(color: inkMuted)),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: _themeCtrl,
                    hint: 'Optionnel — Ex : Littérature japonaise',
                    isDark: isDark, surface: surface, border: border, ink: ink, inkMuted: inkMuted,
                  ),
                  const SizedBox(height: 28),

                  // Amis
                  Text('Inviter des amis', style: AppText.eyebrow(color: inkMuted)),
                  const SizedBox(height: 12),
                  friendsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (friends) => friends.isEmpty
                        ? Text('Tu n\'as pas encore d\'amis à inviter.',
                            style: AppText.body(size: 13, color: inkMuted))
                        : Wrap(
                            spacing: 8, runSpacing: 8,
                            children: friends.map((f) {
                              final isSelected = _selectedIds.contains(f.id);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  isSelected ? _selectedIds.remove(f.id) : _selectedIds.add(f.id);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? accent : surfAlt,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : border,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (isSelected) ...[
                                      Icon(Icons.check_rounded, size: 12, color: accentInk),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(f.name.split(' ').first,
                                        style: AppText.body(size: 13, color: isSelected ? accentInk : ink)
                                            .copyWith(fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  if (_selectedIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: accentSubtle, borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        '${_selectedIds.length} ami${_selectedIds.length > 1 ? 's' : ''} sélectionné${_selectedIds.length > 1 ? 's' : ''}',
                        style: AppText.body(size: 12, color: ink).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ]),
              ),
            ),

            // CTA
            Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              child: GestureDetector(
                onTap: (canCreate && !_saving) ? _create : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: canCreate ? accent : surfAlt,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: canCreate ? AppShadows.soft(dark: isDark) : null,
                  ),
                  child: _saving
                      ? Center(child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: accentInk)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.menu_book_rounded, size: 16, color: canCreate ? accentInk : inkMuted),
                          const SizedBox(width: 8),
                          Text('Créer le book club',
                              style: AppText.body(size: 15, color: canCreate ? accentInk : inkMuted)
                                  .copyWith(fontWeight: FontWeight.w600)),
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Color surface, border, ink, inkMuted;
  final void Function(String)? onChanged;

  const _InputField({
    required this.controller, required this.hint, required this.isDark,
    required this.surface, required this.border, required this.ink, required this.inkMuted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppText.body(size: 14, color: ink),
        decoration: InputDecoration(
          border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
          hintText: hint, hintStyle: AppText.body(size: 14, color: inkMuted),
        ),
      ),
    );
  }
}
