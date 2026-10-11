/// Default chrome for `MonacoEditor` (status bar, loading, error states).
///
/// These widgets are package-internal: `MonacoEditor` renders them when no
/// `statusBarBuilder`/`loadingBuilder`/`errorBuilder` is supplied, and they
/// style themselves from [MonacoEditorTheme]. They are not exported by the
/// package barrel.
library;

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:material_ui/material_ui.dart';

/// The default status bar, optimized to only rebuild when stats change.
///
/// Renders cursor position, character count, selection counts, and the
/// language label from [MonacoController.stats] (D28: labels are composed
/// here on the Dart side, not in the page).
class MonacoStatusBar extends StatelessWidget {
  /// Creates the default status bar for [controller].
  const MonacoStatusBar({required this.controller, super.key});

  /// The controller whose live stats drive the bar.
  final MonacoController controller;

  @override
  Widget build(BuildContext context) {
    final theme = MonacoEditorTheme.of(context);
    final style =
        theme.statusBarTextStyle ??
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12);

    return ValueListenableBuilder<MonacoLiveStats>(
      valueListenable: controller.stats,
      builder: (context, stats, _) {
        final language = stats.language;
        final entries = [
          if (stats.cursorPosition != null)
            'Ln ${stats.cursorPosition!.line}, Col '
                '${stats.cursorPosition!.column}',
          'Ch ${stats.charCount}',
          if (stats.selectedLines > 0) 'Sel Ln ${stats.selectedLines}',
          if (stats.selectedCharacters > 0)
            'Sel Ch ${stats.selectedCharacters}',
          if (language != null) language.label ?? language.id,
        ].where((s) => s.isNotEmpty).toList();

        return Container(
          padding:
              theme.statusBarPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.statusBarBackgroundColor,
            border: Border(
              top: BorderSide(
                color:
                    theme.statusBarBorderColor ??
                    Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: theme.statusBarSpacing ?? 16,
            runSpacing: 4,
            children: [for (final entry in entries) Text(entry, style: style)],
          ),
        );
      },
    );
  }
}

/// The default loading placeholder shown while the editor boots.
class MonacoDefaultLoading extends StatelessWidget {
  /// Creates the default loading placeholder.
  const MonacoDefaultLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MonacoEditorTheme.of(context);
    return ColoredBox(
      color: theme.loadingBackgroundColor ?? Colors.transparent,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.loadingIndicatorColor,
          ),
        ),
      ),
    );
  }
}

/// The default error surface shown when editor initialization fails.
class MonacoDefaultError extends StatelessWidget {
  /// Creates the default error surface for [error].
  const MonacoDefaultError({required this.error, this.onRetry, super.key});

  /// The boot failure being displayed.
  final Object error;

  /// Invoked by the retry button; the button is hidden when null.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final theme = MonacoEditorTheme.of(context);
    final titleStyle =
        theme.errorTitleStyle ?? materialTheme.textTheme.titleMedium;
    final style = theme.errorMessageStyle ?? materialTheme.textTheme.bodyMedium;

    return ColoredBox(
      color: theme.errorBackgroundColor ?? Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.errorIconColor ?? materialTheme.colorScheme.error,
                size: 36,
              ),
              const SizedBox(height: 16),
              Text('Failed to Initialize Editor', style: titleStyle),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center, style: style),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: theme.retryButtonStyle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
