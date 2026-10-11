import 'package:material_ui/material_ui.dart';

import '../data/showcase_metadata.dart';
import '../state/showcase_controller.dart';
import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../util/links.dart';
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
        icon: Icons.difference_outlined,
        title: 'Diff editor',
        body:
            'Side-by-side or inline diffs with revert arrows and change '
            'navigation - new in 3.0.',
        snippet: 'MonacoDiffEditor(original: a, modified: b)',
        tryLabel: 'See it live',
        onTry: controller.scrollToDiff,
      ),
      FeatureCard(
        icon: Icons.keyboard_command_key_rounded,
        title: 'Custom actions & keybindings',
        body:
            'Register Dart callbacks as real editor actions - Cmd/Ctrl+S '
            'save hooks, command palette, context menu. New in 3.0.',
        snippet: 'controller.addAction(descriptor, onSave);',
        onTry: () => _go(controller.runCustomActionDemo),
      ),
      FeatureCard(
        icon: Icons.tab_rounded,
        title: 'Multi-document editing',
        body:
            'Documents are first-class handles with their own undo stacks, '
            'languages, and dirty state - switch without losing anything.',
        snippet: 'final doc = await controller.openDocument(...);',
        onTry: () => _go(controller.runMultiDocumentDemo),
      ),
      FeatureCard(
        icon: Icons.podcasts_rounded,
        title: 'Typed event stream',
        body:
            'One sealed MonacoEvent union for content, selection, and focus '
            '- with structured change ranges, not full-text pulls.',
        snippet: 'controller.events.listen((event) { ... });',
        onTry: () => _go(controller.runEventsDemo),
      ),
      FeatureCard(
        icon: Icons.auto_awesome_outlined,
        title: 'IntelliSense',
        body: 'Plug in static or async completion providers for any language.',
        snippet: 'controller.registerStaticCompletions(...);',
        onTry: () => _go(controller.runIntelliSenseDemo),
      ),
      FeatureCard(
        icon: Icons.hub_outlined,
        title: 'Language Server Protocol',
        body:
            'Connect real language servers over WebSocket, stdio, or a '
            'custom transport - diagnostics, hover, rename, and more.',
        snippet: 'controller.connectLanguageServer(...);',
        tryLabel: 'See the example',
        onTry: () => openUrl(Links.lspExample),
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
        snippet: 'controller.document.setMarkers([...]);',
        onTry: () => _go(controller.runMarkersDemo),
      ),
      FeatureCard(
        icon: Icons.palette_outlined,
        title: 'Theming, ${metadata.typedLanguageCount} languages',
        body:
            '${metadata.builtInThemeCount} built-in themes plus custom token '
            'colors via defineTheme; ${metadata.typedLanguageCount} typed '
            'language ids, open to custom ones.',
        snippet: 'controller.defineTheme(midnightTheme);',
        onTry: () =>
            _go(() => controller.setPlaygroundTheme(PlaygroundTheme.midnight)),
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
              'A typed Dart API over the full Monaco surface - every card '
              'drives the live ${metadata.versionLabel} playground editor.',
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
