import 'dart:convert';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco_example/showcase/data/demo_snippets.dart';
import 'package:flutter_monaco_example/showcase/data/samples.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('playground samples', () {
    test('every curated language has a non-empty sample', () {
      for (final language in kPlaygroundLanguages) {
        final sample = sampleFor(language);
        expect(
          sample.trim(),
          isNotEmpty,
          reason: 'missing sample for ${language.id}',
        );
      }
    });

    test('the default language (Dart) is offered first', () {
      expect(kPlaygroundLanguages.first, MonacoLanguage.dart);
    });

    test('the curated list has no duplicates', () {
      expect(kPlaygroundLanguages.toSet().length, kPlaygroundLanguages.length);
    });

    test('the JSON sample is valid JSON', () {
      final decoded = jsonDecode(sampleFor(MonacoLanguage.json));
      expect(decoded, isA<Map<String, dynamic>>());
    });
  });

  group('demo data', () {
    test('completion items are non-empty and labelled', () {
      expect(kDemoCompletions, isNotEmpty);
      for (final item in kDemoCompletions) {
        expect(item.label.trim(), isNotEmpty);
      }
    });

    test('the invalid JSON sample parses but violates the schema types', () {
      final decoded = jsonDecode(kInvalidJsonSample) as Map<String, dynamic>;
      // Valid JSON...
      expect(decoded.containsKey('name'), isTrue);
      // ...but version should be a string and port an integer per the schema,
      // so these wrong types are what Monaco will flag.
      expect(decoded['version'], isA<int>());
      expect(decoded['port'], isA<String>());
      expect(decoded.containsKey('extra'), isTrue);
    });

    test('JSON diagnostics enable schema validation against one schema', () {
      expect(kJsonDiagnostics.validate, isTrue);
      expect(kJsonDiagnostics.schemas, hasLength(1));
      expect(kJsonDiagnostics.schemas!.first.fileMatch, contains('*'));
    });

    test('marker demo code lines line up with the demo markers', () {
      final lineCount = kMarkersDemoCode.trimRight().split('\n').length;
      for (final marker in [...kDemoErrorMarkers, ...kDemoWarningMarkers]) {
        expect(marker.range.startLine, lessThanOrEqualTo(lineCount));
        expect(marker.message.trim(), isNotEmpty);
      }
    });

    test('the custom theme has a stable id and editor background', () {
      expect(kMidnightTheme.id, kMidnightThemeId);
      expect(kMidnightTheme.colors['editor.background'], isNotNull);
    });
  });
}
