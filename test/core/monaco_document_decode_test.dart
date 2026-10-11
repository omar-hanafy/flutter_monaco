import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

/// A document handle whose bridge answers every call with [result].
MonacoDocument _documentAnswering(Object? result) =>
    MonacoDocument.internal((method, params) async => result, null);

Matcher _protocolErrorFor(String operation) => throwsA(
  isA<MonacoProtocolError>().having((e) => e.operation, 'operation', operation),
);

void main() {
  group('MonacoDocument result decoding', () {
    group('isDirty', () {
      test('decodes booleans', () async {
        expect(await _documentAnswering(true).isDirty(), isTrue);
        expect(await _documentAnswering(false).isDirty(), isFalse);
      });

      for (final wrong in <Object?>[
        null,
        'true',
        1,
        const <String, Object?>{},
      ]) {
        test('rejects ${wrong.runtimeType} instead of reading it as clean', () {
          expect(
            _documentAnswering(wrong).isDirty(),
            _protocolErrorFor('document.isDirty'),
          );
        });
      }
    });

    group('getWordAt', () {
      const position = Position(line: 1, column: 1);

      test('decodes a word and a null (no word at the position)', () async {
        expect(await _documentAnswering('hello').getWordAt(position), 'hello');
        expect(await _documentAnswering(null).getWordAt(position), isNull);
      });

      for (final wrong in <Object?>[
        42,
        true,
        const <Object?>['w'],
      ]) {
        test(
          'rejects ${wrong.runtimeType} instead of reading it as no word',
          () {
            expect(
              _documentAnswering(wrong).getWordAt(position),
              _protocolErrorFor('document.getWordAt'),
            );
          },
        );
      }
    });
  });
}
