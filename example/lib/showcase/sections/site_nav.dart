import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/showcase_controller.dart';
import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../util/links.dart';
import '../widgets/theme_toggle.dart';

/// The sticky top navigation bar.
class SiteNav extends StatelessWidget {
  const SiteNav({
    super.key,
    required this.controller,
    required this.onTapFeatures,
    required this.onTapPlayground,
  });

  final ShowcaseController controller;
  final VoidCallback onTapFeatures;
  final VoidCallback onTapPlayground;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final width = MediaQuery.sizeOf(context).width;
    final compact = Breakpoints.isMobile(width);
    final horizontal = compact ? Insets.lg : Insets.xl;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      decoration: BoxDecoration(
        color: c.page,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          _Logo(),
          const Spacer(),
          if (!compact) ...[
            _NavLink(label: 'Features', onTap: onTapFeatures),
            const SizedBox(width: Insets.lg),
            _NavLink(label: 'Playground', onTap: onTapPlayground),
            const SizedBox(width: Insets.lg),
          ],
          ThemeToggle(controller: controller),
          const SizedBox(width: Insets.xs),
          Tooltip(
            message: 'GitHub',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => openUrl(Links.github),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.sm),
                  child: SvgPicture.asset(
                    'assets/github.svg',
                    package: 'flutter_monaco',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      c.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          _PubButton(compact: compact),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: accentGradient,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: const Icon(Icons.code, color: Colors.white, size: 18),
        ),
        const SizedBox(width: Insets.sm),
        Text(
          'flutter_monaco',
          style: ShowcaseText.h3.copyWith(color: c.textPrimary),
        ),
        const SizedBox(width: Insets.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: c.border),
          ),
          child: Text(
            'v$kPackageVersion',
            style: ShowcaseText.monoLabel.copyWith(color: c.textFaint),
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: ShowcaseText.small.copyWith(color: c.textSecondary),
        ),
      ),
    );
  }
}

class _PubButton extends StatelessWidget {
  const _PubButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => openUrl(Links.pubDev),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Insets.md : Insets.lg,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            gradient: accentGradient,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Text(
            compact ? 'pub.dev' : 'Get it on pub.dev',
            style: ShowcaseText.small.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
