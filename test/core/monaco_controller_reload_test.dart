import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

/// A page reload (the Flutter web engine re-inserted the iframe, a WebView
/// process recovered, or the page was refreshed) discards every page-side
/// object. The controller must converge back to a booted editor on its own:
/// re-dispatch `page.boot` with the original boot payload, re-register its
/// Dart-side completion providers and custom actions, and only then announce
/// the reload so applications can restore content they own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMicrotasks([int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('MonacoController page reload recovery', () {
    late FakePlatformWebViewController webview;
    late MonacoController controller;

    setUp(() async {
      webview = FakePlatformWebViewController();
      controller = await MonacoController.createForTesting(
        webViewController: webview,
        markReady: false,
        runBoot: true,
        bootOptions: const EditorOptions(
          language: MonacoLanguage.dart,
          fontSize: 13,
        ),
        bootInitialText: 'original text',
      );
      await controller.whenReady;
    });

    tearDown(() {
      controller.dispose();
    });

    test('boots through the real pipeline once before any reload', () {
      expect(webview.executionCount('page.boot'), 1);
      final boot = webview.dispatched.singleWhere(
        (call) => call['method'] == 'page.boot',
      );
      final params = boot['params']! as Map<String, Object?>;
      expect(params['text'], 'original text');
      expect(params['language'], 'dart');
    });

    test('re-dispatches page.boot with the original boot payload', () async {
      webview.emitReadyLifecycle();
      await pumpMicrotasks();

      expect(webview.executionCount('page.boot'), 2);
      final reboot = webview.dispatched
          .where((call) => call['method'] == 'page.boot')
          .last;
      final params = reboot['params']! as Map<String, Object?>;
      expect(params['text'], 'original text');
      expect(params['language'], 'dart');
      expect(controller.isReady, isTrue);
    });

    test(
      'onPageReloaded fires only after the editor is booted again',
      () async {
        var bootsAtEmit = -1;
        controller.onPageReloaded.listen((_) {
          bootsAtEmit = webview.executionCount('page.boot');
        });

        webview.emitReadyLifecycle();
        await pumpMicrotasks();

        expect(bootsAtEmit, 2);
      },
    );

    test('re-registers completion providers and custom actions', () async {
      var providerCalled = false;
      await controller.registerCompletions(
        id: 'my-completions',
        languages: [MonacoLanguage.dart],
        triggerCharacters: ['.'],
        provider: (_) async {
          providerCalled = true;
          return const CompletionList(suggestions: []);
        },
      );
      await controller.addAction(
        const MonacoActionDescriptor(
          id: MonacoAction('my.action'),
          label: 'My Action',
        ),
        () async {},
      );
      expect(webview.executionCount('completions.register'), 1);
      expect(webview.executionCount('actions.register'), 1);

      webview.emitReadyLifecycle();
      await pumpMicrotasks();

      expect(webview.executionCount('completions.register'), 2);
      expect(webview.executionCount('actions.register'), 2);

      // The replayed registration still routes to the Dart provider.
      webview.emitRequest('q1', 'completion', {
        'requestId': 'q1',
        'providerId': 'my-completions',
        'language': 'dart',
        'uri': null,
        'position': {'lineNumber': 1, 'column': 1},
        'defaultRange': {
          'startLineNumber': 1,
          'startColumn': 1,
          'endLineNumber': 1,
          'endColumn': 1,
        },
        'triggerKind': 0,
      });
      await pumpMicrotasks();
      expect(providerCalled, isTrue);
      expect(webview.responded, isNotEmpty);
      expect(webview.responded.last['id'], 'q1');
      expect(webview.responded.last['ok'], isTrue);
    });

    test(
      'a disposed completion registration is not replayed after reload',
      () async {
        final registration = await controller.registerCompletions(
          id: 'gone',
          languages: [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );
        await registration.dispose();

        webview.emitReadyLifecycle();
        await pumpMicrotasks();

        expect(webview.executionCount('completions.register'), 1);
      },
    );

    test('a reload during recovery converges to the newest page', () async {
      webview.emitReadyLifecycle();
      webview.emitReadyLifecycle();
      await pumpMicrotasks(16);

      // Both reloads re-boot (the second may interrupt the first); the
      // controller must end up ready with the last boot acknowledged.
      expect(webview.executionCount('page.boot'), greaterThanOrEqualTo(2));
      expect(controller.isReady, isTrue);
    });
  });

  group('MonacoController commands during page-reload recovery', () {
    late FakePlatformWebViewController webview;
    late MonacoController controller;

    setUp(() async {
      webview = FakePlatformWebViewController();
      controller = await MonacoController.createForTesting(
        webViewController: webview,
        markReady: false,
        runBoot: true,
        bootInitialText: 'boot text',
      );
      await controller.whenReady;
      // The reloaded page is driven by hand from here on.
      webview.autoRespond = false;
    });

    tearDown(() {
      controller.dispose();
    });

    /// The id of the last dispatch of [method].
    String lastIdOf(String method) =>
        webview.dispatched.lastWhere((call) => call['method'] == method)['id']!
            as String;

    test(
      'commands issued while the reloaded page has no editor are queued '
      'until the re-boot and replay finish, then run in FIFO order',
      () async {
        webview.autoRespond = true;
        await controller.registerCompletions(
          id: 'kept',
          languages: [MonacoLanguage.dart],
          provider: (_) async => const CompletionList(suggestions: []),
        );
        webview.autoRespond = false;

        webview.emitPageReady();
        await pumpMicrotasks();
        expect(webview.dispatchedMethods.last, 'page.boot');
        expect(controller.isReady, isFalse);

        // An autosave and a follow-up edit land while the page has no editor.
        final first = controller.document.getText();
        final second = controller.document.setText('after reload');
        await pumpMicrotasks();
        expect(
          webview.dispatchedMethods.where((m) => m.startsWith('document.')),
          isEmpty,
          reason:
              'editor commands are only registered once the re-boot '
              'reports ready',
        );

        webview.respondTo(lastIdOf('page.boot'));
        webview.emitLifecycle('ready');
        await pumpMicrotasks();
        List<String> afterBoot() => webview.dispatchedMethods.sublist(
          webview.dispatchedMethods.lastIndexOf('page.boot') + 1,
        );
        // The owned registration is replayed first; app commands still wait.
        expect(afterBoot(), ['completions.register']);
        expect(controller.isReady, isFalse);

        webview.respondTo(lastIdOf('completions.register'));
        await pumpMicrotasks();
        expect(afterBoot(), [
          'completions.register',
          'document.getText',
          'document.setText',
        ]);
        expect(controller.isReady, isTrue);

        webview.respondTo(lastIdOf('document.getText'), value: 'boot text');
        webview.respondTo(lastIdOf('document.setText'));
        expect(await first, 'boot text');
        await second;
      },
    );

    test('a failed recovery fails queued commands with '
        'MonacoPageReloadedError', () async {
      final reloadErrors = <Object>[];
      controller.onPageReloaded.listen((_) {}, onError: reloadErrors.add);

      webview.emitPageReady();
      await pumpMicrotasks();
      final queued = controller.document.getText();
      webview.respondTo(lastIdOf('page.boot'));
      webview.emitLifecycle(
        'fatal',
        error: {'name': 'Error', 'message': 'editor creation failed'},
      );

      await expectLater(queued, throwsA(isA<MonacoPageReloadedError>()));
      await pumpMicrotasks();
      expect(reloadErrors.single, isA<MonacoJavaScriptError>());
      expect(controller.isReady, isFalse);
      // Later commands fail the same way instead of reaching a page whose
      // editor never came back.
      await expectLater(
        controller.getSelection(),
        throwsA(isA<MonacoPageReloadedError>()),
      );
      expect(
        webview.dispatchedMethods.where(
          (m) => m.startsWith('document.') || m.startsWith('editor.'),
        ),
        isEmpty,
      );
    });

    test('a skewed reload that interrupts recovery fails queued commands '
        'instead of leaving them waiting', () async {
      webview.emitPageReady();
      await pumpMicrotasks();
      final queued = controller.document.getText();
      // The page reloads again, now speaking an incompatible protocol: the
      // in-flight re-boot fails and no new recovery can start.
      webview.emitToChannel(
        'flutterChannel',
        '{"v":3,"kind":"lifecycle","name":"pageReady","protocolVersion":2,'
            '"monacoVersion":"test","capabilities":[]}',
      );

      await expectLater(
        queued.timeout(const Duration(seconds: 2)),
        throwsA(isA<MonacoPageReloadedError>()),
      );
    });

    test('a later reload recovers a previously failed recovery', () async {
      webview.emitPageReady();
      await pumpMicrotasks();
      webview.respondTo(lastIdOf('page.boot'));
      webview.emitLifecycle('fatal', error: {'message': 'boom'});
      await pumpMicrotasks();
      expect(controller.isReady, isFalse);

      webview.autoRespond = true;
      webview.emitPageReady();
      await pumpMicrotasks();
      expect(controller.isReady, isTrue);
      await controller.document.setText('works again');
      expect(webview.dispatchedMethods.last, 'document.setText');
    });

    test('dispose during recovery fails queued commands with '
        'MonacoDisposedError', () async {
      webview.emitPageReady();
      await pumpMicrotasks();
      final queued = controller.document.getText();
      await pumpMicrotasks();

      controller.dispose();

      await expectLater(queued, throwsA(isA<MonacoDisposedError>()));
    });
  });

  group('MonacoController reload without a boot payload', () {
    test(
      'a synthetic double-ready on a markReady controller is inert',
      () async {
        final webview = FakePlatformWebViewController();
        final controller = await MonacoController.createForTesting(
          webViewController: webview,
        );
        final reloads = <void>[];
        controller.onPageReloaded.listen(reloads.add);

        // A second ready pair arrives without _startBoot ever having run
        // (nothing to replay): the controller must neither crash nor claim a
        // recovery it cannot perform.
        webview.emitReadyLifecycle();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(webview.executionCount('page.boot'), 0);
        expect(reloads, isEmpty);
        controller.dispose();
      },
    );
  });
}
