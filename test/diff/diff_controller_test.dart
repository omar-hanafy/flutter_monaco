import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

Future<MonacoDiffController> _createController(
  FakePlatformWebViewController webview, {
  bool markReady = true,
}) {
  return MonacoDiffController.createForTesting(
    webViewController: webview,
    markReady: markReady,
  );
}

void main() {
  group('MonacoDiffController', () {
    test('whenReady completes and isReady flips', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.whenReady;
      expect(controller.isReady, isTrue);
    });

    test('setTexts dispatches diff.setTexts with language', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.setTexts(
        original: 'old',
        modified: 'new',
        language: MonacoLanguage.dart,
      );

      final call = webview.dispatched.singleWhere(
        (d) => d['method'] == 'diff.setTexts',
      );
      expect(call['params'], {
        'original': 'old',
        'modified': 'new',
        'language': 'dart',
      });
    });

    test('setTexts omits language when not given', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.setTexts(original: 'old', modified: 'new');

      final call = webview.dispatched.singleWhere(
        (d) => d['method'] == 'diff.setTexts',
      );
      expect(call['params'], {'original': 'old', 'modified': 'new'});
    });

    test('getModifiedText parses diff.getState', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      webview.injectCommandSuccess(
        'diff.getState',
        value: {
          'originalText': 'old',
          'modifiedText': 'new text',
          'lineChangeCount': 2,
          'language': 'dart',
        },
      );

      expect(await controller.getModifiedText(), 'new text');
    });

    test('getModifiedText throws MonacoProtocolError on bad shape', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      webview.injectCommandSuccess('diff.getState', value: {'nope': true});

      await expectLater(
        controller.getModifiedText(),
        throwsA(isA<MonacoProtocolError>()),
      );
    });

    test('getLineChangeCount parses diff.getState', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      webview.injectCommandSuccess(
        'diff.getState',
        value: {'modifiedText': 'x', 'lineChangeCount': 3},
      );

      expect(await controller.getLineChangeCount(), 3);
    });

    test(
      'getLineChangeCount treats an uncomputed diff as a timeout, not 0',
      () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        // The bridge reports lineChangeCount null when Monaco has not
        // computed the diff within the grace window; 0 is a real result.
        webview.injectCommandSuccess(
          'diff.getState',
          value: {'modifiedText': 'x', 'lineChangeCount': null},
        );

        await expectLater(
          controller.getLineChangeCount(),
          throwsA(isA<MonacoTimeoutError>()),
        );
      },
    );

    test(
      'getLineChangeCount throws MonacoProtocolError on bad shape',
      () async {
        final webview = FakePlatformWebViewController();
        final controller = await _createController(webview);

        webview.injectCommandSuccess('diff.getState', value: 'garbage');

        await expectLater(
          controller.getLineChangeCount(),
          throwsA(isA<MonacoProtocolError>()),
        );
      },
    );

    test('updateOptions sends sparse editor options', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.updateOptions(const EditorOptions(fontSize: 18));

      final call = webview.dispatched.singleWhere(
        (d) => d['method'] == 'diff.updateOptions',
      );
      expect(call['params'], {
        'options': {'fontSize': 18},
      });
    });

    test('updateDiffOptions sends sparse diff options', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.updateDiffOptions(
        const MonacoDiffOptions(
          renderSideBySide: false,
          ignoreTrimWhitespace: true,
        ),
      );

      final call = webview.dispatched.singleWhere(
        (d) => d['method'] == 'diff.updateOptions',
      );
      expect(call['params'], {
        'options': {'renderSideBySide': false, 'ignoreTrimWhitespace': true},
      });
    });

    test('MonacoDiffOptions.extra wins over typed fields', () {
      const options = MonacoDiffOptions(
        renderSideBySide: true,
        extra: {'renderSideBySide': false, 'custom': 1},
      );
      expect(options.toMonacoOptions(), {
        'renderSideBySide': false,
        'custom': 1,
      });
    });

    test('setTheme routes through diff.updateOptions', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.setTheme(MonacoTheme.hcBlack);

      final call = webview.dispatched.singleWhere(
        (d) => d['method'] == 'diff.updateOptions',
      );
      expect(call['params'], {
        'options': {'theme': 'hc-black'},
      });
    });

    test('reveal commands dispatch', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      await controller.revealNextChange();
      await controller.revealPreviousChange();

      expect(
        webview.dispatched.map((d) => d['method']),
        containsAll(['diff.revealNextChange', 'diff.revealPreviousChange']),
      );
    });

    test('commands queue until ready then flush in order', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview, markReady: false);

      final pending = controller.setTexts(original: 'a', modified: 'b');
      expect(
        webview.dispatched.where((d) => d['method'] == 'diff.setTexts'),
        isEmpty,
      );

      controller.completeReadyForTesting();
      await pending;

      expect(
        webview.dispatched.where((d) => d['method'] == 'diff.setTexts'),
        hasLength(1),
      );
    });

    test('dispose fails in-flight commands and releases the webview', () async {
      final webview = FakePlatformWebViewController();
      final controller = await _createController(webview);

      controller.dispose();
      controller.dispose(); // idempotent

      expect(webview.disposed, isTrue);
      await expectLater(
        controller.setTexts(original: 'a', modified: 'b'),
        throwsA(isA<MonacoException>()),
      );
    });

    group('failed boot gating', () {
      test(
        'a command issued after a failed boot rethrows the boot error',
        () async {
          final webview = FakePlatformWebViewController();
          final controller = await _createController(webview, markReady: false);
          final bootError = const MonacoTimeoutError(
            message: 'boot timed out',
            timeout: Duration(seconds: 1),
            operation: 'boot',
          );
          controller.failReadyForTesting(bootError);

          await expectLater(controller.whenReady, throwsA(same(bootError)));
          await expectLater(
            controller.setTexts(original: 'a', modified: 'b'),
            throwsA(same(bootError)),
          );
          expect(webview.dispatched, isEmpty);
        },
      );

      test(
        'a command after dispose-during-boot throws MonacoDisposedError',
        () async {
          final webview = FakePlatformWebViewController();
          final controller = await _createController(webview, markReady: false);
          controller.dispose();

          await expectLater(
            controller
                .setTexts(original: 'a', modified: 'b')
                .timeout(const Duration(seconds: 1)),
            throwsA(isA<MonacoDisposedError>()),
          );
        },
      );
    });
  });

  group('MonacoDiffController page-reload recovery', () {
    Future<void> pumpMicrotasks([int rounds = 8]) async {
      for (var i = 0; i < rounds; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    late FakePlatformWebViewController webview;
    late MonacoDiffController controller;

    setUp(() async {
      webview = FakePlatformWebViewController();
      controller = await MonacoDiffController.createForTesting(
        webViewController: webview,
        runBoot: true,
        bootOriginal: 'old',
        bootModified: 'new',
      );
      await controller.whenReady;
      webview.autoRespond = false;
    });

    tearDown(() => controller.dispose());

    String lastIdOf(String method) =>
        webview.dispatched.lastWhere((call) => call['method'] == method)['id']!
            as String;

    test('re-boots with the original payload', () async {
      webview.autoRespond = true;
      webview.emitReadyLifecycle();
      await pumpMicrotasks();

      final boots = webview.dispatched
          .where((call) => call['method'] == 'page.boot')
          .toList();
      expect(boots, hasLength(2));
      final params = boots.last['params']! as Map<String, Object?>;
      expect(params['mode'], 'diff');
      expect(params['original'], 'old');
      expect(params['modified'], 'new');
      expect(controller.isReady, isTrue);
    });

    test('commands issued while the reloaded page has no diff editor wait '
        'for the re-boot and run in FIFO order', () async {
      webview.emitPageReady();
      await pumpMicrotasks();
      expect(webview.dispatchedMethods.last, 'page.boot');
      expect(controller.isReady, isFalse);

      final first = controller.getModifiedText();
      final second = controller.setTexts(original: 'a', modified: 'b');
      await pumpMicrotasks();
      expect(webview.dispatchedMethods.last, 'page.boot');

      webview.respondTo(lastIdOf('page.boot'));
      webview.emitLifecycle('ready');
      await pumpMicrotasks();
      final afterBoot = webview.dispatchedMethods.sublist(
        webview.dispatchedMethods.lastIndexOf('page.boot') + 1,
      );
      expect(afterBoot, ['diff.getState', 'diff.setTexts']);
      expect(controller.isReady, isTrue);

      webview.respondTo(
        lastIdOf('diff.getState'),
        value: {'modifiedText': 'x'},
      );
      webview.respondTo(lastIdOf('diff.setTexts'));
      expect(await first, 'x');
      await second;
    });

    test('a failed recovery fails queued commands with '
        'MonacoPageReloadedError', () async {
      final reloadErrors = <Object>[];
      controller.onPageReloaded.listen((_) {}, onError: reloadErrors.add);

      webview.emitPageReady();
      await pumpMicrotasks();
      final queued = controller.getModifiedText();
      webview.respondTo(lastIdOf('page.boot'));
      webview.emitLifecycle('fatal', error: {'message': 'diff boot failed'});

      await expectLater(queued, throwsA(isA<MonacoPageReloadedError>()));
      await pumpMicrotasks();
      expect(reloadErrors.single, isA<MonacoJavaScriptError>());
      expect(controller.isReady, isFalse);
      expect(
        webview.dispatchedMethods.where((m) => m.startsWith('diff.')),
        // Nothing reached the page that has no diff editor.
        <String>[],
      );
    });

    test('dispose during recovery fails queued commands with '
        'MonacoDisposedError', () async {
      webview.emitPageReady();
      await pumpMicrotasks();
      final queued = controller.getModifiedText();
      await pumpMicrotasks();

      controller.dispose();

      await expectLater(queued, throwsA(isA<MonacoDisposedError>()));
    });
  });

  group('MonacoDiffController reload during the first boot', () {
    Future<void> pumpMicrotasks([int rounds = 8]) async {
      for (var i = 0; i < rounds; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('becomes ready once the re-booted page reports ready', () async {
      final webview = FakePlatformWebViewController()..autoRespond = false;
      final controller = await MonacoDiffController.createForTesting(
        webViewController: webview,
        runBoot: true,
        bootOriginal: 'old',
        bootModified: 'new',
      );
      addTearDown(controller.dispose);
      await pumpMicrotasks();
      expect(webview.dispatchedMethods, contains('page.boot'));

      // The page reloads before it answers the first page.boot.
      webview.emitPageReady();
      await pumpMicrotasks();
      final boots = webview.dispatched
          .where((call) => call['method'] == 'page.boot')
          .toList();
      expect(boots, hasLength(2));
      final params = boots.last['params']! as Map<String, Object?>;
      expect(params['original'], 'old');
      expect(params['modified'], 'new');
      webview.respondTo(boots.last['id']! as String);
      webview.emitLifecycle('ready');

      await controller.whenReady;
      await pumpMicrotasks();
      expect(controller.isReady, isTrue);

      webview.autoRespond = true;
      await controller.setTexts(original: 'a', modified: 'b');
      expect(webview.dispatchedMethods.last, 'diff.setTexts');
    });
  });

  testWidgets('MonacoDiffController fails queued commands when a re-boot '
      'misses the boot deadline', (tester) async {
    final webview = FakePlatformWebViewController();
    final controller = await MonacoDiffController.createForTesting(
      webViewController: webview,
      runBoot: true,
      readyTimeout: const Duration(seconds: 1),
    );
    await tester.pump();
    expect(controller.isReady, isTrue);

    webview.autoRespond = false;
    webview.emitPageReady();
    await tester.pump();
    final boot = webview.dispatched.lastWhere(
      (call) => call['method'] == 'page.boot',
    );
    webview.respondTo(boot['id']! as String);
    Object? queuedError;
    unawaited(
      controller.getModifiedText().then<void>(
        (_) {},
        onError: (Object e) {
          queuedError = e;
        },
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(queuedError, isA<MonacoPageReloadedError>());
    controller.dispose();
  });
}
