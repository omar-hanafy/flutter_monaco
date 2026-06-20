import 'dart:io';

import 'package:flutter_monaco/src/core/monaco_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.baseDir);

  final Directory baseDir;

  @override
  Future<String?> getApplicationSupportPath() async => baseDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonacoAssets', () {
    late PathProviderPlatform originalPlatform;
    late Directory tempDir;

    setUp(() async {
      originalPlatform = PathProviderPlatform.instance;
      tempDir = await Directory.systemTemp.createTemp('monaco_assets_test_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
      await MonacoAssets.clearCache();
    });

    tearDown(() async {
      await MonacoAssets.clearCache();
      PathProviderPlatform.instance = originalPlatform;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('ensureReady extracts assets and writes sentinel', () async {
      await MonacoAssets.ensureReady();
      final info = await MonacoAssets.assetInfo();
      expect(info['exists'], true);
      final targetDir = info['path'] as String;
      final sentinel = File(p.join(targetDir, '.monaco_complete'));
      expect(sentinel.existsSync(), true);
      expect(sentinel.readAsStringSync().trim(), MonacoAssets.monacoVersion);
    });

    test('ensureReady is re-entrant', () async {
      await Future.wait(List.generate(5, (_) => MonacoAssets.ensureReady()));
      final info = await MonacoAssets.assetInfo();
      expect(info['exists'], true);
      final targetDir = info['path'] as String;
      expect(Directory(targetDir).existsSync(), true);
    });

    test('version mismatch forces re-extract', () async {
      final info = await MonacoAssets.assetInfo();
      final targetDir = info['path'] as String;
      final loader = File(p.join(targetDir, 'min', 'vs', 'loader.js'));
      await loader.parent.create(recursive: true);
      await loader.writeAsString('');
      final sentinel = File(p.join(targetDir, '.monaco_complete'));
      await sentinel.writeAsString('0.0.0');
      await MonacoAssets.ensureReady();
      expect(sentinel.readAsStringSync().trim(), MonacoAssets.monacoVersion);
    });

    test('clearCache removes assets and resets caches', () async {
      await MonacoAssets.ensureReady();
      final infoBefore = await MonacoAssets.assetInfo();
      expect(infoBefore['exists'], true);
      await MonacoAssets.clearCache();
      final infoAfter = await MonacoAssets.assetInfo();
      expect(infoAfter['exists'], false);
    });

    test('generated html includes mobile viewport metadata', () {
      final html = MonacoAssets.generateIndexHtml('min/vs');

      expect(html, contains('name="viewport"'));
      expect(
        html,
        contains(
          'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no',
        ),
      );
    });

    test('generated html does not override Monaco inputarea layout', () {
      final html = MonacoAssets.generateIndexHtml('min/vs');

      expect(html, isNot(contains('.monaco-editor .inputarea')));
      expect(html, isNot(contains('@media (pointer: coarse)')));
    });

    test('generated html includes tap-gated mobile gesture focus bridge', () {
      final html = MonacoAssets.generateIndexHtml('min/vs');

      expect(html, contains('const isMobileInputPlatform = () =>'));
      expect(html, contains("navigator.platform === 'MacIntel'"));
      expect(html, contains('navigator.maxTouchPoints > 1'));
      expect(html, contains('const focusEditorTextAreaNow = () =>'));
      expect(html, contains('const ownerDocument = node.ownerDocument'));
      expect(html, contains('const ownerWindow = ownerDocument.defaultView'));
      expect(html, contains('const isAndroid = /Android/i.test(ua)'));
      expect(html, contains('const isFlutterWebEmbed = (() =>'));
      expect(html, contains('const tapMoveThreshold = 8'));
      expect(html, contains('const tapTimeThreshold = 650'));
      expect(html, contains('const compatibilityEventSuppressMs = 1200'));
      expect(html, contains('let androidTouchScrollGesture = null'));
      expect(html, contains('let suppressFocusUntil = 0'));
      expect(html, contains('const usePointerTapBridge ='));
      expect(html, contains('supportsPointerEvents && isAndroid'));
      expect(html, contains('const useTouchTapBridge = !usePointerTapBridge'));
      expect(html, contains('const useAndroidWebFocusGuard ='));
      expect(html, contains('const getScrollSnapshot = () =>'));
      expect(html, contains('ed.getScrollTop'));
      expect(html, contains('ed.getScrollLeft'));
      expect(html, contains('const hasMovedFromStart = (event) =>'));
      expect(html, contains('const hasTouchScrollMovedFromStart = (event) =>'));
      expect(html, contains('const blockEvent = (event) =>'));
      expect(html, contains('const suppressAndBlock = (event) =>'));
      expect(html, contains('const editorInputSelector ='));
      expect(html, contains('textarea.inputarea, .native-edit-context'));
      expect(html, contains('const isEditorInputElement ='));
      expect(html, contains('const getEditorInputElement ='));
      expect(html, contains('let maxObservedViewportHeight = 0'));
      expect(html, contains('const isKeyboardLikelyVisible ='));
      expect(html, contains('const suppressScrollFocusIfNeeded ='));
      expect(html, contains('const guardSuppressedTextAreaFocus ='));
      expect(html, contains('const endGesture = (event, id, kind) =>'));
      expect(html, contains('suppressAndBlock(event);'));
      expect(html, contains('const capturePassiveFalse ='));
      expect(html, contains("ownerDocument.addEventListener('pointerdown'"));
      expect(
        html,
        contains(
          "ownerDocument.addEventListener('pointerup', onPointerUp, capturePassiveFalse",
        ),
      );
      expect(
        html,
        contains(
          "ownerDocument.addEventListener('touchend', onTouchEnd, capturePassiveFalse",
        ),
      );
      expect(
        html,
        contains(
          "ownerDocument.addEventListener('touchend', endAndroidTouchScrollGuard, capturePassiveFalse",
        ),
      );
      expect(
        html,
        contains(
          "ownerDocument.addEventListener('focusin', guardSuppressedTextAreaFocus",
        ),
      );
      expect(
        html,
        contains(
          "ownerDocument.addEventListener('click', blockSuppressedCompatibilityEvent",
        ),
      );
      expect(html, contains('node.style.touchAction'));
      expect(html, isNot(contains('focusFromClick')));
      expect(html, isNot(contains('mobileGestureDebug')));
      expect(html, isNot(contains('monacoGestureDebug')));
    });

    test('generated html keeps desktop preventScroll focus retry', () {
      final html = MonacoAssets.generateIndexHtml('min/vs');

      expect(html, contains('if (isMobileInputPlatform())'));
      expect(html, contains('focusEditorTextAreaNow();'));
      expect(html, contains('ta.focus({ preventScroll: true });'));
    });

    test(
      'web html statically contains touch pans inside the editor document',
      () {
        final html = MonacoAssets.generateIndexHtml(
          'https://example.com/assets/monaco/min/vs',
          isWeb: true,
          messageToken: 'token',
        );

        expect(html, contains('touch-action: none;'));
        expect(html, contains('overscroll-behavior: none;'));
      },
    );

    test('web html includes the visual viewport keyboard fit module', () {
      final html = MonacoAssets.generateIndexHtml(
        'https://example.com/assets/monaco/min/vs',
        isWeb: true,
        messageToken: 'token',
      );

      expect(html, contains('__flutterMonacoViewportFitBound'));
      expect(html, contains('const applyViewportFit = () =>'));
      expect(html, contains('const scheduleViewportFit = () =>'));
      expect(html, contains('const clearViewportFit = () =>'));
      expect(html, contains('fitFrame.getBoundingClientRect()'));
      expect(html, contains('fitParent.visualViewport'));
      expect(html, contains("fitViewport.addEventListener('resize'"));
      expect(html, contains("fitViewport.addEventListener('scroll'"));
      expect(html, contains('ed.revealPosition(pos)'));
      expect(
        html,
        contains("fitWindow.addEventListener('pagehide', detachViewportFit"),
      );
    });

    test(
      'apple worker shim emits escaped newlines inside JS string literals',
      () {
        final html = MonacoAssets.generateIndexHtml(
          'min/vs',
          isIosOrMacOS: true,
        );

        // The escape must reach JavaScript as the two characters backslash-n.
        expect(html, contains(r'''};\n" +'''));
        expect(html, contains(r"""';\n" +"""));
        // A raw newline inside the JS string literal is a SyntaxError that
        // silently disables MonacoEnvironment (workers fall back to the main
        // thread), which is exactly what shipped between 1.0.0 and 1.7.0.
        expect(html, isNot(contains('\' };\n" +')));
        expect(html, isNot(contains('\';\n" +')));
      },
    );

    test('native html does not opt into web scroll containment', () {
      for (final html in [
        MonacoAssets.generateIndexHtml('min/vs'),
        MonacoAssets.generateIndexHtml('min/vs', isIosOrMacOS: true),
        MonacoAssets.generateIndexHtml(
          r'file:///C:/monaco/min/vs',
          isWindows: true,
        ),
      ]) {
        expect(html, isNot(contains('touch-action: none')));
        expect(html, isNot(contains('overscroll-behavior')));
        expect(html, isNot(contains('applyViewportFit')));
        expect(html, isNot(contains('__flutterMonacoViewportFitBound')));
      }
    });
  });
}
