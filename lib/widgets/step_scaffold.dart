import 'package:flutter/material.dart';

import '../theme/brand.dart';

const int kTotalSteps = 7;

/// Shared chrome for every step: back button, progress and a pinned action bar.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
  });

  final int step;
  final String title;
  final Widget child;
  final Widget? actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                'Step $step of $kTotalSteps',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.muted,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: step / kTotalSteps,
            minHeight: 4,
            backgroundColor: BrandColors.border,
            valueColor: const AlwaysStoppedAnimation(BrandColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(padding: padding, child: child),
            ),
            if (actions != null)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: BrandColors.surface,
                  border: Border(top: BorderSide(color: BrandColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BrandColors.primaryDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 14, color: BrandColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Neutral / warning / error banner used across the flow.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = InfoTone.neutral,
  });

  final String message;
  final IconData icon;
  final InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      InfoTone.neutral => (BrandColors.surfaceAlt, BrandColors.primaryDark),
      InfoTone.success => (const Color(0xFFE7F5ED), BrandColors.success),
      InfoTone.danger => (const Color(0xFFFCEBE7), BrandColors.danger),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.4, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

enum InfoTone { neutral, success, danger }
