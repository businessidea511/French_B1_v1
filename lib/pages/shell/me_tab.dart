import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_auth.dart';
import '../../services/global_scroll_manager.dart';
import '../../services/language_provider.dart';
import '../../services/progress_service.dart';
import '../../services/pwa_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../admin/admin_ai_chat_page.dart';
import '../mistakes/mistakes_page.dart';
import 'hub_tabs.dart';

/// Bottom sheet to choose the language of the explanations.
void showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (context) {
      final lp = Provider.of<LanguageProvider>(context);
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Center(
              child: Text(lp.translate('app_language'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),
            for (final lang in AppLanguage.values)
              ListTile(
                title: Text(lang.name, style: TextStyle(color: AppTheme.textPrimary)),
                trailing: lp.currentLanguage == lang ? Icon(Icons.check_circle, color: AppTheme.primary) : null,
                onTap: () {
                  lp.setLanguage(lang);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
}

class MeTab extends StatefulWidget {
  const MeTab({super.key});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  final _scroll = ScrollController();
  bool _canInstall = false;

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scroll);
    PWAService.setupInstallListener(() {
      if (mounted) setState(() => _canInstall = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Theme.of(context).platform == TargetPlatform.iOS && !PWAService.isStandalone()) {
        setState(() => _canInstall = true);
      }
    });
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _install() async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Install on iPhone'),
          content: const Text('1. Tap the "Share" button in Safari.\n2. Choose "Add to Home Screen".\n3. Tap "Add".'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }
    if (await PWAService.installPWA() && mounted) setState(() => _canInstall = false);
  }

  void _openAdmin() {
    if (AdminAuth.isLoggedIn) {
      openPage(context, const AdminAIChatPage());
      return;
    }
    final pass = TextEditingController();
    var obscure = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          Future<void> verify() async {
            final ok = await AdminAuth.login(pass.text);
            if (!mounted || !ctx.mounted) return;
            if (ok) {
              Navigator.pop(ctx);
              openPage(context, const AdminAIChatPage());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Incorrect password'), backgroundColor: Colors.red),
              );
            }
          }

          return AlertDialog(
            title: const Text('🔒 Admin'),
            content: TextField(
              controller: pass,
              obscureText: obscure,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Admin password',
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setDialog(() => obscure = !obscure),
                ),
              ),
              onSubmitted: (_) => verify(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(onPressed: verify, child: const Text('Verify')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final p = context.watch<ProgressService>();
    final level = p.totalXp ~/ 100 + 1;
    final inLevel = (p.totalXp % 100) / 100;
    final week = p.lastWeekXp;
    final today = DateTime.now().weekday;
    const letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return SafeArea(
      bottom: false,
      child: PageBody(
        controller: _scroll,
        children: [
          const SizedBox(height: 12),
          Entrance(
            child: GlassCard(
              glow: AppTheme.accent,
              child: Row(
                children: [
                  Floating(
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                        boxShadow: [BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.5), blurRadius: 24)],
                      ),
                      child: Center(
                        child: Text('$level', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.onColor)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Niveau $level', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: inLevel),
                            duration: const Duration(milliseconds: 1000),
                            builder: (context, v, _) =>
                                LinearProgressIndicator(value: v, minHeight: 10, backgroundColor: AppTheme.fg.withValues(alpha: 0.12)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${p.totalXp % 100} / 100 XP', style: TextStyle(color: AppTheme.textTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(lp.translate('my_progress')),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final (i, (emoji, value, label, color)) in [
                ('🔥', '${p.streak}', lp.translate('streak'), const Color(0xFFF97316)),
                ('⚡', '${p.totalXp}', lp.translate('total_xp'), AppTheme.warning),
                ('🧠', '${p.learnedCount}', lp.translate('words_learned'), AppTheme.success),
                ('📅', '${p.activeDays}', lp.translate('active_days'), AppTheme.primary),
              ].indexed)
                Entrance(
                  index: i,
                  child: Tilt3D(
                    child: GlassCard(
                      glow: color,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$emoji $value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text(label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SectionTitle(lp.translate('this_week')),
          GlassCard(
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${week[i]}', style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: week[i] / (week.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30))),
                            duration: Duration(milliseconds: 600 + i * 120),
                            curve: Curves.easeOutBack,
                            builder: (context, v, _) => Container(
                              width: 22,
                              height: 4 + 90 * v.clamp(0, 1.2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: week[i] >= p.dailyGoal
                                      ? [AppTheme.success, const Color(0xFF14B8A6)]
                                      : [AppTheme.primary, AppTheme.accent],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(letters[(today + i - 7) % 7],
                              style: TextStyle(
                                color: i == 6 ? AppTheme.textPrimary : AppTheme.textTertiary,
                                fontWeight: i == 6 ? FontWeight.bold : FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SectionTitle(lp.translate('daily_goal')),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (xp, label) in [(10, '🌱 Détente'), (30, '🔥 Régulier'), (60, '🚀 Intensif')])
                ChoiceChip(
                  label: Text('$label · $xp XP'),
                  selected: p.dailyGoal == xp,
                  selectedColor: AppTheme.primary,
                  onSelected: (_) => p.setDailyGoal(xp),
                ),
            ],
          ),
          SectionTitle(lp.translate('settings')),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, color: AppTheme.primary),
                const SizedBox(width: 12),
                const Expanded(child: TranslatedText('Appearance')),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_rounded)),
                    ButtonSegment(value: ThemeMode.light, label: Text('☀️'), tooltip: 'Clair'),
                    ButtonSegment(value: ThemeMode.dark, label: Text('🌙'), tooltip: 'Sombre'),
                  ],
                  selected: {context.watch<ThemeController>().mode},
                  onSelectionChanged: (s) => context.read<ThemeController>().setMode(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_rounded, color: AppTheme.primary),
                  title: Text(lp.translate('app_language')),
                  trailing: Text(lp.currentLanguage.name, style: TextStyle(color: AppTheme.textSecondary)),
                  onTap: () => showLanguageSheet(context),
                ),
                ListTile(
                  leading: Icon(Icons.menu_book_rounded, color: AppTheme.error),
                  title: Text(lp.translate('mistakes')),
                  trailing: Text('${p.mistakes.length}', style: TextStyle(color: AppTheme.textSecondary)),
                  onTap: () => openPage(context, const MistakesPage()),
                ),
                if (_canInstall)
                  ListTile(
                    leading: Icon(Icons.install_mobile_rounded, color: AppTheme.success),
                    title: Text(lp.translate('install_app')),
                    onTap: _install,
                  ),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: Colors.redAccent),
                  title: Text(lp.translate('admin_ai')),
                  onTap: _openAdmin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
