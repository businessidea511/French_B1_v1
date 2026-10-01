import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/missions_data.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';

/// The three real-life missions of the week.
class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ProgressService>();
    final missions = missionsOfWeek(DateTime.parse(ProgressService.weekKey()));
    return Scaffold(
      appBar: AppBar(title: const Text('🗺️ Missions de la semaine')),
      body: PageBody(
        children: [
          TranslatedText(
            'Use your French in real life! Three new missions every Monday. Tick them when done: +15 XP each.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          for (final (i, m) in missions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Entrance(index: i, child: MissionCard(mission: m)),
            ),
        ],
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  final Mission mission;
  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final done = progress.missionDone(mission.id);
    return Tilt3D(
      maxTilt: 0.1,
      child: GlassCard(
        glow: done ? AppTheme.success : AppTheme.warning,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(mission.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(mission.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        decoration: done ? TextDecoration.lineThrough : null,
                      )),
                ),
                GestureDetector(
                  onTap: () {
                    final wasDone = done;
                    context.read<ProgressService>().toggleMission(mission.id);
                    if (!wasDone) Confetti.burst(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppTheme.success : Colors.transparent,
                      border: Border.all(color: done ? AppTheme.success : AppTheme.textTertiary, width: 2),
                    ),
                    child: done ? const Icon(Icons.check_rounded, color: Colors.black) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TranslatedText(mission.description, style: TextStyle(color: AppTheme.textSecondary, height: 1.35)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(
                color: AppTheme.fg.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('💬 ${mission.phrase}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 20),
                    onPressed: () => TtsService.instance.speak(mission.phrase),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
