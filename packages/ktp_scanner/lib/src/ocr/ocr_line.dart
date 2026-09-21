import 'dart:ui';

/// A single line recognized by OCR together with its position on the image.
class OcrLine {
  const OcrLine({required this.text, required this.box});

  final String text;
  final Rect box;
}
