import 'package:flutter_monaco/src/models/monaco_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'monaco_theme_definition.freezed.dart';

/// A typed Dart representation of Monaco's `IStandaloneThemeData`.
///
/// Register definitions with [MonacoController.defineTheme] and select them
/// via [MonacoController.setThemeById] or by setting [EditorOptions.themeId]
/// to the definition's [id].
///
/// Mirrors the Monaco editor theme schema while keeping the surface
/// idiomatic for Dart callers: an enum [base], strongly-typed [rules], and a
/// Monaco token-color [colors] map. Use [toMonacoThemeData] when forwarding
/// to the JS bridge and [toJson]/[fromJson] for app-level persistence (the
/// JSON shape includes [id] so loaded themes round-trip cleanly).
@freezed
sealed class MonacoThemeDefinition with _$MonacoThemeDefinition {
  /// Creates a custom Monaco theme definition.
  const factory MonacoThemeDefinition({
    /// Custom theme identifier passed to `monaco.editor.setTheme`.
    required String id,

    /// Built-in Monaco base theme used as the starting point.
    required MonacoTheme base,

    /// Whether Monaco should inherit unspecified rules from [base].
    @Default(true) bool inherit,

    /// Token color rules layered on top of [base].
    @Default(<MonacoThemeRule>[]) List<MonacoThemeRule> rules,

    /// Monaco color-token map (e.g. `{'editor.background': '#1E1E1E'}`).
    @Default(<String, String>{}) Map<String, String> colors,

    /// Optional encoded token colors accepted by Monaco.
    List<String>? encodedTokensColors,
  }) = _MonacoThemeDefinition;

  const MonacoThemeDefinition._();

  /// Creates a definition from JSON produced by [toJson].
  ///
  /// Requires a non-empty `id` field. Raw Monaco `IStandaloneThemeData`
  /// payloads (which don't carry the registration id) should be loaded via
  /// [MonacoThemeDefinition.fromMonacoThemeData].
  factory MonacoThemeDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'MonacoThemeDefinition id must be a non-empty string',
      );
    }

    final rawRules = json['rules'];
    final rules = rawRules is List
        ? rawRules.whereType<Map>().map((entry) {
            return MonacoThemeRule.fromJson(Map<String, dynamic>.from(entry));
          }).toList()
        : const <MonacoThemeRule>[];

    final rawColors = json['colors'];
    final colors = rawColors is Map
        ? rawColors.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : const <String, String>{};

    final rawEncoded = json['encodedTokensColors'];
    final encodedTokensColors = rawEncoded is List
        ? rawEncoded.map((value) => value.toString()).toList()
        : null;

    final rawInherit = json['inherit'];

    return MonacoThemeDefinition(
      id: id,
      base: MonacoTheme.fromId(
        json['base']?.toString(),
        orElse: MonacoTheme.vsDark,
      ),
      inherit: rawInherit is bool ? rawInherit : true,
      rules: rules,
      colors: colors,
      encodedTokensColors: encodedTokensColors,
    );
  }

  /// Creates a definition from raw Monaco `IStandaloneThemeData`.
  ///
  /// Use this when loading theme data that doesn't carry a registration id
  /// (e.g. third-party `.json` files designed for direct use with
  /// `monaco.editor.defineTheme`). The supplied [id] becomes the theme's
  /// registration key.
  factory MonacoThemeDefinition.fromMonacoThemeData(
    String id,
    Map<String, dynamic> data,
  ) {
    return MonacoThemeDefinition.fromJson({'id': id, ...data});
  }

  /// Serializes this theme for app persistence.
  ///
  /// The shape includes [id] so [fromJson] can rebuild a complete
  /// definition. Use [toMonacoThemeData] when forwarding to the JS bridge.
  Map<String, dynamic> toJson() {
    return {'id': id, ...toMonacoThemeData()};
  }

  /// Serializes this theme to Monaco's `IStandaloneThemeData` shape.
  ///
  /// Excludes [id] (which is the registration key, not part of the theme
  /// data) and omits `encodedTokensColors` when unset.
  Map<String, dynamic> toMonacoThemeData() {
    return <String, dynamic>{
      'base': base.id,
      'inherit': inherit,
      'rules': rules.map((rule) => rule.toJson()).toList(),
      'colors': colors,
      if (encodedTokensColors != null)
        'encodedTokensColors': encodedTokensColors,
    };
  }
}

/// A single token color rule inside a [MonacoThemeDefinition].
///
/// Mirrors Monaco's `ITokenThemeRule`: a [token] selector with optional
/// [foreground]/[background] colors (without the `#` prefix) and a
/// [fontStyle] string such as `italic`, `bold`, or `italic underline`.
@freezed
sealed class MonacoThemeRule with _$MonacoThemeRule {
  /// Creates a Monaco token color rule.
  const factory MonacoThemeRule({
    /// Token selector, for example `comment`, `keyword`, or `string`.
    required String token,

    /// Foreground color without the `#` prefix.
    String? foreground,

    /// Background color without the `#` prefix.
    String? background,

    /// Monaco font style string (e.g. `italic`, `bold`, `italic underline`).
    String? fontStyle,
  }) = _MonacoThemeRule;

  const MonacoThemeRule._();

  /// Creates a rule from Monaco-shaped JSON.
  ///
  /// Monaco accepts an empty [token] string as the default-rule selector
  /// (applied when no more-specific rule matches), so the empty case is
  /// allowed here too.
  factory MonacoThemeRule.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String) {
      throw ArgumentError.value(
        token,
        'token',
        'MonacoThemeRule token must be a string',
      );
    }
    return MonacoThemeRule(
      token: token,
      foreground: json['foreground']?.toString(),
      background: json['background']?.toString(),
      fontStyle: json['fontStyle']?.toString(),
    );
  }

  /// Serializes this rule, omitting null-valued style fields.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      if (foreground != null) 'foreground': foreground,
      if (background != null) 'background': background,
      if (fontStyle != null) 'fontStyle': fontStyle,
    };
  }
}
