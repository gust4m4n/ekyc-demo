import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ktp_capture.dart';
import '../models/ktp_scan_result.dart';
import '../ocr/ktp_scanner.dart';
import 'guideline_list.dart';
import 'ktp_camera_page.dart';
import 'ktp_result_view.dart';
import 'ktp_scanner_colors.dart';

/// Drop-in KTP scanning flow: intro, capture, OCR and result.
///
/// Push it and await a [KtpScanResult]:
///
/// ```dart
/// final result = await KtpScannerPage.open(context);
/// ```
///
/// The result owns two temporary files ([KtpScanResult.imagePath] and
/// [KtpScanResult.portraitPath]); copy what you need, then call
/// [KtpScanResult.dispose].
class KtpScannerPage extends StatefulWidget {
  const KtpScannerPage({
    super.key,
    this.title = 'Scan ID card',
    this.confirmLabel = 'Use this data',
    this.onConfirm,
    this.returnsResult = false,
  });

  final String title;

  final String confirmLabel;

  /// Called when the user accepts the extracted data. When both this and
  /// [returnsResult] are unset the page stays open as a standalone demo.
  final ValueChanged<KtpScanResult>? onConfirm;

  /// Pops the route with the accepted [KtpScanResult].
  final bool returnsResult;

  /// Pushes the flow and resolves with the accepted result, or `null` when
  /// the user leaves without confirming.
  static Future<KtpScanResult?> open(
    BuildContext context, {
    String title = 'Scan ID card',
    String confirmLabel = 'Use this data',
  }) {
    return Navigator.of(context).push<KtpScanResult>(
      MaterialPageRoute(
        builder: (_) => KtpScannerPage(
          title: title,
          confirmLabel: confirmLabel,
          returnsResult: true,
        ),
      ),
    );
  }

  @override
  State<KtpScannerPage> createState() => _KtpScannerPageState();
}

class _KtpScannerPageState extends State<KtpScannerPage> {
  final KtpScanner _scanner = KtpScanner();

  KtpScanResult? _result;
  String? _error;
  bool _processing = false;
  bool _handedOver = false;

  @override
  void dispose() {
    _scanner.dispose();
    if (!_handedOver) _result?.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final capture = await Navigator.of(context).push<KtpCapture>(
      MaterialPageRoute(builder: (_) => const KtpCameraPage()),
    );
    if (capture == null || !mounted) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final result = await _scanner.scanCapture(capture);
      if (!mounted) {
        result.dispose();
        return;
      }
      _result?.dispose();
      setState(() {
        _processing = false;
        _result = result;
        _error = _messageFor(result);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'The image could not be processed. Please try again.';
      });
    } finally {
      _deleteCapture(capture.path);
    }
  }

  String? _messageFor(KtpScanResult result) {
    if (result.rawText.trim().isEmpty) {
      return 'No text could be read. Retake the card in better lighting.';
    }
    if (!result.hasFields) {
      return 'Text was read but no KTP field was recognized. Retake the '
          'photo with the card filling the frame.';
    }
    if (!result.recognized) {
      return 'This does not look like a KTP. Double-check the extracted '
          'data below.';
    }
    return null;
  }

  void _deleteCapture(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best effort cleanup of the raw camera file.
    }
  }

  void _reset() {
    _result?.dispose();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _confirm(KtpScanResult result) {
    _handedOver = true;
    widget.onConfirm?.call(result);
    if (widget.returnsResult) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final canConfirm =
        result != null &&
        result.hasFields &&
        (widget.returnsResult || widget.onConfirm != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (result != null)
            IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Clear result',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _processing
                  ? const _ProcessingView()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: result == null
                          ? _buildIntro()
                          : _buildResult(result),
                    ),
            ),
            _buildActionBar(result, canConfirm),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIntro() => [
    const _Hero(),
    const SizedBox(height: 24),
    if (_error != null) ...[
      KtpInfoBanner(message: _error!, tone: KtpInfoTone.danger),
      const SizedBox(height: 20),
    ],
    const GuidelineList(
      title: 'Tips for an accurate read',
      items: [
        'Use a flat surface with a plain background.',
        'Fill the frame with the card, leaving no part cut off.',
        'Avoid shadows, glare and blur.',
        'Shoot straight on, not at an angle.',
      ],
    ),
    const SizedBox(height: 20),
    const KtpInfoBanner(
      message:
          'Text recognition and photo cropping both run on this device. '
          'Nothing is sent to a server.',
      tone: KtpInfoTone.neutral,
    ),
  ];

  List<Widget> _buildResult(KtpScanResult result) => [
    if (_error != null) ...[
      KtpInfoBanner(message: _error!, tone: KtpInfoTone.danger),
      const SizedBox(height: 20),
    ],
    KtpResultView(result: result),
  ];

  Widget _buildActionBar(KtpScanResult? result, bool canConfirm) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: const BoxDecoration(
      color: KtpScannerColors.surface,
      border: Border(top: BorderSide(color: KtpScannerColors.border)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canConfirm) ...[
          ElevatedButton.icon(
            onPressed: () => _confirm(result!),
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.confirmLabel),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _processing ? null : _scan,
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Scan again'),
          ),
        ] else
          ElevatedButton.icon(
            onPressed: _processing ? null : _scan,
            icon: const Icon(Icons.document_scanner_rounded),
            label: Text(result == null ? 'Start scan' : 'Scan again'),
          ),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: KtpScannerColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KtpScannerColors.border),
          ),
          child: const Icon(
            Icons.badge_rounded,
            size: 64,
            color: KtpScannerColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Scan a KTP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KtpScannerColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Photograph the card and its data and the holder\'s photo are '
          'extracted automatically, using on-device text recognition.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: KtpScannerColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Reading the card...',
            style: TextStyle(color: KtpScannerColors.muted),
          ),
        ],
      ),
    );
  }
}

enum KtpInfoTone { neutral, danger }

/// Small inline notice used by the scanner flow.
class KtpInfoBanner extends StatelessWidget {
  const KtpInfoBanner({super.key, required this.message, required this.tone});

  final String message;
  final KtpInfoTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == KtpInfoTone.danger;
    final color = danger ? KtpScannerColors.danger : KtpScannerColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            danger ? Icons.error_outline_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.45, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
