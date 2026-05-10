import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';
import '../../models/grammar_topic.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/pdf_helper.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
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
          title: const Text('Enter Grammar Topic', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Subjonctif, Relative Pronouns...'),
            style: const TextStyle(color: Colors.white),
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
                  _generateGrammar(topic: topic);
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

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      
      setState(() => _isGenerating = true);
      
      try {
        final text = await PdfHelper.extractText(path);
        await _generateGrammar(topic: name, pdfText: text);
      } catch (e) {
        _showError('Failed to process PDF: $e');
      } finally {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateGrammar({required String topic, String? pdfText}) async {
    setState(() => _isGenerating = true);
    
    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
      
      final grammarData = await DeepSeekService.generateFullGrammar(
        topic,
        lp.currentLanguage.englishName,
        pdfText: pdfText,
      );
      
      await lessonsProvider.addGrammar(grammarData);
      _showSuccess('Grammar guide "$topic" added successfully!');
    } catch (e) {
      _showError('Failed to generate grammar: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showUpdateOptions(GrammarTopic topic) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Update "${topic.title}"', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddOption(
                icon: Icons.edit_note,
                title: 'Add via Topic Name',
                subtitle: 'Extend this guide with AI',
                onTap: () {
                  Navigator.pop(context);
                  _showTopicUpdateDialog(topic);
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
            ],
          ),
        );
      },
    );
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
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }

  void _showTopicUpdateDialog(GrammarTopic topic) {
    final TextEditingController controller = TextEditingController(text: topic.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Update Topic', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter sub-topic to add...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateGrammar(topic: controller.text.trim());
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpdateWithPdf(GrammarTopic topic) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isGenerating = true);
    try {
      final text = await PdfHelper.extractText(result.files.single.path!);

      if (!mounted) return;
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      final updatedData = await DeepSeekService.updateGrammarWithPdf(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'sections': topic.content, 'id': topic.id},
        text,
        lp.currentLanguage.englishName,
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings_rounded, color: AppTheme.error),
              SizedBox(width: 10),
              Text('Admin Delete', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. Enter admin password to delete this grammar topic.',
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Admin Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.error),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () {
                const String envPass = String.fromEnvironment('ADMIN_PASSWORD');
                final String adminPass = envPass.isNotEmpty
                    ? envPass
                    : (dotenv.env['ADMIN_PASSWORD'] ?? 'admin123');

                if (passController.text == adminPass) {
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
            ),
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
                    childAspectRatio: 1.6,
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
                    const SpinKitDoubleBounce(color: AppTheme.primary, size: 80),
                    const SizedBox(height: 20),
                    const Text(
                      'AI is generating your grammar guide...',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This might take a few seconds',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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
                  leading: const Icon(Icons.edit, color: AppTheme.primary),
                  title: const Text('Enter Topic Name', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showTopicNameDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppTheme.secondary),
                  title: const Text('Upload PDF', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndGenerateFromPdf();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
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
          onLongPress: isCustom ? () => _showDeleteConfirm(topic.id) : null,
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
                      icon: const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 22),
                      tooltip: 'Update',
                      onPressed: () => _showUpdateOptions(topic),
                    ),
                    if (isCustom)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                        tooltip: 'Delete',
                        onPressed: () => _showDeleteConfirm(topic.id),
                      ),
                    const Icon(Icons.arrow_forward_ios_rounded,
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
                  final needsTranslation = lp.currentLanguage != AppLanguage.english &&
                      lp.currentLanguage != AppLanguage.arabic;
                  if (!needsTranslation) {
                    return Text(
                      topic.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return FutureBuilder<String>(
                    future: DeepSeekService.translateText(topic.subtitle, lp.currentLanguage.name),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? topic.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Topic?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this custom grammar guide?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<LessonsProvider>(context, listen: false).removeGrammar(id);
              Navigator.pop(context);
              _showSuccess('Topic removed');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
