import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/models/loan.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/book_cover.dart';

final loansProvider = FutureProvider<List<Loan>>((ref) => apiService.getLoans());

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  bool _showOut = true;

  @override
  Widget build(BuildContext context) {
    final isDark      = ref.watch(themeProvider).isDark;
    final loansAsync  = ref.watch(loansProvider);

    final bg         = isDark ? AppColors.bgDark : AppColors.bgLight;
    final ink        = isDark ? AppColors.inkDark : AppColors.inkLight;
    final inkSoft    = isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
    final inkMuted   = isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
    final surface    = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfAlt    = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAltLight;
    final border     = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final accent     = isDark ? AppColors.accentRoseDark : AppColors.accentRoseLight;
    final accentStrong = isDark ? AppColors.accentRoseStrongDark : AppColors.accentRoseStrongLight;
    final accentSubtle = isDark ? AppColors.accentRoseSubtleDark : AppColors.accentRoseSubtleLight;
    final accentInk  = isDark ? AppColors.accentRoseInkDark : AppColors.accentRoseInkLight;

    return Scaffold(
      backgroundColor: bg,
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (loans) {
          final loansOut = loans.where((l) => l.direction == LoanDirection.out).toList();
          final loansIn  = loans.where((l) => l.direction == LoanDirection.in_).toList();
          final displayed = _showOut ? loansOut : loansIn;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),

              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Carnet', style: AppText.body(size: 13, color: inkSoft).copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        SizedBox(width: 38, height: 38, child: Icon(Icons.filter_list_rounded, size: 18, color: ink)),
                      ]),
                      const SizedBox(height: 8),
                      Text('${loansOut.length} prêtés · ${loansIn.length} empruntés',
                          style: AppText.eyebrow(color: inkMuted)),
                      const SizedBox(height: 4),
                      Text('Mes prêts', style: AppText.display(size: 34, italic: true, color: ink)),
                    ],
                  ),
                ),
              ),

              // Toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: surfAlt, borderRadius: BorderRadius.circular(999)),
                    child: Row(children: [
                      _ToggleBtn(
                        label: "Que j'ai prêté",
                        count: loansOut.length,
                        active: _showOut,
                        isDark: isDark,
                        ink: ink, inkMuted: inkMuted, surface: surface, accent: accent, accentInk: accentInk,
                        onTap: () => setState(() => _showOut = true),
                      ),
                      _ToggleBtn(
                        label: "Que j'ai emprunté",
                        count: loansIn.length,
                        active: !_showOut,
                        isDark: isDark,
                        ink: ink, inkMuted: inkMuted, surface: surface, accent: accent, accentInk: accentInk,
                        onTap: () => setState(() => _showOut = false),
                      ),
                    ]),
                  ),
                ),
              ),

              // Loans
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: displayed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final loan = displayed[i];
                    return _LoanCard(
                      loan: loan,
                      isOut: _showOut,
                      isDark: isDark,
                      ink: ink, inkSoft: inkSoft, inkMuted: inkMuted,
                      surface: surface, border: border, surfAlt: surfAlt,
                      accent: accent, accentStrong: accentStrong, accentInk: accentInk,
                    );
                  },
                ),
              ),

              // Hint card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: accentSubtle, borderRadius: AppRadius.cardLg),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                        child: Icon(Icons.menu_book_rounded, size: 22, color: accentInk),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Bons retours.', style: TextStyle(fontFamily: 'CormorantGaramond',
                            fontStyle: FontStyle.italic, fontSize: 15, color: isDark ? ink : accentInk,
                            fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(loans.isEmpty
                            ? 'Aucun prêt en cours — ta bibliothèque est bien rangée.'
                            : '${loans.length} prêt${loans.length > 1 ? 's' : ''} en cours — pense à relancer !',
                            style: AppText.body(size: 11.5, color: isDark ? inkSoft : accentInk).copyWith(height: 1.4)),
                      ])),
                    ]),
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

class _ToggleBtn extends StatelessWidget {
  final String label;
  final int count;
  final bool active, isDark;
  final Color ink, inkMuted, surface, accent, accentInk;
  final VoidCallback onTap;

  const _ToggleBtn({required this.label, required this.count, required this.active,
      required this.isDark, required this.ink, required this.inkMuted, required this.surface,
      required this.accent, required this.accentInk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? AppShadows.soft(dark: isDark) : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: AppText.body(size: 12, color: active ? ink : inkMuted)
                .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count', style: AppText.body(size: 10,
                  color: active ? accentInk : inkMuted)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final bool isOut, isDark;
  final Color ink, inkSoft, inkMuted, surface, border, surfAlt, accent, accentStrong, accentInk;

  const _LoanCard({required this.loan, required this.isOut, required this.isDark,
      required this.ink, required this.inkSoft, required this.inkMuted,
      required this.surface, required this.border, required this.surfAlt,
      required this.accent, required this.accentStrong, required this.accentInk});

  @override
  Widget build(BuildContext context) {
    final remaining = loan.daysRemaining;
    final overdue = loan.isOverdue;
    final urgent = loan.isUrgent;

    final statusColor = overdue ? AppColors.statusOverdue
        : urgent ? accentStrong
        : inkMuted;

    String statusText;
    if (overdue) {
      statusText = 'En retard';
    } else if (remaining != null) {
      statusText = 'Encore $remaining jours';
    } else {
      statusText = 'Sans limite';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface, borderRadius: AppRadius.cardLg,
        border: Border.all(color: border, width: 0.5),
        boxShadow: AppShadows.soft(dark: isDark),
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookCover(book: loan.book, width: 70, height: 105, isDark: isDark),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(statusText, style: AppText.eyebrow(color: statusColor)),
            const SizedBox(height: 4),
            Text(loan.book.title, style: TextStyle(fontFamily: 'CormorantGaramond',
                fontStyle: FontStyle.italic, fontWeight: FontWeight.w500,
                fontSize: 18, color: ink, height: 1.1, letterSpacing: -0.15)),
            const SizedBox(height: 2),
            Text(loan.book.author, style: AppText.body(size: 11.5, color: inkMuted)),
            const SizedBox(height: 10),
            Row(children: [
              CircleAvatar(radius: 11, backgroundColor: accent,
                  child: Text(loan.partner.name.split(' ').map((w) => w[0]).take(2).join(''),
                      style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 9,
                          fontStyle: FontStyle.italic, color: accentInk))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${isOut ? 'Chez' : 'Emprunté à'} ${loan.partner.name.split(' ').first}',
                    style: AppText.body(size: 11.5, color: inkSoft).copyWith(fontWeight: FontWeight.w600)),
                Text('Depuis le ${_formatDate(loan.since)}',
                    style: AppText.body(size: 10, color: inkMuted)),
              ])),
            ]),
          ])),
        ]),
        const SizedBox(height: 14),
        // Progress bar + action
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loan.progressRatio,
              backgroundColor: surfAlt,
              valueColor: AlwaysStoppedAnimation<Color>(urgent ? accentStrong : ink),
              minHeight: 4,
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
              child: Text(isOut ? 'Relancer' : 'Rendre',
                  style: AppText.body(size: 11, color: accentInk).copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['jan.','fév.','mars','avr.','mai','juin','juil.','août','sep.','oct.','nov.','déc.'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
