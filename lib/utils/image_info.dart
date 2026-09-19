import 'dart:io';
import 'dart:ui' as ui;

/// Longest edge of an image in pixels, or 0 when it cannot be decoded.
Future<int> longestEdgeOf(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final longest = image.width > image.height ? image.width : image.height;
    image.dispose();
    codec.dispose();
    return longest;
  } catch (_) {
    return 0;
  }
}
