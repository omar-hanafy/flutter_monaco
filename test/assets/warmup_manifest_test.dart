import 'dart:io';

import 'package:flutter_monaco/src/assets/warmup_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web warmup discovers Monaco's hash-named bulk chunk from
/// `editor.main.js` at runtime. These tests pin the parsing rules and guard
/// against a Monaco upgrade silently changing the chunk-reference format
/// (which would degrade warmup to the static files only).
void main() {
  group('extractMonacoWarmupChunks', () {
    test('finds the hashed editor.api chunk in an AMD dependency list', () {
      const source =
          'define(["require","exports","./nls.messages-loader.js!",'
          '"../monaco.contribution-D2OdxNBt","../editor.api-CalNCsUg",'
          '"../workers-DcJshg-q"],(function(a,b){}))';
      expect(extractMonacoWarmupChunks(source), ['editor.api-CalNCsUg.js']);
    });

    test('deduplicates repeated references', () {
      const source = '"../editor.api-AbCd_123" "../editor.api-AbCd_123"';
      expect(extractMonacoWarmupChunks(source), ['editor.api-AbCd_123.js']);
    });

    test('returns empty for sources without a chunk reference', () {
      expect(extractMonacoWarmupChunks('define([],function(){})'), isEmpty);
      expect(extractMonacoWarmupChunks(''), isEmpty);
    });

    test('bundled editor.main.js yields exactly one chunk', () {
      final source = File('assets/monaco/min/vs/editor/editor.main.js')
          .readAsStringSync();
      final chunks = extractMonacoWarmupChunks(source);
      expect(
        chunks,
        hasLength(1),
        reason:
            'Monaco changed how editor.main.js references its bulk chunk; '
            'update extractMonacoWarmupChunks so web warmup keeps covering '
            'the multi-megabyte download.',
      );
      expect(
        chunks.single,
        matches(RegExp(r'^editor\.api-[A-Za-z0-9_-]+\.js$')),
      );
      final chunkFile = File('assets/monaco/min/vs/${chunks.single}');
      expect(
        chunkFile.existsSync(),
        isTrue,
        reason: 'referenced chunk ${chunks.single} is not in the bundle',
      );
      expect(
        chunkFile.lengthSync(),
        greaterThan(1024 * 1024),
        reason: 'the discovered chunk should be the multi-megabyte editor bulk',
      );
    });

    test('static warmup files exist in the bundle', () {
      for (final file in monacoWarmupStaticFiles) {
        expect(
          File('assets/monaco/min/vs/$file').existsSync(),
          isTrue,
          reason: '$file is missing from the Monaco bundle',
        );
      }
    });
  });
}
