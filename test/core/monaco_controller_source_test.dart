import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web queued setters return before editor readiness', () {
    final source = File(
      'lib/src/core/monaco_controller.dart',
    ).readAsStringSync();

    expect(source, contains('_queuedLanguage = language;'));
    expect(source, contains('_queuedValue = value;'));
    expect(source, contains('if (kIsWeb) return;'));
  });
}
