import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// End-to-end proof of the macOS native first-responder handoff.
///
/// Runs against the real app window, the real WKWebView, and the real
/// `flutter_monaco/native_focus` Swift plugin - the full chain a unit test
/// cannot reach: pointer -> MonacoFocusIntent.user -> method channel ->
/// window.makeFirstResponder(webView) -> first-responder query back.
///
/// Run with:
///   cd example && flutter test integration_test/macos_native_focus_test.dart -d macos
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primary click hands native first responder to the WKWebView '
      'and releaseNativeFocus hands it back', (tester) async {
    if (!Platform.isMacOS) {
      markTestSkipped('macOS-only native handoff test');
      return;
    }

    final controller = await MonacoController.create(
      options: const EditorOptions(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MonacoEditor(controller: controller)),
      ),
    );
    await controller.whenReady;
    // Let the platform view attach and settle.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Baseline sanity: the channel must be reachable (the plugin registered).
    // Before any handoff the WKWebView may or may not be first responder,
    // but the answer must be authoritative (non-null) once the view exists.
    final baseline = await controller.hasNativeInputFocus();
    expect(
      baseline,
      isNotNull,
      reason:
          'Native focus channel unreachable or WKWebView not found: '
          'the flutter_monaco macOS plugin did not resolve the editor view.',
    );

    // A real primary click inside the editor routes MonacoFocusIntent.user
    // through the native handoff.
    final target = tester.getCenter(find.byType(MonacoEditor));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await gesture.down(target);
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();

    // The handoff is async behind the pointer handler; poll briefly.
    var owned = false;
    for (var i = 0; i < 40 && !owned; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      owned = await controller.hasNativeInputFocus() ?? false;
    }
    expect(
      owned,
      isTrue,
      reason: 'WKWebView never became first responder after a primary click',
    );

    // And the explicit handoff out of the editor.
    await controller.releaseNativeFocus();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      await controller.hasNativeInputFocus(),
      isFalse,
      reason: 'WKWebView still first responder after releaseNativeFocus',
    );

    binding.reportData = <String, dynamic>{'nativeHandoffVerified': true};
  });
}
