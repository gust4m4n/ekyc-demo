import 'dart:ui';

/// A photo taken by [KtpCameraPage] together with the guide frame the user
/// lined the card up with.
class KtpCapture {
  const KtpCapture({required this.path, this.guide});

  /// Raw file written by the camera.
  final String path;

  /// The guide frame expressed as fractions of the photo (0..1), or `null`
  /// when the preview geometry was unknown. The scanner crops to it before
  /// running OCR so only the card reaches the recognizer.
  final Rect? guide;
}
