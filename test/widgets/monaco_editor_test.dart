import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

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
        bundle.webview.throwOnContains('setValue');

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialValue: 'trigger error',
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
          failingWebview!.throwOnContains('setValue');
          return MonacoController.createForTesting(
            webViewController: failingWebview!,
            markReady: true,
          );
        }

        await tester.pumpWidget(
          _wrap(MonacoEditor(controllerFactory: factory, initialValue: 'boom')),
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
        bundle.webview.throwOnContains('setValue');

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialValue: 'trigger',
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
      testWidgets('initialValue applied once', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialValue: 'initial content',
            ),
          ),
        );
        await tester.pump();

        final setValueScripts = bundle.webview.scriptsContaining('"setValue"');
        expect(setValueScripts.length, 1);
        expect(setValueScripts.first, contains('"initial content"'));

        // Update widget with different initialValue
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialValue: 'new content',
            ),
          ),
        );
        await tester.pump();

        // Should NOT set the new value (initialValue is applied only once)
        expect(
          bundle.webview.scriptsContaining('"setValue"').length,
          1,
          reason: 'initialValue must only be applied during initial bootstrap',
        );
      });

      testWidgets('initialSelection applied after initialValue', (
        tester,
      ) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              initialValue: 'content',
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

        final scripts = bundle.webview.executed;
        final valueIndex = scripts.indexWhere((s) => s.contains('setValue'));
        final selIndex = scripts.indexWhere((s) => s.contains('setSelection'));

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

        bundle.webview.assertExecuted('updateOptions');
        bundle.webview.assertExecuted('setTheme');
        bundle.webview.assertExecuted('setLanguage');
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

        bundle.webview.assertNotExecuted('updateOptions');
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

          bundle.webview.assertExecuted('forceFocus');
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

          bundle.webview.assertNotExecuted('forceFocus');
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

        bundle.webview.assertNotExecuted('forceFocus');
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
          bundle.webview.assertExecuted('forceFocus');
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
          bundle.webview.assertNotExecuted('forceFocus');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('macOS repeated primary mouse down replays input readiness', (
        tester,
      ) async {
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
          // macOS that cached DOM focus is not proof of native input readiness.
          bundle.webview.emitToChannel('flutterChannel', '{"event":"focus"}');
          await tester.pump();

          bundle.webview.executed.clear();
          final second = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          );
          await second.down(target);
          await tester.pumpAndSettle();
          await second.up();

          expect(bundle.webview.executed, contains('REQUEST_NATIVE_FOCUS'));
          bundle.webview.assertExecuted(
            'forceFocus({ replayInputFocus: true })',
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

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
          bundle.webview.emitToChannel('flutterChannel', '{"event":"focus"}');
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
          bundle.webview.assertNotExecuted('forceFocus');
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
            bundle.webview.emitToChannel('flutterChannel', '{"event":"focus"}');
            await tester.pump();

            // The editor silently loses native focus (alt-tab / dialog): Monaco
            // reports a blur while Flutter still thinks the view is focused.
            bundle.webview.emitToChannel('flutterChannel', '{"event":"blur"}');
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
            bundle.webview.assertExecuted('forceFocus');
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
        bundle.webview.injectCommandSuccess('getValue', value: 'A');
        bundle.webview.injectCommandSuccess('getValue', value: 'B');

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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":false}',
        );
        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":false}',
        );

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
        bundle.webview.injectCommandSuccess('getValue', value: 'flushed');

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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
        await tester.pump();

        expect(calls.length, 1);
        expect(calls.first, 'flushed');
      });

      testWidgets('fullTextOnFlushOnly blocks non-flush updates', (
        tester,
      ) async {
        final bundle = await _createBundle();
        final calls = <String>[];
        bundle.webview.injectCommandSuccess('getValue', value: 'content');

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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":false}',
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(calls.length, 0);

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":false}',
        );
        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
        await tester.pump();

        expect(flags, [false, true]);
      });

      testWidgets('rewires listener when callback changes', (tester) async {
        final bundle = await _createBundle();
        final calls1 = <String>[];
        final calls2 = <String>[];
        bundle.webview.injectCommandSuccess('getValue', value: 'v1');
        bundle.webview.injectCommandSuccess('getValue', value: 'v2');

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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
        await tester.pump();

        expect(calls1.length, 1); // Original not called again
        expect(calls2.length, 1); // New callback called
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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"selectionChanged","selection":{"startLineNumber":1,"startColumn":1,"endLineNumber":1,"endColumn":2}}',
        );
        bundle.webview.emitToChannel('flutterChannel', '{"event":"focus"}');
        bundle.webview.emitToChannel('flutterChannel', '{"event":"blur"}');
        await tester.pump();

        expect(selectionCount, 1);
        expect(focusCount, 1);
        expect(blurCount, 1);
      });

      testWidgets('onLiveStats receives updates', (tester) async {
        final bundle = await _createBundle();
        final stats = <LiveStats>[];

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(controller: bundle.controller, onLiveStats: stats.add),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"stats","lineCount":10,"charCount":50}',
        );
        await tester.pump();

        expect(stats.length, 1);
        expect(stats.first.lineCount.value, 10);
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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"stats","lineCount":25,"charCount":100,"cursorLine":5,"cursorColumn":10}',
        );
        await tester.pump();

        expect(find.text('Ln 5:10'), findsOneWidget);
        expect(find.text('Ch 100'), findsOneWidget);
      });

      testWidgets('custom statusBarBuilder used', (tester) async {
        final bundle = await _createBundle();
        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              statusBarBuilder: (context, stats) =>
                  Text('Lines: ${stats.lineCount.value}'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"stats","lineCount":42}',
        );
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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"stats","lineCount":42,"cursorLine":2,"cursorColumn":3}',
        );
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
        expect(find.text('Ln 2:3'), findsOneWidget);
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
        bundleA.webview.injectCommandSuccess('getValue', value: 'A');
        bundleB.webview.injectCommandSuccess('getValue', value: 'B');

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
        bundleA.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
        await tester.pump();
        expect(calls.length, 0);

        // New controller event should trigger
        bundleB.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":true}',
        );
        await tester.pump();
        expect(calls.length, 1);
        expect(calls.first, 'B');
      });
    });

    group('customCss handling', () {
      testWidgets('customCss change does not rebuild when not owned', (
        tester,
      ) async {
        final bundle = await _createBundle();
        var readyCount = 0;

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onReady: (_) => readyCount++,
              customCss: null,
            ),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controller: bundle.controller,
              onReady: (_) => readyCount++,
              customCss: 'body { background: red; }',
            ),
          ),
        );
        await tester.pump();

        expect(readyCount, 1); // Not rebuilt
      });

      testWidgets('customCss change rebuilds when owned', (tester) async {
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
          _wrap(MonacoEditor(controllerFactory: factory, customCss: null)),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              customCss: 'body { background: red; }',
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
              customCss: null,
              onReady: (_) => readyCount++,
            ),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _wrap(
            MonacoEditor(
              controllerFactory: factory,
              customCss: 'body { background: red; }',
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
        bundle.webview.injectCommandSuccess('getValue', value: 'A');

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

        bundle.webview.emitToChannel(
          'flutterChannel',
          '{"event":"contentChanged","isFlush":false}',
        );

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

        // Host page recolor was invoked through the bridge envelope.
        expect(
          bundle.webview
              .scriptsContaining('"setHostPageBackground"')
              .isNotEmpty,
          true,
          reason:
              'backgroundColor should also recolor Monaco\'s HTML host page',
        );
      });

      testWidgets(
        'host-page background failure does not break initialization',
        (tester) async {
          final bundle = await _createBundle();
          bundle.webview.throwOnContains('"setHostPageBackground"');

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
        bundle.webview.injectCommandFailure('setValue', message: 'fail');

        await tester.pumpWidget(
          _wrap(
            MonacoEditorTheme(
              data: const MonacoEditorThemeData(errorIconColor: Colors.purple),
              child: MonacoEditor(
                controller: bundle.controller,
                initialValue: 'trigger',
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
  });
}
