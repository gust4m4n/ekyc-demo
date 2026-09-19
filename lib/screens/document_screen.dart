import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/capture_camera_page.dart';
import '../config/country_profile.dart';
import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/image_info.dart';
import '../utils/validators.dart';
import '../widgets/guideline_list.dart';
import '../widgets/step_scaffold.dart';
import 'selfie_screen.dart';

/// Step 4 — identity document photo.
///
/// The front (or passport data page) is mandatory; a back side is offered only
/// for documents that carry data on it.
class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  File? _front;
  File? _back;
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final draft = EKycScope.read(context);
    _front = _existingFile(draft.documentFront);
    _back = _existingFile(draft.documentBack);
  }

  File? _existingFile(MediaAsset? asset) {
    if (asset == null || !asset.file.existsSync()) return null;
    return asset.file;
  }

  DocumentType get _documentType => EKycScope.read(context).documentType;

  Future<void> _capture({required bool back}) async {
    final type = _documentType;
    final result = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(
        builder: (_) => CaptureCameraPage(
          title: back
              ? '${type.label} — back side'
              : '${type.label} — ${type.frontLabel.toLowerCase()}',
          instruction:
              'Fit the whole document inside the frame. Keep it bright, sharp '
              'and free of glare.',
          guide: CaptureGuide.idCard,
          guideAspectRatio: type.aspectRatio,
          lensDirection: CameraLensDirection.back,
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
      if (error == null) {
        if (back) {
          _back = file;
        } else {
          _front = file;
        }
      }
    });
  }

  void _submit() {
    final front = _front;
    if (front == null) return;

    final controller = EKycScope.read(context);
    controller.setDocumentFront(
      MediaAsset(
        uri: front.path,
        mimeType: photoMimeTypeOf(front.path) ?? 'image/jpeg',
        sizeBytes: front.lengthSync(),
      ),
    );
    final back = _back;
    controller.setDocumentBack(
      back == null
          ? null
          : MediaAsset(
              uri: back.path,
              mimeType: photoMimeTypeOf(back.path) ?? 'image/jpeg',
              sizeBytes: back.lengthSync(),
            ),
    );

    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SelfieScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final type = EKycScope.of(context).documentType;
    final front = _front;

    return StepScaffold(
      step: 4,
      title: 'Document photo',
      actions: front == null
          ? ElevatedButton.icon(
              onPressed: _checking ? null : () => _capture(back: false),
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Take photo'),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _capture(back: false),
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
          SectionTitle(
            'Photograph your ${type.label.toLowerCase()}',
            subtitle: type.captureHint,
          ),
          const SizedBox(height: 20),
          if (_checking)
            AspectRatio(
              aspectRatio: type.aspectRatio,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (front != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: type.aspectRatio,
                child: Image.file(front, fit: BoxFit.cover),
              ),
            )
          else
            _DocumentFramePlaceholder(type: type),
          const SizedBox(height: 16),
          if (_error != null)
            InfoBanner(
              message: _error!,
              tone: InfoTone.danger,
              icon: Icons.error_outline_rounded,
            )
          else if (front != null)
            const InfoBanner(
              message:
                  'Readability check passed (simulated). The document has not '
                  'been officially verified.',
              tone: InfoTone.success,
              icon: Icons.check_circle_outline_rounded,
            ),
          if (type.hasBackSide) ...[
            const SizedBox(height: 20),
            _BackSideSection(
              file: _back,
              onCapture: () => _capture(back: true),
              onRemove: () => setState(() => _back = null),
            ),
          ],
          const SizedBox(height: 20),
          const GuidelineList(
            title: 'Tips for a good photo',
            items: [
              'The whole document is visible inside the frame.',
              'Lighting is even, with no shadows or reflections.',
              'The printed text is sharp and readable.',
              'No finger or object covers part of the document.',
            ],
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            message:
                'JPG, PNG or HEIC, up to 10 MB, with a longest edge of at '
                'least 1280 px.',
          ),
        ],
      ),
    );
  }
}

class _BackSideSection extends StatelessWidget {
  const _BackSideSection({
    required this.file,
    required this.onCapture,
    required this.onRemove,
  });

  final File? file;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final photo = file;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Back side (optional)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: BrandColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add it when your document prints the address or an issue date on '
          'the reverse.',
          style: TextStyle(fontSize: 13, color: BrandColors.muted),
        ),
        const SizedBox(height: 12),
        if (photo != null)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.586,
                    child: Image.file(photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    onPressed: onCapture,
                    icon: const Icon(Icons.refresh_rounded),
                    color: BrandColors.primary,
                    tooltip: 'Retake',
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: BrandColors.danger,
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add back side'),
          ),
      ],
    );
  }
}

class _DocumentFramePlaceholder extends StatelessWidget {
  const _DocumentFramePlaceholder({required this.type});

  final DocumentType type;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: type.aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandColors.primary, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.badge_outlined,
              size: 40,
              color: BrandColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Fill this frame with the ${type.frontLabel.toLowerCase()}',
              style: const TextStyle(fontSize: 13, color: BrandColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
