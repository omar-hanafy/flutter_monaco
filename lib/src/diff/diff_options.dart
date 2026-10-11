/// @docImport 'package:flutter_monaco/src/options/editor_options.dart';
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'diff_options.freezed.dart';

/// Diff-editor-specific options for `MonacoDiffController` /
/// `MonacoDiffEditor`.
///
/// All fields are nullable and sparse like [EditorOptions]: only set fields
/// are sent to Monaco, so unset fields keep Monaco's own defaults. Escape
/// hatch: [extra] entries are merged last and win over typed fields.
@Freezed(fromJson: false, toJson: false)
sealed class MonacoDiffOptions with _$MonacoDiffOptions {
  /// Creates sparse diff options.
  const factory MonacoDiffOptions({
    /// `true` renders original and modified side by side; `false` renders
    /// an inline (unified) diff.
    bool? renderSideBySide,

    /// Whether the modified editor is read-only.
    bool? readOnly,

    /// Whether the original (left) editor accepts edits.
    bool? originalEditable,

    /// Whether leading/trailing whitespace differences are ignored.
    bool? ignoreTrimWhitespace,

    /// Whether the revert arrows are shown in the glyph margin.
    bool? renderMarginRevertIcon,

    /// Raw Monaco diff options merged last (they win over typed fields).
    Map<String, Object?>? extra,
  }) = _MonacoDiffOptions;

  const MonacoDiffOptions._();

  /// The sparse Monaco `IDiffEditorOptions` map (nulls omitted).
  Map<String, Object?> toMonacoOptions() => {
    if (renderSideBySide != null) 'renderSideBySide': renderSideBySide,
    if (readOnly != null) 'readOnly': readOnly,
    if (originalEditable != null) 'originalEditable': originalEditable,
    if (ignoreTrimWhitespace != null)
      'ignoreTrimWhitespace': ignoreTrimWhitespace,
    if (renderMarginRevertIcon != null)
      'renderMarginRevertIcon': renderMarginRevertIcon,
    ...?extra,
  };
}
