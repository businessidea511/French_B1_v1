import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../theme/app_theme.dart';
import '../../services/deepseek_service.dart';
import '../../services/tts_service.dart';

class ListeningPage extends StatefulWidget {
  const ListeningPage({super.key});

  @override
  State<ListeningPage> createState() => _ListeningPageState();
}

class _ListeningPageState extends State<ListeningPage> {
  final TtsService _ttsService = TtsService();
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _showTranscript = false;
  Map<String, dynamic>? _exerciseData;
  final Map<int, String> _selectedAnswers = {};
  final Map<int, bool> _results = {};
  bool _checked = false;

  final List<String> _topics = [
    'Daily Routine',
    'Travel',
    'Food & Cooking',
    'Work & Career',
    'Hobbies',
    'French Culture',
    'Technology',
    'Environment',
    'Logement',
    "Souvenir d'Enfance",
    "Dialogue: Louer un logement (Client/Agence)"
  ];
  String _selectedTopic = 'Daily Routine';
  String _selectedCity = 'Paris'; // Default city for dialogues

  double _playbackRate = 0.9;
  List<String> _sentences = [];
  int _currentSentenceIndex = -1;
  bool _isAudioLoading = false;

  // Voice management
  List<Map<dynamic, dynamic>> _frenchVoices = [];
  Map<dynamic, dynamic>? _selectedClientVoice;
  Map<dynamic, dynamic>? _selectedAgenceVoice;

  @override
  void initState() {
    super.initState();
    _initVoices();
    _ttsService.flutterTts.setCompletionHandler(() {
      if (mounted) {
        if (_currentSentenceIndex < _sentences.length - 1 && _isPlaying) {
          _nextSentence();
        } else {
          setState(() {
            _isPlaying = false;
            _currentSentenceIndex = -1;
          });
        }
      }
    });
  }

  Future<void> _initVoices() async {
    // Retry logic for mobile web compatibility
    for (int i = 0; i < 3; i++) {
      try {
        final voices = await _ttsService.flutterTts.getVoices;
        if (mounted) {
          setState(() {
            _frenchVoices = voices
                .where((v) => v['locale'].toString().startsWith('fr'))
                .toList()
                .cast<Map<dynamic, dynamic>>();

            if (_frenchVoices.isNotEmpty) {
              // Only set defaults if not already set or invalid
              if (_selectedClientVoice == null ||
                  !_frenchVoices.contains(_selectedClientVoice)) {
                _selectedClientVoice = _frenchVoices.first;
              }
              if (_selectedAgenceVoice == null ||
                  !_frenchVoices.contains(_selectedAgenceVoice)) {
                _selectedAgenceVoice = _frenchVoices.length > 1
                    ? _frenchVoices[1]
                    : _frenchVoices.first;
              }
            }
          });
        }
        if (_frenchVoices.isNotEmpty) break;
      } catch (e) {
        debugPrint('Error loading voices: $e');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _generateExercise() async {
    setState(() {
      _isLoading = true;
      _exerciseData = null;
      _selectedAnswers.clear();
      _results.clear();
      _checked = false;
      _showTranscript = false;
      _sentences = [];
      _currentSentenceIndex = -1;
      _isPlaying = false;
    });

    try {
      final data = await DeepSeekService.generateListeningExercise(
        _selectedTopic,
        city: _selectedTopic.startsWith('Dialogue') ? _selectedCity : null,
      );

      // Sanitization: Ensure the 'answer' field exactly matches one of the options if close enough
      final List<dynamic> questions = data['questions'];
      for (var q in questions) {
        String rawAnswer = q['answer'].toString();
        List<dynamic> options = q['options'];

        // Find option that matches normalized answer
        try {
          String matchedOption = options.firstWhere(
              (opt) =>
                  _normalizeText(opt.toString()) == _normalizeText(rawAnswer),
              orElse: () => rawAnswer // Keep original if no match found
              );
          q['answer'] = matchedOption; // Snap to the exact option string
        } catch (e) {
          // Ignore
        }
      }

      setState(() {
        _exerciseData = data;
        _sentences = _splitIntoSentences(data['text']);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating exercise: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _splitIntoSentences(String text) {
    // Better splitting for dialogue: check for newlines or standard punctuation
    if (text.contains('Client:') || text.contains('Agence:')) {
      // Ensure we split before tags if they are inline
      String formatted = text
          .replaceAll('Client:', '\nClient:')
          .replaceAll('Agence:', '\nAgence:');

      // Split by line if it looks like a script
      return formatted
          .split(RegExp(r'\n+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    RegExp re = RegExp(r"(?<=[.!?])\s+");
    return text.split(re);
  }

  // Helper for robust string comparison
  String _normalizeText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _playSentence(int index) async {
    if (index < 0 || index >= _sentences.length) return;

    setState(() {
      _currentSentenceIndex = index;
      _isPlaying = true;
      _isAudioLoading = true;
    });

    String sentence = _sentences[index];
    String spokenText = sentence; // Text to be spoken

    // Voice switching logic
    if (sentence.toLowerCase().startsWith('client:') &&
        _selectedClientVoice != null) {
      await _ttsService.flutterTts
          .setVoice(Map<String, String>.from(_selectedClientVoice!));
      spokenText = sentence.replaceAll(
          RegExp(r'^Client\s*:\s*', caseSensitive: false), '');
    } else if (sentence.toLowerCase().startsWith('agence:') &&
        _selectedAgenceVoice != null) {
      await _ttsService.flutterTts
          .setVoice(Map<String, String>.from(_selectedAgenceVoice!));
      spokenText = sentence.replaceAll(
          RegExp(r'^Agence\s*:\s*', caseSensitive: false), '');
    }

    await _ttsService.setRate(_playbackRate);
    await Future.delayed(
        const Duration(milliseconds: 100)); // Slight delay for voice switch
    await _ttsService.speak(spokenText);

    if (mounted) {
      setState(() {
        _isAudioLoading = false;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_sentences.isEmpty) return;

    if (_isPlaying) {
      await _ttsService.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      int indexToPlay = _currentSentenceIndex == -1 ? 0 : _currentSentenceIndex;
      _playSentence(indexToPlay);
    }
  }

  Future<void> _nextSentence() async {
    if (_currentSentenceIndex < _sentences.length - 1) {
      await _playSentence(_currentSentenceIndex + 1);
    } else {
      setState(() {
        _isPlaying = false;
        _currentSentenceIndex = -1;
      });
    }
  }

  Future<void> _prevSentence() async {
    if (_currentSentenceIndex > 0) {
      await _playSentence(_currentSentenceIndex - 1);
    } else {
      await _playSentence(0);
    }
  }

  void _checkAnswers() {
    if (_exerciseData == null) return;

    setState(() {
      _checked = true;
      final questions = _exerciseData!['questions'] as List;
      for (int i = 0; i < questions.length; i++) {
        final correctAnswer = questions[i]['answer'].toString();
        final selected = _selectedAnswers[i] ?? '';
        _results[i] = _normalizeText(selected) == _normalizeText(correctAnswer);
      }
      _showTranscript = true; // Show text after checking
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Écouter (Listening)'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Controls Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedTopic,
                      decoration: const InputDecoration(
                        labelText: 'Choose a Topic',
                        border: OutlineInputBorder(),
                      ),
                      items: _topics.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTopic = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Voice Selectors (Visible only for Dialogue)
                    if (_selectedTopic.startsWith('Dialogue')) ...[
                      // City Selector
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'Choose Specific City',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: ['Paris', 'Bruxelles', 'Liège'].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCity = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Voice Selectors
                      Row(
                        children: [
                          Expanded(
                            child:
                                DropdownButtonFormField<Map<dynamic, dynamic>>(
                              value: _selectedClientVoice,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Client Voice',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              items: _frenchVoices.isEmpty
                                  ? [
                                      const DropdownMenuItem(
                                          value: null,
                                          child: Text('Default Voice'))
                                    ]
                                  : _frenchVoices.map((v) {
                                      return DropdownMenuItem(
                                        value: v,
                                        child: Text(v['name'].toString(),
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                              onChanged: _frenchVoices.isEmpty
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedClientVoice = val;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                DropdownButtonFormField<Map<dynamic, dynamic>>(
                              value: _selectedAgenceVoice,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Agence Voice',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              items: _frenchVoices.isEmpty
                                  ? [
                                      const DropdownMenuItem(
                                          value: null,
                                          child: Text('Default Voice'))
                                    ]
                                  : _frenchVoices.map((v) {
                                      return DropdownMenuItem(
                                        value: v,
                                        child: Text(v['name'].toString(),
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                              onChanged: _frenchVoices.isEmpty
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _selectedAgenceVoice = val;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_frenchVoices.isEmpty)
                        TextButton.icon(
                          onPressed: _initVoices,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Try Reloading Voices'),
                        )
                      else
                        const Text(
                          'Note: Available voices depend on your device and browser settings.',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateExercise,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(_isLoading
                            ? 'Generating...'
                            : 'Generate New Exercise'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_exerciseData != null) ...[
              // Audio Player Controls
              Card(
                color: AppTheme.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Rate Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Speed: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          DropdownButton<double>(
                            value: _playbackRate,
                            dropdownColor: AppTheme.surfaceLight,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            iconEnabledColor: Colors.white,
                            underline: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            items: [0.5, 0.75, 0.9, 1.0, 1.25, 1.5]
                                .map((r) => DropdownMenuItem(
                                    value: r, child: Text('${r}x')))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _playbackRate = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 32,
                            color: Colors.white,
                            icon: const Icon(Icons.skip_previous_rounded),
                            onPressed: _currentSentenceIndex > 0
                                ? _prevSentence
                                : null,
                          ),
                          const SizedBox(width: 24),
                          FloatingActionButton(
                            onPressed: _isAudioLoading ? null : _togglePlay,
                            backgroundColor: _isPlaying
                                ? AppTheme.warning
                                : AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            child: _isAudioLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 36),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            iconSize: 32,
                            color: Colors.white,
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed:
                                _currentSentenceIndex < _sentences.length - 1
                                    ? _nextSentence
                                    : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Timeline Slider
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayColor:
                                  AppTheme.primary.withValues(alpha: 0.2),
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8.0),
                            ),
                            child: Slider(
                              value: (_currentSentenceIndex == -1
                                      ? 0
                                      : _currentSentenceIndex)
                                  .toDouble()
                                  .clamp(
                                      0.0,
                                      (_sentences.length - 1)
                                          .toDouble()), // Ensure within bounds
                              min: 0.0,
                              max: (_sentences.length - 1).toDouble() > 0
                                  ? (_sentences.length - 1).toDouble()
                                  : 1.0,
                              divisions: (_sentences.length - 1) > 0
                                  ? (_sentences.length - 1)
                                  : 1,
                              onChanged: (val) {
                                _playSentence(val.round());
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isPlaying
                                      ? 'Sentence ${_currentSentenceIndex + 1}'
                                      : 'Paused',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  'Total: ${_sentences.length}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Listen specifically to the text and answer the questions below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Transcript Toggle
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showTranscript = !_showTranscript;
                  });
                },
                icon: Icon(
                    _showTranscript ? Icons.visibility_off : Icons.visibility),
                label: Text(
                    _showTranscript ? 'Hide Transcript' : 'Show Transcript'),
              ),

              if (_showTranscript)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: _sentences.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final sentence = entry.value;
                        final isPlaying = idx == _currentSentenceIndex;
                        return WidgetSpan(
                          child: GestureDetector(
                            onTap: () => _playSentence(idx),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? AppTheme.accent.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 2),
                              child: Text(
                                '$sentence ',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: isPlaying
                                      ? AppTheme.primary
                                      : const Color(0xFF1E293B),
                                  fontWeight: isPlaying
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const Divider(height: 48),

              // Questions
              ...List.generate((_exerciseData!['questions'] as List).length,
                  (index) {
                final question = _exerciseData!['questions'][index];
                final options = question['options'] as List;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${question['question']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...options.map((opt) {
                          final String optStr = opt.toString();
                          final String selectedStr =
                              (_selectedAnswers[index] ?? '');
                          final String correctStr =
                              question['answer'].toString();

                          // Use normalized for correctness check
                          final bool isThisOptionCorrect =
                              _normalizeText(optStr) ==
                                  _normalizeText(correctStr);
                          final bool isThisOptionSelected =
                              _selectedAnswers[index] == opt;

                          Color? tileColor;
                          if (_checked) {
                            if (isThisOptionCorrect) {
                              tileColor = Colors.green.withValues(alpha: 0.1);
                            }
                            if (isThisOptionSelected && !isThisOptionCorrect) {
                              tileColor = Colors.red.withValues(alpha: 0.1);
                            }
                          }

                          return RadioListTile<String>(
                            title: Text(
                              opt,
                              style: TextStyle(
                                color: _checked && isThisOptionCorrect
                                    ? Colors.green
                                    : (_checked &&
                                            isThisOptionSelected &&
                                            !isThisOptionCorrect
                                        ? Colors.red
                                        : null),
                                fontWeight: _checked && isThisOptionCorrect
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                            value: opt,
                            groupValue: _selectedAnswers[index],
                            activeColor: AppTheme.primary,
                            tileColor: tileColor,
                            onChanged: _checked
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedAnswers[index] = val!;
                                    });
                                  },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              if (!_checked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAnswers.length ==
                            (_exerciseData!['questions'] as List).length
                        ? _checkAnswers
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Check Answers'),
                  ),
                ),
            ],

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: SpinKitWave(color: AppTheme.primary, size: 30),
              ),
          ],
        ),
      ),
    );
  }
}
