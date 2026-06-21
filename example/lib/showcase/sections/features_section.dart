import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import '../data/showcase_metadata.dart';
import '../state/showcase_controller.dart';
import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../widgets/feature_card.dart';
import '../widgets/section_container.dart';

/// The features grid. Each card's "Try it" scrolls to the playground and runs
/// the matching live demo on the shared editor.
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({
    super.key,
    required this.controller,
    required this.metadata,
  });

  final ShowcaseController controller;
  final ShowcaseMetadata metadata;

  void _go(VoidCallback action) {
    controller.scrollToPlayground();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;

    final cards = <FeatureCard>[
      FeatureCard(
        icon: Icons.translate_rounded,
        title: '${metadata.typedLanguageCount} typed languages',
        body:
            'Syntax highlighting for Dart, TypeScript, Python, Rust, Go, '
            'SQL and more - switch instantly.',
        snippet: 'controller.setLanguage(MonacoLanguage.rust);',
        onTry: () => _go(() => controller.setLanguage(MonacoLanguage.rust)),
      ),
      FeatureCard(
        icon: Icons.palette_outlined,
        title: 'Theming',
        body:
            '${metadata.builtInThemeCount} built-in themes, plus custom token '
            'colors with defineTheme.',
        snippet: 'controller.defineTheme(midnightTheme);',
        onTry: () =>
            _go(() => controller.setPlaygroundTheme(PlaygroundTheme.midnight)),
      ),
      FeatureCard(
        icon: Icons.auto_awesome_outlined,
        title: 'IntelliSense',
        body: 'Plug in static or async completion providers for any language.',
        snippet: 'controller.registerStaticCompletions(...);',
        onTry: () => _go(controller.runIntelliSenseDemo),
      ),
      FeatureCard(
        icon: Icons.fact_check_outlined,
        title: 'JSON schema validation',
        body:
            'Live diagnostics and JSON schema validation, configured in a '
            'single call.',
        snippet: 'controller.setJsonDiagnostics(options);',
        onTry: () => _go(controller.runJsonValidationDemo),
      ),
      FeatureCard(
        icon: Icons.error_outline_rounded,
        title: 'Markers & decorations',
        body: 'Surface errors, warnings, and line highlights programmatically.',
        snippet: 'controller.setErrorMarkers([...]);',
        onTry: () => _go(controller.runMarkersDemo),
      ),
      FeatureCard(
        icon: Icons.terminal_rounded,
        title: 'Full controller API',
        body:
            'getValue, edits, find/replace, folding, live stats and much '
            'more.',
        snippet: 'final code = await controller.getValue();',
        onTry: () => _go(controller.runDecorationsDemo),
      ),
    ];

    return SectionContainer(
      background: c.brightness == Brightness.dark ? c.surface : c.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything the editor can do',
            style: ShowcaseText.h1.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Insets.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'A typed Dart API over the full Monaco surface - drive any of '
              'these on the live ${metadata.versionLabel} editor below.',
              style: ShowcaseText.bodyLg.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: Insets.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= Breakpoints.desktop
                  ? 3
                  : width >= Breakpoints.tablet
                  ? 2
                  : 1;
              const gap = Insets.lg;
              final itemWidth = (width - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
