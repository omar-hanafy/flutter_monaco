import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

import '../data/migration_diff.dart';
import '../data/showcase_metadata.dart';
import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../util/links.dart';
import '../widgets/gradient_button.dart';
import '../widgets/section_container.dart';

/// The 3.0 rebuild story: six pillar cards plus the proof - the 2.x -> 3.0
/// migration rendered live by the new [MonacoDiffEditor].
class RebuildSection extends StatefulWidget {
  const RebuildSection({super.key, required this.metadata});

  final ShowcaseMetadata metadata;

  @override
  State<RebuildSection> createState() => _RebuildSectionState();
}

class _RebuildSectionState extends State<RebuildSection> {
  MonacoDiffController? _diff;
  bool _sideBySide = true;
  int? _changeCount;

  Future<void> _onDiffReady(MonacoDiffController controller) async {
    _diff = controller;
    await _refreshChangeCount();
  }

  Future<void> _refreshChangeCount() async {
    final diff = _diff;
    if (diff == null) return;
    try {
      final count = await diff.getLineChangeCount();
      if (mounted) setState(() => _changeCount = count);
    } catch (e) {
      debugPrint('[RebuildSection] change count failed: $e');
    }
  }

  Future<void> _setSideBySide(bool value) async {
    if (value == _sideBySide) return;
    setState(() => _sideBySide = value);
    await _diff?.updateDiffOptions(MonacoDiffOptions(renderSideBySide: value));
  }

  Future<void> _reveal(bool next) async {
    final diff = _diff;
    if (diff == null) return;
    if (next) {
      await diff.revealNextChange();
    } else {
      await diff.revealPreviousChange();
    }
    await _refreshChangeCount();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final width = MediaQuery.sizeOf(context).width;
    final mobile = Breakpoints.isMobile(width);

    return SectionContainer(
      background: c.brightness == Brightness.dark ? c.surface : c.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rebuilt from the spine out in 3.0',
            style: ShowcaseText.h1.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Insets.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              '3.0 replaces three ad-hoc JavaScript bridges with one '
              'request-correlated protocol, splits documents from the '
              'editor the way Monaco itself does, and turns every silent '
              'failure into a typed exception. The diff below is the '
              'migration itself - rendered live by the new MonacoDiffEditor.',
              style: ShowcaseText.bodyLg.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: Insets.xl),
          const _PillarGrid(),
          const SizedBox(height: Insets.xl),
          _DiffCard(
            sideBySide: _sideBySide,
            changeCount: _changeCount,
            onSideBySide: _setSideBySide,
            onPrev: () => _reveal(false),
            onNext: () => _reveal(true),
            onReady: _onDiffReady,
            editorHeight: mobile ? 380.0 : 460.0,
          ),
          const SizedBox(height: Insets.lg),
          GradientButton(
            label: 'Read the full migration guide',
            icon: Icons.menu_book_outlined,
            variant: GradientButtonVariant.outline,
            onPressed: () => openUrl(widget.metadata.changelogUrl),
          ),
        ],
      ),
    );
  }
}

class _Pillar {
  const _Pillar(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const List<_Pillar> _pillars = [
  _Pillar(
    Icons.swap_calls_rounded,
    'One wire protocol',
    'A request-correlated envelope replaces three ad-hoc bridges - '
        'identical behavior on Android, iOS, macOS, Windows, and Web.',
  ),
  _Pillar(
    Icons.gpp_maybe_outlined,
    'Errors are data',
    'Reads never silently return defaults; every bridge failure is a '
        'typed MonacoException with the operation name.',
  ),
  _Pillar(
    Icons.article_outlined,
    'Documents, split like Monaco',
    'MonacoDocument mirrors ITextModel and the controller mirrors '
        'ICodeEditor - multi-document editing is first-class.',
  ),
  _Pillar(
    Icons.bolt_rounded,
    'Born configured',
    'Two-phase boot: the editor is created with your options, text, and '
        'theme. No flash, no patch-after-ready, create() never blocks.',
  ),
  _Pillar(
    Icons.sell_outlined,
    'Open typed ids',
    'Themes, languages, and actions are zero-cost extension types over '
        'String - typed catalogs, open sets, custom ids welcome.',
  ),
  _Pillar(
    Icons.tune_rounded,
    'Options that tell the truth',
    'EditorOptions is sparse: updateOptions(EditorOptions(fontSize: 16)) '
        'changes the font size and nothing else.',
  ),
];

class _PillarGrid extends StatelessWidget {
  const _PillarGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= Breakpoints.desktop
            ? 3
            : width >= Breakpoints.tablet
            ? 2
            : 1;
        const gap = Insets.md;
        final itemWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final pillar in _pillars)
              SizedBox(
                width: itemWidth,
                child: _PillarCard(pillar: pillar),
              ),
          ],
        );
      },
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.pillar});

  final _Pillar pillar;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: c.brightness == Brightness.dark ? c.page : Colors.white,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(pillar.icon, size: 18, color: ShowcaseColors.accentBlue),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  pillar.title,
                  style: ShowcaseText.h3.copyWith(color: c.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Text(
            pillar.body,
            style: ShowcaseText.body.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  const _DiffCard({
    required this.sideBySide,
    required this.changeCount,
    required this.onSideBySide,
    required this.onPrev,
    required this.onNext,
    required this.onReady,
    required this.editorHeight,
  });

  final bool sideBySide;
  final int? changeCount;
  final ValueChanged<bool> onSideBySide;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Future<void> Function(MonacoDiffController) onReady;
  final double editorHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            color: c.surfaceAlt,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.sm,
            ),
            child: Row(
              children: [
                Text(
                  'editor_service.dart',
                  style: ShowcaseText.monoLabel.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(width: Insets.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentWash,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    changeCount == null
                        ? '2.x -> 3.0'
                        : '2.x -> 3.0 · $changeCount changed regions',
                    style: ShowcaseText.monoLabel.copyWith(
                      color: ShowcaseColors.accentBlue,
                    ),
                  ),
                ),
                const Spacer(),
                _DiffModeToggle(
                  sideBySide: sideBySide,
                  onChanged: onSideBySide,
                ),
                const SizedBox(width: Insets.sm),
                _DiffIconButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  tooltip: 'Previous change',
                  onTap: onPrev,
                ),
                _DiffIconButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: 'Next change',
                  onTap: onNext,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          // Same rule as the playground: keep the platform view a direct
          // sized child so the iframe keeps a real DOM rect on web.
          SizedBox(
            height: editorHeight,
            child: MonacoDiffEditor(
              key: const ValueKey('showcase-migration-diff'),
              original: kMigrationOriginal,
              modified: kMigrationModified,
              language: MonacoLanguage.dart,
              // theme stays null: the diff follows the page brightness live.
              options: const EditorOptions(
                fontSize: 13,
                minimap: MonacoMinimapOptions(enabled: false),
                scrollBeyondLastLine: false,
                padding: MonacoPadding(top: 12, bottom: 12),
              ),
              diffOptions: const MonacoDiffOptions(renderSideBySide: true),
              // Edge scroll handoff: once the diff hits its vertical scroll
              // edge, the wheel keeps scrolling the page instead of dying
              // over the editor.
              scrollHandoff: const MonacoScrollHandoff.edge(),
              onReady: onReady,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffModeToggle extends StatelessWidget {
  const _DiffModeToggle({required this.sideBySide, required this.onChanged});

  final bool sideBySide;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    Widget chip(String label, bool value) {
      final active = sideBySide == value;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: active ? c.accentWash : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              label,
              style: ShowcaseText.monoLabel.copyWith(
                color: active ? ShowcaseColors.accentBlue : c.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [chip('Side by side', true), chip('Inline', false)],
      ),
    );
  }
}

class _DiffIconButton extends StatelessWidget {
  const _DiffIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 18, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}
