import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../utils/validators.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/video_preview_player.dart';
import 'address_screen.dart';
import 'document_screen.dart';
import 'identity_screen.dart';
import 'liveness_screen.dart';
import 'selfie_screen.dart';
import 'success_screen.dart';

/// Step 7 — `Review your details`.
///
/// Everything the user entered, every photo and the liveness clip live on this
/// single vertically scrollable page. Media is enlarged in a modal on top of
/// the same screen; no detail route is ever pushed.
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
                'Identity details',
                Icons.person_outline_rounded,
                const IdentityScreen(returnToReview: true),
              ),
              (
                'Address',
                Icons.home_outlined,
                const AddressScreen(returnToReview: true),
              ),
              (
                'Document photo',
                Icons.badge_outlined,
                const DocumentScreen(returnToReview: true),
              ),
              (
                'Selfie',
                Icons.face_outlined,
                const SelfieScreen(returnToReview: true),
              ),
              (
                'Liveness video',
                Icons.videocam_outlined,
                const LivenessScreen(returnToReview: true),
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
    final country = draft.country;
    final identity = draft.identity;
    final address = draft.address;

    return StepScaffold(
      step: 7,
      title: 'Review your details',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
            title: 'IDENTITY',
            complete: identity != null,
            onEdit: () =>
                _edit(context, const IdentityScreen(returnToReview: true)),
            children: identity == null
                ? const []
                : [
                    _ReviewRow('Full name', identity.fullName),
                    _ReviewRow('Document type', identity.documentType.label),
                    _ReviewRow(
                      country.documentNumberLabel(identity.documentType),
                      maskDocumentNumber(identity.documentNumber),
                    ),
                    if (identity.documentExpiry != null)
                      _ReviewRow(
                        'Expires on',
                        formatDate(identity.documentExpiry!),
                      ),
                    _ReviewRow('Date of birth', formatDate(identity.birthDate)),
                    _ReviewRow('Place of birth', identity.birthPlace),
                    _ReviewRow('Nationality', identity.nationality),
                    _ReviewRow('Occupation', identity.occupation),
                    _ReviewRow('Issuing country', country.name),
                  ],
          ),
          _ReviewCard(
            title: 'ADDRESS',
            complete: address != null,
            onEdit: () =>
                _edit(context, const AddressScreen(returnToReview: true)),
            children: address == null
                ? const []
                : [
                    _ReviewRow(
                      'Registered address',
                      address.format(country.name),
                    ),
                    _ReviewRow('Province', address.province),
                    _ReviewRow('City or regency', address.city),
                    _ReviewRow('District', address.district),
                  ],
          ),
          _ReviewCard(
            title: 'DOCUMENT & BIOMETRICS',
            complete: draft.hasMedia,
            onEdit: () => _showEditSheet(context),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MediaThumbnail(
                      label: draft.documentType.frontLabel,
                      asset: draft.documentFront,
                      aspectRatio: draft.documentType.aspectRatio,
                      onEmptyTap: () => _edit(
                        context,
                        const DocumentScreen(returnToReview: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                ],
              ),
              if (draft.documentBack != null) ...[
                const SizedBox(height: 16),
                _MediaThumbnail(
                  label: 'Back side',
                  asset: draft.documentBack,
                  aspectRatio: draft.documentType.aspectRatio,
                  onEmptyTap: () => _edit(
                    context,
                    const DocumentScreen(returnToReview: true),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Liveness video',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              if (draft.livenessVideo != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VideoPreviewPlayer(
                      key: ValueKey(
                        draft.livenessVideo!.file
                            .lastModifiedSync()
                            .millisecondsSinceEpoch,
                      ),
                      file: draft.livenessVideo!.file,
                      height: 240,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Length '
                      '${formatDuration(Duration(milliseconds: ((draft.livenessVideo!.durationSeconds ?? 0) * 1000).round()))}'
                      ' • ${draft.livenessVideo!.readableSize}',
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
                    Text(
                      'Incomplete — tap to finish this section',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.danger,
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
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = asset;

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
        if (media != null && media.file.existsSync())
          GestureDetector(
            onTap: () => _openModal(context, media.file),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(media.file, fit: BoxFit.cover),
                    const Positioned(
                      right: 6,
                      bottom: 6,
                      child: Icon(
                        Icons.zoom_out_map_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          AspectRatio(
            aspectRatio: aspectRatio,
            child: _EmptyMediaBox(label: 'No photo yet', onTap: onEmptyTap),
          ),
      ],
    );
  }
}

class _EmptyMediaBox extends StatelessWidget {
  const _EmptyMediaBox({required this.label, required this.onTap, this.height});

  final String label;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: BrandColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.danger),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: BrandColors.danger),
          ),
        ),
      ),
    );
  }
}
