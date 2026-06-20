import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../util/links.dart';
import '../widgets/section_container.dart';

/// The page footer: link columns + brand line.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final mobile = Breakpoints.isMobile(MediaQuery.sizeOf(context).width);

    final brand = _Brand();
    final columns = [
      _LinkColumn(
        title: 'Package',
        links: const [
          ('pub.dev', Links.pubDev),
          ('API docs', Links.apiDocs),
          ('Changelog', Links.changelog),
        ],
      ),
      _LinkColumn(
        title: 'Source',
        links: const [
          ('GitHub', Links.github),
          ('Issues', Links.issues),
          ('License', Links.license),
        ],
      ),
      _LinkColumn(
        title: 'More',
        links: const [
          ('Other projects', Links.portfolio),
          ('Buy me a coffee', Links.buyMeACoffee),
        ],
      ),
    ];

    return SectionContainer(
      background: c.brightness == Brightness.dark ? c.surface : c.surfaceAlt,
      verticalPadding: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            brand,
            const SizedBox(height: Insets.xl),
            Wrap(spacing: Insets.xxl, runSpacing: Insets.xl, children: columns),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: brand),
                Expanded(child: columns[0]),
                Expanded(child: columns[1]),
                Expanded(child: columns[2]),
              ],
            ),
          const SizedBox(height: Insets.xl),
          Divider(color: c.border, height: 1),
          const SizedBox(height: Insets.lg),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: Insets.sm,
            children: [
              Text(
                'Built with flutter_monaco by Omar Hanafy',
                style: ShowcaseText.small.copyWith(color: c.textFaint),
              ),
              Text(
                'v$kPackageVersion - MIT License',
                style: ShowcaseText.monoLabel.copyWith(color: c.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: const Icon(Icons.code, color: Colors.white, size: 17),
            ),
            const SizedBox(width: Insets.sm),
            Text(
              'flutter_monaco',
              style: ShowcaseText.h3.copyWith(color: c.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            "VS Code's editor, inside your Flutter app.",
            style: ShowcaseText.body.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: Insets.md),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => openUrl(Links.github),
            child: SvgPicture.asset(
              'assets/github.svg',
              package: 'flutter_monaco',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(c.textSecondary, BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({required this.title, required this.links});

  final String title;
  final List<(String, String)> links;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: ShowcaseText.label.copyWith(color: c.textFaint),
        ),
        const SizedBox(height: Insets.md),
        for (final (label, url) in links)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => openUrl(url),
                child: Text(
                  label,
                  style: ShowcaseText.body.copyWith(color: c.textSecondary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
