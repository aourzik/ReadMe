import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/book.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/app_providers.dart';

final meProvider = FutureProvider<User>((ref) => apiService.getMe());

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loadingAvatar = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (image == null) return;
    setState(() => _loadingAvatar = true);
    try {
      final bytes = await image.readAsBytes();
      final avatarUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await apiService.updateProfile({'avatarUrl': avatarUrl});
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loadingAvatar = false);
    }
  }

  void _openEditSheet(BuildContext context, User user, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: user,
        isDark: isDark,
        onSaved: () => ref.invalidate(meProvider),
      ),
    );
  }

  String _avgReadingText(List<Book> books) {
    final readBooks = books
        .where((b) => b.status == ReadStatus.read && b.finishedAt != null)
        .toList()
      ..sort((a, b) => a.finishedAt!.compareTo(b.finishedAt!));
    if (readBooks.length < 2) {
      return readBooks.isEmpty
          ? 'Commence à lire pour voir ta moyenne !'
          : 'Plus qu\'un livre lu pour estimer ta cadence.';
    }
    final totalDays =
        readBooks.last.finishedAt!.difference(readBooks.first.finishedAt!).inDays;
    if (totalDays == 0) return 'Tu lis en moyenne plusieurs livres par semaine !';
    final avgDays = totalDays / (readBooks.length - 1);
    if (avgDays < 7) return 'Tu lis en moyenne plus d\'un livre par semaine. Impressionnant !';
    final weeks = (avgDays / 7).round();
    if (weeks == 1) return 'Tu lis en moyenne 1 livre par semaine. Continue !';
    return 'Tu lis en moyenne 1 livre toutes les $weeks semaines.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = ref.watch(themeProvider).isDark;
    final themeNotif = ref.read(themeProvider.notifier);
    final meAsync    = ref.watch(meProvider);
    final booksAsync = ref.watch(booksProvider);

    final bg         = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink        = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft    = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted   = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface    = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt    = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border     = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent     = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk  = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: meAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erreur profil: $e', textAlign: TextAlign.center)),
        data: (user) {
          final books     = booksAsync.valueOrNull ?? [];
          final goal      = user.readingGoal ?? 24;
          final readCount = user.booksReadThisYear ?? 0;
          final avgText   = _avgReadingText(books);
          final pct       = goal > 0 ? (readCount / goal * 100).round() : 0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),

              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(children: [
                    Text(
                      '@${user.handle ?? user.name.toLowerCase().replaceAll(' ', '.')}',
                      style: AppText.body(size: 13, color: inkSoft).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: themeNotif.toggleTheme,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: surfAlt),
                        child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 18, color: ink),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _openEditSheet(context, user, isDark),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: surfAlt),
                        child: Icon(Icons.edit_outlined, size: 17, color: ink),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Avatar + nom ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(children: [
                        _AvatarWidget(
                          avatarUrl: user.avatarUrl,
                          name: user.name,
                          radius: 43,
                          accent: accent,
                          accentInk: accentInk,
                        ),
                        if (_loadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.45),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: surface,
                              border: Border.all(color: border, width: 0.5),
                            ),
                            child: Icon(Icons.camera_alt_rounded, size: 13, color: ink),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Text(user.name, style: AppText.displayMd(italic: true, color: ink)),
                    const SizedBox(height: 4),
                    Text(
                      'Bibliothèque ouverte aux amis${user.location != null ? ' · ${user.location}' : ''}',
                      style: AppText.body(size: 12.5, color: inkMuted),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _openEditSheet(context, user, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Text('Modifier le profil',
                            style: AppText.body(size: 13, color: ink)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Stats ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface, borderRadius: AppRadius.cardLg,
                      border: Border.all(color: border, width: 0.5),
                      boxShadow: AppShadows.soft(dark: isDark),
                    ),
                    child: Row(children: [
                      _StatCell(label: 'Livres',       value: '${user.bookCount}', ink: ink, inkMuted: inkMuted),
                      Container(width: 0.5, height: 40, color: border),
                      _StatCell(label: 'Lus en ${DateTime.now().year}', value: '$readCount', ink: ink, inkMuted: inkMuted),
                      Container(width: 0.5, height: 40, color: border),
                      _StatCell(label: 'Amis',         value: '${user.friendCount}', ink: ink, inkMuted: inkMuted),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),

              // ── Défi ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text('Défi ${DateTime.now().year}', style: AppText.eyebrow(color: inkMuted)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [
                          accent,
                          isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight,
                        ],
                      ),
                      borderRadius: AppRadius.cardLg,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        RichText(text: TextSpan(
                          style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                              fontSize: 28, fontWeight: FontWeight.w500, color: accentInk, height: 1),
                          children: [
                            TextSpan(text: '$readCount '),
                            TextSpan(text: '/ $goal livres',
                                style: TextStyle(fontSize: 18, color: accentInk.withOpacity(0.6))),
                          ],
                        )),
                        Text('$pct %', style: AppText.eyebrow(color: accentInk.withOpacity(0.7))),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goal > 0 ? (readCount / goal).clamp(0.0, 1.0) : 0,
                          backgroundColor: Colors.black.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(accentInk.withOpacity(0.85)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(avgText,
                          style: AppText.body(size: 11.5, color: accentInk.withOpacity(0.75))),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),

              // ── Genres ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(children: [
                    Text('Genres préférés', style: AppText.eyebrow(color: inkMuted)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openEditSheet(context, user, isDark),
                      child: Text('Modifier',
                          style: AppText.body(size: 11, color: inkMuted)
                              .copyWith(decoration: TextDecoration.underline,
                                        decorationColor: inkMuted)),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: user.favoriteGenres.isEmpty
                      ? Text('Ajoute tes genres préférés via "Modifier le profil".',
                          style: AppText.body(size: 12, color: inkMuted))
                      : Wrap(
                          spacing: 8, runSpacing: 8,
                          children: user.favoriteGenres.map((g) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.black12, width: 0.5),
                            ),
                            child: Text(g,
                                style: AppText.body(size: 12, color: inkSoft)
                                    .copyWith(fontWeight: FontWeight.w500)),
                          )).toList(),
                        ),
                ),
              ),

              // ── Logout ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: GestureDetector(
                    onTap: () async {
                      await apiService.logout();
                      if (context.mounted) context.go('/welcome');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.logout_rounded, size: 15, color: inkMuted),
                        const SizedBox(width: 8),
                        Text('Se déconnecter',
                            style: AppText.body(size: 13, color: inkMuted)
                                .copyWith(fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final Color accent, accentInk;

  const _AvatarWidget({
    required this.avatarUrl,
    required this.name,
    required this.radius,
    required this.accent,
    required this.accentInk,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.startsWith('data:')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(avatarUrl!.split(',').last)),
      );
    } else if (avatarUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: accent,
      child: Text(
        name.split(' ').map((w) => w[0]).take(2).join(''),
        style: TextStyle(
          fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500, fontSize: radius * 0.84, color: accentInk,
        ),
      ),
    );
  }
}

// ── Edit profile bottom sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final User user;
  final bool isDark;
  final VoidCallback onSaved;

  const _EditProfileSheet({required this.user, required this.isDark, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _handleCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _genreCtrl;
  late int _goal;
  late List<String> _genres;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.user.name);
    _handleCtrl   = TextEditingController(text: widget.user.handle ?? '');
    _locationCtrl = TextEditingController(text: widget.user.location ?? '');
    _genreCtrl    = TextEditingController();
    _goal         = widget.user.readingGoal ?? 24;
    _genres       = List.from(widget.user.favoriteGenres);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    _locationCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'name':           _nameCtrl.text.trim(),
        'readingGoal':    _goal,
        'favoriteGenres': _genres,
      };
      if (_handleCtrl.text.trim().isNotEmpty) data['handle'] = _handleCtrl.text.trim();
      if (_locationCtrl.text.trim().isNotEmpty) data['location'] = _locationCtrl.text.trim();

      await apiService.updateProfile(data);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addGenre() {
    final g = _genreCtrl.text.trim();
    if (g.isEmpty || _genres.contains(g)) return;
    setState(() {
      _genres.add(g);
      _genreCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = widget.isDark;
    final bg        = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink       = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surfAlt   = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border    = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 16, 20,
            24 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Handle
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text('Modifier le profil', style: AppText.displayMd(italic: true, color: ink)),
            const SizedBox(height: 24),

            // Fields
            _SheetField(label: 'Nom',   ctrl: _nameCtrl,     isDark: isDark),
            const SizedBox(height: 14),
            _SheetField(label: 'Pseudo', ctrl: _handleCtrl,  isDark: isDark, prefix: '@'),
            const SizedBox(height: 14),
            _SheetField(label: 'Ville', ctrl: _locationCtrl, isDark: isDark),
            const SizedBox(height: 22),

            // Objectif
            Row(children: [
              Text('Objectif ${DateTime.now().year}', style: AppText.eyebrow(color: inkMuted)),
              const Spacer(),
              Row(children: [
                GestureDetector(
                  onTap: () { if (_goal > 1) setState(() => _goal--); },
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: surfAlt, borderRadius: BorderRadius.circular(999)),
                    child: Icon(Icons.remove_rounded, size: 14, color: ink),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_goal', textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                          fontSize: 22, fontWeight: FontWeight.w500, color: ink)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _goal++),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: surfAlt, borderRadius: BorderRadius.circular(999)),
                    child: Icon(Icons.add_rounded, size: 14, color: ink),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 26),

            // Genres
            Text('Genres préférés', style: AppText.eyebrow(color: inkMuted)),
            const SizedBox(height: 12),
            if (_genres.isNotEmpty) ...[
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _genres.map((g) => GestureDetector(
                  onTap: () => setState(() => _genres.remove(g)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: accent.withOpacity(0.15),
                      border: Border.all(color: accent.withOpacity(0.3), width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(g, style: AppText.body(size: 12, color: ink)
                          .copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Icon(Icons.close_rounded, size: 12, color: inkMuted),
                    ]),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(child: Container(
                decoration: BoxDecoration(
                  color: surfAlt, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: _genreCtrl,
                    style: AppText.body(size: 13, color: ink),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Roman, SF, Policier…',
                      hintStyle: AppText.body(size: 13, color: inkMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onSubmitted: (_) => _addGenre(),
                  )),
                  const SizedBox(width: 8),
                ]),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addGenre,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                  child: Icon(Icons.add_rounded, size: 18, color: accentInk),
                ),
              ),
            ]),
            const SizedBox(height: 30),

            // Save
            GestureDetector(
              onTap: _loading ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.inkDark : AppColors.inkLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: _loading
                    ? Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: isDark ? AppColors.bgDark : AppColors.bgLight)))
                    : Text('Sauvegarder', textAlign: TextAlign.center,
                        style: AppText.body(size: 15,
                            color: isDark ? AppColors.bgDark : AppColors.bgLight)
                            .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
    );
  }
}

// ── Sheet text field ──────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool isDark;
  final String? prefix;

  const _SheetField({required this.label, required this.ctrl, required this.isDark, this.prefix});

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppText.eyebrow(color: inkMuted).copyWith(fontSize: 10.5, letterSpacing: 1.2)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(children: [
          const SizedBox(width: 16),
          if (prefix != null)
            Text(prefix!, style: AppText.body(size: 14, color: inkMuted)),
          Expanded(child: TextField(
            controller: ctrl,
            style: AppText.body(size: 14, color: ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          )),
          const SizedBox(width: 16),
        ]),
      ),
    ]);
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label, value;
  final Color ink, inkMuted;
  const _StatCell({required this.label, required this.value, required this.ink, required this.inkMuted});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500, fontSize: 28, color: ink, height: 1)),
      const SizedBox(height: 5),
      Text(label, style: AppText.eyebrow(color: inkMuted).copyWith(fontSize: 10, letterSpacing: 1)),
    ]),
  );
}
