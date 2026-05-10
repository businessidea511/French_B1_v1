import 'dart:convert';
import 'dart:io';
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
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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
          border: Border.all(color: iconColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: iconColor.withOpacity(0.05),
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
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor.withOpacity(0.5), size: 14),
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

    try {
      final List<String> base64Images = [];
      String? mimeType;

      for (var file in selectedFiles) {
        final bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
        mimeType ??= file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      }

      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      final lessonData = await DeepSeekService.generateLessonFromImages(
        base64Images,
        mimeType ?? 'image/jpeg',
        lp.currentLanguage.englishName,
      );

      await lessonsProvider.addLesson(lessonData);
      _showSuccess('Lesson generated from ${selectedFiles.length} photo(s) successfully! 📸');
    } catch (e) {
      _showError('Failed to analyze images: $e');
    } finally {
      setState(() => _isGenerating = false);
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
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateLesson({required String topic, String? pdfText}) async {
    setState(() => _isGenerating = true);
    
    try {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
      
      final lessonData = await DeepSeekService.generateFullLesson(
        topic,
        lp.currentLanguage.englishName,
        pdfText: pdfText,
      );
      
      await lessonsProvider.addLesson(lessonData);
      _showSuccess('Lesson "$topic" added successfully!');
    } catch (e) {
      _showError('Failed to generate lesson: $e');
    } finally {
      setState(() => _isGenerating = false);
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

    try {
      final List<String> base64Images = [];
      String? mimeType;
      for (var file in selectedFiles) {
        final bytes = await file.readAsBytes();
        base64Images.add(base64Encode(bytes));
        mimeType ??= file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      }

      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      final updatedData = await DeepSeekService.updateLessonFromImages(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'sections': topic.content, 'id': topic.id},
        base64Images,
        mimeType ?? 'image/jpeg',
        lp.currentLanguage.englishName,
      );

      await lessonsProvider.updateLesson(topic.id, updatedData);
      _showSuccess('Lesson updated with new pages! 📚');
    } catch (e) {
      _showError('Failed to update lesson: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _pickAndUpdateWithPdf(LessonTopic topic) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isGenerating = true);
    try {
      final text = await PdfHelper.extractText(result.files.single.path!);
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);

      final updatedData = await DeepSeekService.updateLessonWithPdf(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'sections': topic.content, 'id': topic.id},
        text,
        lp.currentLanguage.englishName,
      );

      await lessonsProvider.updateLesson(topic.id, updatedData);
      _showSuccess('Lesson updated from PDF content! 📄');
    } catch (e) {
      _showError('Failed to update from PDF: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
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
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
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
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.7),
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
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
    return Card(
      clipBehavior: Clip.antiAlias,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        topic.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (topic.id.startsWith('custom_'))
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 22),
                      tooltip: 'Update this lesson with more pages',
                      onPressed: () => _showUpdateOptions(topic),
                    ),
                  const Icon(Icons.arrow_forward,
                      color: AppTheme.textTertiary, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                topic.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: lp.currentLanguage == AppLanguage.english
                    ? Future.value(topic.subtitle)
                    : DeepSeekService.translateText(
                        topic.subtitle, lp.currentLanguage.name),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getLessonPage(LessonTopic topic) {
    if (topic.content != null) {
      return DynamicLessonPage(topic: topic);
    }
    
    switch (topic.id) {
      case 'metiers':
        return const MetiersPage();
      default:
        return const Scaffold(body: Center(child: Text('Lesson not found')));
    }
  }
}
