import 'package:flutter/material.dart';

import '../state/ekyc_controller.dart';
import '../theme/brand.dart';

/// Simulated submission result shown after `Submit demo`.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.reference});

  final String reference;

  Future<void> _finish(BuildContext context) async {
    final deleteDraft = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BrandColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Erase the demo data?'),
        content: const Text(
          'Your identity details, document photos, selfie and liveness video '
          'will be removed from this device.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep session'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: BrandColors.danger),
            child: const Text('Erase now'),
          ),
        ],
      ),
    );

    if (!context.mounted || deleteDraft == null) return;
    if (deleteDraft) EKycScope.read(context).clear();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: BrandColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: BrandColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'eKYC demo submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This submission is a simulation. Your identity has not '
                  'been verified by any bank or identity registry, and no '
                  'account has been opened.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: BrandColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: BrandColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Demo reference number',
                        style: TextStyle(
                          fontSize: 12,
                          color: BrandColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reference,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: BrandColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _finish(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
