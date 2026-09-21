import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// An upright copy of a captured photo together with its pixel size.
typedef NormalizedImage = ({String path, Size size});

/// Rewrites [source] so its pixels are upright and its EXIF orientation is
/// neutral, which keeps ML Kit boxes aligned with the pixels we later crop.
///
/// When [cropFraction] is given the photo is also cut down to that region,
/// expressed as fractions of the upright image, in the same decode pass.
///
/// Returns `null` when the photo cannot be decoded.
Future<NormalizedImage?> normalizeOrientation({
  required String source,
  required Directory workingDir,
  Rect? cropFraction,
}) async {
  final bytes = await File(source).readAsBytes();
  final crop = cropFraction;
  final baked = await Isolate.run(
    () => _bake(bytes, crop?.left, crop?.top, crop?.right, crop?.bottom),
  );
  if (baked == null) return null;

  final target = File(
    '${workingDir.path}/ktp_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await target.writeAsBytes(baked.bytes, flush: true);

  return (
    path: target.path,
    size: Size(baked.width.toDouble(), baked.height.toDouble()),
  );
}

/// Crops [rect] out of [source] and writes it as a JPEG into [workingDir].
///
/// Returns `null` when the image cannot be decoded.
Future<String?> cropRegion({
  required String source,
  required Rect rect,
  required Directory workingDir,
}) async {
  final bytes = await File(source).readAsBytes();
  final left = rect.left.round();
  final top = rect.top.round();
  final width = rect.width.round();
  final height = rect.height.round();

  final cropped = await Isolate.run(
    () => _crop(bytes, left, top, width, height),
  );
  if (cropped == null) return null;

  final target = File(
    '${workingDir.path}/ktp_portrait_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await target.writeAsBytes(cropped, flush: true);
  return target.path;
}

({Uint8List bytes, int width, int height})? _bake(
  Uint8List bytes,
  double? left,
  double? top,
  double? right,
  double? bottom,
) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var upright = img.bakeOrientation(decoded);

  if (left != null && top != null && right != null && bottom != null) {
    final x = (left * upright.width).round().clamp(0, upright.width - 1);
    final y = (top * upright.height).round().clamp(0, upright.height - 1);
    final width = ((right - left) * upright.width).round().clamp(
      1,
      upright.width - x,
    );
    final height = ((bottom - top) * upright.height).round().clamp(
      1,
      upright.height - y,
    );

    // A degenerate frame means the mapping was off; keep the whole photo.
    if (width >= 64 && height >= 64) {
      upright = img.copyCrop(upright, x: x, y: y, width: width, height: height);
    }
  }

  return (
    bytes: img.encodeJpg(upright, quality: 92),
    width: upright.width,
    height: upright.height,
  );
}

Uint8List? _crop(Uint8List bytes, int x, int y, int width, int height) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  return img.encodeJpg(
    img.copyCrop(decoded, x: x, y: y, width: width, height: height),
    quality: 92,
  );
}
