import 'package:flutter/material.dart';

import '../data/showcase_metadata.dart';
import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';

/// A small chip row of the platforms the package supports.
class PlatformBadges extends StatelessWidget {
  const PlatformBadges({super.key, required this.platforms});

  final List<ShowcasePlatform> platforms;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final platform in platforms)
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
                Icon(iconFor(platform), size: 15, color: c.textSecondary),
                const SizedBox(width: 6),
                Text(
                  platform.label,
                  style: ShowcaseText.small.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData iconFor(ShowcasePlatform platform) => switch (platform.id) {
    'web' => Icons.public,
    'ios' => Icons.phone_iphone,
    'android' => Icons.android,
    'macos' => Icons.laptop_mac,
    'windows' => Icons.desktop_windows,
    'linux' => Icons.terminal,
    _ => Icons.devices_other,
  };
}
