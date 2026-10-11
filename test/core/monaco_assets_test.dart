import 'dart:io';

import 'package:flutter_monaco/src/assets/monaco_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/bridge_sources.dart';
import '../helpers/generate_index_html.dart';
import '../helpers/page_scripts.dart';

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
      expect(info.exists, true);
      final targetDir = info.path;
      final sentinel = File(p.join(targetDir, '.monaco_complete'));
      expect(sentinel.existsSync(), true);
      expect(sentinel.readAsStringSync().trim(), MonacoAssets.monacoVersion);
    });

    test('ensureReady is re-entrant', () async {
      await Future.wait(List.generate(5, (_) => MonacoAssets.ensureReady()));
      final info = await MonacoAssets.assetInfo();
      expect(info.exists, true);
      final targetDir = info.path;
      expect(Directory(targetDir).existsSync(), true);
    });

    test('version mismatch forces re-extract', () async {
      final info = await MonacoAssets.assetInfo();
      final targetDir = info.path;
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
      expect(infoBefore.exists, true);
      await MonacoAssets.clearCache();
      final infoAfter = await MonacoAssets.assetInfo();
      expect(infoAfter.exists, false);
    });

    test('ensureReady during clearCache re-extracts', () async {
      await MonacoAssets.ensureReady();

      // A second engine asks for the assets while the first clears them. It
      // must not get the completed readiness of the tree being deleted.
      final clearing = MonacoAssets.clearCache();
      final ready = MonacoAssets.ensureReady();
      await Future.wait([clearing, ready]);

      final info = await MonacoAssets.assetInfo();
      expect(info.exists, isTrue);
      expect(
        File(p.join(info.path, '.monaco_complete')).readAsStringSync(),
        MonacoAssets.monacoVersion,
      );
    });

    test('generated html includes mobile viewport metadata', () {
      final html = generateIndexHtml('min/vs');

      expect(html, contains('name="viewport"'));
      expect(
        html,
        contains(
          'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no',
        ),
      );
    });

    test('generated html does not override Monaco inputarea layout', () {
      final html = generateIndexHtml('min/vs');

      expect(html, isNot(contains('.monaco-editor .inputarea')));
      expect(html, isNot(contains('@media (pointer: coarse)')));
    });

    test('bridge includes tap-gated mobile gesture focus bridge', () {
      final html = allBridgeSources();

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

    test('bridge keeps desktop preventScroll focus retry', () {
      final html = allBridgeSources();

      expect(html, contains('if (isMobileInputPlatform())'));
      expect(html, contains('focusEditorTextAreaNow();'));
      expect(html, contains('forceFocus: (options = {}) =>'));
      expect(html, contains('const replayInputFocus ='));
      expect(
        html,
        contains(
          'if (!replayInputFocus && input && document.activeElement === input)',
        ),
      );
      expect(html, contains('ta.focus({ preventScroll: true });'));
    });

    test(
      'web html statically contains touch pans inside the editor document',
      () {
        final html = generateIndexHtml(
          'https://example.com/assets/monaco/min/vs',
          isWeb: true,
          messageToken: 'token',
        );

        expect(html, contains('touch-action: none;'));
        expect(html, contains('overscroll-behavior: none;'));
      },
    );

    test('web html references the visual viewport keyboard fit module', () {
      final webHtml = generateIndexHtml(
        'https://example.com/assets/monaco/min/vs',
        isWeb: true,
        messageToken: 'token',
      );
      expect(webHtml, contains('viewport-fit.js'));

      final html = bridgeSource('viewport-fit.js');
      expect(html, contains('__flutterMonacoViewportFitBound'));
      expect(html, contains('const applyViewportFit = () =>'));
      expect(html, contains('const scheduleViewportFit = () =>'));
      expect(html, contains('const clearViewportFit = () =>'));
      expect(html, contains('fitFrame.getBoundingClientRect()'));
      expect(html, contains('fitParent.visualViewport'));
      expect(html, contains("bindParentListener(fitViewport, 'resize'"));
      expect(html, contains("bindParentListener(fitViewport, 'scroll'"));
      expect(html, contains("bindParentListener(fitParent, 'resize'"));
      expect(html, contains('ed.revealPosition(pos)'));
    });

    test('viewport fit pins only while the visual viewport is constrained', () {
      final html = bridgeSource('viewport-fit.js');

      // The pin exists for keyboard/caret-pan states. Without this gate, an
      // editor half-scrolled off inside a scrollable Flutter page gets pinned
      // to the on-screen band and stops scrolling away with the page.
      expect(html, contains('const isViewportConstrained = () =>'));
      expect(html, contains('if (!isViewportConstrained())'));
      // Pinch zoom constrains the visual viewport too but must not pin.
      expect(html, contains('Math.abs(scale - 1)'));
    });

    test(
      'parent-side listeners are self-detaching and centrally detachable',
      () {
        final html = allBridgeSources();

        // Removing the iframe fires no pagehide, so raw addEventListener on a
        // parent object would root the dead document (and Monaco) in the host
        // page forever. Registration must go through bindParentListener, which
        // self-detaches once the frame leaves the parent DOM, and the Dart
        // controller detaches eagerly on dispose via the window hook.
        expect(html, contains('const bindParentListener ='));
        expect(html, contains('frame.isConnected'));
        expect(html, contains('window.__flutterMonacoDetachParentBindings'));
        expect(
          html,
          contains(
            "window.addEventListener('pagehide', "
            'window.__flutterMonacoDetachParentBindings',
          ),
        );
        // The keyboard-baseline listener on the parent viewport is one of the
        // registrations that must use the helper.
        expect(html, contains('ownerWindow.parent.visualViewport,'));
        // No raw registrations on parent objects may remain.
        expect(
          html,
          isNot(contains('parent.visualViewport?.addEventListener')),
        );
        expect(html, isNot(contains('fitViewport.addEventListener')));
        expect(html, isNot(contains('fitParent.addEventListener')));
      },
    );

    test('every inline script of every page flavor parses', () async {
      // A SyntaxError in an inline script silently disables everything that
      // script sets up - a raw newline inside a JS string literal did exactly
      // that to the Apple worker shim between 1.0.0 and 1.7.0.
      final pages = [
        generateIndexHtml('min/vs'),
        generateIndexHtml('min/vs', isIosOrMacOS: true),
        generateIndexHtml(r'file:///C:/monaco/min/vs', isWindows: true),
        generateIndexHtml(
          'https://flutter-monaco.example/monaco-0.57.0/min/vs',
          isWindows: true,
          bridgeBasePath: 'https://flutter-monaco.example/monaco-0.57.0/bridge',
        ),
        generateIndexHtml(
          'https://example.com/assets/monaco/min/vs',
          isWeb: true,
          messageToken: 'token',
        ),
      ];
      for (final html in pages) {
        expect(await jsSyntaxErrors(inlineScriptsIn(html)), isEmpty);
      }
    }, skip: nodeUnavailableReason);

    test('native html does not opt into web scroll containment', () {
      for (final html in [
        generateIndexHtml('min/vs'),
        generateIndexHtml('min/vs', isIosOrMacOS: true),
        generateIndexHtml(r'file:///C:/monaco/min/vs', isWindows: true),
      ]) {
        expect(html, isNot(contains('touch-action: none')));
        expect(html, isNot(contains('overscroll-behavior')));
        expect(html, isNot(contains('viewport-fit.js')));
      }
    });
  });
}
