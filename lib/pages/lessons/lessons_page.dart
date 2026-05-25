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

  // ── ADMIN DELETE ──────────────────────────────────────

  void _confirmDelete(LessonTopic topic) {
    final TextEditingController passController = TextEditingController();
    bool obscure = true;
    final bool isCustom = topic.id.startsWith('custom_');

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
                style: const TextStyle(color: Colors.white, fontSize: 18),
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
                            ? 'This action cannot be undone. Enter admin password to delete this custom lesson.'
                            : 'This is a core lesson. You can either Reset to Default (wipe AI modifications and restore original page) or Hide Lesson completely.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
                onPressed: () {
                  const String envPass = String.fromEnvironment('ADMIN_PASSWORD');
                  final String adminPass = envPass.isNotEmpty
                      ? envPass
                      : (dotenv.env['ADMIN_PASSWORD'] ?? 'admin123');

                  if (passController.text == adminPass) {
                    Navigator.pop(ctx);
                    Provider.of<LessonsProvider>(context, listen: false).removeLesson(topic.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ "${topic.title}" deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
                onPressed: () {
                  const String envPass = String.fromEnvironment('ADMIN_PASSWORD');
                  final String adminPass = envPass.isNotEmpty
                      ? envPass
                      : (dotenv.env['ADMIN_PASSWORD'] ?? 'admin123');

                  if (passController.text == adminPass) {
                    Navigator.pop(ctx);
                    Provider.of<LessonsProvider>(context, listen: false).resetLessonToDefault(topic.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ "${topic.title}" reset to default successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
                label: const Text('Hide Lesson'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () {
                  const String envPass = String.fromEnvironment('ADMIN_PASSWORD');
                  final String adminPass = envPass.isNotEmpty
                      ? envPass
                      : (dotenv.env['ADMIN_PASSWORD'] ?? 'admin123');

                  if (passController.text == adminPass) {
                    Navigator.pop(ctx);
                    Provider.of<LessonsProvider>(context, listen: false).hideLesson(topic.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ "${topic.title}" hidden successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
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

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      
      setState(() => _isGenerating = true);
      
      try {
        final text = await PdfHelper.extractText(bytes);
        if (text.trim().isEmpty) {
          _showError('This PDF seems to have no readable text. It might be a scanned image.');
          return;
        }
        await _generateLesson(topic: name.replaceAll('.pdf', ''), pdfText: text);
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
            children: const [
              Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('Admin Access', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter the admin password to update lesson content.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: obscure,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Admin Password',
                  prefixIcon: const Icon(Icons.password_rounded, color: AppTheme.primary),
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

  void _verifyAndProceed(String input, VoidCallback onGranted, BuildContext ctx) {
    const String envPass = String.fromEnvironment('ADMIN_PASSWORD');
    final String adminPass = envPass.isNotEmpty
        ? envPass
        : (dotenv.env['ADMIN_PASSWORD'] ?? 'admin123');

    if (input == adminPass) {
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
              const SizedBox(height: 12),
              _buildAddOption(
                icon: Icons.auto_awesome_rounded,
                title: 'Update by AI',
                subtitle: 'Tell AI what to add (e.g. "Add flu symptoms")',
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

  void _showAIUpdateDialog(LessonTopic topic) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Update with AI: ${topic.title}', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Add the word "grippe" and its symptoms to the lesson...',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            style: const TextStyle(color: Colors.white),
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
                  _updateLessonWithAI(topic, instructions);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLessonWithAI(LessonTopic topic, String instructions) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    final lessonsProvider = Provider.of<LessonsProvider>(context, listen: false);
    
    setState(() => _isGenerating = true);
    
    try {
      final updatedData = await DeepSeekService.updateLessonWithAI(
        {
          'title': topic.title,
          'subtitle': topic.subtitle,
          'icon': topic.icon,
          'widgets': topic.content ?? [],
          'id': topic.id
        },
        instructions,
        lp.currentLanguage.englishName,
      );

      if (!mounted) return;
      await lessonsProvider.updateLesson(topic.id, updatedData);
      _showSuccess('Lesson updated by AI successfully! ✨');
    } catch (e) {
      _showError('Failed to update with AI: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<String?> _getUpdateInstructions(String sourceName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Update from $sourceName', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Any specific instructions for the AI?', 
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. "Only add the vocabulary list" or "Focus on the dialogue section"',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ""), // Empty string means skip instructions but proceed
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update Lesson'),
          ),
        ],
      ),
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

    final instructions = await _getUpdateInstructions(source == ImageSource.camera ? 'Camera' : 'Gallery');
    if (instructions == null) return; // User cancelled

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
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'widgets': topic.content ?? [], 'id': topic.id},
        base64Images,
        mimeType ?? 'image/jpeg',
        lp.currentLanguage.englishName,
        instructions.isEmpty ? null : instructions,
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final instructions = await _getUpdateInstructions('PDF');
    if (instructions == null) return; // User cancelled

    setState(() => _isGenerating = true);
    try {
      final text = await PdfHelper.extractText(result.files.single.bytes!);

      final updatedData = await DeepSeekService.updateLessonWithPdf(
        {'title': topic.title, 'subtitle': topic.subtitle, 'icon': topic.icon, 'widgets': topic.content ?? [], 'id': topic.id},
        text,
        lp.currentLanguage.englishName,
        instructions.isEmpty ? null : instructions,
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
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await DeepSeekService.clearCache();
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSuccess('Translation cache cleared! Refresh to see changes.');
              },
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Clear Translation Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                foregroundColor: Colors.orange,
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
          onLongPress: () => _confirmDelete(topic),
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
                      onPressed: () => _checkAdminAccess(() => _showUpdateOptions(topic)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                      tooltip: topic.id.startsWith('custom_') ? 'Delete' : 'Reset / Hide',
                      onPressed: () => _confirmDelete(topic),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textTertiary, size: 14),
                  ],
                ),
                const Spacer(),
                // Title is always French now (from AI)
                Text(
                  topic.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Subtitle: translate to user's selected language
                Builder(builder: (context) {
                  final subtitle = topic.subtitle;
                  if (subtitle.isEmpty) return const SizedBox.shrink();
                  final lp = Provider.of<LanguageProvider>(context);
                  return FutureBuilder<String>(
                    future: DeepSeekService.translateText(subtitle, lp.currentLanguage.name),
                    builder: (context, snapshot) {
                      final displayText = snapshot.data ?? subtitle;
                      return Text(
                        displayText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(displayText) 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
                      );
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
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
