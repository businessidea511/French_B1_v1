import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import 'games/duel_page.dart';
import 'shell/hub_tabs.dart';
import 'shell/me_tab.dart';
import 'shell/onboarding_page.dart';
import 'shell/today_tab.dart';

/// App shell: five tabs (Today, Learn, Practise, Words, Me) behind a floating
/// glass navigation bar. Shows the welcome screens on first start.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  static const _icons = [
    Icons.wb_sunny_rounded,
    Icons.menu_book_rounded,
    Icons.sports_esports_rounded,
    Icons.translate_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ['tab_today', 'tab_learn', 'tab_practice', 'tab_words', 'tab_me'];

  Widget _page(int i) => switch (i) {
        0 => TodayTab(onOpenLanguage: () => showLanguageSheet(context)),
        1 => const LearnTab(),
        2 => const PracticeTab(),
        3 => const WordsTab(),
        _ => const MeTab(),
      };

  static bool _duelLinkOpened = false;

  /// Invitation links (…/?duel=ABC123) open the duel with the code filled in.
  void _openDuelLink() {
    if (_duelLinkOpened) return;
    _duelLinkOpened = true;
    final code = DuelPage.codeFromLink();
    if (code == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => DuelPage(initialCode: code)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    if (!progress.onboarded) return const OnboardingPage();
    _openDuelLink();
    final lp = context.watch<LanguageProvider>();
    final badge = progress.dueCount;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value;
            return Opacity(
              opacity: t,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY((1 - t) * pi / 8)
                  ..scale(0.94 + 0.06 * t),
                child: child,
              ),
            );
          },
        ),
        child: KeyedSubtree(key: ValueKey(_tab), child: _page(_tab)),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.fg.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 12)),
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15), blurRadius: 30),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _icons[i],
                        label: lp.translate(_labels[i]),
                        selected: _tab == i,
                        badge: i == 2 && badge > 0 ? '$badge' : null,
                        onTap: () => setState(() => _tab = i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
                decoration: BoxDecoration(
                  gradient: selected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.6), blurRadius: 16, offset: const Offset(0, 6))]
                      : null,
                ),
                child: AnimatedScale(
                  scale: selected ? 1.15 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(icon, size: 22, color: selected ? AppTheme.onColor : AppTheme.textTertiary),
                ),
              ),
              if (badge != null)
                Positioned(
                  right: -2,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(10)),
                    child: Text(badge!, style: TextStyle(fontSize: 10, color: AppTheme.onColor, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.textPrimary : AppTheme.textTertiary,
              )),
        ],
      ),
    );
  }
}
