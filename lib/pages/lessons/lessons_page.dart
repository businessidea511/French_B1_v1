import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/lesson_topic.dart';
import '../../services/language_provider.dart';
import '../../services/lessons_provider.dart';
import '../../services/deepseek_service.dart';
import '../../services/pdf_helper.dart';
import 'metiers_page.dart';
import 'dynamic_lesson_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  bool _isGenerating = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddLessonDialog() {
    final TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Admin Access', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter the admin password to create new lessons.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // First check String.fromEnvironment (for Vercel/Production)
                // Then check dotenv (for local dev)
                const String envPass = String.fromEnvironment('ADMIN_PASSWORD');
                final String adminPass = envPass.isNotEmpty 
                    ? envPass 
                    : (dotenv.env['ADMIN_PASSWORD'] ?? 'admin123');

                if (passwordController.text == adminPass) {
                  Navigator.pop(context);
                  _showLessonOptionsDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Password'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void _showLessonOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Add New Lesson', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddOption(
                icon: Icons.edit_note,
                title: 'By Topic Name',
                subtitle: 'Enter a topic like "Furniture"',
                onTap: () {
                  Navigator.pop(context);
                  _showTopicNameDialog();
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.picture_as_pdf,
                title: 'By PDF Upload',
                subtitle: 'Upload a PDF to generate a lesson',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndGenerateFromPdf();
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.camera_alt_rounded,
                title: 'By Photo',
                subtitle: 'Take a photo or pick from gallery',
                color: AppTheme.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _showImageSourceDialog();
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
                textDirection: lp.currentLanguage.isRTL ? TextDirection.rtl : TextDirection.ltr,
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

  void _showTopicNameDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Enter Topic', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Health, Sports...'),
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
                  _generateLesson(topic: topic);
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  // ── IMAGE CAPTURE ──────────────────────────────────────

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Choose Image Source', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              _buildAddOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take a Photo',
                subtitle: 'Use your camera',
                color: AppTheme.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndGenerateFromImages(ImageSource.camera);
                },
              ),
            if (!kIsWeb) const SizedBox(height: 12),
            _buildAddOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Pick an existing photo',
              color: AppTheme.accent,
              onTap: () {
                Navigator.pop(context);
                _pickAndGenerateFromImages(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndGenerateFromImages(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile> selectedFiles = [];

    if (source == ImageSource.gallery) {
      selectedFiles = await picker.pickMultiImage(
        imageQuality: 40,
        maxWidth: 800,
        maxHeight: 800,
      );
    } else {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) selectedFiles = [image];
    }

    if (selectedFiles.isEmpty) return;
    if (selectedFiles.length > 10) {
      selectedFiles = selectedFiles.sublist(0, 10);
      _showError('Only the first 10 images will be used.');
    }

    setState(() => _isGenerating = true);

      if (!mounted) return;
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      try {
      final List<String> base64Images = [];
      String? mimeType;

      for (var file in selectedFiles) {
        final bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
        mimeType ??= file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      }

      final lessonData = await DeepSeekService.generateLessonFromImages(
        base64Images,
        mimeType ?? 'image/jpeg',
        lp.currentLanguage.englishName,
      );

      if (!mounted) return;
      await lessonsProvider.addLesson(lessonData);
      _showSuccess('Lesson generated from ${selectedFiles.length} photo(s) successfully! 📸');
    } catch (e) {
      _showError('Failed to analyze images: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── PDF ─────────────────────────────────────────────────

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
        await _generateLesson(topic: name, pdfText: text);
      } catch (e) {
        _showError('Failed to process PDF: $e');
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateLesson({required String topic, String? pdfText}) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    setState(() => _isGenerating = true);
    
    try {
      final lessonData = await DeepSeekService.generateFullLesson(
        topic,
        lp.currentLanguage.englishName,
        pdfText: pdfText,
      );
      
      if (!mounted) return;
      await lessonsProvider.addLesson(lessonData);
      _showSuccess('Lesson "$topic" added successfully!');
    } catch (e) {
      _showError('Failed to generate lesson: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── UPDATE LESSON LOGIC ─────────────────────────────────

  void _showUpdateOptions(LessonTopic topic) {
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
                icon: Icons.camera_alt_rounded,
                title: 'Add More Photos',
                subtitle: 'Capture new pages from textbook',
                color: AppTheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpdateFromImages(topic, ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.photo_library_rounded,
                title: 'Add from Gallery',
                subtitle: 'Select saved textbook pages',
                color: AppTheme.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpdateFromImages(topic, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.picture_as_pdf,
                title: 'Add from PDF',
                subtitle: 'Add content from another PDF',
                color: AppTheme.accent,
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

  Future<void> _pickAndUpdateFromImages(LessonTopic topic, ImageSource source) async {
    final picker = ImagePicker();
    List<XFile> selectedFiles = [];

    if (source == ImageSource.gallery) {
      selectedFiles = await picker.pickMultiImage(imageQuality: 40, maxWidth: 800, maxHeight: 800);
    } else {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 40, maxWidth: 800, maxHeight: 800);
      if (image != null) selectedFiles = [image];
    }

    if (selectedFiles.isEmpty) return;
    setState(() => _isGenerating = true);

      if (!mounted) return;
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      try {
      final List<String> base64Images = [];
      String? mimeType;
      for (var file in selectedFiles) {
        final bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
        mimeType ??= file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      }

      final updatedData = await DeepSeekService.updateLessonFromImages(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'sections': topic.content, 'id': topic.id},
        base64Images,
        mimeType ?? 'image/jpeg',
        lp.currentLanguage.englishName,
      );

      if (!mounted) return;
      await lessonsProvider.updateLesson(topic.id, updatedData);
      _showSuccess('Lesson updated with new pages! 📚');
    } catch (e) {
      _showError('Failed to update lesson: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _pickAndUpdateWithPdf(LessonTopic topic) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isGenerating = true);
    try {
      final text = await PdfHelper.extractText(result.files.single.path!);

      final updatedData = await DeepSeekService.updateLessonWithPdf(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'sections': topic.content, 'id': topic.id},
        text,
        lp.currentLanguage.englishName,
      );

      if (!mounted) return;
      await lessonsProvider.updateLesson(topic.id, updatedData);
      _showSuccess('Lesson updated from PDF content! 📄');
    } catch (e) {
      _showError('Failed to update from PDF: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showDiagnostics(BuildContext context, LessonsProvider lp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.cloud_sync, color: AppTheme.primary),
            SizedBox(width: 12),
            Text('Cloud Diagnostics', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiagRow('Status', lp.lastError != null ? 'Error' : 'Connected', 
                lp.lastError != null ? Colors.red : Colors.green),
            if (lp.lastError != null) ...[
              const SizedBox(height: 12),
              const Text('Last Error:', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              Text(lp.lastError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const Divider(height: 32, color: Colors.white10),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await lp.testConnection();
                if (!context.mounted) return;
                _showTestResults(context, result);
              },
              icon: const Icon(Icons.speed),
              label: const Text('Run Connection Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                foregroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: lp.isSyncing ? null : () {
              Navigator.pop(context);
              lp.syncFromCloud();
            },
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  void _showTestResults(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Test Results', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDiagRow('Supabase', result['status'] == 'success' ? 'Connected' : 'Failed',
                result['status'] == 'success' ? Colors.green : Colors.red),
            if (result['status'] == 'success') ...[
              _buildDiagRow('Latency', result['latency'], Colors.white),
              _buildDiagRow('Cloud Rows', '${result['rows']}', Colors.white),
              _buildDiagRow('Schema', result['schema'], result['schemaOk'] ? Colors.green : Colors.orange),
            ] else ...[
              Text(result['message'] ?? 'Unknown error', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Flexible(
            child: Text(value, 
              textAlign: TextAlign.end,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
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
    final lessons = lessonsProvider.allLessons;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        actions: [
          Consumer<LessonsProvider>(
            builder: (context, lp, child) {
              return IconButton(
                icon: Icon(
                  lp.isSyncing ? Icons.sync : Icons.cloud_done_rounded,
                  color: lp.lastError != null ? Colors.red : (lp.isSyncing ? Colors.orange : Colors.green),
                ),
                onPressed: () => _showDiagnostics(context, lp),
                tooltip: 'Cloud Status',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
                child: RefreshIndicator(
                  onRefresh: () => lessonsProvider.syncFromCloud(),
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  child: GridView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final topic = lessons[index];
                      return _buildTopicCard(context, topic, lp);
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_isGenerating)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpinKitDoubleBounce(color: AppTheme.primary, size: 80),
                    const SizedBox(height: 20),
                    const Text(
                      'AI is generating your lesson...',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This might take a few seconds',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _showAddLessonDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Lesson'),
      ),
    );
  }

  Widget _buildTopicCard(
      BuildContext context, LessonTopic topic, LanguageProvider lp) {
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
              MaterialPageRoute(builder: (context) => _getLessonPage(topic)),
            );
          },
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
                    if (topic.id.startsWith('custom_'))
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(topic),
                      ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textTertiary, size: 14),
                  ],
                ),
                const Spacer(),
                // Show title directly — only translate if NOT English or Arabic
                // (Arabic titles from AI-generated lessons are already in Arabic)
                Builder(builder: (context) {
                  final needsTranslation = lp.currentLanguage != AppLanguage.english &&
                      lp.currentLanguage != AppLanguage.arabic;
                  if (!needsTranslation) {
                    return Text(
                      topic.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return FutureBuilder<String>(
                    future: DeepSeekService.translateText(topic.title, lp.currentLanguage.name),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? topic.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  );
                }),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final needsTranslation = lp.currentLanguage != AppLanguage.english &&
                      lp.currentLanguage != AppLanguage.arabic;
                  if (!needsTranslation) {
                    return Text(
                      topic.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
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

  void _confirmDelete(LessonTopic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Lesson', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${topic.title}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<LessonsProvider>(context, listen: false)
                  .removeLesson(topic.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _getLessonPage(LessonTopic topic) {
    if (topic.content != null && topic.content!.isNotEmpty) {
      return DynamicLessonPage(topic: topic);
    }

    switch (topic.id) {
      case 'metiers':
        return const MetiersPage();
      default:
        return Scaffold(
          appBar: AppBar(title: Text(topic.title)),
          body: const Center(child: Text('Lesson content coming soon!')),
        );
    }
  }
}
