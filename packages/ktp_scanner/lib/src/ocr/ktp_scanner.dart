import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ktp_capture.dart';
import '../models/ktp_data.dart';
import '../models/ktp_scan_result.dart';
import 'image_ops.dart';
import 'ktp_parser.dart';
import 'ocr_line.dart';
import 'portrait_extractor.dart';

/// Reads an Indonesian KTP from a photo, entirely on device.
///
/// Create one instance, call [scan] as often as needed, then [dispose].
class KtpScanner {
  KtpScanner({bool extractPortrait = true})
    : _extractPortrait = extractPortrait;

  final bool _extractPortrait;

  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final PortraitExtractor _portraits = PortraitExtractor();

  /// Reads the card in [capture], cropped to the guide frame it was taken in.
  Future<KtpScanResult> scanCapture(
    KtpCapture capture, {
    Directory? workingDir,
  }) => scan(File(capture.path), guide: capture.guide, workingDir: workingDir);

  /// Runs OCR on [image] and, unless disabled, crops the holder's photo.
  ///
  /// [guide] trims the photo down to the card before anything is recognized,
  /// expressed as fractions of the upright image.
  ///
  /// Temporary files are written into [workingDir], defaulting to the system
  /// temp directory. Call [KtpScanResult.dispose] to remove them.
  Future<KtpScanResult> scan(
    File image, {
    Rect? guide,
    Directory? workingDir,
  }) async {
    final dir = workingDir ?? Directory.systemTemp;

    // Bake the EXIF rotation in and cut the card out first, so the recognized
    // boxes and the portrait crop share the coordinate space of the image the
    // user is shown.
    final normalized = await normalizeOrientation(
      source: image.path,
      workingDir: dir,
      cropFraction: guide,
    );
    final path = normalized?.path ?? image.path;

    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(path),
    );

    final outcome = parseKtp(
      lines: [
        for (final block in recognized.blocks)
          for (final line in block.lines)
            OcrLine(text: line.text, box: line.boundingBox),
      ],
    );

    String? portraitPath;
    if (_extractPortrait && normalized != null) {
      portraitPath = await _portraits.extract(
        imagePath: path,
        imageSize: normalized.size,
        workingDir: dir,
      );
    }

    return KtpScanResult(
      recognized: outcome.recognized,
      data: outcome.data,
      rawText: recognized.text,
      imagePath: path,
      portraitPath: portraitPath,
    );
  }

  /// Parses already recognized lines, for tests or a custom OCR pipeline.
  static KtpData parseLines(List<OcrLine> lines) => parseKtp(lines: lines).data;

  Future<void> dispose() async {
    await _recognizer.close();
    await _portraits.dispose();
  }
}
