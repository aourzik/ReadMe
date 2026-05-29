import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/message.dart';
import '../../../core/services/api_service.dart';

final _chatProvider = FutureProvider.family<List<ChatMessage>, String>(
  (ref, partnerId) => apiService.getMessages(partnerId),
);

class ChatScreen extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  const ChatScreen({super.key, required this.partnerId, required this.partnerName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await apiService.sendMessage(widget.partnerId, text);
      ref.invalidate(_chatProvider(widget.partnerId));
      // Scroll to bottom after rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeProvider).isDark;
    final chatAsync = ref.watch(_chatProvider(widget.partnerId));

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
                    child: Icon(Icons.chevron_left_rounded, size: 22, color: ink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.partnerName,
                        style: AppText.body(size: 14, color: ink).copyWith(fontWeight: FontWeight.w600)),
                    Text('En ligne', style: AppText.body(size: 11, color: inkMuted)),
                  ]),
                ),
              ]),
            ),

            const Divider(height: 1),

            // Messages
            Expanded(
              child: chatAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text('Commence la conversation !',
                          style: AppText.body(size: 13, color: inkMuted)),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMe = msg.fromMe;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(radius: 14, backgroundColor: accent,
                                  child: Text(
                                    widget.partnerName.split(' ').map((w) => w[0]).take(2).join(''),
                                    style: TextStyle(fontFamily: 'CormorantGaramond',
                                        fontSize: 10, fontStyle: FontStyle.italic, color: accentInk),
                                  )),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? accent : surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                  border: isMe ? null : Border.all(color: border, width: 0.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(msg.content,
                                        style: AppText.body(size: 14,
                                            color: isMe ? accentInk : ink)),
                                    const SizedBox(height: 3),
                                    Text(_timeLabel(msg.createdAt),
                                        style: AppText.body(size: 10,
                                            color: isMe ? accentInk.withOpacity(0.7) : inkMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: border, width: 0.5)),
              ),
              child: Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: surfAlt, borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: border, width: 0.5),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: AppText.body(size: 14, color: ink),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                        hintText: 'Message…',
                        hintStyle: AppText.body(size: 14, color: inkMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42, height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                    child: _sending
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(strokeWidth: 2, color: accentInk),
                          )
                        : Icon(Icons.send_rounded, size: 18, color: accentInk),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    const months = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
