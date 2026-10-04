import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/story_characters.dart';
import '../../services/life_story_service.dart';
import '../../services/ui_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import 'life_chat_page.dart';

/// "Ma vie en Belgique" on the Today tab: today's messages from the
/// learner's characters, like a chat inbox. The first thing to do each day.
class LifeInbox extends StatefulWidget {
  const LifeInbox({super.key});

  @override
  State<LifeInbox> createState() => _LifeInboxState();
}

class _LifeInboxState extends State<LifeInbox> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => LifeStoryService.instance.ensureToday());
  }

  @override
  Widget build(BuildContext context) {
    final story = context.watch<LifeStoryService>();
    if (!story.setUp) return _StartCard();

    final scenes = story.planDay == story.today ? story.scenes : const <LifeScene>[];
    final cast = [for (final id in story.characters) characterById(id)].whereType<StoryCharacter>().toList()
      // Characters with something to do today first.
      ..sort((a, b) {
        int rank(StoryCharacter c) {
          final s = story.sceneFor(c.id);
          return s == null ? 2 : (s.done ? 1 : 0);
        }

        return rank(a).compareTo(rank(b));
      });

    return GlassCard(
      glow: story.unreadTotal > 0 ? AppTheme.primary : null,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🏡 ', style: TextStyle(fontSize: 20)),
              Expanded(
                child: Text('Ma vie en Belgique',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
              ),
              if (scenes.isNotEmpty)
                Text('${story.scenesDone} / ${scenes.length} ✓',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          if (story.planning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr(context, 'Your characters are writing to you…'),
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            )
          else if (story.planError != null && scenes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: TranslatedText(story.planError!, style: TextStyle(color: AppTheme.error, fontSize: 13))),
                  TextButton(onPressed: story.ensureToday, child: Text(tr(context, 'Try again'))),
                ],
              ),
            ),
          for (final (i, c) in cast.indexed)
            Entrance(key: ValueKey(c.id), index: i, child: _InboxRow(character: c, story: story)),
        ],
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  final StoryCharacter character;
  final LifeStoryService story;
  const _InboxRow({required this.character, required this.story});

  @override
  Widget build(BuildContext context) {
    final messages = story.thread(character.id);
    final last = messages.isEmpty ? null : messages.last;
    final unread = story.unread[character.id] ?? 0;
    final scene = story.sceneFor(character.id);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LifeChatPage(characterId: character.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CharacterAvatar(character),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(character.name,
                            textDirection: TextDirection.ltr,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      ),
                      if (scene != null) ...[
                        const SizedBox(width: 6),
                        Text(scene.done ? '✅' : '🎯', style: const TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                  last == null
                      ? TranslatedText(character.role, style: TextStyle(color: AppTheme.textTertiary, fontSize: 13))
                      : Text(
                          '${last.fromAi ? '' : '${tr(context, 'You')}: '}${last.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: unread > 0 ? AppTheme.textPrimary : AppTheme.textTertiary,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Text('$unread', style: TextStyle(color: AppTheme.onColor, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tilt3D(
      maxTilt: 0.06,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LifeSetupPage())),
      child: GlassCard(
        glow: AppTheme.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final c in storyCharacters.take(5))
                  Padding(padding: const EdgeInsetsDirectional.only(end: 4), child: CharacterAvatar(c, size: 34)),
              ],
            ),
            const SizedBox(height: 12),
            Text('🏡 Ma vie en Belgique',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TranslatedText(
              'Live your life in Belgium in French: your neighbour, colleague, classmate, landlord and a Belgian friend write to you every day. Answer them to move the story forward.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            GlowButton(
              label: tr(context, 'Start my story'),
              icon: Icons.auto_stories_rounded,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LifeSetupPage())),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choose characters, daily time and tell a little about yourself.
class LifeSetupPage extends StatefulWidget {
  const LifeSetupPage({super.key});

  @override
  State<LifeSetupPage> createState() => _LifeSetupPageState();
}

class _LifeSetupPageState extends State<LifeSetupPage> {
  static const cities = ['Bruxelles', 'Liège', 'Namur', 'Charleroi', 'Mons', 'Louvain-la-Neuve', 'Gand', 'Anvers'];
  final _name = TextEditingController();
  final _about = TextEditingController();
  late String _city;
  late int _minutes;
  late Set<String> _characters;

  LifeStoryService get _story => LifeStoryService.instance;

  @override
  void initState() {
    super.initState();
    _name.text = _story.firstName;
    _about.text = _story.about;
    _city = cities.contains(_story.city) ? _story.city : cities.first;
    _minutes = _story.minutes;
    _characters = _story.characters.toSet();
    if (_name.text.isEmpty) {
      SharedPreferences.getInstance().then((p) {
        if (mounted && _name.text.isEmpty) _name.text = p.getString('duel_name') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _story.configure(
      firstName: _name.text,
      city: _city,
      about: _about.text,
      minutes: _minutes,
      characters: [for (final c in storyCharacters) if (_characters.contains(c.id)) c.id],
    );
    if (!mounted) return;
    Navigator.pop(context);
    _story.ensureToday();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏡 Ma vie en Belgique', textDirection: TextDirection.ltr)),
      body: PageBody(
        children: [
          TranslatedText(
            'Every day your characters write to you about real life in Belgium. Answer in French (writing or speaking) to move the story forward. They remember what you tell them.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          SectionTitle(tr(context, 'About you')),
          TextField(
            controller: _name,
            maxLength: 24,
            decoration: InputDecoration(hintText: tr(context, 'Your first name'), prefixIcon: const Icon(Icons.person_rounded)),
          ),
          DropdownButtonFormField<String>(
            value: _city,
            isExpanded: true,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.location_city_rounded), labelText: tr(context, 'Your city')),
            items: [for (final c in cities) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => _city = v ?? _city),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _about,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: tr(context, 'A few words about you: work, family, why you learn French… (any language)'),
            ),
          ),
          SectionTitle(tr(context, 'Your characters')),
          for (final c in storyCharacters)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                glow: _characters.contains(c.id) ? Color(c.color) : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _characters.contains(c.id),
                  onChanged: (v) => setState(() => v == true ? _characters.add(c.id) : _characters.remove(c.id)),
                  secondary: CharacterAvatar(c, size: 42),
                  title: Text(c.name, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: TranslatedText(c.role, style: TextStyle(color: AppTheme.textTertiary)),
                ),
              ),
            ),
          SectionTitle(tr(context, 'Time per day')),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final m in LifeStoryService.minuteOptions)
                ButtonSegment(value: m, label: Text('$m min', textDirection: TextDirection.ltr)),
            ],
            selected: {_minutes},
            onSelectionChanged: (v) => setState(() => _minutes = v.first),
          ),
          const SizedBox(height: 6),
          Text(
            tr(context, '{n} conversation(s) a day', {'n': LifeStoryService.scenesFor(_minutes)}),
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          if (_characters.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(tr(context, 'Choose at least one character.'), style: TextStyle(color: AppTheme.error)),
            ),
          GlowButton(
            label: tr(context, 'Start my story'),
            icon: Icons.auto_stories_rounded,
            onPressed: _characters.isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}
