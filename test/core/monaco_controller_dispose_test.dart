import 'dart:async';

import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

/// A WebView whose page load never finishes, like the web iframe that waits
/// for its platform view to attach.
class _HangingLoadWebView extends FakePlatformWebViewController {
  final Completer<void> loadGate = Completer<void>();

  @override
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()}) =>
      loadGate.future;
}

/// Far below the 20s boot deadline: disposal must settle pending work
/// immediately, not when the boot finally times out.
const _prompt = Duration(milliseconds: 500);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonacoController dispose before ready', () {
    test('settles whenReady with MonacoDisposedError while the page load '
        'is still pending', () async {
      final webview = _HangingLoadWebView();
      final controller = await MonacoController.createForTesting(
        webViewController: webview,
        markReady: false,
        runBoot: true,
      );

      controller.dispose();

      await expectLater(
        controller.whenReady.timeout(_prompt),
        throwsA(isA<MonacoDisposedError>()),
      );
      expect(controller.isReady, isFalse);
    });

    test(
      'fails commands queued before readiness with MonacoDisposedError',
      () async {
        final webview = _HangingLoadWebView();
        final controller = await MonacoController.createForTesting(
          webViewController: webview,
          markReady: false,
          runBoot: true,
        );
        final queued = [
          expectLater(
            controller.document.getText().timeout(_prompt),
            throwsA(isA<MonacoDisposedError>()),
          ),
          expectLater(
            controller.requestFocus().timeout(_prompt),
            throwsA(isA<MonacoDisposedError>()),
          ),
        ];

        controller.dispose();

        await Future.wait(queued);
        expect(
          webview.dispatchedMethods.where((m) => m != 'lsp.disconnectAll'),
          isEmpty,
        );
      },
    );

    test(
      'settles whenReady on a controller that never started booting',
      () async {
        final controller = await MonacoController.createForTesting(
          webViewController: FakePlatformWebViewController(),
          markReady: false,
        );

        controller.dispose();

        await expectLater(
          controller.whenReady.timeout(_prompt),
          throwsA(isA<MonacoDisposedError>()),
        );
      },
    );

    test(
      'a finished load after dispose does not resurrect readiness',
      () async {
        final webview = _HangingLoadWebView();
        final controller = await MonacoController.createForTesting(
          webViewController: webview,
          markReady: false,
          runBoot: true,
        );
        controller.dispose();
        webview.loadGate.complete();
        await Future<void>.delayed(Duration.zero);

        expect(controller.isReady, isFalse);
        await expectLater(
          controller.whenReady,
          throwsA(isA<MonacoDisposedError>()),
        );
      },
    );
  });

  group('MonacoDiffController dispose before ready', () {
    test('settles whenReady and queued commands with MonacoDisposedError '
        'while the page load is still pending', () async {
      final webview = _HangingLoadWebView();
      final controller = await MonacoDiffController.createForTesting(
        webViewController: webview,
        runBoot: true,
      );
      final queued = expectLater(
        controller.getModifiedText().timeout(_prompt),
        throwsA(isA<MonacoDisposedError>()),
      );

      controller.dispose();

      await expectLater(
        controller.whenReady.timeout(_prompt),
        throwsA(isA<MonacoDisposedError>()),
      );
      await queued;
      expect(controller.isReady, isFalse);
      expect(webview.dispatched, isEmpty);
    });
  });
}
