import 'package:flutter/material.dart';

import '../data/showcase_metadata.dart';
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
  const HeroSection({
    super.key,
    required this.metadata,
    required this.onTryPlayground,
  });

  final ShowcaseMetadata metadata;
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
              _EyebrowPill(
                text: '${metadata.versionLabel} - ${metadata.sourceLabel}',
              ),
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
                  metadata.productSummary,
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
                    onPressed: () => openUrl(metadata.pubDevUrl),
                  ),
                  GradientButton(
                    label: 'GitHub',
                    icon: Icons.star_outline_rounded,
                    variant: GradientButtonVariant.ghost,
                    onPressed: () => openUrl(metadata.repositoryUrl),
                  ),
                ],
              ),
              const SizedBox(height: Insets.xl),
              const CopyField(text: 'flutter pub add flutter_monaco'),
              const SizedBox(height: Insets.lg),
              _LiveFacts(metadata: metadata),
              const SizedBox(height: Insets.xl),
              PlatformBadges(platforms: metadata.platforms),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveFacts extends StatelessWidget {
  const _LiveFacts({required this.metadata});

  final ShowcaseMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      (Icons.history_rounded, metadata.publishedLabel),
      (
        Icons.translate_rounded,
        '${metadata.typedLanguageCount} typed languages',
      ),
      (Icons.palette_outlined, '${metadata.showcasedThemeCount} demo themes'),
      if (metadata.downloadCount30Days != null)
        (
          Icons.download_rounded,
          '${compactNumber(metadata.downloadCount30Days!)} downloads / 30d',
        ),
      if (metadata.likeCount != null)
        (
          Icons.favorite_border_rounded,
          '${compactNumber(metadata.likeCount!)} likes',
        ),
      if (metadata.starCount != null)
        (
          Icons.star_outline_rounded,
          '${compactNumber(metadata.starCount!)} stars',
        ),
    ];
    final c = context.showcaseColors;
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final (icon, label) in facts)
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
