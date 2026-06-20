import 'package:flutter/material.dart';

import '../state/showcase_controller.dart';
import '../theme/showcase_tokens.dart';

/// A sun/moon button that flips the page (and editor) brightness.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final isDark = controller.brightness == Brightness.dark;
    return Tooltip(
      message: isDark ? 'Switch to light' : 'Switch to dark',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: controller.toggleBrightness,
          child: Padding(
            padding: const EdgeInsets.all(Insets.sm),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(isDark),
                size: 20,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
