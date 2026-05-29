import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import 'friends_screen.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});
  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _ctrl = TextEditingController();
  List<User> _results = [];
  bool _loading = false;
  // userId → état de la demande
  final Map<String, _RequestState> _states = {};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await apiService.searchUsers(q.trim());
      setState(() => _results = r);
    } catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest(String userId) async {
    setState(() => _states[userId] = _RequestState.loading);
    try {
      await apiService.sendFriendRequest(userId);
      setState(() => _states[userId] = _RequestState.sent);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('409') || msg.contains('Déjà')) {
        setState(() => _states[userId] = _RequestState.sent);
      } else {
        setState(() => _states[userId] = _RequestState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeProvider).isDark;
    final bg        = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink       = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft   = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted  = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface   = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border    = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent    = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    // Demandes reçues
    final requestsAsync = ref.watch(pendingRequestsProvider);

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
                Text('Ajouter des amis', style: AppText.body(size: 13, color: inkSoft)
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                const Spacer(),
                const SizedBox(width: 38),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Qui veux-tu ajouter ?', style: AppText.displayMd(italic: true, color: ink)),
                const SizedBox(height: 6),
                Text('Cherche par nom, pseudo ou email.',
                    style: AppText.body(size: 12.5, color: inkMuted).copyWith(height: 1.4)),
              ]),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: surface, borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border, width: 0.5),
                  boxShadow: AppShadows.soft(dark: isDark),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, size: 16, color: inkMuted),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    onChanged: (v) => _search(v),
                    style: AppText.body(size: 13.5, color: ink),
                    decoration: InputDecoration(
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                      hintText: 'Nom, @pseudo, email…',
                      hintStyle: AppText.body(size: 13.5, color: inkMuted),
                    ),
                  )),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () { _ctrl.clear(); setState(() => _results = []); },
                      child: Icon(Icons.close_rounded, size: 16, color: inkMuted),
                    ),
                ]),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: border, height: 1),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isNotEmpty
                      ? _buildResults(accent, accentInk, ink, inkMuted, surface, border, isDark)
                      : _ctrl.text.isEmpty
                          ? _buildPendingRequests(requestsAsync, accent, accentInk, ink, inkMuted, surface, border, isDark)
                          : Center(child: Text('Aucun résultat', style: AppText.body(size: 13, color: inkMuted))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(Color accent, Color accentInk, Color ink, Color inkMuted,
      Color surface, Color border, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final u = _results[i];
        final state = _states[u.id] ?? _RequestState.idle;
        final initials = u.name.split(' ').map((w) => w[0]).take(2).join('');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 0.5),
              boxShadow: AppShadows.soft(dark: isDark),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 20, backgroundColor: accent,
                child: Text(initials, style: TextStyle(fontFamily: 'CormorantGaramond',
                    fontStyle: FontStyle.italic, fontSize: 16, color: accentInk)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.name, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                if (u.handle != null)
                  Text('@${u.handle}', style: AppText.body(size: 11.5, color: inkMuted)),
              ])),
              _RequestButton(state: state, accent: accent, accentInk: accentInk, inkMuted: inkMuted,
                  onTap: state == _RequestState.idle ? () => _sendRequest(u.id) : null),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequests(AsyncValue<List<FriendRequest>> requestsAsync,
      Color accent, Color accentInk, Color ink, Color inkMuted,
      Color surface, Color border, bool isDark) {
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Demandes reçues', style: AppText.eyebrow(color: inkMuted)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: requests.length,
                itemBuilder: (context, i) {
                  final req = requests[i];
                  final initials = req.sender.name.split(' ').map((w) => w[0]).take(2).join('');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 0.5),
                        boxShadow: AppShadows.soft(dark: isDark),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20, backgroundColor: accent,
                          child: Text(initials, style: TextStyle(fontFamily: 'CormorantGaramond',
                              fontStyle: FontStyle.italic, fontSize: 16, color: accentInk)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(req.sender.name, style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                          Text('souhaite vous rejoindre', style: AppText.body(size: 11.5, color: inkMuted)),
                        ])),
                        GestureDetector(
                          onTap: () async {
                            await apiService.declineFriendRequest(req.id);
                            ref.invalidate(pendingRequestsProvider);
                          },
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: border, width: 0.5),
                            ),
                            child: Icon(Icons.close_rounded, size: 16, color: inkMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await apiService.acceptFriendRequest(req.id);
                            ref.invalidate(pendingRequestsProvider);
                            ref.invalidate(friendsListProvider);
                          },
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                            child: Icon(Icons.check_rounded, size: 16, color: accentInk),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _RequestState { idle, loading, sent }

class _RequestButton extends StatelessWidget {
  final _RequestState state;
  final Color accent, accentInk, inkMuted;
  final VoidCallback? onTap;

  const _RequestButton({required this.state, required this.accent,
      required this.accentInk, required this.inkMuted, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (state == _RequestState.loading) {
      return SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: accent));
    }
    if (state == _RequestState.sent) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_rounded, size: 14, color: accent),
        const SizedBox(width: 4),
        Text('Envoyé', style: AppText.body(size: 11, color: accent).copyWith(fontWeight: FontWeight.w600)),
      ]);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
        child: Text('Ajouter', style: AppText.body(size: 12, color: accentInk).copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
