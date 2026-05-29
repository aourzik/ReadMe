import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/notification.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../loans/screens/loans_screen.dart';
import '../../library/screens/library_screen.dart';


class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Marquer tout comme lu à l'ouverture
    apiService.markAllNotifsRead().then((_) {
      ref.invalidate(unreadNotifCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeProvider).isDark;
    final notifsAsync = ref.watch(notificationsProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt  = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border   = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent   = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentInk= isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                            border: Border.all(color: border, width: 0.5)),
                        child: Icon(Icons.chevron_left_rounded, size: 22, color: ink)),
                  ),
                  const Spacer(),
                  Text('Notifications', style: AppText.body(size: 13, color: inkSoft)
                      .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  const Spacer(),
                  const SizedBox(width: 38),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: Text('Activité récente', style: AppText.displayMd(italic: true, color: ink)),
              ),
            ),
            notifsAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, __) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Text('Erreur : $e', style: AppText.body(size: 13, color: inkMuted)),
                ),
              ),
              data: (notifs) {
                if (notifs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Text('Aucune notification pour l\'instant.',
                          style: AppText.body(size: 13, color: inkMuted)),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _NotifCard(
                      notif: notifs[i],
                      isDark: isDark,
                      ink: ink, inkMuted: inkMuted, surface: surface,
                      surfAlt: surfAlt, border: border, accent: accent, accentInk: accentInk,
                      onAction: (String msg) {
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(loansProvider);
                        ref.invalidate(borrowedLoansProvider);
                        ref.invalidate(booksProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatefulWidget {
  final AppNotification notif;
  final bool isDark;
  final Color ink, inkMuted, surface, surfAlt, border, accent, accentInk;
  final void Function(String msg) onAction;

  const _NotifCard({
    required this.notif, required this.isDark,
    required this.ink, required this.inkMuted, required this.surface,
    required this.surfAlt, required this.border, required this.accent,
    required this.accentInk, required this.onAction,
  });

  @override
  State<_NotifCard> createState() => _NotifCardState();
}

class _NotifCardState extends State<_NotifCard> {
  bool _acting = false;
  int _selectedDays = 21;

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final isLoanRequest = n.type == 'loan_request';
    final isMessage = n.type == 'message_received';

    return GestureDetector(
      onTap: isMessage ? () => context.push('/messages/${n.fromUserId}', extra: n.fromUserName) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: !n.read ? widget.accent.withOpacity(0.4) : widget.border,
            width: !n.read ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: widget.accent.withOpacity(0.15)),
                child: Icon(_iconFor(n.type), size: 16, color: widget.accent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title, style: AppText.body(size: 13.5, color: widget.ink)
                    .copyWith(fontWeight: FontWeight.w600)),
                if (n.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.subtitle, style: AppText.body(size: 12, color: widget.inkMuted)),
                ],
                const SizedBox(height: 2),
                Text(_timeAgo(n.createdAt), style: AppText.body(size: 11, color: widget.inkMuted)),
              ])),
              if (isMessage)
                Icon(Icons.chevron_right_rounded, size: 16, color: widget.inkMuted),
            ]),

            // Actions pour demande de prêt
            if (isLoanRequest && n.loanId != null) ...[
              const SizedBox(height: 12),
              // Sélecteur durée
              Row(children: [
                Text('Durée :', style: AppText.body(size: 12, color: widget.inkMuted)),
                const SizedBox(width: 8),
                ...[{7: '1 sem.'}, {14: '2 sem.'}, {21: '3 sem.'}, {30: '1 mois'}, {0: '∞'}]
                    .expand((m) => m.entries)
                    .map((e) {
                  final active = _selectedDays == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDays = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? widget.accent : widget.surfAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? Colors.transparent : widget.border, width: 0.5),
                      ),
                      child: Text(e.value, style: AppText.body(size: 11,
                          color: active ? widget.accentInk : widget.inkMuted)
                          .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _acting ? null : () => _accept(n.loanId!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                          color: widget.accent, borderRadius: BorderRadius.circular(999)),
                      child: _acting
                          ? Center(child: SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: widget.accentInk)))
                          : Text('Accepter', textAlign: TextAlign.center,
                              style: AppText.body(size: 13, color: widget.accentInk)
                                  .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _acting ? null : () => _decline(n.loanId!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: widget.surfAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: widget.border, width: 0.5),
                      ),
                      child: Text('Refuser', textAlign: TextAlign.center,
                          style: AppText.body(size: 13, color: widget.inkMuted)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept(String loanId) async {
    setState(() => _acting = true);
    try {
      await apiService.acceptLoan(loanId, dueDays: _selectedDays > 0 ? _selectedDays : null);
      final title = widget.notif.bookTitle ?? 'le livre';
      final borrower = widget.notif.fromUserName.split(' ').first;
      widget.onAction('Prêt accepté — « $title » prêté à $borrower.');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline(String loanId) async {
    setState(() => _acting = true);
    try {
      await apiService.declineLoan(loanId);
      widget.onAction('Demande refusée.');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'loan_request':     return Icons.swap_horiz_rounded;
      case 'loan_accepted':    return Icons.check_circle_outline_rounded;
      case 'loan_declined':    return Icons.cancel_outlined;
      case 'message_received': return Icons.chat_bubble_outline_rounded;
      default:                 return Icons.notifications_none_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
