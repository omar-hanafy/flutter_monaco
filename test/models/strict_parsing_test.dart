import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the strict JSON integer parsers.
///
/// Web JSON delivers integers as doubles, so integral doubles (`1.0`) must
/// keep parsing. A fractional value (`1.9`) is a malformed payload and must
/// be reported instead of being truncated into a plausible-looking integer.
void main() {
  const range = Range(startLine: 1, startColumn: 2, endLine: 3, endColumn: 4);

  group('strict integer parsing', () {
    // Each entry builds a payload with [value] at one integer field.
    final parsers = <String, Object? Function(Object value)>{
      'Position.lineNumber': (v) =>
          Position.fromJson({'lineNumber': v, 'column': 1}),
      'Range.endColumn': (v) =>
          Range.fromJson({...range.toJson(), 'endColumn': v}),
      'MarkerData.severity': (v) => MarkerData.fromJson({
        ...range.toJson(),
        'message': 'm',
        'severity': v,
      }),
      'FindOptions.limitResultCount': (v) =>
          FindOptions.fromJson({'limitResultCount': v}),
      'CompletionRequest.triggerKind': (v) => CompletionRequest.fromJson({
        'providerId': 'p',
        'requestId': 'r',
        'language': 'dart',
        'position': {'lineNumber': 1, 'column': 1},
        'defaultRange': range.toJson(),
        'triggerKind': v,
      }),
      'MonacoLiveStats.lineCount': (v) =>
          MonacoLiveStats.fromJson({'lineCount': v}),
      'EditorState.lineCount': (v) =>
          EditorState.fromJson({'content': '', 'lineCount': v}),
      'EditorOptions.tabSize': (v) => EditorOptions.fromJson({'tabSize': v}),
      'EditorOptions.rulers': (v) => EditorOptions.fromJson({
        'rulers': [80, v],
      }),
      'MonacoPadding.top': (v) => MonacoPadding.fromJson({'top': v}),
      'MonacoMinimapOptions.maxColumn': (v) =>
          MonacoMinimapOptions.fromJson({'maxColumn': v}),
      'MonacoScrollbarOptions.verticalScrollbarSize': (v) =>
          MonacoScrollbarOptions.fromJson({'verticalScrollbarSize': v}),
      'MonacoStickyScroll.maxLineCount': (v) =>
          MonacoStickyScroll.fromJson({'maxLineCount': v}),
    };

    for (final MapEntry(key: name, value: parse) in parsers.entries) {
      test('$name accepts integral doubles', () {
        expect(() => parse(2.0), returnsNormally);
      });

      test('$name rejects fractional doubles', () {
        expect(() => parse(1.9), throwsFormatException);
      });

      test('$name rejects non-finite doubles', () {
        expect(() => parse(double.nan), throwsFormatException);
        expect(() => parse(double.infinity), throwsFormatException);
      });
    }

    test('integral doubles keep their value', () {
      expect(
        Position.fromJson(const {'lineNumber': 7.0, 'column': 3.0}),
        (const Position(line: 7, column: 3)),
      );
      expect(EditorOptions.fromJson(const {'tabSize': 2.0}).tabSize, 2);
      expect(
        EditorOptions.fromJson(const {
          'rulers': [80.0, 120],
        }).rulers,
        [80, 120],
      );
    });
  });
}
