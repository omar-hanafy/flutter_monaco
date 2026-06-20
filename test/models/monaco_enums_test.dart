import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Monaco enums', () {
    test('fromId falls back to defaults', () {
      expect(MonacoTheme.fromId('unknown'), MonacoTheme.vsDark);
      expect(MonacoLanguage.fromId('unknown'), MonacoLanguage.markdown);
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
