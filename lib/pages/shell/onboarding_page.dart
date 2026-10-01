import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_provider.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/ui_kit.dart';
import '../../services/ui_strings.dart';

/// First start: welcome, language of the explanations, daily goal.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _step = 0;

  void _go(int step) {
    setState(() => _step = step);
    _pages.animateToPage(step, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: i == _step ? AppTheme.primaryGradient : null,
                      color: i == _step ? null : AppTheme.fg.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [_welcome(), _language(), _goal()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centered(List<Widget> children) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      );

  Widget _welcome() => _centered([
        Center(
          child: Floating(
            distance: 10,
            child: Image.asset('assets/logo.png', width: 132, height: 132),
          ),
        ),
        const SizedBox(height: 24),
        Entrance(
          child: Text('Bienvenue sur PolyLearn !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ),
        const SizedBox(height: 10),
        Entrance(
          index: 2,
          child: Text('Learn French for real life in Belgium — B1 level.\nApprends le français de la vraie vie.',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, height: 1.5)),
        ),
        const SizedBox(height: 40),
        Entrance(index: 4, child: GlowButton(label: tr(context, 'Start'), icon: Icons.arrow_forward_rounded, onPressed: () => _go(1))),
      ]);

  Widget _language() {
    final lp = context.watch<LanguageProvider>();
    return _centered([
      const Text('🌐', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
      const SizedBox(height: 12),
      Text('In which language do you want the explanations?',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      Text('French stays French — only the explanations change.',
          textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary)),
      const SizedBox(height: 20),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final (i, lang) in AppLanguage.values.indexed)
            SizedBox(
              width: 160,
              height: 64,
              child: Entrance(
                index: i,
                child: Tilt3D(
                  onTap: () {
                    lp.setLanguage(lang);
                    Future.delayed(const Duration(milliseconds: 250), () => _go(2));
                  },
                  child: GlassCard(
                    glow: lp.currentLanguage == lang ? AppTheme.primary : null,
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(lang.name,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ]);
  }

  Widget _goal() {
    final goals = [(10, '🌱', tr(context, 'Relaxed'), '5 min'), (30, '🔥', tr(context, 'Regular'), '15 min'), (60, '🚀', tr(context, 'Intensive'), '30 min')];
    return _centered([
      const Text('🎯', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
      const SizedBox(height: 12),
      Text(tr(context, 'Your daily goal?'),
          textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      const SizedBox(height: 20),
      for (final (i, (xp, emoji, label, time)) in goals.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Entrance(
            index: i,
            child: Tilt3D(
              onTap: () {
                final progress = context.read<ProgressService>();
                progress.setDailyGoal(xp);
                Confetti.burst(context);
                progress.completeOnboarding();
              },
              child: GlassCard(
                glow: [AppTheme.success, AppTheme.warning, AppTheme.secondary][i],
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(label, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ),
                    Text('$xp XP · $time', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
