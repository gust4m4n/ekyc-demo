import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktp_scanner/ktp_scanner.dart';

import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../widgets/form_fields.dart';
import '../widgets/step_scaffold.dart';
import 'review_screen.dart';

/// Step 6 — the OCR output, editable.
///
/// Every KTP field is shown, prefilled with what the scanner read. Whatever
/// the user leaves here is the KYC record: no data beyond the card is asked
/// for.
class KtpDataScreen extends StatefulWidget {
  const KtpDataScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<KtpDataScreen> createState() => _KtpDataScreenState();
}

class _KtpDataScreenState extends State<KtpDataScreen> {
  late final Map<KtpFieldKey, TextEditingController> _controllers;

  /// Keys the scanner could not read, flagged so the user can fill them in.
  late final Set<KtpFieldKey> _unread;

  @override
  void initState() {
    super.initState();
    final details = EKycScope.read(context).ktpDetails;
    _unread = {
      for (final key in KtpFieldKey.values)
        if (details[key] == null) key,
    };
    _controllers = {
      for (final key in KtpFieldKey.values)
        key: TextEditingController(text: details[key] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    EKycScope.read(context).confirmKtpDetails(
      const KtpDetails.empty().withValues({
        for (final entry in _controllers.entries) entry.key: entry.value.text,
      }),
    );

    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unread.length;

    return StepScaffold(
      step: 6,
      title: 'KTP details',
      actions: ElevatedButton(
        onPressed: _submit,
        child: Text(widget.returnToReview ? 'Save changes' : 'Continue'),
      ),
      child: ListView(
        children: [
          const SectionTitle(
            'Check the data read from your KTP',
            subtitle:
                'These values came from the scan. Correct anything that is '
                'wrong and fill in whatever could not be read.',
          ),
          const SizedBox(height: 16),
          InfoBanner(
            message: unreadCount == 0
                ? 'Every field was read. Check them against your card before '
                      'continuing.'
                : '$unreadCount field(s) could not be read and were left '
                      'blank. Type them in from your card.',
            tone: unreadCount == 0 ? InfoTone.success : InfoTone.neutral,
            icon: unreadCount == 0
                ? Icons.check_circle_outline_rounded
                : Icons.edit_note_rounded,
          ),
          const SizedBox(height: 20),
          for (final key in KtpFieldKey.values)
            LabeledTextField(
              label: key.label,
              controller: _controllers[key]!,
              hint: _unread.contains(key)
                  ? 'Not read — type it from your card'
                  : null,
              keyboardType: key == KtpFieldKey.nik
                  ? TextInputType.number
                  : null,
              maxLength: _maxLengthOf(key),
              maxLines: key == KtpFieldKey.alamat ? 2 : 1,
              uppercase: key != KtpFieldKey.nik,
              inputFormatters: key == KtpFieldKey.nik
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
            ),
          const SizedBox(height: 4),
          const Text(
            'Only the data printed on your KTP is collected. Nothing else is '
            'asked for, and nothing leaves this device.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: BrandColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  int? _maxLengthOf(KtpFieldKey key) => switch (key) {
    KtpFieldKey.alamat => 120,
    _ => 70,
  };
}
