import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorOptions', () {
    test('fromJson maps values sparsely (unset fields stay null)', () {
      final options = EditorOptions.fromJson({
        'language': 'python',
        'theme': 'vs',
        'fontSize': 16,
        'lineNumbers': 'off',
        'tabSize': 2,
      });
      expect(options.language, MonacoLanguage.python);
      expect(options.theme, MonacoTheme.vs);
      expect(options.fontSize, 16);
      expect(options.lineNumbers, MonacoLineNumbers.off);
      expect(options.tabSize, 2);
      expect(options.wordWrap, isNull);
    });

    test('fromJson throws on unknown keys', () {
      expect(
        () => EditorOptions.fromJson({'themeId': 'app-dark'}),
        throwsFormatException,
      );
    });

    test('fromJson throws on wrongly typed values', () {
      expect(
        () => EditorOptions.fromJson({'lineNumbers': false}),
        throwsFormatException,
      );
      expect(
        () => EditorOptions.fromJson({'fontSize': 'big'}),
        throwsFormatException,
      );
    });

    test('toJson omits null fields and round-trips sparsely', () {
      const options = EditorOptions(
        theme: MonacoTheme('app-dark'),
        fontSize: 16,
        wordWrap: MonacoWordWrap.bounded,
        minimap: MonacoMinimapOptions(enabled: true),
        padding: MonacoPadding(top: 10),
      );

      final json = options.toJson();
      expect(json.containsKey('lineNumbers'), false);
      expect(json.containsKey('tabSize'), false);

      final restored = EditorOptions.fromJson(json);
      expect(restored, options);
    });

    test('merge lets non-null fields of the other options win', () {
      const base = EditorOptions(fontSize: 14, tabSize: 4);
      const override = EditorOptions(fontSize: 16);

      final merged = base.merge(override);
      expect(merged.fontSize, 16);
      expect(merged.tabSize, 4);
    });

    test('merge composes nested minimap options instead of replacing them', () {
      // The curated default disables the minimap; a caller who only picks a
      // side must not silently re-enable it (Monaco's own default is ON).
      final merged = MonacoDefaults.editorOptions.merge(
        const EditorOptions(
          minimap: MonacoMinimapOptions(side: MonacoMinimapSide.left),
        ),
      );
      expect(merged.minimap!.enabled, false);
      expect(merged.minimap!.side, MonacoMinimapSide.left);
    });

    test('merge composes nested padding instead of replacing it', () {
      final merged = MonacoDefaults.editorOptions.merge(
        const EditorOptions(padding: MonacoPadding(bottom: 4)),
      );
      expect(merged.padding!.top, 10);
      expect(merged.padding!.bottom, 4);
    });

    test('merge deep-merges every structured sub-option field-wise', () {
      const base = EditorOptions(
        scrollbar: MonacoScrollbarOptions(
          verticalScrollbarSize: 8,
          handleMouseWheel: true,
        ),
        guides: MonacoGuidesOptions(bracketPairs: true),
        stickyScroll: MonacoStickyScroll(enabled: true, maxLineCount: 5),
      );
      const override = EditorOptions(
        scrollbar: MonacoScrollbarOptions(handleMouseWheel: false),
        guides: MonacoGuidesOptions(indentation: false),
        stickyScroll: MonacoStickyScroll(maxLineCount: 3),
      );

      final merged = base.merge(override);
      expect(merged.scrollbar!.verticalScrollbarSize, 8);
      expect(merged.scrollbar!.handleMouseWheel, false);
      expect(merged.guides!.bracketPairs, true);
      expect(merged.guides!.indentation, false);
      expect(merged.stickyScroll!.enabled, true);
      expect(merged.stickyScroll!.maxLineCount, 3);
    });

    test(
      'merge keeps a one-sided nested value when the other side is unset',
      () {
        const withMinimap = EditorOptions(
          minimap: MonacoMinimapOptions(enabled: true),
        );
        expect(
          withMinimap.merge(const EditorOptions()).minimap,
          const MonacoMinimapOptions(enabled: true),
        );
        expect(
          const EditorOptions().merge(withMinimap).minimap,
          const MonacoMinimapOptions(enabled: true),
        );
      },
    );

    test('toMonacoOptions maps expected keys', () {
      const options = EditorOptions(
        wordWrap: MonacoWordWrap.off,
        minimap: MonacoMinimapOptions(enabled: true),
        lineNumbers: MonacoLineNumbers.off,
        cursorBlinking: CursorBlinking.expand,
        cursorStyle: CursorStyle.block,
        renderWhitespace: RenderWhitespace.all,
        parameterHints: false,
        hover: false,
        contextMenu: false,
        bracketPairColorization: false,
      );
      final map = options.toMonacoOptions();
      expect(map['wordWrap'], 'off');
      expect(map['minimap'], {'enabled': true});
      expect(map['lineNumbers'], 'off');
      expect(map['cursorBlinking'], 'expand');
      expect(map['cursorStyle'], 'block');
      expect(map['renderWhitespace'], 'all');
      expect(map['parameterHints'], {'enabled': false});
      expect(map['hover'], {'enabled': false});
      expect(map['contextmenu'], false);
      expect(map['bracketPairColorization'], {'enabled': false});
      expect(map.containsKey('padding'), false);
    });
  });

  group('Monaco 0.56/0.57 options', () {
    const find = MonacoFindOptions(
      seedSearchStringFromSelection: MonacoFindSeedSearchString.selection,
      autoFindInSelection: MonacoAutoFindInSelection.multiline,
      addExtraSpaceOnTop: false,
      loop: false,
      closeOnResult: true,
    );
    const options = EditorOptions(
      wordWrapIndicator: true,
      fullwidthCharacterWidth: MonacoFullwidthCharacterWidth.twoCells,
      doubleClickSelectsBlock: false,
      find: find,
    );

    test('toJson emits Monaco value strings and round-trips', () {
      final json = options.toJson();
      expect(json, {
        'wordWrapIndicator': true,
        'fullwidthCharacterWidth': 'twoCells',
        'doubleClickSelectsBlock': false,
        'find': {
          'seedSearchStringFromSelection': 'selection',
          'autoFindInSelection': 'multiline',
          'addExtraSpaceOnTop': false,
          'loop': false,
          'closeOnResult': true,
        },
      });
      expect(EditorOptions.fromJson(json), options);
    });

    test('toMonacoOptions maps the new options to Monaco keys', () {
      expect(options.toMonacoOptions(), {
        'wordWrapIndicator': true,
        'fullwidthCharacterWidth': 'twoCells',
        'doubleClickSelectsBlock': false,
        'find': {
          'seedSearchStringFromSelection': 'selection',
          'autoFindInSelection': 'multiline',
          'addExtraSpaceOnTop': false,
          'loop': false,
          'closeOnResult': true,
        },
      });
    });

    test('unset options and empty find stay sparse', () {
      expect(const EditorOptions().toMonacoOptions(), isEmpty);
      expect(const MonacoFindOptions().toMonacoJson(), isEmpty);
      expect(
        const EditorOptions(find: MonacoFindOptions(loop: true))
            .toMonacoOptions(),
        {
          'find': {'loop': true},
        },
      );
      expect(MonacoFindOptions.fromJson(const {}), const MonacoFindOptions());
    });

    test('extra still overrides the modeled keys', () {
      final map = options
          .copyWith(
            extra: const {
              'doubleClickSelectsBlock': true,
              'find': {'cursorMoveOnType': false},
            },
          )
          .toMonacoOptions();
      expect(map['doubleClickSelectsBlock'], true);
      // `extra` replaces the whole key; it does not deep-merge.
      expect(map['find'], {'cursorMoveOnType': false});
      expect(map['wordWrapIndicator'], true);
    });

    test('fromJson rejects unknown enum ids and wrong types', () {
      expect(
        () => EditorOptions.fromJson(const {'fullwidthCharacterWidth': 'wide'}),
        throwsFormatException,
      );
      expect(
        () => EditorOptions.fromJson(const {'wordWrapIndicator': 'yes'}),
        throwsFormatException,
      );
      expect(
        () => EditorOptions.fromJson(const {'doubleClickSelectsBlock': 1}),
        throwsFormatException,
      );
      expect(
        () => EditorOptions.fromJson(const {'find': true}),
        throwsFormatException,
      );
    });

    test('MonacoFindOptions.fromJson is strict', () {
      expect(
        () => MonacoFindOptions.fromJson(const {'cursorMoveOnType': false}),
        throwsFormatException,
      );
      expect(
        () => EditorOptions.fromJson(const {
          'find': {'loop': true, 'history': 'never'},
        }),
        throwsFormatException,
      );
      // Monaco also accepts booleans here; the typed surface does not.
      expect(
        () => MonacoFindOptions.fromJson(const {
          'seedSearchStringFromSelection': true,
        }),
        throwsFormatException,
      );
      expect(
        () => MonacoFindOptions.fromJson(const {'autoFindInSelection': 'some'}),
        throwsFormatException,
      );
      expect(
        () => MonacoFindOptions.fromJson(const {'closeOnResult': 'true'}),
        throwsFormatException,
      );
    });

    test('merge is field-wise and nulls do not overwrite', () {
      const base = EditorOptions(
        wordWrapIndicator: true,
        fullwidthCharacterWidth: MonacoFullwidthCharacterWidth.twoCells,
        doubleClickSelectsBlock: false,
        find: MonacoFindOptions(
          seedSearchStringFromSelection: MonacoFindSeedSearchString.never,
          loop: false,
        ),
      );
      const override = EditorOptions(
        doubleClickSelectsBlock: true,
        find: MonacoFindOptions(closeOnResult: true),
      );

      final merged = base.merge(override);
      expect(merged.wordWrapIndicator, true);
      expect(
        merged.fullwidthCharacterWidth,
        MonacoFullwidthCharacterWidth.twoCells,
      );
      expect(merged.doubleClickSelectsBlock, true);
      expect(
        merged.find,
        const MonacoFindOptions(
          seedSearchStringFromSelection: MonacoFindSeedSearchString.never,
          loop: false,
          closeOnResult: true,
        ),
      );

      expect(base.merge(const EditorOptions()), base);
      expect(const EditorOptions().merge(base).find, base.find);
      expect(find.merge(null), same(find));
      expect(find.merge(const MonacoFindOptions()), find);
    });

    test('curated defaults leave the new options to Monaco', () {
      final defaults = MonacoDefaults.editorOptions;
      expect(defaults.wordWrapIndicator, isNull);
      expect(defaults.fullwidthCharacterWidth, isNull);
      expect(defaults.doubleClickSelectsBlock, isNull);
      expect(defaults.find, isNull);
    });
  });
}
