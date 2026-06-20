import 'package:flutter/material.dart';

/// Inherited styling for [MonacoEditor]'s built-in Flutter chrome.
///
/// Wrap a subtree in [MonacoEditorTheme] to override the look of the
/// default loading spinner, error overlay, and status bar without replacing
/// them via the widget-level `loadingBuilder`/`errorBuilder`/`statusBarBuilder`
/// callbacks. Descendants resolve the theme via [MonacoEditorTheme.of].
///
/// This theme is intentionally separate from Monaco's own editor theme. To
/// change Monaco token colors or the editor surface background, register a
/// `MonacoThemeDefinition` instead.
///
/// ```dart
/// MonacoEditorTheme(
///   data: const MonacoEditorThemeData(
///     loadingIndicatorColor: Colors.amber,
///     statusBarBackgroundColor: Color(0xFF101010),
///   ),
///   child: const MonacoEditor(showStatusBar: true),
/// )
/// ```
class MonacoEditorTheme extends InheritedTheme {
  /// Creates a theme override for descendant [MonacoEditor] chrome.
  ///
  /// This constructor cannot be `const` because the widget composes nested
  /// ancestor themes through a `_MonacoEditorThemeResolver` wrapper whose
  /// `child` is a runtime parameter. Call sites incur a normal allocation,
  /// not a const lookup - acceptable for a theme widget that sits at the
  /// top of a subtree rather than rebuilding frequently.
  MonacoEditorTheme({super.key, required this.data, required Widget child})
    : _isResolved = false,
      super(child: _MonacoEditorThemeResolver(child: child));

  const MonacoEditorTheme._resolved({required this.data, required super.child})
    : _isResolved = true;

  /// The chrome theme applied to descendants.
  final MonacoEditorThemeData data;

  final bool _isResolved;

  /// Returns the composed ancestor [MonacoEditorThemeData] without applying any
  /// Material fallback derivation. Returns `null` when no ancestor is present.
  static MonacoEditorThemeData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MonacoEditorTheme>()
        ?.data;
  }

  /// Returns the resolved chrome theme for [context].
  ///
  /// Values from the nearest [MonacoEditorTheme] override the fallback theme
  /// derived from the surrounding Material [Theme]. The returned object is
  /// always fully populated, so default chrome widgets can read it without
  /// per-field null checks.
  static MonacoEditorThemeData of(BuildContext context) {
    final fallback = MonacoEditorThemeData.fallback(context);
    return fallback.merge(maybeOf(context));
  }

  @override
  bool updateShouldNotify(MonacoEditorTheme oldWidget) {
    return data != oldWidget.data || _isResolved != oldWidget._isResolved;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MonacoEditorTheme._resolved(data: data, child: child);
  }

  static MonacoEditorThemeData _resolveOverrides(BuildContext context) {
    final themes = <MonacoEditorTheme>[];
    context.visitAncestorElements((element) {
      if (element is InheritedElement && element.widget is MonacoEditorTheme) {
        themes.add(
          context.dependOnInheritedElement(element) as MonacoEditorTheme,
        );
      }
      return true;
    });

    var resolved = const MonacoEditorThemeData();
    for (final theme in themes.reversed) {
      resolved = resolved.merge(theme.data);
    }
    return resolved;
  }
}

class _MonacoEditorThemeResolver extends StatelessWidget {
  const _MonacoEditorThemeResolver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MonacoEditorTheme._resolved(
      data: MonacoEditorTheme._resolveOverrides(context),
      child: child,
    );
  }
}

/// Visual configuration for [MonacoEditor]'s built-in loading, error, and
/// status-bar chrome.
///
/// All fields are nullable so that explicit overrides can be distinguished
/// from defaults during [merge]. The defaults applied by [MonacoEditorTheme.of]
/// come from [MonacoEditorThemeData.fallback], which derives sensible values
/// from the surrounding Material [Theme].
@immutable
class MonacoEditorThemeData {
  /// Creates theme overrides for MonacoEditor's built-in chrome.
  ///
  /// Any field left `null` is filled in by [MonacoEditorThemeData.fallback]
  /// (or, when used as the right-hand side of [merge], leaves the underlying
  /// value untouched).
  const MonacoEditorThemeData({
    this.loadingIndicatorColor,
    this.loadingBackgroundColor,
    this.errorIconColor,
    this.errorTitleStyle,
    this.errorMessageStyle,
    this.errorBackgroundColor,
    this.retryButtonStyle,
    this.statusBarBackgroundColor,
    this.statusBarBorderColor,
    this.statusBarTextStyle,
    this.statusBarSpacing,
    this.statusBarPadding,
  });

  /// Color of the default loading spinner.
  final Color? loadingIndicatorColor;

  /// Optional background behind the default loading overlay.
  final Color? loadingBackgroundColor;

  /// Color of the default error icon.
  final Color? errorIconColor;

  /// Text style of the default error title.
  final TextStyle? errorTitleStyle;

  /// Text style of the default error message.
  final TextStyle? errorMessageStyle;

  /// Optional background behind the default error overlay.
  final Color? errorBackgroundColor;

  /// Button style used by the default retry button.
  final ButtonStyle? retryButtonStyle;

  /// Background color of the built-in status bar.
  final Color? statusBarBackgroundColor;

  /// Top border color of the built-in status bar.
  final Color? statusBarBorderColor;

  /// Text style of the built-in status bar entries.
  final TextStyle? statusBarTextStyle;

  /// Horizontal spacing between built-in status bar entries.
  final double? statusBarSpacing;

  /// Padding of the built-in status bar container.
  final EdgeInsetsGeometry? statusBarPadding;

  /// Returns a copy with selective overrides.
  MonacoEditorThemeData copyWith({
    Color? loadingIndicatorColor,
    Color? loadingBackgroundColor,
    Color? errorIconColor,
    TextStyle? errorTitleStyle,
    TextStyle? errorMessageStyle,
    Color? errorBackgroundColor,
    ButtonStyle? retryButtonStyle,
    Color? statusBarBackgroundColor,
    Color? statusBarBorderColor,
    TextStyle? statusBarTextStyle,
    double? statusBarSpacing,
    EdgeInsetsGeometry? statusBarPadding,
  }) {
    return MonacoEditorThemeData(
      loadingIndicatorColor:
          loadingIndicatorColor ?? this.loadingIndicatorColor,
      loadingBackgroundColor:
          loadingBackgroundColor ?? this.loadingBackgroundColor,
      errorIconColor: errorIconColor ?? this.errorIconColor,
      errorTitleStyle: errorTitleStyle ?? this.errorTitleStyle,
      errorMessageStyle: errorMessageStyle ?? this.errorMessageStyle,
      errorBackgroundColor: errorBackgroundColor ?? this.errorBackgroundColor,
      retryButtonStyle: retryButtonStyle ?? this.retryButtonStyle,
      statusBarBackgroundColor:
          statusBarBackgroundColor ?? this.statusBarBackgroundColor,
      statusBarBorderColor: statusBarBorderColor ?? this.statusBarBorderColor,
      statusBarTextStyle: statusBarTextStyle ?? this.statusBarTextStyle,
      statusBarSpacing: statusBarSpacing ?? this.statusBarSpacing,
      statusBarPadding: statusBarPadding ?? this.statusBarPadding,
    );
  }

  /// Overlays non-null fields from [other] onto this theme.
  ///
  /// Used by [MonacoEditorTheme.of] to merge ancestor overrides on top of the
  /// derived Material fallback so default chrome widgets see a fully
  /// populated theme. Returns `this` unchanged when [other] is `null`.
  MonacoEditorThemeData merge(MonacoEditorThemeData? other) {
    if (other == null) return this;
    return copyWith(
      loadingIndicatorColor: other.loadingIndicatorColor,
      loadingBackgroundColor: other.loadingBackgroundColor,
      errorIconColor: other.errorIconColor,
      errorTitleStyle: other.errorTitleStyle,
      errorMessageStyle: other.errorMessageStyle,
      errorBackgroundColor: other.errorBackgroundColor,
      retryButtonStyle: other.retryButtonStyle,
      statusBarBackgroundColor: other.statusBarBackgroundColor,
      statusBarBorderColor: other.statusBarBorderColor,
      statusBarTextStyle: other.statusBarTextStyle,
      statusBarSpacing: other.statusBarSpacing,
      statusBarPadding: other.statusBarPadding,
    );
  }

  /// Resolves a sensible fallback theme from the current Material theme.
  static MonacoEditorThemeData fallback(BuildContext context) {
    final theme = Theme.of(context);
    return MonacoEditorThemeData(
      loadingIndicatorColor: theme.colorScheme.primary,
      loadingBackgroundColor: Colors.transparent,
      errorIconColor: theme.colorScheme.error,
      errorTitleStyle: theme.textTheme.titleMedium,
      errorMessageStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
      ),
      errorBackgroundColor: Colors.transparent,
      retryButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      statusBarBackgroundColor: theme.colorScheme.surface.withValues(
        alpha: 0.95,
      ),
      statusBarBorderColor: theme.dividerColor,
      statusBarTextStyle:
          theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
      statusBarSpacing: 16,
      statusBarPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonacoEditorThemeData &&
        other.loadingIndicatorColor == loadingIndicatorColor &&
        other.loadingBackgroundColor == loadingBackgroundColor &&
        other.errorIconColor == errorIconColor &&
        other.errorTitleStyle == errorTitleStyle &&
        other.errorMessageStyle == errorMessageStyle &&
        other.errorBackgroundColor == errorBackgroundColor &&
        other.retryButtonStyle == retryButtonStyle &&
        other.statusBarBackgroundColor == statusBarBackgroundColor &&
        other.statusBarBorderColor == statusBarBorderColor &&
        other.statusBarTextStyle == statusBarTextStyle &&
        other.statusBarSpacing == statusBarSpacing &&
        other.statusBarPadding == statusBarPadding;
  }

  @override
  int get hashCode {
    return Object.hash(
      loadingIndicatorColor,
      loadingBackgroundColor,
      errorIconColor,
      errorTitleStyle,
      errorMessageStyle,
      errorBackgroundColor,
      retryButtonStyle,
      statusBarBackgroundColor,
      statusBarBorderColor,
      statusBarTextStyle,
      statusBarSpacing,
      statusBarPadding,
    );
  }
}
