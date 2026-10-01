import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/word_bank.dart';
import '../../services/deepseek_service.dart';
import '../../services/language_provider.dart';
import '../../services/progress_service.dart';
import '../../services/word_decks.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion.dart';
import '../../widgets/translated_text.dart';
import '../../widgets/ui_kit.dart';
import '../flashcards/flashcards_page.dart';
import 'word_category_page.dart';

/// Take a photo of anything (kitchen, street, menu…) and get its French words.
class PhotoWordsPage extends StatefulWidget {
  const PhotoWordsPage({super.key});

  @override
  State<PhotoWordsPage> createState() => _PhotoWordsPageState();
}

class _PhotoWordsPageState extends State<PhotoWordsPage> {
  Uint8List? _image;
  bool _loading = false;
  String? _error;
  String _scene = '';
  List<WordItem> _words = [];
  List<WordGloss> _glosses = [];
  final Set<int> _selected = {};

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 70);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _image = bytes;
        _words = [];
        _error = null;
      });
      await _analyse(bytes, file.mimeType ?? 'image/jpeg');
    } catch (e) {
      setState(() => _error = 'Could not open the photo.');
    }
  }

  Future<void> _analyse(Uint8List bytes, String mimeType) async {
    setState(() => _loading = true);
    final language = context.read<LanguageProvider>().currentLanguage;
    try {
      final result = await DeepSeekService.chatJson([
        {
          'role': 'system',
          'content': 'You help a B1 French learner living in Belgium learn vocabulary from photos. '
              'List the useful everyday things you can CLEARLY see in the photo (objects, food, places, actions, '
              'and any printed text worth knowing), up to 15. Use the French word a Belgian would say, with its article '
              '(le, la, l\', les, un, une). Prefer common B1 words. For each give the English meaning and a short simple '
              'French example sentence about the photo. '
              'Return JSON: {"scene": "short French title for the photo", '
              '"items": [{"fr": "la bouilloire", "en": "kettle", "example": "La bouilloire est sur le plan de travail."}]}',
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Which French words can I learn from this photo?'},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,${base64Encode(bytes)}'},
            },
          ],
        },
      ], temperature: 0.3, maxTokens: 3000);
      final words = [
        for (final raw in (result['items'] as List? ?? const []))
          if (raw is Map && '${raw['fr'] ?? ''}'.trim().isNotEmpty)
            WordItem('${raw['fr']}'.trim(), '${raw['en'] ?? ''}'.trim(), example: '${raw['example'] ?? ''}'.trim()),
      ];
      if (words.isEmpty) throw Exception('no words');
      final glosses = await WordDecks.glosses(words, language);
      if (!mounted) return;
      setState(() {
        _scene = '${result['scene'] ?? ''}';
        _words = words;
        _glosses = glosses;
        _selected
          ..clear()
          ..addAll(List.generate(words.length, (i) => i));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'I could not find words in this photo. Try another one, closer and with good light.';
        });
      }
    }
  }

  List<Map<String, String>> get _cards => [
        for (final i in _selected)
          {'front': _words[i].fr, 'back': _glosses[i].meaning, 'example': _words[i].example, 'tip': ''}
      ];

  void _save() {
    context.read<ProgressService>().saveWords(_cards);
    Confetti.burst(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selected.length} mots ajoutés à « Mes mots » et à tes révisions ✓')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📸 Photo → mots')),
      body: PageBody(
        children: [
          TranslatedText(
            'Take a photo of your kitchen, the street, a menu or a sign. Professeur AI finds the French words in it, and you can save them to learn them.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlowButton(
                    label: 'Caméra', icon: Icons.photo_camera_rounded, onPressed: _loading ? null : () => _pick(ImageSource.camera)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlowButton(
                  label: 'Galerie',
                  icon: Icons.photo_library_rounded,
                  colors: [AppTheme.secondary, AppTheme.accent],
                  onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Tilt3D(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.memory(_image!, height: 240, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
          if (_loading)
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Column(children: [
                Floating(child: Text('🔎', style: TextStyle(fontSize: 56))),
                SizedBox(height: 10),
                TranslatedText('Looking for French words…', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TranslatedText(_error!, style: TextStyle(color: AppTheme.error)),
            ),
          if (_words.isNotEmpty) ...[
            SectionTitle(_scene.isEmpty ? 'Mots trouvés' : _scene),
            for (final (i, w) in _words.indexed)
              Entrance(
                index: i,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _selected.contains(i),
                      onChanged: (v) => setState(() => v == true ? _selected.add(i) : _selected.remove(i)),
                    ),
                    Expanded(child: WordTile(item: w, meaning: _glosses[i].meaning, note: '')),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            GlowButton(
              label: 'Enregistrer ${_selected.length} mots',
              icon: Icons.bookmark_add_rounded,
              onPressed: _selected.isEmpty ? null : _save,
              colors: [AppTheme.success, Color(0xFF14B8A6)],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => FlashcardsPage(deck: _cards, deckTitle: _scene.isEmpty ? 'Photo' : _scene))),
              icon: const Text('🎴'),
              label: const Text('Flashcards'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Words the learner saved from photos.
class MyWordsPage extends StatelessWidget {
  const MyWordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressService>();
    final words = progress.savedWords;
    return Scaffold(
      appBar: AppBar(title: const Text('⭐ Mes mots')),
      body: PageBody(
        children: [
          if (words.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(child: Floating(child: Text('📸', style: TextStyle(fontSize: 64)))),
            const SizedBox(height: 12),
            TranslatedText('No saved words yet. Take a photo to find words to learn!',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            GlowButton(
              label: 'Photo → mots',
              icon: Icons.photo_camera_rounded,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoWordsPage())),
            ),
          ] else ...[
            GlowButton(
              label: 'Flashcards · ${words.length}',
              icon: Icons.style_rounded,
              colors: [AppTheme.success, Color(0xFF14B8A6)],
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => FlashcardsPage(deck: words, deckTitle: 'Mes mots'))),
            ),
            const SizedBox(height: 16),
            for (final w in words)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WordTile(
                      item: WordItem(w['front'] ?? '', w['back'] ?? '', example: w['example'] ?? ''),
                      meaning: w['back'] ?? '',
                      note: '',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: Icon(Icons.delete_outline_rounded, color: AppTheme.textTertiary),
                    onPressed: () => context.read<ProgressService>().removeSavedWord(w['front'] ?? ''),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
