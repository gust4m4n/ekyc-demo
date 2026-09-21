import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'image_ops.dart';

/// Locates the portrait photo printed on a KTP and crops it out.
///
/// The card photo is the only face on the document, so the largest detected
/// face is expanded into an ID-photo sized frame (head plus shoulders).
class PortraitExtractor {
  PortraitExtractor()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.03,
        ),
      );

  final FaceDetector _detector;

  /// Returns the path of the cropped portrait, or `null` when the card holds
  /// no detectable face.
  Future<String?> extract({
    required String imagePath,
    required Size imageSize,
    required Directory workingDir,
  }) async {
    final faces = await _detector.processImage(
      InputImage.fromFilePath(imagePath),
    );
    if (faces.isEmpty) return null;

    final face = faces.reduce(
      (a, b) =>
          a.boundingBox.width * a.boundingBox.height >
              b.boundingBox.width * b.boundingBox.height
          ? a
          : b,
    );

    final frame = _portraitFrame(face.boundingBox, imageSize);
    if (frame.width < 24 || frame.height < 24) return null;

    return cropRegion(source: imagePath, rect: frame, workingDir: workingDir);
  }

  Future<void> dispose() => _detector.close();

  /// Expands the face box into a 3:4 head-and-shoulders frame, clamped to the
  /// image so the crop never runs off the card.
  Rect _portraitFrame(Rect face, Size image) {
    final height = face.height * 2.4;
    final width = height * 0.78;

    var left = face.center.dx - width / 2;
    var top = face.top - face.height * 0.6;

    left = left.clamp(0.0, math.max(0.0, image.width - width));
    top = top.clamp(0.0, math.max(0.0, image.height - height));

    return Rect.fromLTWH(
      left,
      top,
      math.min(width, image.width - left),
      math.min(height, image.height - top),
    );
  }
}
