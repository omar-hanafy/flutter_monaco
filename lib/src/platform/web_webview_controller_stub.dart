// Stub file for non-web platforms
// This file is used when compiling for iOS, Android, macOS, Windows, Linux

import 'platform_webview_interface.dart';

/// Stub implementation that throws an error if accidentally used
class WebWebViewController implements PlatformWebViewController {
  WebWebViewController() {
    throw UnsupportedError(
      'WebWebViewController is only available on web platform',
    );
  }

  @override
  Future<Object?> runJavaScript(String script) {
    throw UnsupportedError('Not available on this platform');
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) {
    throw UnsupportedError('Not available on this platform');
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) {
    throw UnsupportedError('Not available on this platform');
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) {
    throw UnsupportedError('Not available on this platform');
  }

  @override
  void dispose() {}
}
