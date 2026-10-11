import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/blob_url_spy.dart';

/// Runs on Chrome only (`flutter test --platform chrome`): the web
/// controller hosts Monaco in an iframe that only loads once its platform
/// view attaches. Disposing while load() waits for that must end the load
/// at once, without creating blob URLs nobody revokes.
void main() {
  test('dispose while load() waits for the iframe to attach ends the load '
      'promptly without creating blob URLs', () async {
    final blobUrlsCreated = spyOnCreateObjectUrl();
    final webView = PlatformWebViewFactory.createController();
    await webView.initialize();
    await webView.addJavaScriptChannel('flutterChannel', (_) {});

    // The platform view is never mounted, so the iframe stays detached.
    final load = webView.load();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    webView.dispose();

    await expectLater(
      load.timeout(const Duration(milliseconds: 500)),
      throwsA(isA<MonacoDisposedError>()),
    );
    // Give a would-be retry attempt time to run, then check for leaks.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(blobUrlsCreated(), 0);
  }, skip: !kIsWeb);
}
