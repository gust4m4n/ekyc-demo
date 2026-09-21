import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ktp_data.dart';
import '../models/ktp_scan_result.dart';
import 'ktp_scanner_colors.dart';

/// Renders everything a scan produced: the card, the holder's photo and the
/// extracted fields.
class KtpResultView extends StatelessWidget {
  const KtpResultView({super.key, required this.result, this.allowCopy = true});

  final KtpScanResult result;
  final bool allowCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KtpCapturePreview(path: result.imagePath),
        const SizedBox(height: 16),
        KtpPortraitCard(path: result.portraitPath),
        const SizedBox(height: 20),
        if (result.hasFields) ...[
          const _SectionTitle('Extracted data'),
          const SizedBox(height: 12),
          _FieldTable(
            fields: result.fields,
            onCopy: allowCopy ? (field) => _copy(context, field) : null,
          ),
        ],
      ],
    );
  }

  void _copy(BuildContext context, KtpField field) {
    Clipboard.setData(ClipboardData(text: field.value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${field.label} copied')));
  }
}

/// The captured card, cropped to the ID-1 aspect ratio.
class KtpCapturePreview extends StatelessWidget {
  const KtpCapturePreview({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Image.file(file, fit: BoxFit.cover),
      ),
    );
  }
}

/// The portrait cropped off the card, or a hint when none was found.
class KtpPortraitCard extends StatelessWidget {
  const KtpPortraitCard({super.key, required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final file = path == null ? null : File(path);
    final available = file != null && file.existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KtpScannerColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KtpScannerColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 104,
              height: 136,
              child: available
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: KtpScannerColors.border,
                      child: const Icon(
                        Icons.person_off_rounded,
                        color: KtpScannerColors.muted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cardholder photo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KtpScannerColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  available
                      ? 'Cropped from the photo printed on the card.'
                      : 'No photo was detected. Retake the card in better '
                            'lighting.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: KtpScannerColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: KtpScannerColors.primaryDark,
      ),
    ),
  );
}

class _FieldTable extends StatelessWidget {
  const _FieldTable({required this.fields, required this.onCopy});

  final List<KtpField> fields;
  final void Function(KtpField field)? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KtpScannerColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KtpScannerColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _FieldRow(field: fields[i], onCopy: onCopy),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.onCopy});

  final KtpField field;
  final void Function(KtpField field)? onCopy;

  @override
  Widget build(BuildContext context) {
    final onCopy = this.onCopy;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, onCopy == null ? 14 : 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 126,
            child: Text(
              field.label,
              style: const TextStyle(
                fontSize: 13,
                color: KtpScannerColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              field.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: KtpScannerColors.primaryDark,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: () => onCopy(field),
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
