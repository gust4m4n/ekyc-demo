import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/capture_camera_page.dart';
import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/image_info.dart';
import '../utils/validators.dart';
import '../widgets/guideline_list.dart';
import '../widgets/step_scaffold.dart';
import 'liveness_screen.dart';

/// Step 5 — selfie photo.
class SelfieScreen extends StatefulWidget {
  const SelfieScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  File? _pendingFile;
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final existing = EKycScope.read(context).selfiePhoto;
    if (existing != null && existing.file.existsSync()) {
      _pendingFile = existing.file;
    }
  }

  Future<void> _capture() async {
    final result = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => const CaptureCameraPage(
          title: 'Selfie',
          instruction:
              'Remove any mask or sunglasses, face the camera and make sure '
              'the light is even.',
          guide: CaptureGuide.faceOval,
          lensDirection: CameraLensDirection.front,
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
    if (!mounted) return;

    setState(() {
      _checking = false;
      _error = error;
      _pendingFile = error == null ? file : null;
    });
  }

  void _submit() {
    final file = _pendingFile;
    if (file == null) return;

    EKycScope.read(context).setSelfiePhoto(
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
    ).push(MaterialPageRoute(builder: (_) => const LivenessScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final file = _pendingFile;

    return StepScaffold(
      step: 5,
      title: 'Selfie',
      actions: file == null
          ? ElevatedButton.icon(
              onPressed: _checking ? null : _capture,
              icon: const Icon(Icons.photo_camera_front_rounded),
              label: const Text('Take selfie'),
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
            'Take a photo of your face',
            subtitle:
                'This photo is used to simulate a match against the portrait '
                'on your identity document.',
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 220,
              height: 280,
              child: _checking
                  ? const Center(child: CircularProgressIndicator())
                  : file != null
                  ? ClipOval(child: Image.file(file, fit: BoxFit.cover))
                  : const _SelfieOvalPlaceholder(),
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
                  'Face detected (local simulation). No face match has been '
                  'performed.',
              tone: InfoTone.success,
              icon: Icons.face_retouching_natural_rounded,
            ),
          const SizedBox(height: 20),
          const GuidelineList(
            title: 'Selfie guidelines',
            items: [
              'Exactly one face is visible inside the oval.',
              'Your face is not covered by a mask, hat or sunglasses.',
              'The light is even and your face is not in shadow.',
              'Look straight at the camera with a neutral expression.',
            ],
          ),
          const SizedBox(height: 12),
          const InfoBanner(message: 'JPG, PNG or HEIC, up to 10 MB.'),
        ],
      ),
    );
  }
}

class _SelfieOvalPlaceholder extends StatelessWidget {
  const _SelfieOvalPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surfaceAlt,
        borderRadius: const BorderRadius.all(Radius.elliptical(110, 140)),
        border: Border.all(color: BrandColors.primary, width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 48,
            color: BrandColors.primary,
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Position your face inside the oval',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: BrandColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
