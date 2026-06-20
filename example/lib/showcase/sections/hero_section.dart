import 'package:flutter/material.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../util/links.dart';
import '../widgets/copy_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/platform_badges.dart';
import '../widgets/section_container.dart';

/// The hero: headline, subhead, CTAs, install line, and platform badges,
/// over a soft accent-gradient glow.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onTryPlayground});

  final VoidCallback onTryPlayground;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final width = MediaQuery.sizeOf(context).width;
    final mobile = Breakpoints.isMobile(width);
    final headlineTop = mobile ? ShowcaseText.display : ShowcaseText.displayXl;
    final headlineSize = mobile ? 34.0 : null;

    return Stack(
      children: [
        Positioned.fill(child: _Glow(brightness: c.brightness)),
        SectionContainer(
          verticalPadding: mobile ? 64 : 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EyebrowPill(text: "Powered by VS Code's Monaco engine"),
              const SizedBox(height: Insets.lg),
              Text(
                "VS Code's editor,",
                style:
                    (headlineSize != null
                            ? headlineTop.copyWith(fontSize: headlineSize)
                            : headlineTop)
                        .copyWith(color: c.textPrimary),
              ),
              ShaderMask(
                shaderCallback: (bounds) => accentGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'inside your Flutter app.',
                  style:
                      (headlineSize != null
                              ? headlineTop.copyWith(fontSize: headlineSize)
                              : headlineTop)
                          .copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: Insets.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  'Embed Monaco - the engine behind VS Code - with 100+ '
                  'languages, rich theming, IntelliSense, and a full Dart API. '
                  'On web, desktop, and mobile.',
                  style: ShowcaseText.bodyLg.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: Insets.xl),
              Wrap(
                spacing: Insets.md,
                runSpacing: Insets.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GradientButton(
                    label: 'Try the playground',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onTryPlayground,
                  ),
                  GradientButton(
                    label: 'View on pub.dev',
                    icon: Icons.open_in_new_rounded,
                    variant: GradientButtonVariant.outline,
                    onPressed: () => openUrl(Links.pubDev),
                  ),
                  GradientButton(
                    label: 'GitHub',
                    icon: Icons.star_outline_rounded,
                    variant: GradientButtonVariant.ghost,
                    onPressed: () => openUrl(Links.github),
                  ),
                ],
              ),
              const SizedBox(height: Insets.xl),
              const CopyField(text: 'flutter pub add flutter_monaco'),
              const SizedBox(height: Insets.xl),
              const PlatformBadges(),
            ],
          ),
        ),
      ],
    );
  }
}

class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      decoration: BoxDecoration(
        color: c.accentWash,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
          color: ShowcaseColors.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 14, color: ShowcaseColors.accentBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: ShowcaseText.eyebrow.copyWith(
                color: ShowcaseColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final intensity = brightness == Brightness.dark ? 0.28 : 0.16;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -1.1),
          radius: 1.3,
          colors: [
            ShowcaseColors.accentIndigo.withValues(alpha: intensity),
            ShowcaseColors.accentBlue.withValues(alpha: intensity * 0.6),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.75],
        ),
      ),
    );
  }
}
