import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_shrink.dart';

/// Takes or chooses photos, small enough to send to the AI.
///
/// On the web the picker's own resizing decodes the whole photo in memory,
/// which can crash the page on older phones. So the photo is picked as it
/// is and made small by the browser without decoding it at full size.
///
/// Photos are taken with a camera inside the page: the phone's own camera
/// app sends the browser to the background, and Android often closes the
/// page to free memory (the app then starts again on the home page). When
/// the browser gives no camera access, the phone's camera is used, and a
/// mark is kept while it is open, so the app can explain a restart.
class PhotoPicker {
  static const _cameraKey = 'camera_opened_at';

  static Future<List<Uint8List>> pick({
    required bool camera,
    bool multiple = false,
    int maxSide = 1400,
    int quality = 60,
  }) async {
    if (camera && kIsWeb) {
      // The camera inside the page first: the app stays on screen.
      final (available, photo) = await takePhotoInPage(maxSide, quality / 100);
      if (available) return [if (photo != null) photo];
    }
    final picker = ImagePicker();
    final prefs = await SharedPreferences.getInstance();
    if (camera) await prefs.setInt(_cameraKey, DateTime.now().millisecondsSinceEpoch);
    try {
      // Native apps resize well themselves; on the web, shrink below.
      final side = kIsWeb ? null : maxSide.toDouble();
      final q = kIsWeb ? null : quality;
      final List<XFile> files;
      if (camera) {
        final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: side, maxHeight: side, imageQuality: q);
        files = photo == null ? [] : [photo];
      } else if (multiple) {
        files = await picker.pickMultiImage(maxWidth: side, maxHeight: side, imageQuality: q);
      } else {
        final photo = await picker.pickImage(source: ImageSource.gallery, maxWidth: side, maxHeight: side, imageQuality: q);
        files = photo == null ? [] : [photo];
      }
      return [
        for (final f in files) await _small(await f.readAsBytes(), maxSide, quality),
      ];
    } finally {
      if (camera) await prefs.remove(_cameraKey);
    }
  }

  static Future<Uint8List> _small(Uint8List bytes, int maxSide, int quality) async {
    if (!kIsWeb) return bytes;
    return await shrinkImage(bytes, maxSide, quality / 100) ?? bytes;
  }

  /// True (once) when the app starts again just after the camera was opened:
  /// the phone closed the page while the camera was open.
  static Future<bool> closedByCamera() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final at = prefs.getInt(_cameraKey);
      if (at == null) return false;
      await prefs.remove(_cameraKey);
      return DateTime.now().millisecondsSinceEpoch - at < const Duration(minutes: 5).inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  /// "image/png" or "image/jpeg", from the first bytes.
  static String mimeOf(Uint8List bytes) =>
      bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
          ? 'image/png'
          : 'image/jpeg';
}
