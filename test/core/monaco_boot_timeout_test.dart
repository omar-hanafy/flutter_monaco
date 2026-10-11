import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_webview_controller.dart';

/// A sandboxed macOS app without the outgoing network connections
/// entitlement never loads the editor page: WKWebView only logs an empty
/// error and the boot runs into its deadline. The timeout must say so.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const timeout = Duration(seconds: 1);

  /// A page that never reports in, like a WKWebView the sandbox blocked.
  FakePlatformWebViewController silentPage() =>
      FakePlatformWebViewController()..emitPageReadyOnLoad = false;

  Matcher bootTimeout({required bool namesEntitlement}) {
    final entitlement = allOf(
      contains('com.apple.security.network.client'),
      contains('Outgoing Connections (Client)'),
    );
    return isA<MonacoTimeoutError>()
        .having((e) => e.operation, 'operation', 'boot')
        .having((e) => e.timeout, 'timeout', timeout)
        .having(
          (e) => e.message,
          'message',
          allOf(
            contains('did not report ready in 1 seconds.'),
            namesEntitlement ? entitlement : isNot(contains('entitlement')),
          ),
        );
  }

  for (final (platform, namesEntitlement) in [
    (TargetPlatform.macOS, true),
    (TargetPlatform.android, false),
  ]) {
    testWidgets('editor boot timeout on ${platform.name} '
        '${namesEntitlement ? 'names' : 'does not name'} the macOS network '
        'entitlement', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final controller = await MonacoController.createForTesting(
          webViewController: silentPage(),
          runBoot: true,
          readyTimeout: timeout,
        );
        final ready = expectLater(
          controller.whenReady,
          throwsA(bootTimeout(namesEntitlement: namesEntitlement)),
        );
        await tester.pump(const Duration(seconds: 2));
        await ready;
        controller.dispose();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('diff editor boot timeout on ${platform.name} '
        '${namesEntitlement ? 'names' : 'does not name'} the macOS network '
        'entitlement', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final controller = await MonacoDiffController.createForTesting(
          webViewController: silentPage(),
          runBoot: true,
          readyTimeout: timeout,
        );
        final ready = expectLater(
          controller.whenReady,
          throwsA(bootTimeout(namesEntitlement: namesEntitlement)),
        );
        await tester.pump(const Duration(seconds: 2));
        await ready;
        controller.dispose();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
