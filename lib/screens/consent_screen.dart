import 'package:flutter/material.dart';

import '../state/ekyc_controller.dart';
import '../theme/brand.dart';
import '../widgets/step_scaffold.dart';
import 'liveness_screen.dart';

/// Step 1 — introduction and consent.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  void _start() {
    EKycScope.read(context).acceptConsent();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LivenessScreen()));
  }

  void _showPrivacyNotice() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: BrandColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Demo privacy notice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryDark,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'This application is a demonstration. Your liveness video, '
                  'selfies, KTP photo and the data read off the card are kept '
                  'on this device only, for the duration of the session.\n\n'
                  'The KTP is read by an on-device OCR engine: the photo is '
                  'never uploaded, no government registry is contacted, and '
                  'no account is opened. The media you capture is deleted '
                  'when the demo ends or when you choose to erase it.\n\n'
                  'Your NIK is masked on the summary screen, and no sensitive '
                  'value is written to the application logs.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: BrandColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 1,
      title: 'Identity verification',
      actions: ElevatedButton(
        onPressed: _accepted ? _start : null,
        child: const Text('Start verification'),
      ),
      child: ListView(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 88,
                height: 88,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            'Identity verification',
            subtitle:
                'This takes about 3–5 minutes. Have your KTP ready and find a '
                'well-lit spot.',
          ),
          const SizedBox(height: 20),
          const _ChecklistItem(
            icon: Icons.videocam_outlined,
            title: 'A liveness check',
            subtitle: 'A short video where you follow a few prompts.',
          ),
          const _ChecklistItem(
            icon: Icons.face_outlined,
            title: 'Two selfies',
            subtitle: 'One of your face, one of you holding your KTP.',
          ),
          const _ChecklistItem(
            icon: Icons.badge_outlined,
            title: 'Your KTP',
            subtitle:
                'Photographed and read on this device. Your details are '
                'filled in for you; you can correct them afterwards.',
          ),
          const _ChecklistItem(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Even lighting',
            subtitle: 'Avoid shadows and glare on the card and your face.',
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            message:
                'This is a simulation. The app does not open an account, does '
                'not contact any identity registry, and does not store your '
                'data on a server.',
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: BrandColors.primary,
            title: const Text(
              'I agree to my data being processed for this eKYC demo',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showPrivacyNotice,
              child: const Text('Read the demo privacy notice'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: BrandColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: BrandColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: BrandColors.muted,
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
