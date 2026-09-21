import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
// The package ships its own guideline widget; this app uses its branded one.
import 'package:ktp_scanner/ktp_scanner.dart' hide GuidelineList;

import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/image_compressor.dart';
import '../utils/validators.dart';
import '../widgets/guideline_list.dart';
import '../widgets/step_scaffold.dart';
import 'ktp_data_screen.dart';

/// Step 5 — photograph the KTP and read it with the bundled `ktp_scanner`.
///
/// OCR runs entirely on device; the extracted fields are handed to the next
/// step, where the user can correct them.
class KtpScanScreen extends StatefulWidget {
  const KtpScanScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<KtpScanScreen> createState() => _KtpScanScreenState();
}

class _KtpScanScreenState extends State<KtpScanScreen> {
  final KtpScanner _scanner = KtpScanner();

  KtpScanResult? _result;

  /// The card image actually stored: OCR runs at full resolution, but only
  /// this downscaled JPEG is kept.
  File? _photo;

  String? _error;
  bool _processing = false;
  bool _handedOver = false;

  @override
  void dispose() {
    _scanner.dispose();
    if (!_handedOver) {
      _result?.dispose();
      final photo = _photo;
      if (photo != null) unawaited(deleteQuietly(photo));
    }
    super.dispose();
  }

  Future<void> _scan() async {
    final capture = await Navigator.of(context).push<KtpCapture>(
      MaterialPageRoute(
        builder: (_) => const KtpCameraPage(
          title: 'Scan your KTP',
          instruction:
              'Place the KTP inside the frame. Make sure the whole card, its '
              'text and the photo are visible, well lit and free of glare.',
          guideAspectRatio: kKtpAspectRatio,
        ),
      ),
    );
    if (capture == null || !mounted) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final result = await _scanner.scanCapture(capture);
      final photo = await compressToJpeg(
        File(result.imagePath),
        maxWidth: kKtpMaxWidth,
        maxHeight: kKtpMaxHeight,
        deleteSource: true,
      );
      if (!mounted) {
        result.dispose();
        await deleteQuietly(photo);
        return;
      }
      _result?.dispose();
      final previous = _photo;
      if (previous != null) unawaited(deleteQuietly(previous));
      setState(() {
        _processing = false;
        _result = result;
        _photo = photo;
        _error = _messageFor(result);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'The image could not be processed. Please try again.';
      });
    } finally {
      // The scanner works off a normalized copy, so the raw frame can go.
      await deleteQuietly(File(capture.path));
    }
  }

  String? _messageFor(KtpScanResult result) {
    if (result.rawText.trim().isEmpty) {
      return 'No text could be read. Retake the card in better lighting.';
    }
    if (!result.hasFields) {
      return 'Text was read but no KTP field was recognised. Retake the photo '
          'with the card filling the frame.';
    }
    if (!result.recognized) {
      return 'This does not look like a KTP. Check the extracted data on the '
          'next step before continuing.';
    }
    return null;
  }

  Future<void> _submit() async {
    final result = _result;
    final photo = _photo;
    if (result == null || photo == null) return;

    final portrait = result.portraitFile;

    EKycScope.read(context).setKtpScan(
      photo: MediaAsset(
        uri: photo.path,
        mimeType: photoMimeTypeOf(photo.path) ?? 'image/jpeg',
        sizeBytes: photo.existsSync() ? photo.lengthSync() : 0,
      ),
      portrait: portrait == null || !portrait.existsSync()
          ? null
          : MediaAsset(
              uri: portrait.path,
              mimeType: photoMimeTypeOf(portrait.path) ?? 'image/jpeg',
              sizeBytes: portrait.lengthSync(),
            ),
      data: result.data,
    );
    // The controller owns the files from here on.
    _handedOver = true;

    if (!mounted) return;
    if (widget.returnToReview) {
      // A rescan replaces the data too, so the user re-checks the fields.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const KtpDataScreen(returnToReview: true),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const KtpDataScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final photo = _photo;

    return StepScaffold(
      step: 5,
      title: 'KTP photo',
      actions: result == null
          ? ElevatedButton.icon(
              onPressed: _processing ? null : _scan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(_processing ? 'Reading…' : 'Scan KTP'),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processing ? null : _scan,
                    child: const Text('Rescan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processing ? null : _submit,
                    child: const Text('Use scan'),
                  ),
                ),
              ],
            ),
      child: ListView(
        children: [
          const SectionTitle(
            'Photograph your KTP',
            subtitle:
                'The card is read on this device. Nothing is uploaded, and '
                'you can correct every field on the next step.',
          ),
          const SizedBox(height: 20),
          if (_processing)
            AspectRatio(
              aspectRatio: kKtpAspectRatio,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                photo,
                key: ValueKey(photo.path),
                fit: BoxFit.contain,
              ),
            )
          else
            const _KtpFramePlaceholder(),
          const SizedBox(height: 16),
          if (_error != null)
            InfoBanner(
              message: _error!,
              tone: InfoTone.danger,
              icon: Icons.error_outline_rounded,
            )
          else if (result != null)
            InfoBanner(
              message:
                  '${result.fields.length} of ${KtpFieldKey.values.length} '
                  'fields were read. Review them on the next step.',
              tone: InfoTone.success,
              icon: Icons.check_circle_outline_rounded,
            ),
          if (result?.portraitFile != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Portrait found on the card',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BrandColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                result!.portraitFile!,
                key: ValueKey(result.portraitPath),
                width: 104,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const GuidelineList(
            title: 'Tips for a readable scan',
            items: [
              'The whole card is inside the frame and fills it.',
              'Lighting is even, with no shadows or reflections.',
              'The printed text is sharp, especially the NIK.',
              'No finger or object covers part of the card.',
            ],
          ),
        ],
      ),
    );
  }
}

class _KtpFramePlaceholder extends StatelessWidget {
  const _KtpFramePlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kKtpAspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandColors.primary, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 40, color: BrandColors.primary),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Line the KTP up inside the frame',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: BrandColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
