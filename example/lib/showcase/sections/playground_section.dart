import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import '../data/demo_snippets.dart';
import '../data/samples.dart';
import '../state/showcase_controller.dart';
import '../theme/showcase_text.dart';
import '../theme/showcase_tokens.dart';
import '../widgets/section_container.dart';

/// The interactive playground: one shared Monaco editor plus the controls and
/// demos that drive it.
class PlaygroundSection extends StatelessWidget {
  const PlaygroundSection({
    super.key,
    required this.controller,
    required this.routeObserver,
  });

  final ShowcaseController controller;
  final MonacoRouteObserver routeObserver;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final width = MediaQuery.sizeOf(context).width;
    final editorHeight = Breakpoints.isMobile(width)
        ? 380.0
        : Breakpoints.isTablet(width)
            ? 460.0
            : 520.0;

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live playground',
              style: ShowcaseText.h1.copyWith(color: c.textPrimary)),
          const SizedBox(height: Insets.md),
          Text(
              'Real Monaco, running right here. Switch languages and themes, '
              'toggle options, or trigger a feature - it all drives one editor.',
              style: ShowcaseText.bodyLg.copyWith(color: c.textSecondary)),
          const SizedBox(height: Insets.xl),
          _EditorCard(
            controller: controller,
            routeObserver: routeObserver,
            editorHeight: editorHeight,
          ),
          const SizedBox(height: Insets.lg),
          _OptionsRow(controller: controller),
          const SizedBox(height: Insets.lg),
          _DemosRow(controller: controller),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.controller,
    required this.routeObserver,
    required this.editorHeight,
  });

  final ShowcaseController controller;
  final MonacoRouteObserver routeObserver;
  final double editorHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final monaco = controller.monaco;
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Toolbar(controller: controller),
          Divider(height: 1, color: c.border),
          SizedBox(
            height: editorHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MonacoEditor(
                    key: const ValueKey('showcase-playground-editor'),
                    options: controller.initialEditorOptions,
                    initialValue: controller.initialValue,
                    customCss: kEditorCustomCss,
                    backgroundColor: const Color(0xFF0D1117),
                    onReady: controller.attachEditor,
                  ),
                ),
                if (monaco != null)
                  MonacoFocusGuard(
                    controller: monaco,
                    modalRouteObserver: routeObserver,
                  ),
              ],
            ),
          ),
          if (controller.hint != null)
            _HintBanner(
              hint: controller.hint!,
              onClose: controller.reset,
            ),
          Divider(height: 1, color: c.border),
          _LiveStatsBar(controller: controller),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller});

  final ShowcaseController controller;

  Future<void> _copy(BuildContext context) async {
    final code = await controller.currentValue();
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 240,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      color: c.surfaceAlt,
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: Insets.sm),
      child: Wrap(
        spacing: Insets.sm,
        runSpacing: Insets.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ToolbarMenu<MonacoLanguage>(
            icon: Icons.translate_rounded,
            value: controller.language,
            entries: [
              for (final l in kPlaygroundLanguages) (l, l.label),
            ],
            onSelected: controller.setLanguage,
          ),
          _ToolbarMenu<PlaygroundTheme>(
            icon: Icons.palette_outlined,
            value: controller.playgroundTheme,
            entries: [
              for (final t in PlaygroundTheme.values) (t, t.label),
            ],
            onSelected: controller.setPlaygroundTheme,
          ),
          _ToolbarAction(
              icon: Icons.format_align_left_rounded,
              tooltip: 'Format',
              onTap: controller.format),
          _ToolbarAction(
              icon: Icons.search_rounded,
              tooltip: 'Find',
              onTap: controller.find),
          _ToolbarAction(
              icon: Icons.unfold_less_rounded,
              tooltip: 'Fold all',
              onTap: controller.foldAll),
          _ToolbarAction(
              icon: Icons.content_copy_rounded,
              tooltip: 'Copy',
              onTap: () => _copy(context)),
          _ToolbarAction(
              icon: Icons.restart_alt_rounded,
              tooltip: 'Reset',
              onTap: controller.reset),
        ],
      ),
    );
  }
}

class _ToolbarMenu<T> extends StatelessWidget {
  const _ToolbarMenu({
    required this.icon,
    required this.value,
    required this.entries,
    required this.onSelected,
  });

  final IconData icon;
  final T value;
  final List<(T, String)> entries;
  final ValueChanged<T> onSelected;

  String get _currentLabel =>
      entries.firstWhere((e) => e.$1 == value, orElse: () => entries.first).$2;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return PopupMenuButton<T>(
      onSelected: onSelected,
      tooltip: '',
      position: PopupMenuPosition.under,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.border),
      ),
      itemBuilder: (context) => [
        for (final (v, label) in entries)
          PopupMenuItem<T>(
            value: v,
            height: 40,
            child: Row(
              children: [
                Icon(Icons.check,
                    size: 16,
                    color: v == value
                        ? ShowcaseColors.accentBlue
                        : Colors.transparent),
                const SizedBox(width: Insets.sm),
                Text(label,
                    style: ShowcaseText.small.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.md, vertical: Insets.sm),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c.textSecondary),
            const SizedBox(width: 6),
            Text(_currentLabel,
                style: ShowcaseText.small.copyWith(color: c.textPrimary)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 18, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
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
        borderRadius: BorderRadius.circular(Radii.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 18, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EDITOR OPTIONS',
            style: ShowcaseText.label.copyWith(color: c.textFaint)),
        const SizedBox(height: Insets.md),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ToggleChip(
                icon: Icons.map_outlined,
                label: 'Minimap',
                value: controller.minimap,
                onChanged: controller.setMinimap),
            _ToggleChip(
                icon: Icons.wrap_text_rounded,
                label: 'Word wrap',
                value: controller.wordWrap,
                onChanged: controller.setWordWrap),
            _ToggleChip(
                icon: Icons.format_list_numbered_rounded,
                label: 'Line numbers',
                value: controller.lineNumbers,
                onChanged: controller.setLineNumbers),
            _ToggleChip(
                icon: Icons.lock_outline_rounded,
                label: 'Read-only',
                value: controller.readOnly,
                onChanged: controller.setReadOnly),
            _FontSizeChip(controller: controller),
          ],
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final active = value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
              horizontal: Insets.md, vertical: Insets.sm),
          decoration: BoxDecoration(
            color: active ? c.accentWash : c.surface,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: active
                  ? ShowcaseColors.accentBlue.withValues(alpha: 0.6)
                  : c.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? ShowcaseColors.accentBlue : c.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: ShowcaseText.small.copyWith(
                      color: active
                          ? ShowcaseColors.accentBlue
                          : c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeChip extends StatelessWidget {
  const _FontSizeChip({required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
              icon: Icons.remove, onTap: () => controller.changeFontSize(-1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('${controller.fontSize.toInt()}px',
                style: ShowcaseText.monoLabel.copyWith(color: c.textSecondary)),
          ),
          _StepButton(
              icon: Icons.add, onTap: () => controller.changeFontSize(1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 15, color: c.textSecondary),
        ),
      ),
    );
  }
}

class _DemosRow extends StatelessWidget {
  const _DemosRow({required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRY A FEATURE',
            style: ShowcaseText.label.copyWith(color: c.textFaint)),
        const SizedBox(height: Insets.md),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            _DemoButton(
                icon: Icons.auto_awesome_outlined,
                label: 'IntelliSense',
                onTap: controller.runIntelliSenseDemo),
            _DemoButton(
                icon: Icons.fact_check_outlined,
                label: 'JSON validation',
                onTap: controller.runJsonValidationDemo),
            _DemoButton(
                icon: Icons.error_outline_rounded,
                label: 'Markers',
                onTap: controller.runMarkersDemo),
            _DemoButton(
                icon: Icons.format_color_fill_outlined,
                label: 'Decorations',
                onTap: controller.runDecorationsDemo),
          ],
        ),
      ],
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Insets.md, vertical: Insets.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ShowcaseColors.accentBlue),
              const SizedBox(width: 6),
              Text(label,
                  style: ShowcaseText.small.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.hint, required this.onClose});

  final String hint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      width: double.infinity,
      color: ShowcaseColors.accentBlue.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(
          horizontal: Insets.md, vertical: Insets.sm),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 16, color: ShowcaseColors.accentBlue),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(hint,
                style: ShowcaseText.small.copyWith(color: c.textPrimary)),
          ),
          InkWell(
            onTap: onClose,
            child: Icon(Icons.close, size: 15, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LiveStatsBar extends StatelessWidget {
  const _LiveStatsBar({required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final stats = controller.liveStats;
    final style = ShowcaseText.monoLabel.copyWith(color: c.textSecondary);

    Widget bar(List<String> left, String right) => Container(
          width: double.infinity,
          color: c.surfaceAlt,
          padding: const EdgeInsets.symmetric(
              horizontal: Insets.md, vertical: Insets.sm),
          child: Row(
            children: [
              for (final item in left) ...[
                Text(item, style: style),
                const SizedBox(width: Insets.md),
              ],
              const Spacer(),
              Text(right, style: style),
            ],
          ),
        );

    if (stats == null) {
      return bar(const ['Ready when the editor loads'], 'UTF-8');
    }

    return ValueListenableBuilder<LiveStats>(
      valueListenable: stats,
      builder: (context, value, _) {
        return bar(
          [
            'Ln ${value.cursorPosition?.label ?? '1:1'}',
            '${value.lineCount.value} lines',
            if (value.selectedCharacters.value > 0)
              '${value.selectedCharacters.value} selected',
          ],
          (value.language ?? controller.language.id).toUpperCase(),
        );
      },
    );
  }
}
