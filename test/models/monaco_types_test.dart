import 'package:convert_object/convert_object.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Position', () {
    test('fromJson with standard keys', () {
      final pos = Position.fromJson({'lineNumber': 5, 'column': 10});
      expect(pos.line, 5);
      expect(pos.column, 10);
    });

    test('fromJson with alternative keys', () {
      expect(Position.fromJson({'line': 2, 'col': 3}).line, 2);
      expect(Position.fromJson({'ln': 4, 'character': 5}).column, 5);
      expect(Position.fromJson({'row': 6, 'ch': 7}).line, 6);
    });

    test('fromJson with defaults', () {
      final pos = Position.fromJson({});
      expect(pos.line, 1);
      expect(pos.column, 1);
    });

    test('fromZeroBased adds one', () {
      final pos = Position.fromZeroBased(0, 0);
      expect(pos.line, 1);
      expect(pos.column, 1);

      final pos2 = Position.fromZeroBased(9, 19);
      expect(pos2.line, 10);
      expect(pos2.column, 20);
    });

    test('zeroBasedGetters', () {
      const pos = Position(line: 5, column: 10);
      expect(pos.lineZeroBased, 4);
      expect(pos.columnZeroBased, 9);
    });

    test('toJson roundtrip', () {
      const pos = Position(line: 3, column: 7);
      final json = pos.toJson();
      final restored = Position.fromJson(json);
      expect(restored.line, 3);
      expect(restored.column, 7);
    });

    test('equality', () {
      const pos1 = Position(line: 1, column: 1);
      const pos2 = Position(line: 1, column: 1);
      const pos3 = Position(line: 1, column: 2);
      expect(pos1, equals(pos2));
      expect(pos1, isNot(equals(pos3)));
    });
  });

  group('Range', () {
    test('fromJson with standard keys', () {
      final range = Range.fromJson({
        'startLineNumber': 1,
        'startColumn': 5,
        'endLineNumber': 3,
        'endColumn': 10,
      });
      expect(range.startLine, 1);
      expect(range.startColumn, 5);
      expect(range.endLine, 3);
      expect(range.endColumn, 10);
    });

    test('fromJson with alternative keys', () {
      final range = Range.fromJson({
        'startLine': 1,
        'startCol': 2,
        'endLine': 3,
        'endCol': 4,
      });
      expect(range.startLine, 1);
      expect(range.startColumn, 2);
      expect(range.endLine, 3);
      expect(range.endColumn, 4);

      final range2 = Range.fromJson({
        'from_line': 5,
        'from_column': 6,
        'to_line': 7,
        'to_column': 8,
      });
      expect(range2.startLine, 5);
      expect(range2.endLine, 7);
    });

    test('fromPositions', () {
      const start = Position(line: 1, column: 5);
      const end = Position(line: 2, column: 10);
      final range = Range.fromPositions(start, end);
      expect(range.startLine, 1);
      expect(range.startColumn, 5);
      expect(range.endLine, 2);
      expect(range.endColumn, 10);
    });

    test('singleLine', () {
      final range = Range.singleLine(5, startColumn: 3, endColumn: 10);
      expect(range.startLine, 5);
      expect(range.endLine, 5);
      expect(range.startColumn, 3);
      expect(range.endColumn, 10);

      final collapsed = Range.singleLine(5, startColumn: 3);
      expect(collapsed.endColumn, 3);
    });

    test('lines uses max endColumn', () {
      final range = Range.lines(2, 4);
      expect(range.startLine, 2);
      expect(range.endLine, 4);
      expect(range.startColumn, 1);
      expect(range.endColumn, 2147483647);
    });

    test('startPosition and endPosition', () {
      const range = Range(
        startLine: 1,
        startColumn: 5,
        endLine: 3,
        endColumn: 10,
      );
      expect(range.startPosition.line, 1);
      expect(range.startPosition.column, 5);
      expect(range.endPosition.line, 3);
      expect(range.endPosition.column, 10);
    });

    test('isCollapsed', () {
      const collapsed = Range(
        startLine: 1,
        startColumn: 1,
        endLine: 1,
        endColumn: 1,
      );
      expect(collapsed.isCollapsed, true);

      const notCollapsed = Range(
        startLine: 1,
        startColumn: 1,
        endLine: 1,
        endColumn: 2,
      );
      expect(notCollapsed.isCollapsed, false);
    });

    test('containsPosition', () {
      const range = Range(
        startLine: 2,
        startColumn: 5,
        endLine: 4,
        endColumn: 10,
      );

      // Inside
      expect(range.containsPosition(const Position(line: 3, column: 1)), true);
      expect(range.containsPosition(const Position(line: 2, column: 5)), true);
      expect(range.containsPosition(const Position(line: 4, column: 10)), true);

      // Outside
      expect(range.containsPosition(const Position(line: 1, column: 5)), false);
      expect(range.containsPosition(const Position(line: 2, column: 4)), false);
      expect(
        range.containsPosition(const Position(line: 4, column: 11)),
        false,
      );
      expect(range.containsPosition(const Position(line: 5, column: 1)), false);
    });

    test('intersects', () {
      const range1 = Range(
        startLine: 1,
        startColumn: 1,
        endLine: 3,
        endColumn: 10,
      );
      const range2 = Range(
        startLine: 3,
        startColumn: 5,
        endLine: 5,
        endColumn: 10,
      );
      const range3 = Range(
        startLine: 4,
        startColumn: 1,
        endLine: 6,
        endColumn: 10,
      );

      expect(range1.intersects(range2), true);
      expect(range2.intersects(range1), true);
      expect(range1.intersects(range3), false);
      expect(range3.intersects(range1), false);
    });

    test('toJson roundtrip', () {
      const range = Range(
        startLine: 1,
        startColumn: 5,
        endLine: 3,
        endColumn: 10,
      );
      final json = range.toJson();
      final restored = Range.fromJson(json);
      expect(restored, range);
    });
  });

  group('MarkerSeverity', () {
    test('values', () {
      expect(MarkerSeverity.hint.value, 1);
      expect(MarkerSeverity.info.value, 2);
      expect(MarkerSeverity.warning.value, 4);
      expect(MarkerSeverity.error.value, 8);
    });

    test('fromValue', () {
      expect(MarkerSeverity.fromValue(1), MarkerSeverity.hint);
      expect(MarkerSeverity.fromValue(2), MarkerSeverity.info);
      expect(MarkerSeverity.fromValue(4), MarkerSeverity.warning);
      expect(MarkerSeverity.fromValue(8), MarkerSeverity.error);
    });

    test('fromValue defaults to info', () {
      expect(MarkerSeverity.fromValue(999), MarkerSeverity.info);
      expect(MarkerSeverity.fromValue(0), MarkerSeverity.info);
    });
  });

  group('MarkerData', () {
    test('error factory sets severity', () {
      final marker = MarkerData.error(
        range: const Range(
          startLine: 1,
          startColumn: 1,
          endLine: 1,
          endColumn: 10,
        ),
        message: 'Error message',
      );
      expect(marker.severity, MarkerSeverity.error);
    });

    test('warning factory sets severity', () {
      final marker = MarkerData.warning(
        range: const Range(
          startLine: 1,
          startColumn: 1,
          endLine: 1,
          endColumn: 10,
        ),
        message: 'Warning message',
      );
      expect(marker.severity, MarkerSeverity.warning);
    });

    test('toJson includes all fields', () {
      const marker = MarkerData(
        range: Range(startLine: 1, startColumn: 1, endLine: 1, endColumn: 10),
        message: 'Test message',
        severity: MarkerSeverity.error,
        code: 'E001',
        source: 'linter',
        tags: ['unnecessary'],
      );

      final json = marker.toJson();
      expect(json['message'], 'Test message');
      expect(json['severity'], 8);
      expect(json['code'], 'E001');
      expect(json['source'], 'linter');
      expect(json['tags'], ['unnecessary']);
    });

    test('toJson excludes null optional fields', () {
      const marker = MarkerData(
        range: Range(startLine: 1, startColumn: 1, endLine: 1, endColumn: 5),
        message: 'Test',
      );

      final json = marker.toJson();
      expect(json.containsKey('code'), false);
      expect(json.containsKey('source'), false);
      expect(json.containsKey('tags'), false);
    });
  });

  group('RelatedInformation', () {
    test('fromJson with defaults', () {
      final info = RelatedInformation.fromJson({
        'message': 'Related info',
        'startLineNumber': 5,
        'startColumn': 1,
        'endLineNumber': 5,
        'endColumn': 10,
      });

      expect(info.message, 'Related info');
      expect(info.resource.toString(), 'file:///unknown');
    });

    test('fromJson with uri', () {
      final info = RelatedInformation.fromJson({
        'resource': 'file:///test.dart',
        'message': 'Info',
        'startLineNumber': 1,
        'startColumn': 1,
        'endLineNumber': 1,
        'endColumn': 1,
      });

      expect(info.resource.toString(), 'file:///test.dart');
    });
  });

  group('DecorationOptions', () {
    test('inlineClass factory', () {
      final deco = DecorationOptions.inlineClass(
        range: const Range(
          startLine: 1,
          startColumn: 1,
          endLine: 1,
          endColumn: 5,
        ),
        className: 'highlight',
        hoverMessage: 'Hover text',
      );

      expect(deco.options['inlineClassName'], 'highlight');
      expect(deco.options['hoverMessage'], 'Hover text');
    });

    test('glyphMargin factory', () {
      final deco = DecorationOptions.glyphMargin(
        range: const Range(
          startLine: 1,
          startColumn: 1,
          endLine: 1,
          endColumn: 5,
        ),
        className: 'breakpoint',
      );

      expect(deco.options['glyphMarginClassName'], 'breakpoint');
    });

    test('line factory', () {
      final deco = DecorationOptions.line(
        range: const Range(
          startLine: 5,
          startColumn: 1,
          endLine: 5,
          endColumn: 100,
        ),
        className: 'current-line',
        isWholeLine: true,
      );

      expect(deco.options['className'], 'current-line');
      expect(deco.options['isWholeLine'], true);
    });
  });

  group('EditOperation', () {
    test('insert factory', () {
      final edit = EditOperation.insert(
        position: const Position(line: 1, column: 1),
        text: 'inserted',
        forceMoveMarkers: true,
      );

      expect(edit.range.isCollapsed, true);
      expect(edit.text, 'inserted');
      expect(edit.forceMoveMarkers, true);
    });

    test('delete factory', () {
      final edit = EditOperation.delete(
        range: const Range(
          startLine: 1,
          startColumn: 1,
          endLine: 1,
          endColumn: 10,
        ),
      );

      expect(edit.text, '');
    });

    test('toJson includes forceMoveMarkers when set', () {
      final edit = EditOperation.insert(
        position: const Position(line: 1, column: 1),
        text: 'test',
        forceMoveMarkers: true,
      );

      final json = edit.toJson();
      expect(json['forceMoveMarkers'], true);
    });

    test('toJson excludes forceMoveMarkers when null', () {
      const edit = EditOperation(
        range: Range(startLine: 1, startColumn: 1, endLine: 1, endColumn: 1),
        text: 'test',
      );

      final json = edit.toJson();
      expect(json.containsKey('forceMoveMarkers'), false);
    });
  });

  group('CompletionItem', () {
    test('fromJson parses all fields', () {
      final item = CompletionItem.fromJson({
        'label': 'testMethod',
        'insertText': 'testMethod()',
        'kind': 'Method',
        'detail': 'A method',
        'documentation': 'Docs here',
        'sortText': '0001',
        'filterText': 'test',
        'range': {
          'startLineNumber': 1,
          'startColumn': 1,
          'endLineNumber': 1,
          'endColumn': 5,
        },
        'commitCharacters': ['('],
        'insertTextRules': ['InsertAsSnippet'],
      });

      expect(item.label, 'testMethod');
      expect(item.insertText, 'testMethod()');
      expect(item.kind, CompletionItemKind.method);
      expect(item.detail, 'A method');
      expect(item.documentation, 'Docs here');
      expect(item.sortText, '0001');
      expect(item.filterText, 'test');
      expect(item.range, isNotNull);
      expect(item.commitCharacters, ['(']);
      expect(item.insertTextRules, {InsertTextRule.insertAsSnippet});
    });

    test('toJson excludes null fields', () {
      const item = CompletionItem(label: 'minimal');
      final json = item.toJson();

      expect(json['label'], 'minimal');
      expect(json.containsKey('insertText'), false);
      expect(json.containsKey('kind'), false);
      expect(json.containsKey('detail'), false);
    });
  });

  group('CompletionItemKind', () {
    test('fromJsonValue handles all kinds', () {
      for (final kind in CompletionItemKind.values) {
        expect(CompletionItemKind.fromJsonValue(kind.jsonValue), kind);
      }
    });

    test('fromJsonValue defaults to text', () {
      expect(
        CompletionItemKind.fromJsonValue('Unknown'),
        CompletionItemKind.text,
      );
    });

    test('maybeFromJsonValue returns null for unknown', () {
      expect(CompletionItemKind.maybeFromJsonValue('Unknown'), isNull);
      expect(CompletionItemKind.maybeFromJsonValue(null), isNull);
    });
  });

  group('InsertTextRule', () {
    test('fromJsonValue', () {
      expect(
        InsertTextRule.fromJsonValue('InsertAsSnippet'),
        InsertTextRule.insertAsSnippet,
      );
      expect(
        InsertTextRule.fromJsonValue('KeepWhitespace'),
        InsertTextRule.keepWhitespace,
      );
    });

    test('fromJsonValue defaults to insertAsSnippet', () {
      expect(
        InsertTextRule.fromJsonValue('Unknown'),
        InsertTextRule.insertAsSnippet,
      );
    });
  });

  group('FindOptions', () {
    test('caseSensitive factory', () {
      final options = FindOptions.caseSensitive(wholeWord: true);
      expect(options.matchCase, true);
      expect(options.wholeWord, true);
      expect(options.isRegex, false);
    });

    test('regex factory', () {
      final options = FindOptions.regex(matchCase: true);
      expect(options.isRegex, true);
      expect(options.matchCase, true);
      expect(options.wholeWord, false);
    });

    test('toJson includes only set fields', () {
      const options = FindOptions(
        isRegex: true,
        matchCase: false,
        wholeWord: true,
      );

      final json = options.toJson();
      expect(json['isRegex'], true);
      expect(json['matchCase'], false);
      expect(json['wholeWord'], true);
      expect(json.containsKey('limitResultCount'), false);
    });
  });

  group('LiveStats', () {
    test('defaults', () {
      final stats = LiveStats.defaults();
      expect(stats.lineCount.value, 0);
      expect(stats.charCount.value, 0);
      expect(stats.caretCount.value, 1);
      expect(stats.cursorPosition, isNull);
    });

    test('fromJson parses cursor position', () {
      final stats = LiveStats.fromJson({
        'lineCount': 10,
        'charCount': 100,
        'selLines': 2,
        'selChars': 15,
        'caretCount': 1,
        'cursorLine': 5,
        'cursorColumn': 10,
        'language': 'dart',
      });

      expect(stats.cursorPosition?.label, '5:10');
      expect(stats.language, 'dart');
      expect(stats.hasSelection, true);
    });

    test('hasSelection and hasMultipleCursors', () {
      expect(LiveStats.fromJson({'selChars': 5}).hasSelection, true);
      expect(LiveStats.fromJson({'selChars': 0}).hasSelection, false);
      expect(LiveStats.fromJson({'caretCount': 3}).hasMultipleCursors, true);
      expect(LiveStats.fromJson({'caretCount': 1}).hasMultipleCursors, false);
    });

    test('allStats returns all statistics', () {
      final stats = LiveStats.fromJson({
        'lineCount': 10,
        'charCount': 50,
        'selLines': 1,
        'selChars': 5,
        'caretCount': 1,
        'cursorLine': 3,
        'cursorColumn': 7,
      });

      expect(stats.allStats.length, 6); // Including cursor
    });
  });

  group('EditorState', () {
    test('isEmpty and wordCount', () {
      const empty = EditorState(
        content: '',
        lineCount: 0,
        hasUnsavedChanges: false,
      );
      expect(empty.isEmpty, true);
      expect(empty.wordCount, 0);

      const withContent = EditorState(
        content: 'hello world test',
        lineCount: 1,
        hasUnsavedChanges: false,
      );
      expect(withContent.isEmpty, false);
      expect(withContent.wordCount, 3);
    });

    test('fromJson parses nested objects', () {
      final state = EditorState.fromJson({
        'content': 'test content',
        'lineCount': 5,
        'hasUnsavedChanges': true,
        'selection': {
          'startLineNumber': 1,
          'startColumn': 1,
          'endLineNumber': 1,
          'endColumn': 5,
        },
        'cursorPosition': {'lineNumber': 1, 'column': 3},
        'language': 'dart',
        'theme': 'vs-dark',
      });

      expect(state.content, 'test content');
      expect(state.lineCount, 5);
      expect(state.hasUnsavedChanges, true);
      expect(state.selection?.endColumn, 5);
      expect(state.cursorPosition?.column, 3);
      expect(state.language, 'dart');
      expect(state.theme, 'vs-dark');
    });
  });

  group('FindMatch', () {
    test('fromJson', () {
      final match = FindMatch.fromJson({
        'match': 'found text',
        'range': {
          'startLineNumber': 5,
          'startColumn': 10,
          'endLineNumber': 5,
          'endColumn': 20,
        },
      });

      expect(match.match, 'found text');
      expect(match.range.startLine, 5);
      expect(match.range.startColumn, 10);
    });

    test('toJson', () {
      const match = FindMatch(
        range: Range(startLine: 1, startColumn: 1, endLine: 1, endColumn: 5),
        match: 'test',
      );

      final json = match.toJson();
      expect(json['match'], 'test');
      expect(json['range'], isNotNull);
    });
  });

  group('JsonDiagnosticsOptions', () {
    test('toJson serializes configured diagnostics settings', () {
      final options = JsonDiagnosticsOptions(
        allowComments: true,
        enableSchemaRequest: false,
        validate: true,
        trailingCommas: DiagnosticsSeverity.warning,
        schemaRequest: DiagnosticsSeverity.error,
        schemaValidation: DiagnosticsSeverity.warning,
        comments: DiagnosticsSeverity.ignore,
        schemas: [
          JsonDiagnosticsSchema(
            uri: Uri.parse('https://example.com/schema.json'),
            fileMatch: ['*.json'],
            schema: {'type': 'object'},
          ),
        ],
      );

      final json = options.toJson();

      expect(json['validate'], true);
      expect(json['allowComments'], true);
      expect(json['enableSchemaRequest'], false);
      expect(json['schemaRequest'], 'error');
      expect(json['schemaValidation'], 'warning');
      expect(json['comments'], 'ignore');
      expect(json['trailingCommas'], 'warning');
      expect(json['schemas'], [
        {
          'uri': 'https://example.com/schema.json',
          'fileMatch': ['*.json'],
          'schema': {'type': 'object'},
        },
      ]);
    });

    test('fromJson round-trip preserves all fields', () {
      final original = JsonDiagnosticsOptions(
        allowComments: true,
        enableSchemaRequest: false,
        validate: true,
        trailingCommas: DiagnosticsSeverity.warning,
        schemaRequest: DiagnosticsSeverity.error,
        schemaValidation: DiagnosticsSeverity.warning,
        comments: DiagnosticsSeverity.ignore,
        schemas: [
          JsonDiagnosticsSchema(
            uri: Uri.parse('https://example.com/schema.json'),
            fileMatch: ['*.json'],
            schema: {'type': 'object'},
          ),
        ],
      );

      final restored = JsonDiagnosticsOptions.fromJson(original.toJson());

      expect(restored.allowComments, original.allowComments);
      expect(restored.enableSchemaRequest, original.enableSchemaRequest);
      expect(restored.validate, original.validate);
      expect(restored.trailingCommas, original.trailingCommas);
      expect(restored.schemaRequest, original.schemaRequest);
      expect(restored.schemaValidation, original.schemaValidation);
      expect(restored.comments, original.comments);
      expect(restored.schemas?.length, 1);
      expect(
        restored.schemas!.first.uri.toString(),
        'https://example.com/schema.json',
      );
      expect(restored.schemas!.first.fileMatch, ['*.json']);
      expect(restored.schemas!.first.schema, {'type': 'object'});
    });

    test('fromJson with empty map produces all-null fields', () {
      final options = JsonDiagnosticsOptions.fromJson({});

      expect(options.allowComments, isNull);
      expect(options.enableSchemaRequest, isNull);
      expect(options.validate, isNull);
      expect(options.trailingCommas, isNull);
      expect(options.schemaRequest, isNull);
      expect(options.schemaValidation, isNull);
      expect(options.comments, isNull);
      expect(options.schemas, isNull);
    });

    test('toJson omits null fields', () {
      final json = const JsonDiagnosticsOptions().toJson();
      expect(json, isEmpty);
    });
  });

  group('JsonDiagnosticsSchema', () {
    test('toJson serializes all fields', () {
      final schema = JsonDiagnosticsSchema(
        uri: Uri.parse('https://example.com/schema.json'),
        fileMatch: ['*.json', 'config.*'],
        schema: {
          'type': 'object',
          'required': ['name'],
        },
      );

      final json = schema.toJson();

      expect(json['uri'], 'https://example.com/schema.json');
      expect(json['fileMatch'], ['*.json', 'config.*']);
      expect(json['schema'], {
        'type': 'object',
        'required': ['name'],
      });
    });

    test('fromJson parses uri key', () {
      final schema = JsonDiagnosticsSchema.fromJson({
        'uri': 'https://example.com/schema.json',
        'fileMatch': ['*.json'],
      });

      expect(schema.uri.toString(), 'https://example.com/schema.json');
      expect(schema.fileMatch, ['*.json']);
    });

    test('fromJson parses schemaUri alias', () {
      final schema = JsonDiagnosticsSchema.fromJson({
        'schemaUri': 'https://example.com/alt.json',
        'fileMatch': ['*'],
      });

      expect(schema.uri.toString(), 'https://example.com/alt.json');
    });

    test('fromJson throws when both uri and schemaUri are missing', () {
      expect(
        () => JsonDiagnosticsSchema.fromJson({
          'fileMatch': ['*.json'],
        }),
        throwsA(isA<ConversionException>()),
      );
    });

    test('round-trip preserves data', () {
      final original = JsonDiagnosticsSchema(
        uri: Uri.parse('https://example.com/schema.json'),
        fileMatch: ['*.json'],
        schema: {'type': 'object'},
      );

      final restored = JsonDiagnosticsSchema.fromJson(original.toJson());

      expect(restored.uri, original.uri);
      expect(restored.fileMatch, original.fileMatch);
      expect(restored.schema, original.schema);
    });

    test('toJson omits null optional fields', () {
      final schema = JsonDiagnosticsSchema(
        uri: Uri.parse('https://example.com/schema.json'),
      );

      final json = schema.toJson();

      expect(json['uri'], 'https://example.com/schema.json');
      expect(json.containsKey('fileMatch'), false);
      expect(json.containsKey('schema'), false);
    });
  });
}
