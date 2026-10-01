import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/grammar_topic.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/grammar_generator.dart';
import '../../services/topic_match.dart';
import '../../widgets/photo_pages_sheet.dart';
import '../../services/pdf_helper.dart';
import '../../services/global_scroll_manager.dart';
import '../lessons/dynamic_lesson_page.dart';
import '../../models/lesson_topic.dart';
import 'lessons/present_page.dart';
import 'lessons/passe_compose_page.dart';
import 'lessons/imparfait_page.dart';
import 'lessons/plus_que_parfait_page.dart';
import 'lessons/conditionnel_page.dart';
import 'lessons/negative_complex_page.dart';
import 'lessons/futur_proche_page.dart';
import 'lessons/futur_simple_page.dart';
import 'lessons/cod_coi_page.dart';
import 'lessons/si_seulement_page.dart';
import 'lessons/voix_passive_page.dart';
import 'lessons/adverbes_ment_page.dart';
import 'lessons/subjonctif_page.dart';
import 'lessons/comparatif_page.dart';
import 'lessons/duration_prepositions_page.dart';
import 'lessons/connectors_page.dart';

class GrammarPage extends StatefulWidget {
  const GrammarPage({super.key});

  @override
  State<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends State<GrammarPage> {
  bool _isGenerating = false;
  String? _progress;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    GlobalScrollManager.register(_scrollController);
  }

  @override
  void dispose() {
    GlobalScrollManager.unregister(_scrollController);
    _scrollController.dispose();
    super.dispose();
  }

  void _showTopicNameDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Enter Grammar Topic', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Subjonctif, Relative Pronouns...'),
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final topic = controller.text.trim();
                if (topic.isNotEmpty) {
                  Navigator.pop(context);
                  _createTopic(topic);
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndGenerateFromPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;

    _startProgress('Reading the PDF…');
    try {
      final text = await PdfHelper.extractText(bytes);
      if (text.trim().isEmpty) {
        throw Exception('This PDF has no readable text (it may be scanned). Use "By Photo" instead.');
      }
      await _createTopicsFromSource(text);
    } catch (e) {
      _showError('Failed to process PDF: $e');
    } finally {
      _stopProgress();
    }
  }

  Future<void> _generateFromPhotos() async {
    final request = await showPhotoPagesSheet(
      context,
      title: 'New grammar topic from photos',
      mode: PhotoImportMode.fullLesson,
      askInstructions: false,
    );
    if (request == null || !mounted) return;

    _startProgress('Reading ${request.base64Images.length} page(s)…');
    try {
      final description = await DeepSeekService.describeImages(request.base64Images, request.mimeType);
      if (description.startsWith('ERROR')) throw Exception(description);
      await _createTopicsFromSource(description);
    } catch (e) {
      _showError('Failed to create topic from photos: $e');
    } finally {
      _stopProgress();
    }
  }

  /// Finds the grammar topics in a textbook extract, lets the admin choose,
  /// then builds each chosen topic (book content + any missing rules).
  Future<void> _createTopicsFromSource(String sourceText) async {
    setState(() => _progress = 'Finding the grammar topics on these pages…');
    final topics = await GrammarGenerator.detectTopics(sourceText);
    if (!mounted) return;
    final chosen = await _chooseTopics(topics);
    if (chosen == null || chosen.isEmpty || !mounted) return;
    for (final t in chosen) {
      await _createTopic(t['title'].toString(), sourceText: sourceText, alreadyBusy: true);
      if (!mounted) return;
    }
  }

  /// Builds one complete topic. If a topic on the same subject already exists,
  /// asks whether to rebuild it (keeps one topic per subject) or add a new one.
  Future<void> _createTopic(String topic, {String? sourceText, bool alreadyBusy = false}) async {
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    final existing = TopicMatch.find(lessonsProvider.allGrammar, topic, (GrammarTopic g) => g.title);
    String? replaceId;
    if (existing != null) {
      final choice = await _askDuplicate(topic, existing);
      if (choice == null || !mounted) return;
      if (choice == _DuplicateChoice.rebuild) {
        replaceId = existing.id;
        sourceText = _withCurrentContent(sourceText, existing);
      }
    }

    if (!alreadyBusy) _startProgress('Starting…');
    try {
      final data = await GrammarGenerator.generate(
        topic,
        sourceText: sourceText,
        onProgress: (step) {
          if (mounted) setState(() => _progress = step);
        },
      );
      if (replaceId != null) {
        await lessonsProvider.replaceGrammar(replaceId, data);
        _showSuccess('"${data['title']}" rebuilt as a complete topic ✅');
      } else {
        await lessonsProvider.addGrammar(data);
        _showSuccess('"${data['title']}" added ✅');
      }
    } catch (e) {
      _showError('Failed to generate "$topic": $e');
    } finally {
      if (!alreadyBusy) _stopProgress();
    }
  }

  /// Adds the topic's current content to the source so a rebuild keeps it.
  String? _withCurrentContent(String? sourceText, GrammarTopic topic) {
    final content = topic.content ?? const [];
    final parts = [
      if (sourceText != null) sourceText,
      if (content.isNotEmpty) 'CURRENT VERSION OF THIS TOPIC (keep its useful content):\n${jsonEncode(content)}',
    ];
    return parts.isEmpty ? null : parts.join('\n\n');
  }

  void _startProgress(String message) => setState(() {
        _isGenerating = true;
        _progress = message;
      });

  void _stopProgress() {
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _progress = null;
      });
    }
  }

  Future<_DuplicateChoice?> _askDuplicate(String topic, GrammarTopic existing) {
    return showDialog<_DuplicateChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Topic already exists', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '"${existing.title}" already covers "$topic".\n\n'
          'Rebuild it to make one complete topic (its current content is kept and completed), '
          'or add a separate topic anyway.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DuplicateChoice.addNew),
            child: const Text('Add separate'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _DuplicateChoice.rebuild),
            child: const Text('Rebuild existing'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>?> _chooseTopics(List<Map<String, dynamic>> topics) {
    final selected = List<bool>.filled(topics.length, true);
    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Grammar found on these pages', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < topics.length; i++)
                CheckboxListTile(
                  value: selected[i],
                  onChanged: (v) => setDlg(() => selected[i] = v ?? false),
                  title: Text(topics[i]['title'].toString(), style: TextStyle(color: AppTheme.textPrimary)),
                  subtitle: Text(
                    '${topics[i]['subtitle'] ?? ''}\n${topics[i]['why'] ?? ''}'.trim(),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, [
                for (int i = 0; i < topics.length; i++)
                  if (selected[i]) topics[i]
              ]),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRebuild(GrammarTopic topic) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Rebuild "${topic.title}"?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'The AI checks every rule of this topic, keeps the useful content already here, '
          'adds what is missing, and rewrites it as one complete, simple topic with street '
          'expressions, a summary and a quiz.\n\nThe current version is replaced.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rebuild')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    _startProgress('Starting…');
    try {
      final data = await GrammarGenerator.generate(
        topic.title,
        sourceText: _withCurrentContent(null, topic),
        onProgress: (step) {
          if (mounted) setState(() => _progress = step);
        },
      );
      if (!mounted) return;
      await Provider.of<LessonsProvider>(context, listen: false).replaceGrammar(topic.id, data);
      _showSuccess('"${data['title']}" rebuilt ✅');
    } catch (e) {
      _showError('Failed to rebuild: $e');
    } finally {
      _stopProgress();
    }
  }

  void _checkAdminAccess(VoidCallback onGranted) {
    final TextEditingController passController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('Admin Access', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter the admin password to manage grammar content.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: obscure,
                autofocus: true,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Admin Password',
                  prefixIcon: Icon(Icons.password_rounded, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                    onPressed: () => setDlgState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (_) {
                   _verifyAndProceed(passController.text, onGranted, ctx);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _verifyAndProceed(passController.text, onGranted, ctx),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyAndProceed(String input, VoidCallback onGranted, BuildContext ctx) async {
    final granted = await AdminAuth.login(input);
    if (!mounted || !ctx.mounted) return;

    if (granted) {
      Navigator.pop(ctx);
      onGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Incorrect password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdateOptions(GrammarTopic topic) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Update "${topic.title}"', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddOption(
                icon: Icons.auto_fix_high_rounded,
                title: 'Rebuild complete topic',
                subtitle: 'Check every rule, fill gaps, simple explanations + quiz',
                color: AppTheme.warning,
                onTap: () {
                  Navigator.pop(context);
                  _confirmRebuild(topic);
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.menu_book_rounded,
                title: 'Add Pages (photos)',
                subtitle: 'New textbook pages: main points + their exercises',
                color: AppTheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpdateFromImages(topic, PhotoImportMode.fullLesson);
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.edit_note_rounded,
                title: 'Add Exercises (photos)',
                subtitle: 'Exercise pages become interactive exercises here',
                color: AppTheme.success,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpdateFromImages(topic, PhotoImportMode.exercisesOnly);
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.picture_as_pdf,
                title: 'Add from PDF',
                subtitle: 'Add content from another PDF',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpdateWithPdf(topic);
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.auto_awesome_rounded,
                title: 'Update by AI',
                subtitle: 'Tell AI what to add (e.g. "Add subjonctif rules")',
                color: Colors.amber,
                onTap: () {
                  Navigator.pop(context);
                  _showAIUpdateDialog(topic);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getUpdateInstructions(String sourceName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Update from $sourceName', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Any specific instructions for the AI?', 
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: AppTheme.textPrimary),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. "Only add the conjugation table"',
                hintStyle: TextStyle(color: AppTheme.fg.withValues(alpha: 0.3)),
                filled: true,
                fillColor: AppTheme.fg.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ""), 
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update Grammar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpdateFromImages(GrammarTopic topic, PhotoImportMode mode) async {
    final exercisesOnly = mode == PhotoImportMode.exercisesOnly;
    final request = await showPhotoPagesSheet(
      context,
      title: exercisesOnly ? 'Add exercises to "${topic.title}"' : 'Add pages to "${topic.title}"',
      mode: mode,
    );
    if (request == null || !mounted) return;

    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    setState(() => _isGenerating = true);

    try {
      final updatedData = await DeepSeekService.updateGrammarFromImages(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'widgets': topic.content ?? [], 'id': topic.id},
        request.base64Images,
        request.mimeType,
        DeepSeekService.contentLanguage,
        request.instructions,
        exercisesOnly: exercisesOnly,
      );

      if (!mounted) return;
      await lessonsProvider.updateGrammar(topic.id, updatedData);
      final added = ((updatedData['new_widgets'] as List?) ?? const [])
          .where((w) => w is Map && w['type'] == 'exercise')
          .length;
      _showSuccess(exercisesOnly
          ? '$added exercise(s) added to "${topic.title}" ✍️'
          : '"${topic.title}" updated with ${request.base64Images.length} page(s) 📚');
    } catch (e) {
      _showError('Failed to update grammar topic: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showAIUpdateDialog(GrammarTopic topic) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Update Grammar with AI: ${topic.title}', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Add more examples of irregular verbs to this guide...',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
            ),
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final instructions = controller.text.trim();
                if (instructions.isNotEmpty) {
                  Navigator.pop(context);
                  _updateGrammarWithAI(topic, instructions);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGrammarWithAI(GrammarTopic topic, String instructions) async {
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    setState(() => _isGenerating = true);
    
    try {
      final updatedData = await DeepSeekService.updateGrammarWithAI(
        {
          'title': topic.title,
          'subtitle': topic.subtitle,
          'icon': topic.icon,
          'widgets': topic.content ?? [],
          'id': topic.id
        },
        instructions,
        DeepSeekService.contentLanguage,
      );

      if (!mounted) return;
      await lessonsProvider.updateGrammar(topic.id, updatedData);
      _showSuccess('Grammar updated by AI successfully! ✨');
    } catch (e) {
      _showError('Failed to update with AI: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppTheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
          color: iconColor.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: AppTheme.fg.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }


  Future<void> _pickAndUpdateWithPdf(GrammarTopic topic) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final instructions = await _getUpdateInstructions('PDF');
    if (instructions == null) return;

    setState(() => _isGenerating = true);
    try {
      final text = await PdfHelper.extractText(result.files.single.bytes!);

      if (!mounted) return;
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      final updatedData = await DeepSeekService.updateGrammarWithPdf(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'widgets': topic.content ?? [], 'id': topic.id},
        text,
        DeepSeekService.contentLanguage,
        instructions.isEmpty ? null : instructions,
      );

      if (!mounted) return;
      await lessonsProvider.updateGrammar(topic.id, updatedData);
      _showSuccess('Grammar guide updated successfully! 📄');
    } catch (e) {
      _showError('Failed to update from PDF: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showDeleteConfirm(String topicId) {
    final TextEditingController passController = TextEditingController();
    bool obscure = true;
    final bool isCustom = topicId.startsWith('custom_');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isCustom ? Icons.delete_outline_rounded : Icons.admin_panel_settings_rounded,
                color: isCustom ? AppTheme.error : AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                isCustom ? 'Admin Delete' : 'Admin Reset / Hide',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isCustom ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (isCustom ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCustom ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      color: isCustom ? AppTheme.error : AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCustom
                            ? 'This action cannot be undone. Enter admin password to delete this custom topic.'
                            : 'This is a core lesson. You can either Reset to Default (wipe AI modifications and restore original page) or Hide Topic completely.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: obscure,
                autofocus: true,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Admin Password',
                  prefixIcon: Icon(Icons.lock_outline, color: isCustom ? AppTheme.error : AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                    onPressed: () => setDlgState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (isCustom)
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () async {
                  final granted = await AdminAuth.login(passController.text);
                  if (!mounted || !ctx.mounted) return;

                  if (granted) {
                    Navigator.pop(ctx);
                    final lp = Provider.of<LessonsProvider>(context, listen: false);
                    lp.removeGrammar(topicId);
                    _showSuccess('Grammar topic deleted successfully.');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Incorrect password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              )
            else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Reset to Default'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  final granted = await AdminAuth.login(passController.text);
                  if (!mounted || !ctx.mounted) return;

                  if (granted) {
                    Navigator.pop(ctx);
                    final lp = Provider.of<LessonsProvider>(context, listen: false);
                    lp.resetGrammarToDefault(topicId);
                    _showSuccess('Grammar topic reset to default successfully.');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Incorrect password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility_off_rounded, size: 18),
                label: const Text('Hide Topic'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () async {
                  final granted = await AdminAuth.login(passController.text);
                  if (!mounted || !ctx.mounted) return;

                  if (granted) {
                    Navigator.pop(ctx);
                    final lp = Provider.of<LessonsProvider>(context, listen: false);
                    lp.hideGrammar(topicId);
                    _showSuccess('Grammar topic hidden successfully.');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Incorrect password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final lessonsProvider = Provider.of<LessonsProvider>(context);
    final grammarItems = lessonsProvider.allGrammar;

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('grammar_lessons')),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900
                        ? 3
                        : MediaQuery.of(context).size.width > 600
                            ? 2
                            : 1,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    mainAxisExtent: 200,
                  ),
                  itemCount: grammarItems.length,
                  itemBuilder: (context, index) {
                    final topic = grammarItems[index];
                    return _buildTopicCard(context, topic, lp);
                  },
                ),
              ),
            ),
          ),
          if (_isGenerating)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitDoubleBounce(color: AppTheme.primary, size: 80),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _progress ?? 'AI is generating your grammar guide...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A complete topic takes about a minute',
                      style: TextStyle(color: AppTheme.fg.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating
            ? null
            : () {
                _checkAdminAccess(() {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.edit, color: AppTheme.primary),
                          title: Text('Enter Topic Name', style: TextStyle(color: AppTheme.textPrimary)),
                          onTap: () {
                            Navigator.pop(context);
                            _showTopicNameDialog();
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_camera_rounded, color: AppTheme.success),
                          title: Text('By Photo', style: TextStyle(color: AppTheme.textPrimary)),
                          subtitle: Text('Photograph the grammar pages of your book',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          onTap: () {
                            Navigator.pop(context);
                            _generateFromPhotos();
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: AppTheme.secondary),
                          title: Text('Upload PDF', style: TextStyle(color: AppTheme.textPrimary)),
                          onTap: () {
                            Navigator.pop(context);
                            _pickAndGenerateFromPdf();
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                });
              },
        icon: const Icon(Icons.add),
        label: const Text('Add Grammar Topic'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildTopicCard(
      BuildContext context, GrammarTopic topic, LanguageProvider lp) {
    final bool isCustom = topic.id.startsWith('custom_');
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.fg.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _getGrammarPage(topic),
              ),
            );
          },
          onLongPress: () => _showDeleteConfirm(topic.id),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.2),
                            AppTheme.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          topic.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.sync_rounded, color: AppTheme.primary, size: 22),
                      tooltip: 'Update',
                      onPressed: () => _checkAdminAccess(() => _showUpdateOptions(topic)),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                      tooltip: isCustom ? 'Delete' : 'Reset / Hide',
                      onPressed: () => _showDeleteConfirm(topic.id),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textTertiary, size: 14),
                  ],
                ),
                const Spacer(),
                Text(
                  topic.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Builder(builder: (context) {
                  final subtitle = topic.subtitle;
                  if (subtitle.isEmpty) return const SizedBox.shrink();
                  // Always translate unless user's language is English (original subtitle lang)
                  if (lp.currentLanguage == AppLanguage.english) {
                    return Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return FutureBuilder<String>(
                    future: DeepSeekService.translateText(subtitle, lp.currentLanguage.name),
                    builder: (context, snapshot) {
                      final displayText = snapshot.data ?? subtitle;
                      return Text(
                        displayText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(displayText)
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getGrammarPage(GrammarTopic topic) {
    // If it has cloud content, use the dynamic viewer
    if (topic.content != null && topic.content!.isNotEmpty) {
      return DynamicLessonPage(
        topic: LessonTopic(
          id: topic.id,
          title: topic.title,
          subtitle: topic.subtitle,
          icon: topic.icon,
          description: topic.description,
          content: topic.content,
        ),
      );
    }

    // Fallback to hardcoded pages
    switch (topic.id) {
      case 'present': return const PresentPage();
      case 'passe_compose': return const PasseComposePage();
      case 'imparfait': return const ImparfaitPage();
      case 'plus_que_parfait': return const PlusQueParfaitPage();
      case 'conditionnel': return const ConditionnelPage();
      case 'negative_complex': return const NegativeComplexPage();
      case 'futur_proche': return const FuturProchePage();
      case 'futur_simple': return const FuturSimplePage();
      case 'cod_coi': return const CodCoiPage();
      case 'si_seulement': return const SiSeulementPage();
      case 'voix_passive': return const VoixPassivePage();
      case 'adverbes_ment': return const AdverbesMentPage();
      case 'subjonctif': return const SubjonctifPage();
      case 'comparatif': return const ComparatifPage();
      case 'time_prepositions': return const DurationPrepositionsPage();
      case 'connectors': return const ConnectorsPage();
      default:
        // For truly custom ones that somehow lack content
        return Scaffold(
          appBar: AppBar(title: Text(topic.title)),
          body: const Center(child: Text('No content available yet.')),
        );
    }
  }
}

enum _DuplicateChoice { rebuild, addNew }
