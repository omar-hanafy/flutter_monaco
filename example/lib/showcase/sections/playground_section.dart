import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

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
          Text(
            'Live playground',
            style: ShowcaseText.h1.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Insets.md),
          Text(
            'Real Monaco, running right here. Switch languages and themes, '
            'toggle options, or trigger a feature - it all drives one editor.',
            style: ShowcaseText.bodyLg.copyWith(color: c.textSecondary),
          ),
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
      child: Column(
        children: [
          _Toolbar(controller: controller),
          Divider(height: 1, color: c.border),
          if (controller.tabs.isNotEmpty) ...[
            _DocTabs(controller: controller),
            Divider(height: 1, color: c.border),
          ],
          // Keep the iframe-backed HtmlElementView as a direct sized child.
          // In the web showcase, Stack/Positioned.fill collapses its DOM rect.
          // The key sits on the Column child: when the tab strip appears
          // above, reconciliation must match this subtree by key or the
          // editor is disposed and rebooted.
          SizedBox(
            key: const ValueKey('showcase-playground-editor-box'),
            height: editorHeight,
            child: MonacoEditor(
              key: const ValueKey('showcase-playground-editor'),
              options: controller.initialEditorOptions,
              initialText: controller.initialValue,
              page: const MonacoPageConfig(customCss: kEditorCustomCss),
              backgroundColor: const Color(0xFF0D1117),
              // Edge scroll handoff: once the editor hits its scroll edge,
              // the wheel keeps scrolling the page (and the event feed shows
              // the MonacoScrollHandoffEvent doing it).
              scrollHandoff: const MonacoScrollHandoff.edge(),
              onReady: controller.attachEditor,
            ),
          ),
          if (monaco != null)
            MonacoFocusGuard(
              controller: monaco,
              modalRouteObserver: routeObserver,
            ),
          if (controller.hint != null)
            _HintBanner(hint: controller.hint!, onClose: controller.reset),
          if (controller.eventFeedOpen) _EventFeedPanel(controller: controller),
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
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Wrap(
        spacing: Insets.sm,
        runSpacing: Insets.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ToolbarMenu<MonacoLanguage>(
            icon: Icons.translate_rounded,
            value: controller.language,
            entries: [
              for (final l in kPlaygroundLanguages) (l, l.label ?? l.id),
            ],
            onSelected: controller.setLanguage,
          ),
          _ToolbarMenu<PlaygroundTheme>(
            icon: Icons.palette_outlined,
            value: controller.playgroundTheme,
            entries: [for (final t in PlaygroundTheme.values) (t, t.label)],
            onSelected: controller.setPlaygroundTheme,
          ),
          _ToolbarAction(
            icon: Icons.format_align_left_rounded,
            tooltip: 'Format',
            onTap: controller.format,
          ),
          _ToolbarAction(
            icon: Icons.search_rounded,
            tooltip: 'Find',
            onTap: controller.find,
          ),
          _ToolbarAction(
            icon: Icons.unfold_less_rounded,
            tooltip: 'Fold all',
            onTap: controller.foldAll,
          ),
          _ToolbarAction(
            icon: Icons.content_copy_rounded,
            tooltip: 'Copy',
            onTap: () => _copy(context),
          ),
          _ToolbarAction(
            icon: Icons.restart_alt_rounded,
            tooltip: 'Reset',
            onTap: controller.reset,
          ),
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
                Icon(
                  Icons.check,
                  size: 16,
                  color: v == value
                      ? ShowcaseColors.accentBlue
                      : Colors.transparent,
                ),
                const SizedBox(width: Insets.sm),
                Text(
                  label,
                  style: ShowcaseText.small.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
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
            Text(
              _currentLabel,
              style: ShowcaseText.small.copyWith(color: c.textPrimary),
            ),
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
        Text(
          'EDITOR OPTIONS',
          style: ShowcaseText.label.copyWith(color: c.textFaint),
        ),
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
              onChanged: controller.setMinimap,
            ),
            _ToggleChip(
              icon: Icons.wrap_text_rounded,
              label: 'Word wrap',
              value: controller.wordWrap,
              onChanged: controller.setWordWrap,
            ),
            _ToggleChip(
              icon: Icons.format_list_numbered_rounded,
              label: 'Line numbers',
              value: controller.lineNumbers,
              onChanged: controller.setLineNumbers,
            ),
            _ToggleChip(
              icon: Icons.lock_outline_rounded,
              label: 'Read-only',
              value: controller.readOnly,
              onChanged: controller.setReadOnly,
            ),
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
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
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
              Icon(
                icon,
                size: 15,
                color: active ? ShowcaseColors.accentBlue : c.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: ShowcaseText.small.copyWith(
                  color: active ? ShowcaseColors.accentBlue : c.textSecondary,
                ),
              ),
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
            icon: Icons.remove,
            onTap: () => controller.changeFontSize(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${controller.fontSize.toInt()}px',
              style: ShowcaseText.monoLabel.copyWith(color: c.textSecondary),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: () => controller.changeFontSize(1),
          ),
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
        Text(
          'TRY A FEATURE',
          style: ShowcaseText.label.copyWith(color: c.textFaint),
        ),
        const SizedBox(height: Insets.md),
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            _DemoButton(
              icon: Icons.keyboard_command_key_rounded,
              label: 'Custom action (Ctrl/Cmd+S)',
              onTap: controller.runCustomActionDemo,
            ),
            _DemoButton(
              icon: Icons.tab_rounded,
              label: 'Multi-document',
              onTap: controller.runMultiDocumentDemo,
            ),
            _DemoButton(
              icon: Icons.podcasts_rounded,
              label: 'Event stream',
              onTap: controller.runEventsDemo,
            ),
            _DemoButton(
              icon: Icons.auto_awesome_outlined,
              label: 'IntelliSense',
              onTap: controller.runIntelliSenseDemo,
            ),
            _DemoButton(
              icon: Icons.fact_check_outlined,
              label: 'JSON validation',
              onTap: controller.runJsonValidationDemo,
            ),
            _DemoButton(
              icon: Icons.error_outline_rounded,
              label: 'Markers',
              onTap: controller.runMarkersDemo,
            ),
            _DemoButton(
              icon: Icons.format_color_fill_outlined,
              label: 'Decorations',
              onTap: controller.runDecorationsDemo,
            ),
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
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
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
              Text(
                label,
                style: ShowcaseText.small.copyWith(color: c.textPrimary),
              ),
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
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: ShowcaseColors.accentBlue,
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              hint,
              style: ShowcaseText.small.copyWith(color: c.textPrimary),
            ),
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

  /// The right-hand slot: live handshake data once the editor is up
  /// (Monaco + protocol version straight from `controller.capabilities`).
  String get _handshakeLabel {
    final caps = controller.capabilities;
    if (caps == null) return 'Monaco ${MonacoAssets.monacoVersion}';
    return 'Monaco ${caps.monacoVersion} · protocol v${caps.protocolVersion}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    final stats = controller.liveStats;
    final style = ShowcaseText.monoLabel.copyWith(color: c.textSecondary);

    Widget bar(List<String> left, String right) => Container(
      width: double.infinity,
      color: c.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Row(
        children: [
          for (final item in left) ...[
            Text(item, style: style),
            const SizedBox(width: Insets.md),
          ],
          const Spacer(),
          Text(right, style: style, overflow: TextOverflow.ellipsis),
        ],
      ),
    );

    if (stats == null) {
      return bar(const ['Ready when the editor loads'], _handshakeLabel);
    }

    return ValueListenableBuilder<MonacoLiveStats>(
      valueListenable: stats,
      builder: (context, value, _) {
        final cursor = value.cursorPosition;
        return bar([
          'Ln ${cursor != null ? '${cursor.line}:${cursor.column}' : '1:1'}',
          // Stats arrive with the first edit/cursor event; hide the
          // zero-valued placeholder until then.
          if (value.lineCount > 0) '${value.lineCount} lines',
          if (value.selectedCharacters > 0)
            '${value.selectedCharacters} selected',
          (value.language ?? controller.language).id.toUpperCase(),
        ], _handshakeLabel);
      },
    );
  }
}

class _DocTabs extends StatelessWidget {
  const _DocTabs({required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      width: double.infinity,
      color: c.surfaceAlt,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: controller.dirtyDocs,
          builder: (context, dirty, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, tab) in controller.tabs.indexed)
                  _DocTab(
                    label: tab.label,
                    active: index == controller.activeTab,
                    dirty: dirty.contains(tab.uri?.toString()),
                    closable: index > 0,
                    onTap: () => controller.activateTab(index),
                    onClose: () => controller.closeTab(index),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DocTab extends StatelessWidget {
  const _DocTab({
    required this.label,
    required this.active,
    required this.dirty,
    required this.closable,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final bool active;
  final bool dirty;
  final bool closable;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            color: active ? c.surface : Colors.transparent,
            border: Border(
              top: BorderSide(
                width: 2,
                color: active ? ShowcaseColors.accentBlue : Colors.transparent,
              ),
              right: BorderSide(color: c.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: ShowcaseText.monoLabel.copyWith(
                  color: active ? c.textPrimary : c.textSecondary,
                ),
              ),
              if (dirty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: ShowcaseColors.accentCyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              if (closable) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onClose,
                  child: Icon(Icons.close, size: 13, color: c.textFaint),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventFeedPanel extends StatelessWidget {
  const _EventFeedPanel({required this.controller});

  final ShowcaseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.showcaseColors;
    return Container(
      width: double.infinity,
      color: c.surfaceAlt,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.podcasts_rounded,
                size: 14,
                color: ShowcaseColors.accentBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'controller.events - sealed MonacoEvent union, live',
                style: ShowcaseText.label.copyWith(color: c.textSecondary),
              ),
              const Spacer(),
              InkWell(
                onTap: controller.closeEventFeed,
                child: Icon(Icons.close, size: 15, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          ValueListenableBuilder<List<ShowcaseEventEntry>>(
            valueListenable: controller.eventLog,
            builder: (context, entries, _) {
              if (entries.isEmpty) {
                return Text(
                  'Waiting for events - type or select in the editor.',
                  style: ShowcaseText.monoSm.copyWith(color: c.textFaint),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text(
                            entry.type,
                            style: ShowcaseText.monoSm.copyWith(
                              color: ShowcaseColors.accentCyan,
                            ),
                          ),
                          const SizedBox(width: Insets.sm),
                          Expanded(
                            child: Text(
                              entry.detail,
                              overflow: TextOverflow.ellipsis,
                              style: ShowcaseText.monoSm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
