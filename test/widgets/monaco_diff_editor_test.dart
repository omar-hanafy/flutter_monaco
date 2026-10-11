import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes/fake_platform_webview_controller.dart';

class _TestBundle {
  _TestBundle(this.controller, this.webview);

  final MonacoDiffController controller;
  final FakePlatformWebViewController webview;
}

Future<_TestBundle> _createBundle({bool ready = true}) async {
  final webview = FakePlatformWebViewController(
    widget: const SizedBox(key: Key('diff-webview')),
  );
  final controller = await MonacoDiffController.createForTesting(
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

  group('MonacoDiffEditor widget', () {
    testWidgets('shows loading while controller not ready', (tester) async {
      final bundle = await _createBundle(ready: false);
      await tester.pumpWidget(
        _wrap(MonacoDiffEditor(controller: bundle.controller)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('transitions to ready, applies config, and fires onReady', (
      tester,
    ) async {
      final bundle = await _createBundle();
      MonacoDiffController? readyController;

      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controllerFactory: () async => bundle.controller,
            original: 'old',
            modified: 'new',
            language: MonacoLanguage.dart,
            diffOptions: const MonacoDiffOptions(renderSideBySide: true),
            onReady: (c) => readyController = c,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('diff-webview')), findsOneWidget);
      expect(readyController, same(bundle.controller));

      // The factory path applies texts/options post-readiness.
      final setTexts = bundle.webview.dispatched.singleWhere(
        (d) => d['method'] == 'diff.setTexts',
      );
      expect(setTexts['params'], {
        'original': 'old',
        'modified': 'new',
        'language': 'dart',
      });
      final optionUpdates = bundle.webview.dispatched
          .where((d) => d['method'] == 'diff.updateOptions')
          .toList();
      expect(optionUpdates, isNotEmpty);
    });

    testWidgets('boot failure renders the default error surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controllerFactory: () async => throw StateError('diff boot failed'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Failed to Initialize Editor'), findsOneWidget);
      expect(find.textContaining('diff boot failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('changing texts dispatches diff.setTexts', (tester) async {
      final bundle = await _createBundle();
      Future<MonacoDiffController> factory() async => bundle.controller;

      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controllerFactory: factory,
            original: 'one',
            modified: 'two',
          ),
        ),
      );
      await tester.pump();
      final before = bundle.webview.dispatched
          .where((d) => d['method'] == 'diff.setTexts')
          .length;

      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controllerFactory: factory,
            original: 'one',
            modified: 'three',
          ),
        ),
      );
      await tester.pump();

      final calls = bundle.webview.dispatched
          .where((d) => d['method'] == 'diff.setTexts')
          .toList();
      expect(calls, hasLength(before + 1));
      expect(
        (calls.last['params']! as Map<String, Object?>)['modified'],
        'three',
      );
    });

    testWidgets('changing diffOptions dispatches diff.updateOptions', (
      tester,
    ) async {
      final bundle = await _createBundle();
      Future<MonacoDiffController> factory() async => bundle.controller;

      await tester.pumpWidget(
        _wrap(MonacoDiffEditor(controllerFactory: factory)),
      );
      await tester.pump();
      final before = bundle.webview.dispatched
          .where((d) => d['method'] == 'diff.updateOptions')
          .length;

      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controllerFactory: factory,
            diffOptions: const MonacoDiffOptions(renderSideBySide: false),
          ),
        ),
      );
      await tester.pump();

      final calls = bundle.webview.dispatched
          .where((d) => d['method'] == 'diff.updateOptions')
          .toList();
      expect(calls.length, greaterThan(before));
      expect(calls.last['params'], {
        'options': {'renderSideBySide': false},
      });
    });

    testWidgets('external controller is not disposed with the widget', (
      tester,
    ) async {
      final bundle = await _createBundle();

      await tester.pumpWidget(
        _wrap(MonacoDiffEditor(controller: bundle.controller)),
      );
      await tester.pump();
      await tester.pumpWidget(_wrap(const SizedBox()));

      expect(bundle.webview.disposed, isFalse);
      bundle.controller.dispose();
      expect(bundle.webview.disposed, isTrue);
    });

    testWidgets('a throwing onReady does not destroy a healthy diff editor', (
      tester,
    ) async {
      final bundle = await _createBundle();
      final reported = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = oldHandler);

      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controller: bundle.controller,
            onReady: (_) => throw StateError('app bug in diff onReady'),
            errorBuilder: (context, error, st) => const Text('DIFF-ERROR-UI'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIFF-ERROR-UI'), findsNothing);
      expect(find.byKey(const Key('diff-webview')), findsOneWidget);
      expect(
        reported.map((d) => d.exception.toString()).join(),
        contains('app bug in diff onReady'),
      );
    });

    testWidgets('an owned controller is disposed on boot failure', (
      tester,
    ) async {
      final bundle = await _createBundle(ready: false);

      await tester.pumpWidget(
        _wrap(
          MonacoDiffEditor(
            controllerFactory: () async => bundle.controller,
            errorBuilder: (context, error, st) => const Text('BOOT-FAILED'),
          ),
        ),
      );
      await tester.pump();

      bundle.controller.failReadyForTesting(
        const MonacoTimeoutError(
          message: 'boot timed out',
          timeout: Duration(seconds: 1),
          operation: 'boot',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BOOT-FAILED'), findsOneWidget);
      // The single editor disposes its failed owned controller immediately;
      // the diff editor must not leak its WebView until retry/dispose.
      expect(bundle.webview.disposed, isTrue);
    });
  });
}
