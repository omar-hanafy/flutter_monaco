import 'package:flutter/material.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';

/// A small chip row of the platforms the package supports.
class PlatformBadges extends StatelessWidget {
  const PlatformBadges({super.key});

  static const _items = <(IconData, String)>[
    (Icons.public, 'Web'),
    (Icons.phone_iphone, 'iOS'),
    (Icons.android, 'Android'),
    (Icons.laptop_mac, 'macOS'),
    (Icons.desktop_windows, 'Windows'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final (icon, label) in _items)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.sm,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: c.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: ShowcaseText.small.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
