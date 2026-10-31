import 'dart:typed_data';

/// Not on the web: the picker already made the photo small.
Future<Uint8List?> shrinkImage(Uint8List bytes, int maxSide, double quality) async => null;

/// Not on the web: no in-app camera, the picker opens the phone's camera.
Future<(bool available, Uint8List? photo)> takePhotoInPage(int maxSide, double quality) async => (false, null);
