import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String nativeControllerSource() => File(
    'lib/src/platform/web_view_controller/native.dart',
  ).readAsStringSync();

  test('native focus handoff is only implemented by Windows WebView2', () {
    final source = nativeControllerSource();

    final baseFocusStart = source.indexOf(
      '@override\n  Future<void> requestNativeFocus() async {',
    );
    final baseFocusEnd = source.indexOf('/// Generates and caches');
    expect(baseFocusStart, isNonNegative);
    expect(baseFocusEnd, greaterThan(baseFocusStart));

    final baseFocusBlock = source.substring(baseFocusStart, baseFocusEnd);
    expect(baseFocusBlock, contains('No-op by default'));
    expect(baseFocusBlock, isNot(contains('_controller.focus()')));

    final windowsClassStart = source.indexOf('class WindowsWebViewController');
    final windowsFocusStart = source.indexOf(
      '@override\n  Future<void> requestNativeFocus() async {',
      windowsClassStart,
    );
    final windowsFocusEnd = source.indexOf(
      '@override\n  Future<void> enableJavaScript()',
      windowsFocusStart,
    );
    expect(windowsClassStart, isNonNegative);
    expect(windowsFocusStart, greaterThan(windowsClassStart));
    expect(windowsFocusEnd, greaterThan(windowsFocusStart));

    final windowsFocusBlock = source.substring(
      windowsFocusStart,
      windowsFocusEnd,
    );
    expect(windowsFocusBlock, contains('await _controller.focus();'));
  });
}
