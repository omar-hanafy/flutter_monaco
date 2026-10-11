import 'package:flutter_monaco/src/options/option_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sub_options.freezed.dart';

/// Editor content padding, in pixels.
///
/// All fields are nullable: `null` means "do not send this key to Monaco"
/// (Monaco keeps its own default or the previously applied value).
@freezed
sealed class MonacoPadding with _$MonacoPadding {
  /// Creates a padding configuration.
  const factory MonacoPadding({
    /// Space above the first line, in pixels.
    int? top,

    /// Space below the last line, in pixels.
    int? bottom,
  }) = _MonacoPadding;

  const MonacoPadding._();

  /// Returns a copy where non-null fields of [other] override this
  /// instance's fields. Returns `this` when [other] is null.
  MonacoPadding merge(MonacoPadding? other) {
    if (other == null) return this;
    return MonacoPadding(top: other.top ?? top, bottom: other.bottom ?? bottom);
  }

  /// Parses a padding map produced by [toJson].
  ///
  /// Throws a [FormatException] on wrongly-typed values.
  factory MonacoPadding.fromJson(Map<String, dynamic> json) {
    return MonacoPadding(
      top: _optInt(json, 'top', 'MonacoPadding'),
      bottom: _optInt(json, 'bottom', 'MonacoPadding'),
    );
  }

  /// Serializes for persistence; omits null fields.
  Map<String, dynamic> toJson() => toMonacoJson();

  /// Monaco `padding` option payload; omits null fields.
  Map<String, dynamic> toMonacoJson() {
    return {if (top != null) 'top': top, if (bottom != null) 'bottom': bottom};
  }
}

/// Minimap (code overview strip) configuration.
@freezed
sealed class MonacoMinimapOptions with _$MonacoMinimapOptions {
  /// Creates a minimap configuration.
  const factory MonacoMinimapOptions({
    /// Whether the minimap is shown.
    bool? enabled,

    /// Which side of the editor hosts the minimap.
    MonacoMinimapSide? side,

    /// Whether real characters (instead of color blocks) are rendered.
    bool? renderCharacters,

    /// Maximum number of columns the minimap renders.
    int? maxColumn,

    /// Minimap scale factor (1, 2, or 3).
    int? scale,
  }) = _MonacoMinimapOptions;

  const MonacoMinimapOptions._();

  /// Returns a copy where non-null fields of [other] override this
  /// instance's fields. Returns `this` when [other] is null.
  MonacoMinimapOptions merge(MonacoMinimapOptions? other) {
    if (other == null) return this;
    return MonacoMinimapOptions(
      enabled: other.enabled ?? enabled,
      side: other.side ?? side,
      renderCharacters: other.renderCharacters ?? renderCharacters,
      maxColumn: other.maxColumn ?? maxColumn,
      scale: other.scale ?? scale,
    );
  }

  /// Parses a minimap map produced by [toJson].
  ///
  /// Throws a [FormatException] on wrongly-typed values.
  factory MonacoMinimapOptions.fromJson(Map<String, dynamic> json) {
    return MonacoMinimapOptions(
      enabled: _optBool(json, 'enabled', 'MonacoMinimapOptions'),
      side: _optEnum(
        json,
        'side',
        'MonacoMinimapOptions',
        MonacoMinimapSide.values,
        (e) => e.id,
      ),
      renderCharacters: _optBool(
        json,
        'renderCharacters',
        'MonacoMinimapOptions',
      ),
      maxColumn: _optInt(json, 'maxColumn', 'MonacoMinimapOptions'),
      scale: _optInt(json, 'scale', 'MonacoMinimapOptions'),
    );
  }

  /// Serializes for persistence; omits null fields.
  Map<String, dynamic> toJson() => toMonacoJson();

  /// Monaco `minimap` option payload; omits null fields.
  Map<String, dynamic> toMonacoJson() {
    return {
      if (enabled != null) 'enabled': enabled,
      if (side != null) 'side': side!.id,
      if (renderCharacters != null) 'renderCharacters': renderCharacters,
      if (maxColumn != null) 'maxColumn': maxColumn,
      if (scale != null) 'scale': scale,
    };
  }
}

/// Scrollbar behavior and sizing.
@freezed
sealed class MonacoScrollbarOptions with _$MonacoScrollbarOptions {
  /// Creates a scrollbar configuration.
  const factory MonacoScrollbarOptions({
    /// Vertical scrollbar visibility.
    MonacoScrollbarVisibility? vertical,

    /// Horizontal scrollbar visibility.
    MonacoScrollbarVisibility? horizontal,

    /// Vertical scrollbar width, in pixels.
    int? verticalScrollbarSize,

    /// Horizontal scrollbar height, in pixels.
    int? horizontalScrollbarSize,

    /// Whether the editor consumes mouse wheel events.
    bool? handleMouseWheel,

    /// Whether scrollbars cast shadows on the content.
    bool? useShadows,
  }) = _MonacoScrollbarOptions;

  const MonacoScrollbarOptions._();

  /// Returns a copy where non-null fields of [other] override this
  /// instance's fields. Returns `this` when [other] is null.
  MonacoScrollbarOptions merge(MonacoScrollbarOptions? other) {
    if (other == null) return this;
    return MonacoScrollbarOptions(
      vertical: other.vertical ?? vertical,
      horizontal: other.horizontal ?? horizontal,
      verticalScrollbarSize:
          other.verticalScrollbarSize ?? verticalScrollbarSize,
      horizontalScrollbarSize:
          other.horizontalScrollbarSize ?? horizontalScrollbarSize,
      handleMouseWheel: other.handleMouseWheel ?? handleMouseWheel,
      useShadows: other.useShadows ?? useShadows,
    );
  }

  /// Parses a scrollbar map produced by [toJson].
  ///
  /// Throws a [FormatException] on wrongly-typed values.
  factory MonacoScrollbarOptions.fromJson(Map<String, dynamic> json) {
    return MonacoScrollbarOptions(
      vertical: _optEnum(
        json,
        'vertical',
        'MonacoScrollbarOptions',
        MonacoScrollbarVisibility.values,
        (e) => e.id,
      ),
      horizontal: _optEnum(
        json,
        'horizontal',
        'MonacoScrollbarOptions',
        MonacoScrollbarVisibility.values,
        (e) => e.id,
      ),
      verticalScrollbarSize: _optInt(
        json,
        'verticalScrollbarSize',
        'MonacoScrollbarOptions',
      ),
      horizontalScrollbarSize: _optInt(
        json,
        'horizontalScrollbarSize',
        'MonacoScrollbarOptions',
      ),
      handleMouseWheel: _optBool(
        json,
        'handleMouseWheel',
        'MonacoScrollbarOptions',
      ),
      useShadows: _optBool(json, 'useShadows', 'MonacoScrollbarOptions'),
    );
  }

  /// Serializes for persistence; omits null fields.
  Map<String, dynamic> toJson() => toMonacoJson();

  /// Monaco `scrollbar` option payload; omits null fields.
  Map<String, dynamic> toMonacoJson() {
    return {
      if (vertical != null) 'vertical': vertical!.id,
      if (horizontal != null) 'horizontal': horizontal!.id,
      if (verticalScrollbarSize != null)
        'verticalScrollbarSize': verticalScrollbarSize,
      if (horizontalScrollbarSize != null)
        'horizontalScrollbarSize': horizontalScrollbarSize,
      if (handleMouseWheel != null) 'handleMouseWheel': handleMouseWheel,
      if (useShadows != null) 'useShadows': useShadows,
    };
  }
}

/// Bracket-pair and indentation guide rendering.
@freezed
sealed class MonacoGuidesOptions with _$MonacoGuidesOptions {
  /// Creates a guides configuration.
  const factory MonacoGuidesOptions({
    /// Whether bracket-pair guides are rendered.
    bool? bracketPairs,

    /// Whether indentation guides are rendered.
    bool? indentation,
  }) = _MonacoGuidesOptions;

  const MonacoGuidesOptions._();

  /// Returns a copy where non-null fields of [other] override this
  /// instance's fields. Returns `this` when [other] is null.
  MonacoGuidesOptions merge(MonacoGuidesOptions? other) {
    if (other == null) return this;
    return MonacoGuidesOptions(
      bracketPairs: other.bracketPairs ?? bracketPairs,
      indentation: other.indentation ?? indentation,
    );
  }

  /// Parses a guides map produced by [toJson].
  ///
  /// Throws a [FormatException] on wrongly-typed values.
  factory MonacoGuidesOptions.fromJson(Map<String, dynamic> json) {
    return MonacoGuidesOptions(
      bracketPairs: _optBool(json, 'bracketPairs', 'MonacoGuidesOptions'),
      indentation: _optBool(json, 'indentation', 'MonacoGuidesOptions'),
    );
  }

  /// Serializes for persistence; omits null fields.
  Map<String, dynamic> toJson() => toMonacoJson();

  /// Monaco `guides` option payload; omits null fields.
  Map<String, dynamic> toMonacoJson() {
    return {
      if (bracketPairs != null) 'bracketPairs': bracketPairs,
      if (indentation != null) 'indentation': indentation,
    };
  }
}

/// Sticky scroll (pinned enclosing scopes at the top of the viewport).
@freezed
sealed class MonacoStickyScroll with _$MonacoStickyScroll {
  /// Creates a sticky scroll configuration.
  const factory MonacoStickyScroll({
    /// Whether sticky scroll is enabled.
    bool? enabled,

    /// Maximum number of sticky lines shown.
    int? maxLineCount,
  }) = _MonacoStickyScroll;

  const MonacoStickyScroll._();

  /// Returns a copy where non-null fields of [other] override this
  /// instance's fields. Returns `this` when [other] is null.
  MonacoStickyScroll merge(MonacoStickyScroll? other) {
    if (other == null) return this;
    return MonacoStickyScroll(
      enabled: other.enabled ?? enabled,
      maxLineCount: other.maxLineCount ?? maxLineCount,
    );
  }

  /// Parses a sticky scroll map produced by [toJson].
  ///
  /// Throws a [FormatException] on wrongly-typed values.
  factory MonacoStickyScroll.fromJson(Map<String, dynamic> json) {
    return MonacoStickyScroll(
      enabled: _optBool(json, 'enabled', 'MonacoStickyScroll'),
      maxLineCount: _optInt(json, 'maxLineCount', 'MonacoStickyScroll'),
    );
  }

  /// Serializes for persistence; omits null fields.
  Map<String, dynamic> toJson() => toMonacoJson();

  /// Monaco `stickyScroll` option payload; omits null fields.
  Map<String, dynamic> toMonacoJson() {
    return {
      if (enabled != null) 'enabled': enabled,
      if (maxLineCount != null) 'maxLineCount': maxLineCount,
    };
  }
}

int? _optInt(Map<String, dynamic> json, String key, String type) {
  final value = json[key];
  if (value == null) return null;
  // Web numbers are doubles: `2.0 is int` and `double.infinity is int` hold.
  if (value is int && value.isFinite) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw FormatException(
    '$type.fromJson: "$key" must be an integer, got $value',
  );
}

bool? _optBool(Map<String, dynamic> json, String key, String type) {
  final value = json[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException('$type.fromJson: "$key" must be a bool, got $value');
}

T? _optEnum<T>(
  Map<String, dynamic> json,
  String key,
  String type,
  List<T> values,
  String Function(T) idOf,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) {
    for (final candidate in values) {
      if (idOf(candidate) == value) return candidate;
    }
  }
  throw FormatException('$type.fromJson: unknown "$key" value $value');
}
