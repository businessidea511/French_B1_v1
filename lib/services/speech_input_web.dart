import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// French speech-to-text through the browser's SpeechRecognition (Chrome, Edge, Safari).
class SpeechInput {
  static JSFunction? get _ctor =>
      (globalContext['SpeechRecognition'] ?? globalContext['webkitSpeechRecognition']) as JSFunction?;

  static bool get supported {
    try {
      return _ctor != null;
    } catch (_) {
      return false;
    }
  }

  JSObject? _rec;

  /// Listens for one French sentence. [onText] gets the text heard so far; [onEnd] runs when listening stops.
  bool start({
    required void Function(String text, bool isFinal) onText,
    required void Function() onEnd,
    void Function(String error)? onError,
  }) {
    try {
      final ctor = _ctor;
      if (ctor == null) return false;
      final rec = ctor.callAsConstructor<JSObject>();
      rec['lang'] = 'fr-FR'.toJS;
      rec['interimResults'] = true.toJS;
      rec['continuous'] = false.toJS;
      rec['maxAlternatives'] = 1.toJS;
      rec['onresult'] = ((JSObject event) {
        final results = event['results'] as JSObject;
        final count = (results['length'] as JSNumber).toDartInt;
        final text = StringBuffer();
        var allFinal = true;
        for (var i = 0; i < count; i++) {
          final result = results.callMethod<JSObject>('item'.toJS, i.toJS);
          final alt = result.callMethod<JSObject>('item'.toJS, 0.toJS);
          text.write((alt['transcript'] as JSString).toDart);
          if (!(result['isFinal'] as JSBoolean).toDart) allFinal = false;
        }
        onText(text.toString().trim(), allFinal);
      }).toJS;
      rec['onerror'] = ((JSObject event) {
        onError?.call('${(event['error'] as JSString?)?.toDart}');
      }).toJS;
      rec['onend'] = (() {
        _rec = null;
        onEnd();
      }).toJS;
      rec.callMethod<JSAny?>('start'.toJS);
      _rec = rec;
      return true;
    } catch (_) {
      return false;
    }
  }

  void stop() {
    try {
      _rec?.callMethod<JSAny?>('stop'.toJS);
    } catch (_) {}
  }
}
