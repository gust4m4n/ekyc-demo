/// Reusable on-device Indonesian KTP scanner.
///
/// Three layers, pick the one that fits the host app:
///
/// * [KtpScannerPage] — the whole flow (intro, camera, OCR, result).
/// * [KtpCameraPage] + [KtpScanner] — bring your own UI around the engine.
/// * [KtpScanner.parseLines] — feed your own OCR output into the parser.
library;

export 'src/models/ktp_capture.dart';
export 'src/models/ktp_data.dart';
export 'src/models/ktp_scan_result.dart';
export 'src/ocr/ktp_parser.dart' show looksLikeKtp, parseKtp, KtpParseOutcome;
export 'src/ocr/ktp_scanner.dart';
export 'src/ocr/ocr_line.dart';
export 'src/ui/guideline_list.dart';
export 'src/ui/ktp_camera_page.dart';
export 'src/ui/ktp_result_view.dart';
export 'src/ui/ktp_scanner_colors.dart';
export 'src/ui/ktp_scanner_page.dart';
