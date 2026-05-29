import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/message.dart';
import '../../../core/services/api_service.dart';

final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => apiService.getConversations(),
);

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark  = ref.watch(themeProvider).isDark;
    final convosAsync = ref.watch(conversationsProvider);

    final bg       = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink      = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft  = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface  = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
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
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: surface,
                          border: Border.all(color: border, width: 0.5)),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: ink),
                    ),
                  ),
                  const Spacer(),
                  Text('Messages', style: AppText.body(size: 13, color: inkSoft)
                      .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  const Spacer(),
                  const SizedBox(width: 38),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tes conversations', style: AppText.displayMd(italic: true, color: ink)),
                ]),
              ),
            ),
            convosAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (convos) {
                if (convos.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Text('Aucune conversation pour l\'instant.',
                          style: AppText.body(size: 13, color: inkMuted)),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: convos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = convos[i];
                      final initials = c.partnerName.split(' ').map((w) => w[0]).take(2).join('');
                      return GestureDetector(
                        onTap: () => context.push(
                          '/messages/${c.partnerId}',
                          extra: c.partnerName,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: surface, borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 0.5),
                          ),
                          child: Row(children: [
                            Stack(children: [
                              CircleAvatar(radius: 22, backgroundColor: accent,
                                  child: Text(initials, style: TextStyle(
                                      fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic,
                                      fontSize: 16, color: accentInk))),
                              if (c.unread > 0)
                                Positioned(right: 0, top: 0,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                                    child: Center(child: Text('${c.unread}',
                                        style: TextStyle(fontSize: 9, color: accentInk,
                                            fontWeight: FontWeight.w700))),
                                  )),
                            ]),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(c.partnerName, style: AppText.body(size: 14, color: ink)
                                    .copyWith(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(_timeLabel(c.lastAt),
                                    style: AppText.body(size: 11, color: inkMuted)),
                              ]),
                              const SizedBox(height: 2),
                              Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: AppText.body(size: 12.5,
                                      color: c.unread > 0 ? ink : inkMuted)
                                      .copyWith(fontWeight: c.unread > 0
                                          ? FontWeight.w600 : FontWeight.w400)),
                            ])),
                          ]),
                        ),
                      );
                    },
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

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    const months = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
