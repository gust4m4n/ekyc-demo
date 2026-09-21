import 'dart:io';

import 'ktp_data.dart';

/// Outcome of a single KTP scan.
class KtpScanResult {
  const KtpScanResult({
    required this.recognized,
    required this.data,
    required this.rawText,
    required this.imagePath,
    this.portraitPath,
  });

  /// Whether enough KTP keywords were found to treat the image as a KTP.
  final bool recognized;

  final KtpData data;

  /// Everything OCR read, useful for debugging a bad extraction.
  final String rawText;

  /// Orientation-corrected copy of the captured card.
  final String imagePath;

  /// Cropped portrait photo, `null` when no face was found on the card.
  final String? portraitPath;

  List<KtpField> get fields => data.fields;
  bool get hasFields => data.isNotEmpty;
  bool get hasPortrait => portraitPath != null;

  File get imageFile => File(imagePath);
  File? get portraitFile {
    final path = portraitPath;
    return path == null ? null : File(path);
  }

  /// Deletes the temporary files this scan produced.
  void dispose() {
    _delete(imagePath);
    _delete(portraitPath);
  }

  static void _delete(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best effort cleanup of the temporary capture.
    }
  }
}
