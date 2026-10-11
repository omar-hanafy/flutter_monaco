import 'dart:math' as math;

import 'package:flutter_monaco/src/common/exceptions.dart';
import 'package:flutter_monaco/src/options/language.dart';
import 'package:flutter_monaco/src/types/geometry.dart';
import 'package:flutter_monaco/src/types/markers.dart';
import 'package:flutter_monaco/src/types/text.dart';

/// Internal command dispatcher a document handle rides. Wired to the
/// controller's readiness-gated invoke.
typedef MonacoDocumentInvoke = Future<Object?> Function(
  String method,
  Map<String, Object?> params,
);

/// A handle to one Monaco text model.
///
/// Obtained from `MonacoController.document` (the active-tracking handle:
/// [uri] is `null` and every call targets whatever model is currently
/// attached to the editor), `openDocument`, `documentByUri`, or
/// `listDocuments` (pinned handles: calls target that exact model whether
/// or not it is visible).
///
/// All methods throw a [MonacoException] on bridge failure; a pinned
/// handle whose model was closed throws [MonacoJavaScriptError]. A page reload
/// recreates only the boot document, so handles pinned to other models become
/// stale. Listen to `MonacoController.onPageReloaded`, reopen those documents
/// with their stable URIs, and replace the old handles before using them again.
final class MonacoDocument {
  /// Internal: construct via MonacoController.
  MonacoDocument.internal(this._invoke, this.uri);

  final MonacoDocumentInvoke _invoke;

  /// URI this handle is pinned to, or `null` for the active-tracking
  /// handle.
  final Uri? uri;

  String? get _uriParam => uri?.toString();

  /// Returns the full document text.
  Future<String> getText() async {
    final result = await _invoke('document.getText', {'uri': _uriParam});
    if (result is String) return result;
    throw MonacoProtocolError(
      operation: 'document.getText',
      message: 'Expected a string document text, got ${result.runtimeType}.',
    );
  }

  /// Replaces the entire document text.
  ///
  /// This is a programmatic load: Monaco's undo stack is reset and the
  /// dirty baseline moves to the new content, so [isDirty] reports `false`
  /// until the next edit. Use [insert], [applyEdits], or [replaceRange]
  /// for changes that should count as unsaved.
  Future<void> setText(String text) async {
    await _invoke('document.setText', {'uri': _uriParam, 'text': text});
  }

  /// Returns the total number of lines.
  Future<int> lineCount() async {
    final result = await _invoke('document.lineCount', {'uri': _uriParam});
    if (result is int) return result;
    if (result is num) return result.toInt();
    throw MonacoProtocolError(
      operation: 'document.lineCount',
      message: 'Expected a numeric line count, got ${result.runtimeType}.',
    );
  }

  /// Returns lines [startLine]..[endLine] (1-based, inclusive) in one
  /// bridge call. Out-of-range bounds are clamped JS-side; use [lineAt]
  /// for a strict single-line read.
  Future<List<String>> getLines(int startLine, int endLine) async {
    if (startLine < 1) {
      throw RangeError.range(startLine, 1, null, 'startLine');
    }
    if (endLine < startLine) {
      throw RangeError.range(endLine, startLine, null, 'endLine');
    }
    final result = await _invoke('document.getLines', {
      'uri': _uriParam,
      'startLine': startLine,
      'endLine': endLine,
    });
    if (result is List) {
      return result.map((e) => e?.toString() ?? '').toList();
    }
    throw MonacoProtocolError(
      operation: 'document.getLines',
      message: 'Expected a list of lines, got ${result.runtimeType}.',
    );
  }

  /// Returns the content of one [line] (1-based).
  ///
  /// Strict, unlike the ranged [getLines]: a line beyond the end of the
  /// document throws a [MonacoJavaScriptError] instead of silently
  /// clamping to the last line.
  Future<String> lineAt(int line) async {
    if (line < 1) {
      throw RangeError.range(line, 1, null, 'line');
    }
    final result = await _invoke('document.getLines', {
      'uri': _uriParam,
      'startLine': line,
      'endLine': line,
      'strict': true,
    });
    if (result is List && result.isNotEmpty) {
      return result.first?.toString() ?? '';
    }
    throw MonacoProtocolError(
      operation: 'document.getLines',
      message: 'Expected one line for line $line, got $result.',
    );
  }

  /// Returns the document language.
  Future<MonacoLanguage> getLanguage() async {
    final result = await _invoke('document.getLanguage', {'uri': _uriParam});
    if (result is String) return MonacoLanguage(result);
    throw MonacoProtocolError(
      operation: 'document.getLanguage',
      message: 'Expected a language id string, got ${result.runtimeType}.',
    );
  }

  /// Changes the document language (re-tokenizes).
  Future<void> setLanguage(MonacoLanguage language) async {
    await _invoke('document.setLanguage', {
      'uri': _uriParam,
      'language': language.id,
    });
  }

  /// Applies a batch of [edits] atomically.
  Future<void> applyEdits(List<EditOperation> edits) async {
    if (edits.isEmpty) return;
    await _invoke('document.applyEdits', {
      'uri': _uriParam,
      'edits': edits.map((e) => e.toJson()).toList(),
    });
  }

  /// Inserts [text] at [position].
  Future<void> insert(Position position, String text) async {
    await applyEdits([EditOperation.insert(position: position, text: text)]);
  }

  /// Replaces [range] with [text].
  Future<void> replaceRange(Range range, String text) async {
    await applyEdits([EditOperation(range: range, text: text)]);
  }

  /// Deletes the text in [range].
  Future<void> deleteRange(Range range) async {
    await applyEdits([EditOperation.delete(range: range)]);
  }

  /// Finds up to [limit] matches of [query].
  ///
  /// When [FindOptions.limitResultCount] is also set, the smaller of the
  /// two caps applies.
  Future<List<FindMatch>> findMatches(
    String query, {
    FindOptions options = const FindOptions(),
    int limit = 1000,
  }) async {
    final limitCap = options.limitResultCount;
    final effectiveLimit = limitCap == null ? limit : math.min(limit, limitCap);
    final matches = await _invoke('document.findMatches', {
      'uri': _uriParam,
      'query': query,
      'isRegex': options.isRegex,
      'matchCase': options.matchCase,
      'wholeWord': options.wholeWord,
      if (options.searchOnlyEditableRange != null)
        'searchOnlyEditableRange': options.searchOnlyEditableRange,
      'limit': effectiveLimit,
    });
    if (matches is! List) {
      throw MonacoProtocolError(
        operation: 'document.findMatches',
        message: 'Expected a list of matches, got ${matches.runtimeType}.',
      );
    }
    return matches
        .whereType<Map<Object?, Object?>>()
        .map((match) => FindMatch.fromJson(Map<String, dynamic>.from(match)))
        .toList();
  }

  /// Replaces every match of [query] with [replacement]; returns the
  /// replacement count.
  ///
  /// [replacement] is inserted LITERALLY: regex capture references such as
  /// `$1` are not substituted, even when [FindOptions.isRegex] is set.
  Future<int> replaceMatches(
    String query,
    String replacement, {
    FindOptions options = const FindOptions(),
  }) async {
    final result = await _invoke('document.replaceMatches', {
      'uri': _uriParam,
      'query': query,
      'replacement': replacement,
      'isRegex': options.isRegex,
      'matchCase': options.matchCase,
      'wholeWord': options.wholeWord,
      if (options.searchOnlyEditableRange != null)
        'searchOnlyEditableRange': options.searchOnlyEditableRange,
    });
    if (result is int) return result;
    if (result is num) return result.toInt();
    throw MonacoProtocolError(
      operation: 'document.replaceMatches',
      message:
          'Expected a numeric replacement count, got ${result.runtimeType}.',
    );
  }

  /// Returns the word at [position], or `null` when there is none.
  ///
  /// Throws a [MonacoProtocolError] when the bridge answers with anything
  /// other than a string or `null`.
  Future<String?> getWordAt(Position position) async {
    final result = await _invoke('document.getWordAt', {
      'uri': _uriParam,
      'position': {'lineNumber': position.line, 'column': position.column},
    });
    if (result == null || result is String) return result as String?;
    throw MonacoProtocolError(
      operation: 'document.getWordAt',
      message: 'Expected a word string or null, got ${result.runtimeType}.',
    );
  }

  /// Whether the document changed since the last [markSaved].
  ///
  /// Throws a [MonacoProtocolError] when the bridge answers with anything
  /// other than a boolean.
  Future<bool> isDirty() async {
    final result = await _invoke('document.isDirty', {'uri': _uriParam});
    if (result is bool) return result;
    throw MonacoProtocolError(
      operation: 'document.isDirty',
      message: 'Expected a boolean dirty flag, got ${result.runtimeType}.',
    );
  }

  /// Marks the current content as the saved baseline for [isDirty].
  Future<void> markSaved() async {
    await _invoke('document.markSaved', {'uri': _uriParam});
  }

  /// Replaces the diagnostic [markers] under [owner].
  Future<void> setMarkers(
    List<MarkerData> markers, {
    String owner = 'flutter',
  }) async {
    await _invoke('document.setMarkers', {
      'uri': _uriParam,
      'owner': owner,
      'markers': markers.map((m) => m.toJson()).toList(),
    });
  }

  /// Clears the diagnostic markers under [owner].
  Future<void> clearMarkers({String owner = 'flutter'}) async {
    await setMarkers(const [], owner: owner);
  }

  /// Closes (disposes) this document's model.
  ///
  /// Only valid on pinned handles; the active-tracking handle throws a
  /// [StateError] (closing "whatever is active" is never what you mean).
  Future<void> close() async {
    if (uri == null) {
      throw StateError(
        'close() is only valid on pinned document handles; the '
        'active-tracking handle cannot close "whatever is active".',
      );
    }
    await _invoke('docs.close', {'uri': _uriParam});
  }

  @override
  String toString() => 'MonacoDocument(${uri ?? 'active'})';
}
