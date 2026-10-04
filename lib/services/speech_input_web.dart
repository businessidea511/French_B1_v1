import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// French speech-to-text through the browser's SpeechRecognition (Chrome, Edge, Safari).
///
/// Learners speak slowly and stop to think, but the browser ends listening
/// after a short pause. So listening restarts by itself and keeps the words
/// already heard, until the learner taps the microphone again or stays
/// silent for [silenceLimit].
class SpeechInput {
  static const silenceLimit = Duration(seconds: 10);

  static JSFunction? get _ctor =>
      (globalContext['SpeechRecognition'] ?? globalContext['webkitSpeechRecognition']) as JSFunction?;

  static bool get supported {
    try {
      return _ctor != null;
    } catch (_) {
      return false;
    }
  }

  /// Android Chrome repeats words in continuous mode: there, one phrase per session.
  static bool get _continuousWorks {
    try {
      final ua = ((globalContext['navigator'] as JSObject)['userAgent'] as JSString).toDart;
      return !ua.contains('Android');
    } catch (_) {
      return true;
    }
  }

  JSObject? _rec;
  bool _wanted = false; // the learner wants to keep speaking
  String _committed = ''; // text of the sessions already finished
  String _session = ''; // text of the current session
  DateTime _lastHeard = DateTime.now();
  Timer? _silence;
  void Function(String text, bool isFinal)? _onText;
  void Function()? _onEnd;
  void Function(String error)? _onError;

  static String _join(String a, String b) => a.isEmpty ? b : (b.isEmpty ? a : '$a $b');

  /// Listens to French until [stop] or a long silence. [onText] gets all the text heard so far.
  bool start({
    required void Function(String text, bool isFinal) onText,
    required void Function() onEnd,
    void Function(String error)? onError,
  }) {
    if (_ctor == null) return false;
    _onText = onText;
    _onEnd = onEnd;
    _onError = onError;
    _committed = '';
    _session = '';
    _lastHeard = DateTime.now();
    _wanted = true;
    if (!_startSession()) {
      _wanted = false;
      return false;
    }
    _silence?.cancel();
    _silence = Timer.periodic(const Duration(seconds: 1), (_) {
      if (DateTime.now().difference(_lastHeard) > silenceLimit) stop();
    });
    return true;
  }

  bool _startSession() {
    try {
      final rec = _ctor!.callAsConstructor<JSObject>();
      rec['lang'] = 'fr-FR'.toJS;
      rec['interimResults'] = true.toJS;
      rec['continuous'] = _continuousWorks.toJS;
      rec['maxAlternatives'] = 1.toJS;
      rec['onresult'] = ((JSObject event) {
        final results = event['results'] as JSObject;
        final count = (results['length'] as JSNumber).toDartInt;
        var text = '';
        var allFinal = true;
        for (var i = 0; i < count; i++) {
          final result = results.callMethod<JSObject>('item'.toJS, i.toJS);
          final alt = result.callMethod<JSObject>('item'.toJS, 0.toJS);
          text = _join(text, (alt['transcript'] as JSString).toDart.trim());
          if (!(result['isFinal'] as JSBoolean).toDart) allFinal = false;
        }
        _session = text;
        _lastHeard = DateTime.now();
        _onText?.call(_join(_committed, _session), allFinal && !_wanted);
      }).toJS;
      rec['onerror'] = ((JSObject event) {
        final error = '${(event['error'] as JSString?)?.toDart}';
        // Silence or a restart are normal while the learner thinks.
        if (error == 'no-speech' || error == 'aborted') return;
        if (error == 'not-allowed' || error == 'service-not-allowed' || error == 'audio-capture') _wanted = false;
        _onError?.call(error);
      }).toJS;
      rec['onend'] = (() {
        if (!identical(_rec, rec)) return;
        _committed = _join(_committed, _session);
        _session = '';
        if (_wanted) {
          // Paused to think: keep listening.
          Timer(const Duration(milliseconds: 120), () {
            if (_wanted && identical(_rec, rec) && !_startSession()) _finish();
          });
        } else {
          _finish();
        }
      }).toJS;
      rec.callMethod<JSAny?>('start'.toJS);
      _rec = rec;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _finish() {
    _wanted = false;
    _silence?.cancel();
    _silence = null;
    _rec = null;
    _onEnd?.call();
  }

  void stop() {
    if (!_wanted && _rec == null) return;
    _wanted = false;
    try {
      _rec?.callMethod<JSAny?>('stop'.toJS);
    } catch (_) {
      _finish();
    }
  }
}
