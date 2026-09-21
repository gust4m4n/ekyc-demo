import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ktp_scanner/ktp_scanner.dart';

import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/validators.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/video_preview_player.dart';
import 'ktp_data_screen.dart';
import 'ktp_scan_screen.dart';
import 'liveness_screen.dart';
import 'selfie_screen.dart';
import 'selfie_with_ktp_screen.dart';
import 'success_screen.dart';

/// Step 7 — everything captured, on one screen.
///
/// The liveness clip, the selfie, the selfie with the KTP, the card photo and
/// the (corrected) card data all live on this single vertically scrollable
/// page. Media is enlarged in a modal on top of the same screen; no detail
/// route is ever pushed.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  Future<void> _edit(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: BrandColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Edit details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryDark,
                  ),
                ),
              ),
            ),
            for (final entry in <(String, IconData, Widget)>[
              (
                'Liveness video',
                Icons.videocam_outlined,
                const LivenessScreen(returnToReview: true),
              ),
              (
                'Selfie',
                Icons.face_outlined,
                const SelfieScreen(returnToReview: true),
              ),
              (
                'Selfie with KTP',
                Icons.badge_outlined,
                const SelfieWithKtpScreen(returnToReview: true),
              ),
              (
                'KTP photo (rescan)',
                Icons.document_scanner_outlined,
                const KtpScanScreen(returnToReview: true),
              ),
              (
                'KTP details',
                Icons.edit_note_rounded,
                const KtpDataScreen(returnToReview: true),
              ),
            ])
              ListTile(
                leading: Icon(entry.$2, color: BrandColors.primary),
                title: Text(entry.$1),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _edit(context, entry.$3);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final controller = EKycScope.read(context);
    final reference = controller.buildDemoReference();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SuccessScreen(reference: reference)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = EKycScope.of(context);
    final details = draft.ktpDetails;
    final liveness = draft.livenessVideo;

    return StepScaffold(
      step: 7,
      title: 'Review everything',
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showEditSheet(context),
              child: const Text('Edit details'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: draft.isReadyToSubmit ? () => _submit(context) : null,
              child: const Text('Submit demo'),
            ),
          ),
        ],
      ),
      child: ListView(
        children: [
          InfoBanner(
            message: draft.isReadyToSubmit
                ? 'Everything is ready for review. This is a simulation, not '
                      'a bank verification.'
                : 'Some sections are still incomplete. Finish them before '
                      'submitting the demo.',
            tone: draft.isReadyToSubmit ? InfoTone.success : InfoTone.danger,
            icon: draft.isReadyToSubmit
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
          ),
          const SizedBox(height: 20),
          _ReviewCard(
            title: 'LIVENESS VIDEO',
            complete: liveness != null,
            onEdit: () =>
                _edit(context, const LivenessScreen(returnToReview: true)),
            children: [
              if (liveness != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VideoPreviewPlayer(
                      // The SDK always writes to the same filename, so key on
                      // mtime to force a fresh controller after a re-record.
                      key: ValueKey(
                        liveness.file.lastModifiedSync().millisecondsSinceEpoch,
                      ),
                      file: liveness.file,
                      height: 240,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Length '
                      '${formatDuration(Duration(milliseconds: ((liveness.durationSeconds ?? 0) * 1000).round()))}'
                      ' • ${liveness.readableSize}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
                )
              else
                _EmptyMediaBox(
                  label: 'No liveness video yet',
                  height: 120,
                  onTap: () => _edit(
                    context,
                    const LivenessScreen(returnToReview: true),
                  ),
                ),
            ],
          ),
          _ReviewCard(
            title: 'PHOTOS',
            complete:
                draft.hasSelfie && draft.hasSelfieWithKtp && draft.hasKtpPhoto,
            onEdit: () => _showEditSheet(context),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MediaThumbnail(
                      label: 'Selfie',
                      asset: draft.selfiePhoto,
                      aspectRatio: 1,
                      onEmptyTap: () => _edit(
                        context,
                        const SelfieScreen(returnToReview: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MediaThumbnail(
                      label: 'Selfie with KTP',
                      asset: draft.selfieWithKtpPhoto,
                      aspectRatio: 1,
                      onEmptyTap: () => _edit(
                        context,
                        const SelfieWithKtpScreen(returnToReview: true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MediaThumbnail(
                label: 'KTP photo',
                asset: draft.ktpPhoto,
                aspectRatio: kKtpAspectRatio,
                onEmptyTap: () =>
                    _edit(context, const KtpScanScreen(returnToReview: true)),
              ),
              if (draft.ktpPortrait != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 120,
                  child: _MediaThumbnail(
                    label: 'Portrait on card',
                    asset: draft.ktpPortrait,
                    aspectRatio: 0.8,
                    onEmptyTap: () => _edit(
                      context,
                      const KtpScanScreen(returnToReview: true),
                    ),
                  ),
                ),
              ],
            ],
          ),
          _ReviewCard(
            title: 'KTP DATA',
            complete: draft.hasKtpDetails,
            onEdit: () =>
                _edit(context, const KtpDataScreen(returnToReview: true)),
            children: details.isEmpty
                ? const []
                : [
                    for (final field in details.filled)
                      _ReviewRow(
                        field.label,
                        field.key == KtpFieldKey.nik
                            ? maskDocumentNumber(field.value)
                            : field.value,
                      ),
                  ],
          ),
          _ReviewCard(
            title: 'CONSENT',
            complete: draft.hasConsent,
            children: draft.consent == null
                ? const []
                : [
                    _ReviewRow(
                      'Accepted on',
                      formatDateTime(draft.consent!.acceptedAt),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'I agree to my data being processed for this eKYC demo. '
                      'Nothing is sent to a server and no account is opened.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: BrandColors.muted,
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.complete,
    required this.children,
    this.onEdit,
  });

  final String title;
  final bool complete;
  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete ? BrandColors.border : BrandColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: BrandColors.muted,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!complete)
            InkWell(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: BrandColors.danger,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Incomplete — tap to finish this section',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BrandColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: BrandColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: BrandColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.label,
    required this.asset,
    required this.aspectRatio,
    required this.onEmptyTap,
  });

  final String label;
  final MediaAsset? asset;
  final double aspectRatio;
  final VoidCallback onEmptyTap;

  void _openModal(BuildContext context, File file) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = this.asset;
    final file = asset?.file;
    final exists = file != null && file.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: BrandColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        if (exists)
          GestureDetector(
            onTap: () => _openModal(context, file),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Image.file(
                  file,
                  key: ValueKey(asset!.uri),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        else
          _EmptyMediaBox(label: 'Not captured', height: 96, onTap: onEmptyTap),
        if (exists) ...[
          const SizedBox(height: 6),
          Text(
            asset!.readableSize,
            style: const TextStyle(fontSize: 12, color: BrandColors.muted),
          ),
        ],
      ],
    );
  }
}

class _EmptyMediaBox extends StatelessWidget {
  const _EmptyMediaBox({
    required this.label,
    required this.height,
    required this.onTap,
  });

  final String label;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: BrandColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.danger),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: BrandColors.danger,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: BrandColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
