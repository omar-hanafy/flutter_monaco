import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes/fake_platform_webview_controller.dart';

Future<MonacoController> _controller(FakePlatformWebViewController webview) {
  return MonacoController.createForTesting(
    webViewController: webview,
    markReady: true,
  );
}

/// A WebView whose native focus handoff fails, like a platform channel
/// error on desktop.
class _NativeFocusFailingWebView extends FakePlatformWebViewController {
  @override
  Future<NativeFocusResult> requestNativeFocus() async {
    throw PlatformException(code: 'focus', message: 'no first responder');
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonacoFocusGuard', () {
    testWidgets('resumed triggers ensureEditorFocus', (tester) async {
      final webview = FakePlatformWebViewController();
      final controller = await _controller(webview);
      await tester.pumpWidget(
        _wrap(MonacoFocusGuard(controller: controller, ensureAttempts: 1)),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(webview.executed.join('\n').contains('focus.force'), true);
    });

    testWidgets('didPopNext triggers ensureEditorFocus', (tester) async {
      final webview = FakePlatformWebViewController();
      final controller = await _controller(webview);
      final observer = RouteObserver<PageRoute<dynamic>>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    MonacoFocusGuard(
                      controller: controller,
                      routeObserver: observer,
                      ensureAttempts: 1,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const Scaffold(body: Text('next')),
                          ),
                        );
                      },
                      child: const Text('push'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      webview.executed.clear();

      Navigator.of(tester.element(find.text('next'))).pop();
      await tester.pumpAndSettle();
      expect(webview.executed.join('\n').contains('focus.force'), true);
    });

    testWidgets('modal route toggles interaction', (tester) async {
      final webview = FakePlatformWebViewController();
      final controller = await _controller(webview);
      final observer = MonacoRouteObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    MonacoFocusGuard(
                      controller: controller,
                      modalRouteObserver: observer,
                      autoDisableInteraction: true,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => const Text('Dialog'),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initial state: interaction enabled
      expect(webview.interactionEnabled, true);

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog is open -> interaction disabled
      expect(webview.interactionEnabled, false);

      // Close dialog
      // Use navigator pop to be robust against hit test geometry
      Navigator.of(tester.element(find.text('Dialog'))).pop();
      await tester.pumpAndSettle();

      // Dialog closed -> interaction re-enabled
      expect(webview.interactionEnabled, true);
    });

    group('async focus failures', () {
      testWidgets('app resume after a failed boot does not leak an uncaught '
          'error', (tester) async {
        final controller = await MonacoController.createForTesting(
          webViewController: FakePlatformWebViewController(),
          markReady: false,
        );
        controller.failReadyForTesting(StateError('boot failed'));
        await tester.pumpWidget(
          _wrap(
            MonacoFocusGuard(
              controller: controller,
              autoDisableInteraction: false,
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('a route pop after a failed boot does not leak an uncaught '
          'error', (tester) async {
        final controller = await MonacoController.createForTesting(
          webViewController: FakePlatformWebViewController(),
          markReady: false,
        );
        controller.failReadyForTesting(StateError('boot failed'));
        final observer = MonacoRouteObserver();
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [observer],
            home: Scaffold(
              body: MonacoFocusGuard(
                controller: controller,
                modalRouteObserver: observer,
              ),
            ),
          ),
        );

        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Text('next')),
        );
        await tester.pumpAndSettle();
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('a focus failure on a ready editor is reported to onError', (
        tester,
      ) async {
        final webview = _NativeFocusFailingWebView();
        final controller = await _controller(webview);
        final errors = <Object>[];
        await tester.pumpWidget(
          _wrap(
            MonacoFocusGuard(
              controller: controller,
              ensureAttempts: 1,
              autoDisableInteraction: false,
              onError: (error, _) => errors.add(error),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();

        expect(errors, [isA<PlatformException>()]);
      });
    });

    group('interaction disable scope', () {
      Widget guardedEditor({
        required GlobalKey<NavigatorState> navigatorKey,
        required MonacoRouteObserver observer,
        required MonacoController controller,
        bool interactionEnabled = true,
      }) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          home: Scaffold(
            body: Column(
              children: [
                MonacoFocusGuard(
                  controller: controller,
                  modalRouteObserver: observer,
                  ensureAttempts: 1,
                ),
                Expanded(
                  child: MonacoEditor(
                    controller: controller,
                    interactionEnabled: interactionEnabled,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      testWidgets('a pop keeps interaction disabled when the app disabled it '
          'while the route was covered', (tester) async {
        final webview = FakePlatformWebViewController(
          widget: const SizedBox(key: Key('webview')),
        );
        final controller = await _controller(webview);
        final observer = MonacoRouteObserver();
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          guardedEditor(
            navigatorKey: navigatorKey,
            observer: observer,
            controller: controller,
          ),
        );
        await tester.pumpAndSettle();

        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Text('dialog')),
        );
        await tester.pumpAndSettle();
        expect(controller.isInteractionEnabled, isFalse);

        // The app locks the editor while the route is covered.
        await tester.pumpWidget(
          guardedEditor(
            navigatorKey: navigatorKey,
            observer: observer,
            controller: controller,
            interactionEnabled: false,
          ),
        );
        await tester.pump();
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();

        expect(controller.isInteractionEnabled, isFalse);
        expect(webview.interactionEnabled, isFalse);
      });

      testWidgets('swapping the controller while covered moves the disable '
          'scope to the new controller', (tester) async {
        final oldWebview = FakePlatformWebViewController();
        final oldController = await _controller(oldWebview);
        final newWebview = FakePlatformWebViewController();
        final newController = await _controller(newWebview);
        final observer = MonacoRouteObserver();
        final navigatorKey = GlobalKey<NavigatorState>();
        Widget app(MonacoController controller) => MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          home: Scaffold(
            body: MonacoFocusGuard(
              controller: controller,
              modalRouteObserver: observer,
              ensureAttempts: 1,
            ),
          ),
        );
        await tester.pumpWidget(app(oldController));

        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Text('dialog')),
        );
        await tester.pumpAndSettle();
        expect(oldController.isInteractionEnabled, isFalse);

        await tester.pumpWidget(app(newController));
        await tester.pump();
        expect(oldController.isInteractionEnabled, isTrue);
        expect(newController.isInteractionEnabled, isFalse);

        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
        expect(newController.isInteractionEnabled, isTrue);
        expect(oldController.isInteractionEnabled, isTrue);
      });

      testWidgets('disposing the guard while covered releases its scope', (
        tester,
      ) async {
        final webview = FakePlatformWebViewController();
        final controller = await _controller(webview);
        final observer = MonacoRouteObserver();
        final navigatorKey = GlobalKey<NavigatorState>();
        Widget app({required bool withGuard}) => MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          home: Scaffold(
            body: withGuard
                ? MonacoFocusGuard(
                    controller: controller,
                    modalRouteObserver: observer,
                  )
                : const SizedBox(),
          ),
        );
        await tester.pumpWidget(app(withGuard: true));
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Text('dialog')),
        );
        await tester.pumpAndSettle();
        expect(controller.isInteractionEnabled, isFalse);

        await tester.pumpWidget(app(withGuard: false));
        await tester.pump();

        expect(controller.isInteractionEnabled, isTrue);
      });
    });
  });
}
