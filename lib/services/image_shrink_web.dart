import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Shrinks a photo in the browser (window.plShrinkImage in web/index.html)
/// to at most [maxSide] pixels, as JPEG. Null if the browser cannot.
Future<Uint8List?> shrinkImage(Uint8List bytes, int maxSide, double quality) async {
  try {
    if (!globalContext.has('plShrinkImage')) return null;
    final promise = globalContext.callMethod<JSPromise<JSUint8Array?>>(
        'plShrinkImage'.toJS, bytes.toJS, maxSide.toJS, quality.toJS);
    return (await promise.toDart)?.toDart;
  } catch (_) {
    return null;
  }
}
