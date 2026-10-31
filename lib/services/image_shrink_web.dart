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

/// The camera inside the page (window.plTakePhoto in web/index.html).
/// (false, null) when the browser has no camera access: use the phone's camera.
/// (true, null) when the learner closed it. (true, photo) with a JPEG photo.
Future<(bool available, Uint8List? photo)> takePhotoInPage(int maxSide, double quality) async {
  try {
    if (!globalContext.has('plTakePhoto')) return (false, null);
    final promise = globalContext.callMethod<JSPromise<JSObject>>('plTakePhoto'.toJS, maxSide.toJS, quality.toJS);
    final result = await promise.toDart;
    if (result.has('unavailable')) return (false, null);
    final bytes = result['bytes'] as JSUint8Array?;
    return (true, bytes?.toDart);
  } catch (_) {
    return (false, null);
  }
}
