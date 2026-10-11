import 'package:flutter_monaco/src/options/option_enums.dart';

/// A Monaco editor theme identifier.
///
/// This is an extension type over [String]: it erases to a plain [String] at
/// runtime, so `jsonEncode` works on it directly and equality is string
/// equality. Because of the erasure, `is MonacoTheme` checks are not
/// meaningful at runtime. Custom theme ids are constructed directly, for
/// example `MonacoTheme('app-dark')`.
extension type const MonacoTheme(
  /// The raw theme id string sent to the Monaco editor.
  String id,
) {
  /// The standard light theme.
  static const vs = MonacoTheme('vs');

  /// The standard dark theme.
  static const vsDark = MonacoTheme('vs-dark');

  /// A high-contrast dark theme for accessibility.
  static const hcBlack = MonacoTheme('hc-black');

  /// A high-contrast light theme for accessibility.
  static const hcLight = MonacoTheme('hc-light');

  /// All themes bundled with the Monaco editor.
  static const List<MonacoTheme> builtIn = [vs, vsDark, hcBlack, hcLight];

  /// Whether this theme is one of the themes bundled with the Monaco editor.
  bool get isBuiltIn => builtIn.contains(this);

  /// A human-readable label for built-in themes, or `null` for custom ids.
  String? get label => switch (id) {
    'vs' => 'Light',
    'vs-dark' => 'Dark',
    'hc-black' => 'High Contrast Dark',
    'hc-light' => 'High Contrast Light',
    _ => null,
  };

  /// The [MonacoBaseTheme] equivalent for built-in themes, or `null` for
  /// custom ids.
  MonacoBaseTheme? get asBaseTheme => switch (id) {
    'vs' => MonacoBaseTheme.vs,
    'vs-dark' => MonacoBaseTheme.vsDark,
    'hc-black' => MonacoBaseTheme.hcBlack,
    'hc-light' => MonacoBaseTheme.hcLight,
    _ => null,
  };
}
