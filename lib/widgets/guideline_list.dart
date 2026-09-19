import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Bullet list of capture tips shown on the media steps.
class GuidelineList extends StatelessWidget {
  const GuidelineList({super.key, required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: BrandColors.primaryDark,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: BrandColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: BrandColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
