import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monaco paints an unparsable theme color red and reports nothing, so
/// non-string color values must fail at parse time.
void main() {
  group('MonacoThemeDefinition.fromJson colors', () {
    Map<String, dynamic> theme(Map<String, Object?> colors) => {
      'id': 'app',
      'base': 'vs-dark',
      'colors': colors,
    };

    test('accepts string color values', () {
      final definition = MonacoThemeDefinition.fromJson(
        theme({'editor.background': '#1E1E1E'}),
      );
      expect(definition.colors, {'editor.background': '#1E1E1E'});
    });

    test('rejects a null color value instead of sending "null"', () {
      expect(
        () =>
            MonacoThemeDefinition.fromJson(theme({'editor.background': null})),
        throwsFormatException,
      );
    });

    test('rejects a numeric color value instead of stringifying it', () {
      expect(
        () => MonacoThemeDefinition.fromJson(
          theme({'editor.background': 0x1E1E1E}),
        ),
        throwsFormatException,
      );
    });

    test('rejects other non-string color values', () {
      expect(
        () =>
            MonacoThemeDefinition.fromJson(theme({'editor.background': true})),
        throwsFormatException,
      );
      expect(
        () => MonacoThemeDefinition.fromMonacoThemeData('raw', const {
          'base': 'vs',
          'colors': {
            'editor.foreground': ['#fff'],
          },
        }),
        throwsFormatException,
      );
    });
  });
}
