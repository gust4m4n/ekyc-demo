import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Quality every stored photo is re-encoded at.
const int kJpegQuality = 80;

/// Upright bounds for the two selfies, which are shot portrait.
const int kSelfieMaxWidth = 768;
const int kSelfieMaxHeight = 1024;

/// Upright bounds for the KTP, which is shot landscape.
const int kKtpMaxWidth = 1024;
const int kKtpMaxHeight = 768;

/// Re-encodes [source] as a JPEG at [kJpegQuality], shrunk to fit inside
/// [maxWidth] x [maxHeight] with its aspect ratio kept. Photos already within
/// those bounds are re-encoded but not scaled.
///
/// [mirror] flips the photo horizontally, which is what a front-camera shot
/// needs to match the mirrored preview the user framed it in.
///
/// Returns [source] untouched when it cannot be decoded, so a capture is never
/// lost to a compression failure.
Future<File> compressToJpeg(
  File source, {
  required int maxWidth,
  required int maxHeight,
  bool mirror = false,
  bool deleteSource = false,
}) async {
  final Uint8List bytes;
  try {
    bytes = await source.readAsBytes();
  } catch (_) {
    return source;
  }

  final encoded = await Isolate.run(
    () => _resizeAndEncode(bytes, maxWidth, maxHeight, mirror),
  );
  if (encoded == null) return source;

  final target = File(
    '${source.parent.path}/ekyc_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await target.writeAsBytes(encoded, flush: true);
  if (deleteSource) await deleteQuietly(source);
  return target;
}

/// Removes a temporary capture without ever surfacing its path in a log.
Future<void> deleteQuietly(File file) async {
  try {
    if (file.existsSync()) await file.delete();
  } catch (_) {
    // Media cleanup is best effort.
  }
}

Uint8List? _resizeAndEncode(
  Uint8List bytes,
  int maxWidth,
  int maxHeight,
  bool mirror,
) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // EXIF rotation has to be baked in first, or the bounds land on the wrong
  // axis for a photo the camera stored sideways.
  var upright = img.bakeOrientation(decoded);
  if (mirror) upright = img.flipHorizontal(upright);

  final scale = [
    1.0,
    maxWidth / upright.width,
    maxHeight / upright.height,
  ].reduce((a, b) => a < b ? a : b);

  final sized = scale < 1
      ? img.copyResize(
          upright,
          width: (upright.width * scale).round(),
          height: (upright.height * scale).round(),
          interpolation: img.Interpolation.average,
        )
      : upright;

  return img.encodeJpg(sized, quality: kJpegQuality);
}
