import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Monaco enums', () {
    test('option enum fromId falls back to defaults', () {
      expect(CursorBlinking.fromId('unknown'), CursorBlinking.blink);
      expect(CursorStyle.fromId('unknown'), CursorStyle.line);
      expect(RenderWhitespace.fromId('unknown'), RenderWhitespace.selection);
      expect(
        AutoClosingBehavior.fromId('unknown'),
        AutoClosingBehavior.languageDefined,
      );
      expect(
        DiagnosticsSeverity.fromId('unknown'),
        DiagnosticsSeverity.warning,
      );
    });

    test('find and fullwidth enums use Monaco ids and default fallbacks', () {
      expect(MonacoFullwidthCharacterWidth.values.map((e) => e.id), [
        'font',
        'twoCells',
      ]);
      expect(MonacoFindSeedSearchString.values.map((e) => e.id), [
        'never',
        'always',
        'selection',
      ]);
      expect(MonacoAutoFindInSelection.values.map((e) => e.id), [
        'never',
        'always',
        'multiline',
      ]);

      // Fallbacks are Monaco's own defaults.
      expect(
        MonacoFullwidthCharacterWidth.fromId('unknown'),
        MonacoFullwidthCharacterWidth.font,
      );
      expect(
        MonacoFindSeedSearchString.fromId(null),
        MonacoFindSeedSearchString.always,
      );
      expect(
        MonacoAutoFindInSelection.fromId('unknown'),
        MonacoAutoFindInSelection.never,
      );
      expect(
        MonacoAutoFindInSelection.fromId(
          'unknown',
          orElse: MonacoAutoFindInSelection.multiline,
        ),
        MonacoAutoFindInSelection.multiline,
      );

      for (final value in MonacoFullwidthCharacterWidth.values) {
        expect(MonacoFullwidthCharacterWidth.fromId(value.id), value);
      }
      for (final value in MonacoFindSeedSearchString.values) {
        expect(MonacoFindSeedSearchString.fromId(value.id), value);
      }
      for (final value in MonacoAutoFindInSelection.values) {
        expect(MonacoAutoFindInSelection.fromId(value.id), value);
      }
    });

    test('theme and language ids are open sets with no fallback', () {
      const theme = MonacoTheme('unknown');
      expect(theme.id, 'unknown');
      expect(theme.isBuiltIn, false);
      expect(theme.label, isNull);

      const language = MonacoLanguage('unknown');
      expect(language.id, 'unknown');
      expect(language.isBuiltIn, false);
      expect(language.label, isNull);
    });

    test('builtIn catalogs expose the bundled ids', () {
      expect(MonacoTheme.builtIn, contains(MonacoTheme.vsDark));
      expect(MonacoTheme.vsDark.isBuiltIn, true);
      expect(MonacoLanguage.builtIn, contains(MonacoLanguage.dart));
      expect(MonacoLanguage.dart.isBuiltIn, true);
    });

    test('ids match expected values', () {
      expect(MonacoTheme.vsDark.id, 'vs-dark');
      expect(MonacoLanguage.dart.id, 'dart');
      expect(CursorBlinking.smooth.id, 'smooth');
      expect(CursorStyle.block.id, 'block');
      expect(RenderWhitespace.all.id, 'all');
      expect(AutoClosingBehavior.never.id, 'never');
      expect(DiagnosticsSeverity.error.id, 'error');
    });
  });
}
