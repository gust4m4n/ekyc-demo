import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/capture_camera_page.dart';
import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/image_compressor.dart';
import '../utils/image_info.dart';
import '../utils/validators.dart';
import '../widgets/guideline_list.dart';
import '../widgets/step_scaffold.dart';
import 'ktp_scan_screen.dart';

/// Step 4 — selfie while holding the KTP, tying the person to the card.
class SelfieWithKtpScreen extends StatefulWidget {
  const SelfieWithKtpScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<SelfieWithKtpScreen> createState() => _SelfieWithKtpScreenState();
}

class _SelfieWithKtpScreenState extends State<SelfieWithKtpScreen> {
  File? _pendingFile;
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final existing = EKycScope.read(context).selfieWithKtpPhoto;
    if (existing != null && existing.file.existsSync()) {
      _pendingFile = existing.file;
    }
  }

  Future<void> _capture() async {
    final result = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => const CaptureCameraPage(
          title: 'Selfie with your KTP',
          instruction:
              'Hold the KTP next to your chest with the printed side facing '
              'the camera. Keep your face and the whole card inside the '
              'frame.',
          guide: CaptureGuide.portraitWithCard,
          guideAspectRatio: kKtpAspectRatio,
          lensDirection: CameraLensDirection.front,
          // A mirrored preview would print the card's text backwards, so this
          // step shows the true image and stores it unchanged.
          mirrorPreview: false,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _checking = true;
      _error = null;
    });

    final file = File(result.path);
    final longestEdge = await longestEdgeOf(file);
    final error = validatePhotoFile(file, longestEdge: longestEdge);

    // Checked at full resolution, stored downscaled.
    final stored = error == null
        ? await compressToJpeg(
            file,
            maxWidth: kSelfieMaxWidth,
            maxHeight: kSelfieMaxHeight,
            deleteSource: true,
          )
        : null;
    if (!mounted) return;

    setState(() {
      _checking = false;
      _error = error;
      _pendingFile = stored;
    });
  }

  void _submit() {
    final file = _pendingFile;
    if (file == null) return;

    EKycScope.read(context).setSelfieWithKtpPhoto(
      MediaAsset(
        uri: file.path,
        mimeType: photoMimeTypeOf(file.path) ?? 'image/jpeg',
        sizeBytes: file.lengthSync(),
      ),
    );

    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const KtpScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final file = _pendingFile;

    return StepScaffold(
      step: 4,
      title: 'Selfie with KTP',
      actions: file == null
          ? ElevatedButton.icon(
              onPressed: _checking ? null : _capture,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Take photo'),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _capture,
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Use photo'),
                  ),
                ),
              ],
            ),
      child: ListView(
        children: [
          const SectionTitle(
            'Hold your KTP next to your face',
            subtitle:
                'One photo showing you and the card together, so the demo can '
                'simulate that the card belongs to you.',
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 240,
              height: 300,
              child: _checking
                  ? const Center(child: CircularProgressIndicator())
                  : file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : const _HoldCardPlaceholder(),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            InfoBanner(
              message: _error!,
              tone: InfoTone.danger,
              icon: Icons.error_outline_rounded,
            )
          else if (file != null)
            const InfoBanner(
              message:
                  'Photo accepted (local simulation). No face or card match '
                  'has been performed.',
              tone: InfoTone.success,
              icon: Icons.check_circle_outline_rounded,
            ),
          const SizedBox(height: 20),
          const GuidelineList(
            title: 'Guidelines',
            items: [
              'Your face and the whole card are visible in one shot.',
              'The printed side of the KTP faces the camera.',
              'Your fingers do not cover the photo or the NIK on the card.',
              'No glare on the card and no shadow across your face.',
            ],
          ),
          const SizedBox(height: 12),
          const InfoBanner(message: 'JPG, PNG or HEIC, up to 10 MB.'),
        ],
      ),
    );
  }
}

class _HoldCardPlaceholder extends StatelessWidget {
  const _HoldCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.primary, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 44,
            color: BrandColors.primary,
          ),
          const SizedBox(height: 10),
          Container(
            width: 116,
            height: 116 / kKtpAspectRatio,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BrandColors.primarySoft, width: 2),
            ),
            child: const Icon(
              Icons.badge_outlined,
              size: 26,
              color: BrandColors.primarySoft,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Fit your face and the card inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: BrandColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
