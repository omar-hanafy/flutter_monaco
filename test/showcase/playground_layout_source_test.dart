import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('showcase lays MonacoEditor out as a direct sized child', () {
    final source = File(
      'example/lib/showcase/sections/playground_section.dart',
    ).readAsStringSync();
    final editorStart = source.indexOf('child: MonacoEditor(');
    expect(editorStart, isNonNegative);

    final sizedBoxStart = source.lastIndexOf('SizedBox(', editorStart);
    final guardStart = source.indexOf('if (monaco != null)', editorStart);
    expect(sizedBoxStart, isNonNegative);
    expect(guardStart, greaterThan(editorStart));

    final editorLayout = source.substring(sizedBoxStart, guardStart);
    expect(editorLayout, contains('height: editorHeight'));
    expect(editorLayout, isNot(contains('Stack(')));
    expect(editorLayout, isNot(contains('Positioned.fill')));
  });
}
