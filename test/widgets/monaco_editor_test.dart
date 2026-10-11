import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes/fake_platform_webview_controller.dart';

/// A WebView whose native focus handoff fails, like a platform channel
/// error on desktop.
class _NativeFocusFailingWebView extends FakePlatformWebViewController {
  _NativeFocusFailingWebView()
    : super(widget: const SizedBox(key: Key('webview')));

  @override
  Future<NativeFocusResult> requestNativeFocus() async {
    throw PlatformException(code: 'focus', message: 'no first responder');
  }
}

class _TestBundle {
  _TestBundle(this.controller, this.webview);

  final MonacoController controller;
  final FakePlatformWebViewController webview;
}

Future<_TestBundle> _createBundle({bool ready = true}) async {
  final webview = FakePlatformWebViewController(
    widget: const SizedBox(key: Key('webview')),
  );
  final controller = await MonacoController.createForTesting(
    webViewController: webview,
    markReady: ready,
  );
  return _TestBundle(controller, webview);
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonacoEditor widget', () {
    group('initialization states', () {
      testWidgets('shows loading while controller not ready', (tester) async {
        final bundle = await _createBundle(ready: false);
        await tester.pumpWidget(
          _wrap(MonacoEditor(controller: bundle.controller)),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('custom loadingBuilder is used', (tester) async {
        final bundle = await _createBundle(ready: false);
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              loadingBuilder: (context) => const Text('Custom Loading'),
            ),
          ),
        );
        expect(find.text('Custom Loading'), findsOneWidget);
      });

      testWidgets('transitions to ready state and fires onReady', (
        tester,
      ) async {
        final bundle = await _createBundle(ready: false);
        MonacoController? receivedController;
        var readyCount = 0;

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onReady: (c) {
                receivedController = c;
                readyCount++;
              },
            ),
          ),
        );

        bundle.controller.completeReadyForTesting();
        await tester.pump();

        expect(find.byKey(const Key('webview')), findsOneWidget);
        expect(readyCount, 1);
        expect(receivedController, bundle.controller);
      });

      testWidgets('error state shows error and retry only when owned', (
        tester,
      ) async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'document.setText',
          message: 'boom',
        );

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialText: 'trigger error',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Failed to Initialize Editor'), findsOneWidget);
        expect(find.text('Retry'), findsNothing); // Not owned
      });

      testWidgets('owned controller disposed when bootstrap fails', (
        tester,
      ) async {
        FakePlatformWebViewController? failingWebview;

        Future<MonacoController> factory() async {
          failingWebview = FakePlatformWebViewController(
            widget: const SizedBox(key: Key('webview')),
          );
          failingWebview!.injectCommandFailure(
            'document.setText',
            message: 'boom',
          );
          return MonacoController.createForTesting(
            webViewController: failingWebview!,
            markReady: true,
          );
        }

        await tester.pumpWidget(
          _wrap(MonacoEditor(controllerFactory: factory, initialText: 'boom')),
        );
        await tester.pump();

        expect(find.text('Failed to Initialize Editor'), findsOneWidget);
        expect(failingWebview, isNotNull);
        expect(failingWebview!.disposed, true);
      });

      testWidgets('error state shows retry when widget owns controller', (
        tester,
      ) async {
        var factoryCalls = 0;
        Future<MonacoController> factory() async {
          factoryCalls++;
          if (factoryCalls == 1) {
            throw StateError('Initialization failed');
          }
          final webview = FakePlatformWebViewController(
            widget: const SizedBox(key: Key('webview')),
          );
          return MonacoController.createForTesting(
            webViewController: webview,
            markReady: true,
          );
        }

        await tester.pumpWidget(
          _wrap(MonacoEditor(controllerFactory: factory)),
        );
        await tester.pump();

        expect(find.text('Failed to Initialize Editor'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('webview')), findsOneWidget);
        expect(factoryCalls, 2);
      });

      testWidgets('custom errorBuilder is used', (tester) async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'document.setText',
          message: 'boom',
        );

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialText: 'trigger',
              errorBuilder: (context, error, st) =>
                  Text('Custom Error: $error'),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Custom Error'), findsOneWidget);
      });
    });

    group('initial values', () {
      testWidgets('initialText applied once', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialText: 'initial content',
            ),
          ),
        );
        await tester.pump();

        final setTextCalls = bundle.webview.dispatched
            .where((d) => d['method'] == 'document.setText')
            .toList();
        expect(setTextCalls.length, 1);
        expect(
          (setTextCalls.single['params']! as Map)['text'],
          'initial content',
        );

        // Update widget with different initialText
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialText: 'new content',
            ),
          ),
        );
        await tester.pump();

        // Should NOT set the new value (initialText is applied only once)
        expect(
          bundle.webview.dispatched
              .where((d) => d['method'] == 'document.setText')
              .length,
          1,
          reason: 'initialText must only be applied during initial bootstrap',
        );
      });

      testWidgets('initialSelection applied after initialText', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialText: 'content',
              initialSelection: const Range(
                startLine: 1,
                startColumn: 1,
                endLine: 1,
                endColumn: 5,
              ),
            ),
          ),
        );
        await tester.pump();

        final methods = bundle.webview.dispatched
            .map((d) => d['method'])
            .toList();
        final valueIndex = methods.indexOf('document.setText');
        final selIndex = methods.indexOf('editor.setSelection');

        expect(valueIndex, greaterThanOrEqualTo(0));
        expect(selIndex, greaterThan(valueIndex));
      });
    });

    group('options updates', () {
      testWidgets('options change triggers updateOptions/theme/language', (
        tester,
      ) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              options: const EditorOptions(
                language: MonacoLanguage.dart,
                theme: MonacoTheme.vsDark,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.clearExecuted();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              options: const EditorOptions(
                language: MonacoLanguage.python,
                theme: MonacoTheme.vs,
                fontSize: 16,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.assertExecuted('editor.updateOptions');
        bundle.webview.assertExecuted('editor.setTheme');
        bundle.webview.assertExecuted('document.setLanguage');
      });

      testWidgets('same options do not trigger updates', (tester) async {
        final bundle = await _createBundle();
        const options = EditorOptions(
          language: MonacoLanguage.dart,
          theme: MonacoTheme.vsDark,
        );

        await tester.pumpWidget(
          _wrap(MonacoEditor(controller: bundle.controller, options: options)),
        );
        await tester.pumpAndSettle();

        bundle.webview.clearExecuted();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              options: options, // Same options
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.assertNotExecuted('editor.updateOptions');
      });
    });

    group('autofocus', () {
      testWidgets('autofocus triggers ensureEditorFocus on desktop', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller, autofocus: true)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          bundle.webview.assertExecuted('focus.force');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('autofocus skips programmatic focus on mobile', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller, autofocus: true)),
          );
          await tester.pumpAndSettle();

          bundle.webview.assertNotExecuted('focus.force');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('autofocus false does not trigger focus', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(MonacoEditor(controller: bundle.controller, autofocus: false)),
        );
        await tester.pumpAndSettle();

        bundle.webview.assertNotExecuted('focus.force');
      });
    });

    group('mobile input wrapper policy', () {
      final monacoFocusWrapper = find.byWidgetPredicate(
        (widget) =>
            widget is Focus &&
            widget.focusNode?.debugLabel == 'MonacoWebViewFocus',
      );
      final monacoPointerWrapper = find.byWidgetPredicate(
        (widget) =>
            widget is Listener &&
            widget.behavior == HitTestBehavior.translucent,
      );

      testWidgets('mobile renders bare webview without focus wrappers', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller)),
          );
          await tester.pumpAndSettle();

          final webview = find.byKey(const Key('webview'));
          expect(webview, findsOneWidget);
          expect(
            find.ancestor(of: webview, matching: monacoFocusWrapper),
            findsNothing,
          );
          expect(
            find.ancestor(of: webview, matching: monacoPointerWrapper),
            findsNothing,
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('desktop keeps focus wrappers', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller)),
          );
          await tester.pumpAndSettle();

          final webview = find.byKey(const Key('webview'));
          expect(webview, findsOneWidget);
          expect(
            find.ancestor(of: webview, matching: monacoFocusWrapper),
            findsOneWidget,
          );
          expect(
            find.ancestor(of: webview, matching: monacoPointerWrapper),
            findsOneWidget,
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('desktop primary mouse down requests editor focus', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller)),
          );
          await tester.pumpAndSettle();
          bundle.webview.executed.clear();

          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          );
          await gesture.down(
            tester.getCenter(find.byKey(const Key('webview'))),
          );
          await tester.pumpAndSettle();
          await gesture.up();

          expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
          bundle.webview.assertExecuted('focus.force');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('desktop secondary mouse down does not force editor focus', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller)),
          );
          await tester.pumpAndSettle();
          bundle.webview.executed.clear();

          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.down(
            tester.getCenter(find.byKey(const Key('webview'))),
          );
          await tester.pumpAndSettle();
          await gesture.up();

          expect(
            bundle.webview.executed,
            isNot(contains('REQUEST_NATIVE_FOCUS')),
          );
          bundle.webview.assertNotExecuted('focus.force');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets(
        'macOS repeated primary mouse down re-verifies native focus, and '
        'replays input readiness only without a native handoff',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          try {
            final bundle = await _createBundle();
            await tester.pumpWidget(
              _wrap(MonacoEditor(controller: bundle.controller)),
            );
            await tester.pumpAndSettle();

            final target = tester.getCenter(find.byKey(const Key('webview')));
            final first = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            );
            await first.down(target);
            await tester.pumpAndSettle();
            await first.up();
            // Monaco reports the editor focused after the first click, but on
            // macOS that cached DOM focus is not proof of native input
            // readiness, so every primary click still routes a user intent.
            bundle.webview.emitEvent('focusChanged', {'focused': true});
            await tester.pump();

            // Without the native plugin (fake default: unsupported), the
            // click falls back to the full input-focus replay.
            bundle.webview.executed.clear();
            final second = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            );
            await second.down(target);
            await tester.pumpAndSettle();
            await second.up();

            expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
            bundle.webview.assertExecuted('focus.force');
            bundle.webview.assertExecuted('"replayInputFocus":true');

            // With a working native handoff, the same click verifies first
            // responder state and must NOT replay (no caret double-blink).
            bundle.webview.nativeFocusResult = NativeFocusResult.alreadyOwned;
            bundle.webview.executed.clear();
            final third = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            );
            await third.down(target);
            await tester.pumpAndSettle();
            await third.up();

            expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
            bundle.webview.assertExecuted('"replayInputFocus":false');
            bundle.webview.assertNotExecuted('"replayInputFocus":true');
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );

      testWidgets('Windows repeated primary mouse down does not refocus', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        try {
          final bundle = await _createBundle();
          await tester.pumpWidget(
            _wrap(MonacoEditor(controller: bundle.controller)),
          );
          await tester.pumpAndSettle();

          final target = tester.getCenter(find.byKey(const Key('webview')));
          final first = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          );
          await first.down(target);
          await tester.pumpAndSettle();
          await first.up();
          // Monaco reports the editor focused after the first click; Windows
          // must not replay focus because WebView2 focus replay flickers the
          // caret and can tear down the context menu.
          bundle.webview.emitEvent('focusChanged', {'focused': true});
          await tester.pump();

          bundle.webview.executed.clear();
          final second = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          );
          await second.down(target);
          await tester.pumpAndSettle();
          await second.up();

          expect(
            bundle.webview.executed,
            isNot(contains('REQUEST_NATIVE_FOCUS')),
          );
          bundle.webview.assertNotExecuted('focus.force');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets(
        'desktop click re-asserts focus after Monaco blurs (alt-tab/dialog '
        'desync)',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          try {
            final bundle = await _createBundle();
            await tester.pumpWidget(
              _wrap(MonacoEditor(controller: bundle.controller)),
            );
            await tester.pumpAndSettle();

            final target = tester.getCenter(find.byKey(const Key('webview')));
            // First click focuses; Monaco then reports focused.
            final first = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            );
            await first.down(target);
            await tester.pumpAndSettle();
            await first.up();
            bundle.webview.emitEvent('focusChanged', {'focused': true});
            await tester.pump();

            // The editor silently loses native focus (alt-tab / dialog): Monaco
            // reports a blur while Flutter still thinks the view is focused.
            bundle.webview.emitEvent('focusChanged', {'focused': false});
            await tester.pump();
            bundle.webview.executed.clear();

            // A click must now re-assert focus so typing recovers.
            final second = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: kPrimaryMouseButton,
            );
            await second.down(target);
            await tester.pumpAndSettle();
            await second.up();

            expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
            bundle.webview.assertExecuted('focus.force');
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    });

    group('content change callbacks', () {
      testWidgets('onContentChanged debounces non-flush events', (
        tester,
      ) async {
        final bundle = await _createBundle();
        final calls = <String>[];
        bundle.webview.injectCommandSuccess('document.getText', value: 'A');
        bundle.webview.injectCommandSuccess('document.getText', value: 'B');

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              contentDebounce: const Duration(milliseconds: 30),
              onContentChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': false});
        bundle.webview.emitEvent('contentChanged', {'isFlush': false});

        // Before debounce completes
        await tester.pump(const Duration(milliseconds: 10));
        expect(calls.length, 0);

        // After debounce
        await tester.pump(const Duration(milliseconds: 40));
        expect(calls.length, 1);
      });

      testWidgets('flush event bypasses debounce', (tester) async {
        final bundle = await _createBundle();
        final calls = <String>[];
        bundle.webview.injectCommandSuccess(
          'document.getText',
          value: 'flushed',
        );

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              contentDebounce: const Duration(milliseconds: 200),
              onContentChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();

        expect(calls.length, 1);
        expect(calls.first, 'flushed');
      });

      testWidgets('fullTextOnFlushOnly blocks non-flush updates', (
        tester,
      ) async {
        final bundle = await _createBundle();
        final calls = <String>[];
        bundle.webview.injectCommandSuccess(
          'document.getText',
          value: 'content',
        );

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              fullTextOnFlushOnly: true,
              onContentChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': false});
        await tester.pump(const Duration(milliseconds: 200));
        expect(calls.length, 0);

        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();
        expect(calls.length, 1);
      });

      testWidgets('onRawContentChanged receives flush flag', (tester) async {
        final bundle = await _createBundle();
        final flags = <bool>[];

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onRawContentChanged: flags.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': false});
        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();

        expect(flags, [false, true]);
      });

      testWidgets('rewires listener when callback changes', (tester) async {
        final bundle = await _createBundle();
        final calls1 = <String>[];
        final calls2 = <String>[];
        bundle.webview.injectCommandSuccess('document.getText', value: 'v1');
        bundle.webview.injectCommandSuccess('document.getText', value: 'v2');

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              contentDebounce: Duration.zero,
              onContentChanged: calls1.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();
        expect(calls1.length, 1);

        // Change callback
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              contentDebounce: Duration.zero,
              onContentChanged: calls2.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();

        expect(calls1.length, 1); // Original not called again
        expect(calls2.length, 1); // New callback called
      });
    });

    testWidgets('an autofocus failure is reported to onError', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final webview = _NativeFocusFailingWebView();
        final controller = await MonacoController.createForTesting(
          webViewController: webview,
        );
        final errors = <Object>[];
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: controller,
              autofocus: true,
              onError: (e, _) => errors.add(e),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(errors, [isA<PlatformException>()]);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    group('callbacks changed after readiness', () {
      testWidgets('onSelectionChanged supplied after bootstrap fires', (
        tester,
      ) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(MonacoEditor(controller: bundle.controller)),
        );
        await tester.pumpAndSettle();

        final selections = <Range?>[];
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onSelectionChanged: selections.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        bundle.webview.emitEvent('selectionChanged', {
          'selection': {
            'startLineNumber': 1,
            'startColumn': 1,
            'endLineNumber': 1,
            'endColumn': 2,
          },
        });
        await tester.pump();

        expect(selections, hasLength(1));
      });

      testWidgets('clearing onContentChanged with a debounce pending reports '
          'no error and emits nothing', (tester) async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandSuccess('document.getText', value: 'abc');
        final errors = <Object>[];
        final calls = <String>[];
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onContentChanged: calls.add,
              onError: (e, _) => errors.add(e),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('contentChanged', {'isFlush': false});
        await tester.pump();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onError: (e, _) => errors.add(e),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        expect(errors, isEmpty);
        expect(calls, isEmpty);
      });

      testWidgets('clearing onContentChanged while a pull is in flight '
          'reports no error', (tester) async {
        final bundle = await _createBundle();
        final errors = <Object>[];
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onContentChanged: (_) {},
              onError: (e, _) => errors.add(e),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Hold the text pull in flight.
        bundle.webview.autoRespond = false;

        bundle.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();
        final pull = bundle.webview.dispatched.lastWhere(
          (d) => d['method'] == 'document.getText',
        );
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onError: (e, _) => errors.add(e),
            ),
          ),
        );
        bundle.webview.respondTo(pull['id']! as String, value: 'abc');
        await tester.pump();
        await tester.pump();

        expect(errors, isEmpty);
      });
    });

    group('other callbacks', () {
      testWidgets('selection/focus/blur callbacks wired', (tester) async {
        final bundle = await _createBundle();
        var selectionCount = 0;
        var focusCount = 0;
        var blurCount = 0;

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onSelectionChanged: (_) => selectionCount++,
              onFocus: () => focusCount++,
              onBlur: () => blurCount++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('selectionChanged', {
          'selection': {
            'startLineNumber': 1,
            'startColumn': 1,
            'endLineNumber': 1,
            'endColumn': 2,
          },
        });
        bundle.webview.emitEvent('focusChanged', {'focused': true});
        bundle.webview.emitEvent('focusChanged', {'focused': false});
        await tester.pump();

        expect(selectionCount, 1);
        expect(focusCount, 1);
        expect(blurCount, 1);
      });

      testWidgets('onLiveStats receives updates', (tester) async {
        final bundle = await _createBundle();
        final stats = <MonacoLiveStats>[];

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(controller: bundle.controller, onLiveStats: stats.add),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('stats', {'lineCount': 10, 'charCount': 50});
        await tester.pump();

        expect(stats.length, 1);
        expect(stats.first.lineCount, 10);
      });
    });

    group('status bar', () {
      testWidgets('status bar renders stats', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(controller: bundle.controller, showStatusBar: true),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('stats', {
          'lineCount': 25,
          'charCount': 100,
          'cursorLine': 5,
          'cursorColumn': 10,
        });
        // One pump delivers the protocol event, the next renders the update.
        await tester.pump();
        await tester.pump();

        expect(find.text('Ln 5, Col 10'), findsOneWidget);
        expect(find.text('Ch 100'), findsOneWidget);
      });

      testWidgets('custom statusBarBuilder used', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              statusBarBuilder: (context, stats) =>
                  Text('Lines: ${stats.lineCount}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('stats', {'lineCount': 42});
        // One pump delivers the protocol event, the next renders the update.
        await tester.pump();
        await tester.pump();

        expect(find.text('Lines: 42'), findsOneWidget);
      });

      testWidgets('MonacoEditorTheme customizes default status bar', (
        tester,
      ) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditorTheme(
              data: const MonacoEditorThemeData(
                statusBarBackgroundColor: Colors.black,
                statusBarBorderColor: Colors.red,
                statusBarTextStyle: TextStyle(color: Colors.green),
                statusBarSpacing: 8,
              ),
              child: MonacoEditor(
                controller: bundle.controller,
                showStatusBar: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitEvent('stats', {
          'lineCount': 42,
          'cursorLine': 2,
          'cursorColumn': 3,
        });
        // One pump delivers the protocol event, the next renders the update.
        await tester.pump();
        await tester.pump();

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MonacoEditor),
                matching: find.byType(Container),
              )
              .last,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, Colors.black);
        expect(find.text('Ln 2, Col 3'), findsOneWidget);
      });

      testWidgets('status bar hidden when showStatusBar false', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(controller: bundle.controller, showStatusBar: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ln'), findsNothing);
        expect(find.text('Ch'), findsNothing);
      });
    });

    group('controller swapping', () {
      testWidgets('swapping controllers rewires listeners', (tester) async {
        final bundleA = await _createBundle();
        final bundleB = await _createBundle();
        final calls = <String>[];
        bundleA.webview.injectCommandSuccess('document.getText', value: 'A');
        bundleB.webview.injectCommandSuccess('document.getText', value: 'B');

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundleA.controller,
              contentDebounce: Duration.zero,
              onContentChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundleB.controller,
              contentDebounce: Duration.zero,
              onContentChanged: calls.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Old controller event should not trigger callback
        bundleA.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();
        expect(calls.length, 0);

        // New controller event should trigger
        bundleB.webview.emitEvent('contentChanged', {'isFlush': true});
        await tester.pump();
        expect(calls.length, 1);
        expect(calls.first, 'B');
      });
    });

    group('page config handling', () {
      testWidgets('page change does not rebuild when not owned', (
        tester,
      ) async {
        final bundle = await _createBundle();
        var readyCount = 0;

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onReady: (_) => readyCount++,
            ),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onReady: (_) => readyCount++,
              page: const MonacoPageConfig(
                customCss: 'body { background: red; }',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(readyCount, 1); // Not rebuilt
      });

      testWidgets('page change rebuilds when owned', (tester) async {
        var factoryCalls = 0;
        final webviews = <FakePlatformWebViewController>[];

        Future<MonacoController> factory() async {
          factoryCalls++;
          final webview = FakePlatformWebViewController(
            widget: const SizedBox(key: Key('webview')),
          );
          webviews.add(webview);
          return MonacoController.createForTesting(
            webViewController: webview,
            markReady: true,
          );
        }

        await tester.pumpWidget(
          _wrap(MonacoEditor(controllerFactory: factory)),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              page: const MonacoPageConfig(
                customCss: 'body { background: red; }',
              ),
            ),
          ),
        );
        await tester.pump();

        expect(factoryCalls, 2);
        expect(webviews.first.disposed, true);
      });

      testWidgets('stale bootstrap ignores late readiness', (tester) async {
        final controllers = <MonacoController>[];
        var readyCount = 0;
        var callIndex = 0;

        Future<MonacoController> factory() async {
          callIndex++;
          final ready = callIndex > 1;
          final webview = FakePlatformWebViewController(
            widget: SizedBox(key: Key('webview_$callIndex')),
          );
          final controller = await MonacoController.createForTesting(
            webViewController: webview,
            markReady: ready,
          );
          controllers.add(controller);
          return controller;
        }

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              onReady: (_) => readyCount++,
            ),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              page: const MonacoPageConfig(
                customCss: 'body { background: red; }',
              ),
              onReady: (_) => readyCount++,
            ),
          ),
        );
        await tester.pump();

        expect(controllers.length, 2);
        expect(readyCount, 1);

        controllers.first.completeReadyForTesting();
        await tester.pump();

        expect(readyCount, 1);
      });
    });

    group('disposal', () {
      testWidgets('dispose cancels debounce timers', (tester) async {
        final bundle = await _createBundle();
        final calls = <String>[];
        bundle.webview.injectCommandSuccess('document.getText', value: 'A');

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              contentDebounce: const Duration(milliseconds: 100),
              onContentChanged: calls.add,
            ),
          ),
        );
        await tester.pump();

        bundle.webview.emitEvent('contentChanged', {'isFlush': false});

        // Dispose before debounce completes
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 200));

        expect(calls.length, 0); // Timer cancelled
      });

      testWidgets('owned controller disposed on unmount', (tester) async {
        final webviews = <FakePlatformWebViewController>[];

        Future<MonacoController> factory() async {
          final webview = FakePlatformWebViewController(
            widget: const SizedBox(key: Key('webview')),
          );
          webviews.add(webview);
          return MonacoController.createForTesting(
            webViewController: webview,
            markReady: true,
          );
        }

        await tester.pumpWidget(
          _wrap(MonacoEditor(controllerFactory: factory)),
        );
        await tester.pump();

        expect(webviews.length, 1);
        expect(webviews.first.disposed, false);

        await tester.pumpWidget(const SizedBox.shrink());

        expect(webviews.first.disposed, true);
      });

      testWidgets('external controller not disposed on unmount', (
        tester,
      ) async {
        final bundle = await _createBundle();

        await tester.pumpWidget(
          _wrap(MonacoEditor(controller: bundle.controller)),
        );
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());

        expect(bundle.webview.disposed, false);
      });
    });

    group('styling', () {
      testWidgets('backgroundColor applies both native and host-page layers', (
        tester,
      ) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              backgroundColor: Colors.red,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byKey(const Key('webview')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container.color, Colors.red);

        // Native WebView API was invoked.
        expect(
          bundle.webview.executed.any(
            (s) => s.startsWith('SET_BACKGROUND_COLOR'),
          ),
          true,
          reason: 'setBackgroundColor must hit the native WebView container',
        );

        // Host page recolor was invoked through the protocol dispatch.
        expect(
          bundle.webview.scriptsContaining('page.setBackground').isNotEmpty,
          true,
          reason:
              'backgroundColor should also recolor Monaco\'s HTML host page',
        );
      });

      testWidgets(
        'host-page background failure does not break initialization',
        (tester) async {
          final bundle = await _createBundle();
          bundle.webview.injectCommandFailure(
            'page.setBackground',
            message: 'host page recolor failed',
          );

          await tester.pumpWidget(
            _wrap(
              MonacoEditor(
                controller: bundle.controller,
                backgroundColor: Colors.red,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Native layer succeeds; HTML host-page failure is best-effort.
          expect(find.byKey(const Key('webview')), findsOneWidget);
          expect(find.text('Failed to Initialize Editor'), findsNothing);
        },
      );

      testWidgets('native background failure does not break initialization', (
        tester,
      ) async {
        final bundle = await _createBundle();
        bundle.webview.setBackgroundColorError = StateError(
          'Simulated macOS native background failure',
        );

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              backgroundColor: Colors.red,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Native failure is best-effort; HTML host-page recolor still runs.
        expect(find.byKey(const Key('webview')), findsOneWidget);
        expect(find.text('Failed to Initialize Editor'), findsNothing);
      });

      testWidgets('padding applied', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              padding: const EdgeInsets.all(16),
            ),
          ),
        );
        await tester.pump();

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byKey(const Key('webview')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container.padding, const EdgeInsets.all(16));
      });

      testWidgets('constraints applied', (tester) async {
        final bundle = await _createBundle();
        const constraints = BoxConstraints(maxHeight: 300);

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              constraints: constraints,
            ),
          ),
        );
        await tester.pump();

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byKey(const Key('webview')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(container.constraints, constraints);
      });
    });

    group('interaction', () {
      testWidgets('interactionEnabled applied before ready', (tester) async {
        final bundle = await _createBundle(ready: false);

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              interactionEnabled: false,
            ),
          ),
        );
        await tester.pump();

        expect(bundle.webview.interactionEnabled, false);
        expect(
          bundle.webview.executed.any((s) => s == 'SET_INTERACTION:false'),
          true,
        );
      });

      testWidgets('interactionEnabled updates while connecting', (
        tester,
      ) async {
        final bundle = await _createBundle(ready: false);

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              interactionEnabled: false,
            ),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              interactionEnabled: true,
            ),
          ),
        );
        await tester.pump();

        final joined = bundle.webview.executed.join('\n');
        expect(joined.contains('SET_INTERACTION:false'), true);
        expect(joined.contains('SET_INTERACTION:true'), true);
      });
    });

    group('default chrome theming', () {
      testWidgets('MonacoEditorTheme customizes loading UI', (tester) async {
        final bundle = await _createBundle(ready: false);
        await tester.pumpWidget(
          _wrap(
            MonacoEditorTheme(
              data: const MonacoEditorThemeData(
                loadingIndicatorColor: Colors.orange,
                loadingBackgroundColor: Colors.black,
              ),
              child: MonacoEditor(controller: bundle.controller),
            ),
          ),
        );

        final progress = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(progress.color, Colors.orange);
      });

      testWidgets('MonacoEditorTheme customizes default error UI', (
        tester,
      ) async {
        final bundle = await _createBundle();
        bundle.webview.injectCommandFailure(
          'document.setText',
          message: 'fail',
        );

        await tester.pumpWidget(
          _wrap(
            MonacoEditorTheme(
              data: const MonacoEditorThemeData(errorIconColor: Colors.purple),
              child: MonacoEditor(
                controller: bundle.controller,
                initialText: 'trigger',
              ),
            ),
          ),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(icon.color, Colors.purple);
      });

      testWidgets('MonacoEditorTheme composes nested overrides', (
        tester,
      ) async {
        MonacoEditorThemeData? resolvedTheme;

        await tester.pumpWidget(
          MaterialApp(
            home: MonacoEditorTheme(
              data: const MonacoEditorThemeData(
                loadingIndicatorColor: Colors.orange,
                errorIconColor: Colors.purple,
              ),
              child: MonacoEditorTheme(
                data: const MonacoEditorThemeData(
                  statusBarBackgroundColor: Colors.black,
                ),
                child: Builder(
                  builder: (context) {
                    resolvedTheme = MonacoEditorTheme.of(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        expect(resolvedTheme, isNotNull);
        expect(resolvedTheme!.loadingIndicatorColor, Colors.orange);
        expect(resolvedTheme!.errorIconColor, Colors.purple);
        expect(resolvedTheme!.statusBarBackgroundColor, Colors.black);
      });

      testWidgets(
        'MonacoEditorTheme propagates into dialog routes via captureAll',
        (tester) async {
          final bundle = await _createBundle();
          MonacoEditorThemeData? capturedTheme;

          await tester.pumpWidget(
            MaterialApp(
              home: MonacoEditorTheme(
                data: const MonacoEditorThemeData(
                  loadingIndicatorColor: Colors.cyan,
                  statusBarBackgroundColor: Colors.black,
                ),
                child: Builder(
                  builder: (context) {
                    return Scaffold(
                      body: Column(
                        children: [
                          Expanded(
                            child: MonacoEditor(controller: bundle.controller),
                          ),
                          ElevatedButton(
                            key: const Key('openDialog'),
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) => Builder(
                                  builder: (innerContext) {
                                    capturedTheme = MonacoEditorTheme.of(
                                      innerContext,
                                    );
                                    return const SizedBox.shrink();
                                  },
                                ),
                              );
                            },
                            child: const Text('open'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('openDialog')));
          await tester.pumpAndSettle();

          // showDialog uses InheritedTheme.captureAll, which invokes our
          // MonacoEditorTheme.wrap to carry the data across the dialog route.
          expect(capturedTheme, isNotNull);
          expect(capturedTheme!.loadingIndicatorColor, Colors.cyan);
          expect(capturedTheme!.statusBarBackgroundColor, Colors.black);
        },
      );
    });
    group('ambient theme (D27)', () {
      List<Object?> themeDispatches(FakePlatformWebViewController webview) {
        return webview.dispatched
            .where((d) => d['method'] == 'editor.setTheme')
            .map((d) => (d['params']! as Map<String, Object?>)['theme'])
            .toList();
      }

      Widget wrapWithBrightness(Brightness brightness, Widget child) {
        return MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: child),
        );
      }

      testWidgets('null theme follows ambient brightness changes', (
        tester,
      ) async {
        final bundle = await _createBundle();
        Future<MonacoController> factory() async => bundle.controller;

        await tester.pumpWidget(
          wrapWithBrightness(
            Brightness.light,
            MonacoEditor(controllerFactory: factory),
          ),
        );
        await tester.pumpAndSettle();
        expect(themeDispatches(bundle.webview).last, 'vs');

        await tester.pumpWidget(
          wrapWithBrightness(
            Brightness.dark,
            MonacoEditor(controllerFactory: factory),
          ),
        );
        await tester.pumpAndSettle();
        expect(themeDispatches(bundle.webview).last, 'vs-dark');

        // Same brightness again: deduped, no extra bridge traffic.
        final dispatchCount = themeDispatches(bundle.webview).length;
        await tester.pumpWidget(
          wrapWithBrightness(
            Brightness.dark,
            MonacoEditor(controllerFactory: factory),
          ),
        );
        await tester.pumpAndSettle();
        expect(themeDispatches(bundle.webview).length, dispatchCount);
      });

      testWidgets('explicit theme never reacts to brightness', (tester) async {
        final bundle = await _createBundle();
        Future<MonacoController> factory() async => bundle.controller;
        const options = EditorOptions(theme: MonacoTheme.vsDark);

        await tester.pumpWidget(
          wrapWithBrightness(
            Brightness.light,
            MonacoEditor(controllerFactory: factory, options: options),
          ),
        );
        await tester.pumpAndSettle();
        expect(themeDispatches(bundle.webview).last, 'vs-dark');
        final dispatchCount = themeDispatches(bundle.webview).length;

        await tester.pumpWidget(
          wrapWithBrightness(
            Brightness.dark,
            MonacoEditor(controllerFactory: factory, options: options),
          ),
        );
        await tester.pumpAndSettle();
        expect(themeDispatches(bundle.webview).length, dispatchCount);
      });
    });

    group('boot-error isolation (onReady)', () {
      testWidgets('a throwing onReady does not destroy a healthy editor', (
        tester,
      ) async {
        final bundle = await _createBundle();
        final reported = <FlutterErrorDetails>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = reported.add;
        addTearDown(() => FlutterError.onError = oldHandler);

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onReady: (_) => throw StateError('app bug in onReady'),
              errorBuilder: (context, error, st) => const Text('ERROR-UI'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The editor stays alive and ready; the app bug is reported through
        // FlutterError instead of tearing the editor down.
        expect(find.text('ERROR-UI'), findsNothing);
        expect(find.byKey(const Key('webview')), findsOneWidget);
        expect(
          reported.map((d) => d.exception.toString()).join(),
          contains('app bug in onReady'),
        );
      });
    });

    group('boot-time desired-state reconciliation', () {
      testWidgets('options changed during boot are applied before ready', (
        tester,
      ) async {
        final bundle = await _createBundle(ready: false);
        Future<MonacoController> factory() async => bundle.controller;

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              options: const EditorOptions(fontSize: 14),
            ),
          ),
        );
        await tester.pump();

        // Hold the post-ready apply open so the widget rebuild lands while
        // the bootstrap is still in flight (didUpdateWidget drops it).
        bundle.webview.autoRespond = false;
        bundle.controller.completeReadyForTesting();
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              options: const EditorOptions(fontSize: 22),
            ),
          ),
        );

        // Answer every pending dispatch until the bootstrap settles.
        var answered = 0;
        var idle = 0;
        while (idle < 5) {
          if (answered < bundle.webview.dispatched.length) {
            final call = bundle.webview.dispatched[answered++];
            bundle.webview.emitToChannel(
              'flutterChannel',
              jsonEncode({
                'v': 3,
                'kind': 'response',
                'id': call['id'],
                'ok': true,
                'undefined': true,
                'value': null,
              }),
            );
            idle = 0;
          } else {
            idle++;
          }
          await tester.pump();
        }

        final optionUpdates = bundle.webview.dispatched
            .where((d) => d['method'] == 'editor.updateOptions')
            .map((d) => (d['params']! as Map)['options']! as Map)
            .toList();
        expect(
          optionUpdates.any((o) => o['fontSize'] == 22),
          isTrue,
          reason:
              'the fontSize set during boot must be reconciled before ready; '
              'saw: $optionUpdates',
        );
      });
    });

    group('background color reset', () {
      testWidgets('clearing backgroundColor restores the resolved default', (
        tester,
      ) async {
        final bundle = await _createBundle();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              backgroundColor: const Color(0xFFFF0000),
            ),
          ),
        );
        await tester.pumpAndSettle();
        bundle.webview.dispatched.clear();

        await tester.pumpWidget(
          _wrap(MonacoEditor(controller: bundle.controller)),
        );
        await tester.pumpAndSettle();

        final backgroundCalls = bundle.webview.dispatched
            .where((d) => d['method'] == 'page.setBackground')
            .map((d) => (d['params']! as Map)['color'].toString())
            .toList();
        expect(
          backgroundCalls,
          isNotEmpty,
          reason:
              'null backgroundColor must restore the default, '
              'not keep the stale red',
        );
        expect(backgroundCalls.last, contains('rgba(255, 255, 255'));
      });
    });

    group('content pulls across controller swaps', () {
      testWidgets('a stale pull from a replaced controller never emits', (
        tester,
      ) async {
        final bundleA = await _createBundle();
        final bundleB = await _createBundle();
        final received = <String>[];

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundleA.controller,
              contentDebounce: Duration.zero,
              onContentChanged: received.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Block controller A's getText pull, then trigger it.
        bundleA.webview.autoRespond = false;
        bundleA.webview.emitToChannel(
          'flutterChannel',
          jsonEncode({
            'v': 3,
            'kind': 'event',
            'seq': 1,
            'name': 'contentChanged',
            'data': {
              'uri': null,
              'isFlush': false,
              'truncated': false,
              'changes': <Object?>[],
            },
          }),
        );
        await tester.pump(Duration.zero);
        await tester.pump();

        final pull = bundleA.webview.dispatched.lastWhere(
          (d) => d['method'] == 'document.getText',
        );

        // Swap to controller B while A's pull is still in flight.
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundleB.controller,
              contentDebounce: Duration.zero,
              onContentChanged: received.add,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // A's pull now completes with stale text.
        bundleA.webview.emitToChannel(
          'flutterChannel',
          jsonEncode({
            'v': 3,
            'kind': 'response',
            'id': pull['id'],
            'ok': true,
            'undefined': false,
            'value': 'stale text from A',
          }),
        );
        await tester.pumpAndSettle();

        expect(received, isNot(contains('stale text from A')));
      });
    });
  });
}
