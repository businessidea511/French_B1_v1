import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import '../../services/deepseek_service.dart';

class AdminAIChatPage extends StatefulWidget {
  const AdminAIChatPage({super.key});

  @override
  State<AdminAIChatPage> createState() => _AdminAIChatPageState();
}

class _AdminAIChatPageState extends State<AdminAIChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _questionController = TextEditingController();
  
  bool _isLoading = false;
  String? _aiResponse;
  String _selectedLang = 'English';

  List<Map<String, dynamic>> _savedQAs = [];

  final List<String> _supportedLanguages = [
    'English',
    'French',
    'Arabic',
    'Ukrainian',
    'Italian',
    'Tigrinya',
    'Turkish',
    'Indonesian'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set default explanation language to the app's current language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _selectedLang = lp.currentLanguage.englishName;
      });
    });

    _loadSavedQAs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  // Load saved Q&As from SharedPreferences
  Future<void> _loadSavedQAs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('saved_admin_qas');
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          _savedQAs = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading saved QAs: $e');
    }
  }

  // Save the current Q&A to SharedPreferences
  Future<void> _saveCurrentQA() async {
    final question = _questionController.text.trim();
    final answer = _aiResponse;
    if (question.isEmpty || answer == null) return;

    // Check if already saved
    final exists = _savedQAs.any((item) => item['question'] == question && item['answer'] == answer);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This Q&A is already saved!')),
      );
      return;
    }

    final newItem = {
      'question': question,
      'answer': answer,
      'lang': _selectedLang,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _savedQAs.insert(0, newItem);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_admin_qas', jsonEncode(_savedQAs));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to library! 📚'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('Error saving QA: $e');
    }
  }

  // Delete a saved Q&A
  Future<void> _deleteQA(int index) async {
    setState(() {
      _savedQAs.removeAt(index);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_admin_qas', jsonEncode(_savedQAs));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from library.')),
      );
    } catch (e) {
      debugPrint('Error deleting QA: $e');
    }
  }

  // Send question to DeepSeekService
  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiResponse = null;
    });

    try {
      final response = await DeepSeekService.askGeneralFrenchQuestion(question, _selectedLang);
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'Failed to get explanation. Please check your internet or retry.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin AI Assistant 🔒'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.forum_rounded), text: 'AI Chat'),
            Tab(icon: Icon(Icons.bookmark_rounded), text: 'Saved Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(lp),
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab(LanguageProvider lp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ask any question regarding our B1 course, French grammar, or general French. You can type and receive explanations in any language.',
                    style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Input Box Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Select Dropdown
                Row(
                  children: [
                    const Icon(Icons.g_translate_rounded, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Explanation Language:',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLang,
                          dropdownColor: AppTheme.surface,
                          items: _supportedLanguages.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLang = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Text Field
                TextField(
                  controller: _questionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g. Explain how to use the subjonctif with clear B1 examples...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _askQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Ask Professeur AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Response Display View
          if (_aiResponse != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Explanation ($_selectedLang):',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warning,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saveCurrentQA,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Save', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MarkdownBody(
                    data: _aiResponse!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: Color(0xFFE2E8F0),
                        fontFamily: 'Inter',
                      ),
                      strong: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        color: AppTheme.accent,
                        fontStyle: FontStyle.italic,
                      ),
                      h1: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.black.withValues(alpha: 0.1),
                        color: AppTheme.success,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      blockquote: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: AppTheme.primary, width: 4),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_savedQAs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.white24),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Saved Explanations Yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your saved Q&As will appear here.',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _savedQAs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _savedQAs[index];
        final String question = item['question'] ?? '';
        final String answer = item['answer'] ?? '';
        final String lang = item['lang'] ?? 'English';
        final String timestamp = item['timestamp'] != null 
          ? DateTime.parse(item['timestamp']).toString().substring(0, 16)
          : '';

        return Card(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.bookmark, color: AppTheme.primary),
            title: Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Language: $lang • Saved: $timestamp',
              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              onPressed: () => _deleteQA(index),
            ),
            childrenPadding: const EdgeInsets.all(20),
            expandedAlignment: Alignment.topLeft,
            children: [
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 16),
              ),
              MarkdownBody(
                data: answer,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFFCBD5E1),
                    fontFamily: 'Inter',
                  ),
                  strong: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  em: const TextStyle(
                    color: AppTheme.accent,
                    fontStyle: FontStyle.italic,
                  ),
                  h1: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: AppTheme.accent, fontSize: 18, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: AppTheme.secondary, fontSize: 16, fontWeight: FontWeight.bold),
                  code: TextStyle(
                    backgroundColor: Colors.black.withValues(alpha: 0.1),
                    color: AppTheme.success,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
