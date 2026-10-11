import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/protocol/envelope.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serialization, equality, and error-path coverage for the wire types.
///
/// These types cross the JS bridge verbatim; an untested branch here is a
/// protocol bug waiting to happen (Section 13: coverage not below the
/// 2.3.0 baseline).
void main() {
  const range = Range(startLine: 1, startColumn: 2, endLine: 3, endColumn: 4);

  group('MonacoAssetDiagnostics', () {
    const diagnostics = MonacoAssetDiagnostics(
      exists: true,
      path: '/cache/monaco',
      monacoVersion: '0.57.0',
      fileCount: 12,
      totalSizeBytes: 2 * 1024 * 1024,
      generatedHtmlCount: 3,
    );

    test('totalSizeMB converts bytes', () {
      expect(diagnostics.totalSizeMB, 2.0);
    });

    test('value equality and hashCode', () {
      const same = MonacoAssetDiagnostics(
        exists: true,
        path: '/cache/monaco',
        monacoVersion: '0.57.0',
        fileCount: 12,
        totalSizeBytes: 2 * 1024 * 1024,
        generatedHtmlCount: 3,
      );
      const different = MonacoAssetDiagnostics(
        exists: false,
        path: '/cache/monaco',
        monacoVersion: '0.57.0',
      );
      expect(diagnostics, same);
      expect(diagnostics.hashCode, same.hashCode);
      expect(diagnostics, isNot(different));
    });

    test('toString reports every field', () {
      final text = '$diagnostics';
      expect(text, contains('exists: true'));
      expect(text, contains('/cache/monaco'));
      expect(text, contains('0.57.0'));
      expect(text, contains('fileCount: 12'));
      expect(text, contains('generatedHtmlCount: 3'));
    });
  });

  group('MonacoPageConfig', () {
    test('equality compares connect sources by content', () {
      const config = MonacoPageConfig(
        customCss: 'body {}',
        allowedConnectSources: ['wss://lsp.example.com'],
      );
      const same = MonacoPageConfig(
        customCss: 'body {}',
        allowedConnectSources: ['wss://lsp.example.com'],
      );
      const different = MonacoPageConfig(
        customCss: 'body {}',
        allowedConnectSources: ['ws://127.0.0.1:9999'],
      );
      expect(identical(config, config), isTrue);
      expect(config, equals(config));
      expect(config, same);
      expect(config.hashCode, same.hashCode);
      expect(config, isNot(different));
      expect(config, isNot(const MonacoPageConfig(allowCdnFonts: true)));
    });

    test('stableCacheKey is deterministic and config-sensitive', () {
      const a = MonacoPageConfig(
        customCss: '.x{}',
        allowCdnFonts: true,
        allowedConnectSources: ['wss://a'],
      );
      const b = MonacoPageConfig(
        customCss: '.x{}',
        allowCdnFonts: true,
        allowedConnectSources: ['wss://a'],
      );

      expect(a.stableCacheKey(), b.stableCacheKey());
      expect(
        a.stableCacheKey(),
        isNot(const MonacoPageConfig().stableCacheKey()),
      );
      expect(a.stableCacheKey(), matches(RegExp(r'^[0-9a-f]{16}$')));

      // Golden pins: the key names generated HTML files on disk, so it must
      // stay stable across processes AND releases (unlike hashCode, which
      // Dart seeds per run). Changing the algorithm orphans cached files.
      expect(const MonacoPageConfig().stableCacheKey(), '27e4515bfc9e5827');
      expect(a.stableCacheKey(), '66223b0815404914');
    });

    test('stableCacheKey separates CSS that differs only above ASCII', () {
      // Two configurations sharing a key share one generated HTML file, so
      // whichever editor loads second silently gets the other's page. The
      // key must hash the full text: U+0151 ("ő") and U+0051 ("Q") share
      // their low byte, as do U+0100 and NUL.
      const pairs = [
        ['.x::after { content: "ő"; }', '.x::after { content: "Q"; }'],
        ['.y { font-family: "Ā"; }', '.y { font-family: "\u0000"; }'],
        ['/* \u{1F600} */', '/* \u{1F610} */'],
      ];
      for (final pair in pairs) {
        final first = MonacoPageConfig(customCss: pair[0]);
        final second = MonacoPageConfig(customCss: pair[1]);
        expect(first, isNot(second));
        expect(
          first.stableCacheKey(),
          isNot(second.stableCacheKey()),
          reason: '${pair[0]} vs ${pair[1]}',
        );
      }
    });
  });

  group('MonacoCapabilities', () {
    test('fromHandshake maps capability flags', () {
      const handshake = MonacoHandshake(
        protocolVersion: 3,
        monacoVersion: '0.57.0',
        capabilities: {'lsp'},
      );
      final capabilities = MonacoCapabilities.fromHandshake(handshake);
      expect(capabilities.monacoVersion, '0.57.0');
      expect(capabilities.protocolVersion, 3);
      expect(capabilities.lsp, isTrue);
      expect(capabilities.diff, isFalse);
      expect('$capabilities', contains('protocol v3'));
      expect('$capabilities', contains('lsp: true'));
    });
  });

  group('MonacoViewState', () {
    test('wraps and round-trips the raw payload', () {
      const state = MonacoViewState.fromJson({'cursorState': 1});
      expect(state.toJson(), {'cursorState': 1});
      expect(state.isEmpty, isFalse);
      expect(const MonacoViewState.fromJson({}).isEmpty, isTrue);
    });

    test('value equality, hashCode, and toString', () {
      const state = MonacoViewState.fromJson({'a': 1, 'b': 2});
      const same = MonacoViewState.fromJson({'a': 1, 'b': 2});
      expect(state, same);
      expect(state.hashCode, same.hashCode);
      expect(state, isNot(const MonacoViewState.fromJson({'a': 1})));
      expect('$state', 'MonacoViewState(2 entries)');
    });

    test('toJson returns an independent copy of the payload', () {
      const state = MonacoViewState.fromJson({
        'scroll': {'top': 10},
      });

      final leaked = state.toJson();
      leaked['scroll'] = 'clobbered';
      (state.toJson()['scroll']! as Map)['top'] = 99;

      expect(state.toJson(), {
        'scroll': {'top': 10},
      });
    });

    test('equality and hashCode are deep over nested payloads', () {
      // Deliberately NON-const: const literals canonicalize to the same
      // instance, which would test identity instead of deep equality.
      // ignore: prefer_const_constructors
      final a = MonacoViewState.fromJson({
        'cursorState': [
          {'position': 4},
        ],
        'scroll': {'top': 10},
      });
      // Non-const for the same reason.
      // ignore: prefer_const_constructors
      final b = MonacoViewState.fromJson({
        'cursorState': [
          {'position': 4},
        ],
        'scroll': {'top': 10},
      });

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const MonacoViewState.fromJson({
            'cursorState': [
              {'position': 5},
            ],
            'scroll': {'top': 10},
          }),
        ),
      );
    });
  });

  group('MonacoPadding', () {
    test('round-trips and omits nulls', () {
      const padding = MonacoPadding(top: 8, bottom: 4);
      expect(padding.toJson(), {'top': 8, 'bottom': 4});
      expect(MonacoPadding.fromJson(padding.toJson()), padding);
      expect(const MonacoPadding().toMonacoJson(), isEmpty);
      expect(MonacoPadding.fromJson(const {}), const MonacoPadding());
    });

    test('accepts wire doubles and rejects wrong types', () {
      expect(MonacoPadding.fromJson(const {'top': 8.0}).top, 8);
      expect(
        () => MonacoPadding.fromJson(const {'top': 'eight'}),
        throwsFormatException,
      );
    });
  });

  group('MonacoMinimapOptions', () {
    test('round-trips including the side enum', () {
      const minimap = MonacoMinimapOptions(
        enabled: true,
        side: MonacoMinimapSide.left,
        renderCharacters: false,
        maxColumn: 80,
        scale: 2,
      );
      expect(minimap.toJson(), {
        'enabled': true,
        'side': 'left',
        'renderCharacters': false,
        'maxColumn': 80,
        'scale': 2,
      });
      expect(MonacoMinimapOptions.fromJson(minimap.toJson()), minimap);
    });

    test('rejects unknown enum ids and wrong types', () {
      expect(
        () => MonacoMinimapOptions.fromJson(const {'side': 'middle'}),
        throwsFormatException,
      );
      expect(
        () => MonacoMinimapOptions.fromJson(const {'enabled': 1}),
        throwsFormatException,
      );
    });
  });

  group('MonacoScrollbarOptions', () {
    test('round-trips every field', () {
      const scrollbar = MonacoScrollbarOptions(
        vertical: MonacoScrollbarVisibility.auto,
        horizontal: MonacoScrollbarVisibility.visible,
        verticalScrollbarSize: 14,
        horizontalScrollbarSize: 10,
        handleMouseWheel: true,
        useShadows: false,
      );
      expect(scrollbar.toJson(), {
        'vertical': 'auto',
        'horizontal': 'visible',
        'verticalScrollbarSize': 14,
        'horizontalScrollbarSize': 10,
        'handleMouseWheel': true,
        'useShadows': false,
      });
      expect(MonacoScrollbarOptions.fromJson(scrollbar.toJson()), scrollbar);
      expect(const MonacoScrollbarOptions().toMonacoJson(), isEmpty);
    });

    test('rejects wrong types', () {
      expect(
        () => MonacoScrollbarOptions.fromJson(const {'vertical': 2}),
        throwsFormatException,
      );
      expect(
        () => MonacoScrollbarOptions.fromJson(const {'useShadows': 'no'}),
        throwsFormatException,
      );
    });
  });

  group('MonacoGuidesOptions and MonacoStickyScroll', () {
    test('round-trip and omit nulls', () {
      const guides = MonacoGuidesOptions(
        bracketPairs: true,
        indentation: false,
      );
      expect(guides.toJson(), {'bracketPairs': true, 'indentation': false});
      expect(MonacoGuidesOptions.fromJson(guides.toJson()), guides);
      expect(const MonacoGuidesOptions().toMonacoJson(), isEmpty);

      const sticky = MonacoStickyScroll(enabled: true, maxLineCount: 5);
      expect(sticky.toJson(), {'enabled': true, 'maxLineCount': 5});
      expect(MonacoStickyScroll.fromJson(sticky.toJson()), sticky);
      expect(const MonacoStickyScroll().toMonacoJson(), isEmpty);
    });
  });

  group('MonacoTheme', () {
    test('maps built-ins to base themes and labels', () {
      expect(MonacoTheme.vs.asBaseTheme, MonacoBaseTheme.vs);
      expect(MonacoTheme.vsDark.asBaseTheme, MonacoBaseTheme.vsDark);
      expect(MonacoTheme.hcBlack.asBaseTheme, MonacoBaseTheme.hcBlack);
      expect(MonacoTheme.hcLight.asBaseTheme, MonacoBaseTheme.hcLight);
      expect(const MonacoTheme('app-dark').asBaseTheme, isNull);
      expect(MonacoTheme.vs.label, 'Light');
      expect(const MonacoTheme('app-dark').label, isNull);
      expect(MonacoTheme.vsDark.isBuiltIn, isTrue);
      expect(const MonacoTheme('app-dark').isBuiltIn, isFalse);
    });
  });

  group('DecorationOptions', () {
    test('inlineClass factory shapes Monaco options', () {
      final withHover = DecorationOptions.inlineClass(
        range: range,
        className: 'hl',
        hoverMessage: 'hint',
        additionalOptions: const {'stickiness': 1},
      );
      expect(withHover.options, {
        'inlineClassName': 'hl',
        'hoverMessage': 'hint',
        'stickiness': 1,
      });
      final withoutHover = DecorationOptions.inlineClass(
        range: range,
        className: 'hl',
      );
      expect(withoutHover.options, {'inlineClassName': 'hl'});
    });

    test('glyphMargin and line factories shape Monaco options', () {
      final glyph = DecorationOptions.glyphMargin(
        range: range,
        className: 'gutter-icon',
        hoverMessage: 'breakpoint',
      );
      expect(glyph.options, {
        'glyphMarginClassName': 'gutter-icon',
        'glyphMarginHoverMessage': 'breakpoint',
      });
      final line = DecorationOptions.line(
        range: range,
        className: 'error-line',
        additionalOptions: const {'linesDecorationsClassName': 'stripe'},
      );
      expect(line.options, {
        'className': 'error-line',
        'isWholeLine': true,
        'linesDecorationsClassName': 'stripe',
      });
    });

    test('round-trips and rejects a missing range', () {
      const decoration = DecorationOptions(
        range: range,
        options: {'className': 'x'},
      );
      expect(DecorationOptions.fromJson(decoration.toJson()), decoration);
      expect(
        DecorationOptions.fromJson({'range': range.toJson()}).options,
        isEmpty,
      );
      expect(
        () =>
            DecorationOptions.fromJson(const {'options': <String, Object?>{}}),
        throwsFormatException,
      );
    });
  });

  group('MonacoKeybinding', () {
    test('value equality and hashCode', () {
      const binding = MonacoKeybinding(
        key: MonacoKey.keyS,
        ctrlCmd: true,
        shift: true,
      );
      const same = MonacoKeybinding(
        key: MonacoKey.keyS,
        ctrlCmd: true,
        shift: true,
      );
      const different = MonacoKeybinding(key: MonacoKey.keyS, ctrlCmd: true);
      expect(binding, same);
      expect(binding.hashCode, same.hashCode);
      expect(binding, isNot(different));
    });

    test('toString and toJson spell out the chord', () {
      const binding = MonacoKeybinding(
        key: MonacoKey.keyS,
        ctrlCmd: true,
        alt: true,
        winCtrl: true,
      );
      expect('$binding', 'MonacoKeybinding(CtrlCmd+Alt+WinCtrl+KeyS)');
      expect(binding.toJson(), {
        'key': 'KeyS',
        'ctrlCmd': true,
        'shift': false,
        'alt': true,
        'winCtrl': true,
      });
    });
  });

  group('MarkerSeverity', () {
    test('fromValue maps Monaco values and defaults to info', () {
      expect(MarkerSeverity.fromValue(1), MarkerSeverity.hint);
      expect(MarkerSeverity.fromValue(8), MarkerSeverity.error);
      expect(MarkerSeverity.fromValue(99), MarkerSeverity.info);
    });
  });

  group('MarkerData', () {
    test('error and warning factories set severity', () {
      final error = MarkerData.error(
        range: range,
        message: 'broken',
        code: 'E1',
        source: 'linter',
      );
      expect(error.severity, MarkerSeverity.error);
      expect(error.code, 'E1');
      expect(
        MarkerData.warning(range: range, message: 'meh').severity,
        MarkerSeverity.warning,
      );
    });

    test('round-trips the flattened wire shape', () {
      final marker = MarkerData(
        range: range,
        message: 'unused variable',
        severity: MarkerSeverity.warning,
        code: 'W1',
        source: 'linter',
        tags: const ['unnecessary'],
        relatedInformation: [
          RelatedInformation(
            resource: Uri.parse('file:///a.dart'),
            range: range,
            message: 'declared here',
          ),
        ],
      );
      final json = marker.toJson();
      expect(json['startLineNumber'], 1);
      expect(json['severity'], MarkerSeverity.warning.value);
      expect(MarkerData.fromJson(json), marker);
    });

    test('minimal wire shape defaults severity to info', () {
      final marker = MarkerData.fromJson({
        ...range.toJson(),
        'message': 'plain',
      });
      expect(marker.severity, MarkerSeverity.info);
      expect(marker.code, isNull);
      expect(marker.tags, isNull);
      expect(marker.relatedInformation, isNull);
      expect(marker.toJson().containsKey('code'), isFalse);
    });

    test('rejects missing or mistyped wire values', () {
      expect(() => MarkerData.fromJson(range.toJson()), throwsFormatException);
      expect(
        () => MarkerData.fromJson({
          ...range.toJson(),
          'message': 'x',
          'severity': 'high',
        }),
        throwsFormatException,
      );
      expect(
        () => MarkerData.fromJson({
          ...range.toJson(),
          'message': 'x',
          'tags': 'unnecessary',
        }),
        throwsFormatException,
      );
      expect(
        () => MarkerData.fromJson({
          ...range.toJson(),
          'message': 'x',
          'relatedInformation': ['not a map'],
        }),
        throwsFormatException,
      );
      expect(
        () =>
            MarkerData.fromJson({...range.toJson(), 'message': 'x', 'code': 7}),
        throwsFormatException,
      );
    });
  });

  group('RelatedInformation', () {
    test('round-trips and validates the resource URI', () {
      final info = RelatedInformation(
        resource: Uri.parse('file:///b.dart'),
        range: range,
        message: 'related',
      );
      expect(RelatedInformation.fromJson(info.toJson()), info);
      expect(
        () => RelatedInformation.fromJson({
          ...range.toJson(),
          'resource': 'http://[',
          'message': 'related',
        }),
        throwsFormatException,
      );
    });
  });

  group('EditOperation', () {
    test('insert and delete factories shape the range', () {
      final insert = EditOperation.insert(
        position: const Position(line: 2, column: 3),
        text: 'abc',
      );
      expect(
        insert.range,
        Range.fromPositions(
          const Position(line: 2, column: 3),
          const Position(line: 2, column: 3),
        ),
      );
      final delete = EditOperation.delete(range: range);
      expect(delete.text, isEmpty);
    });

    test('round-trips and rejects bad wire values', () {
      const operation = EditOperation(
        range: range,
        text: 'abc',
        forceMoveMarkers: true,
      );
      expect(EditOperation.fromJson(operation.toJson()), operation);
      expect(
        const EditOperation(
          range: range,
          text: 'x',
        ).toJson().containsKey('forceMoveMarkers'),
        isFalse,
      );
      expect(
        () => EditOperation.fromJson({'range': range.toJson()}),
        throwsFormatException,
      );
      expect(
        () => EditOperation.fromJson(const {'range': 'x', 'text': 'y'}),
        throwsFormatException,
      );
    });
  });

  group('MonacoTextChange', () {
    test('round-trips and rejects a missing range', () {
      const change = MonacoTextChange(range: range, text: 'typed');
      expect(MonacoTextChange.fromJson(change.toJson()), change);
      expect(
        () => MonacoTextChange.fromJson(const {'text': 'typed'}),
        throwsFormatException,
      );
    });
  });

  group('FindMatch', () {
    test('round-trips with and without matched text', () {
      const match = FindMatch(range: range, match: 'needle');
      expect(FindMatch.fromJson(match.toJson()), match);
      const bare = FindMatch(range: range);
      expect(bare.toJson().containsKey('match'), isFalse);
      expect(FindMatch.fromJson(bare.toJson()), bare);
    });
  });

  group('FindOptions', () {
    test('convenience factories set the right flags', () {
      final caseSensitive = FindOptions.caseSensitive(wholeWord: true);
      expect(caseSensitive.matchCase, isTrue);
      expect(caseSensitive.wholeWord, isTrue);
      final regex = FindOptions.regex(matchCase: true);
      expect(regex.isRegex, isTrue);
      expect(regex.matchCase, isTrue);
    });

    test('round-trips, defaults, and error paths', () {
      const options = FindOptions(
        isRegex: true,
        matchCase: true,
        wholeWord: true,
        searchOnlyEditableRange: false,
        limitResultCount: 50,
      );
      expect(FindOptions.fromJson(options.toJson()), options);
      expect(FindOptions.fromJson(const {}), const FindOptions());
      expect(
        const FindOptions().toJson().containsKey('limitResultCount'),
        isFalse,
      );
      expect(
        () => FindOptions.fromJson(const {'isRegex': 'yes'}),
        throwsFormatException,
      );
      expect(
        () => FindOptions.fromJson(const {'limitResultCount': 'many'}),
        throwsFormatException,
      );
    });
  });
}
