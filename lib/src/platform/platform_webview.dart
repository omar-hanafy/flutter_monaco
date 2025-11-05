import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

import 'platform_detector.dart' if (dart.library.html) 'platform_detector_stub.dart';
import 'platform_webview_interface.dart';
import 'web_webview_controller.dart' if (dart.library.io) 'web_webview_controller_stub.dart';

// Export the interface so consumers can use it
export 'platform_webview_interface.dart';

/// Flutter WebView implementation (for non-Windows platforms)
class FlutterWebViewController implements PlatformWebViewController {
  FlutterWebViewController() {
    _controller = wf.WebViewController();
  }

  late final wf.WebViewController _controller;
  bool _disposed = false;
  wf.WebViewController get flutterController => _controller;

  Future<Object?> setJavaScriptMode() async {
    await _controller.setJavaScriptMode(wf.JavaScriptMode.unrestricted);
    return null;
  }

  Future<Object?> setBackgroundColor(Color color) async {
    await _controller.setBackgroundColor(color);
    return null;
  }

  Future<Object?> loadFlutterAsset(String asset) async {
    await _controller.loadFlutterAsset(asset);
    return null;
  }

  Future<Object?> loadFile(String path) async {
    await _controller.loadFile(path);
    return null;
  }

  void setNavigationDelegate(wf.NavigationDelegate delegate) {
    _controller.setNavigationDelegate(delegate);
  }

  Future<void> setOnConsoleMessage(
    void Function(wf.JavaScriptConsoleMessage) onConsoleMessage,
  ) async {
    await _controller.setOnConsoleMessage(onConsoleMessage);
  }

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('[FlutterWebViewController] JS execution error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    try {
      return await _controller.runJavaScriptReturningResult(script);
    } catch (e) {
      debugPrint('[FlutterWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    await _controller.addJavaScriptChannel(
      name,
      onMessageReceived: (wf.JavaScriptMessage message) {
        onMessage(message.message);
      },
    );
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    await _controller.removeJavaScriptChannel(name);
    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // WebViewController doesn't have an explicit dispose method in webview_flutter
  }
}

/// Windows WebView implementation with better message handling
class WindowsWebViewController implements PlatformWebViewController {
  WindowsWebViewController() {
    _controller = ww.WebviewController();
  }

  late final ww.WebviewController _controller;
  final Map<String, void Function(String)> _channels = {};
  StreamSubscription<dynamic>? _webMessageSubscription;
  bool _isInitialized = false;
  bool _disposed = false;

  ww.WebviewController get windowsController => _controller;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[WindowsWebViewController] Initializing WebView2...');
    await _controller.initialize();
    _isInitialized = true;

    // Set up default configuration
    await _controller.setBackgroundColor(const Color(0xFF1E1E1E));
    await _controller.setPopupWindowPolicy(ww.WebviewPopupWindowPolicy.deny);

    // Set up message handler BEFORE adding any channels
    _setupWebMessageHandler();

    debugPrint('[WindowsWebViewController] WebView2 initialized successfully');
  }

  void _setupWebMessageHandler() {
    _webMessageSubscription?.cancel();

    _webMessageSubscription = _controller.webMessage.listen((
      dynamic rawMessage,
    ) {
      debugPrint(
        '[WindowsWebViewController] Raw message: $rawMessage (${rawMessage.runtimeType})',
      );

      try {
        String messageStr;

        if (rawMessage is String) {
          messageStr = rawMessage;
        } else if (rawMessage is Map) {
          messageStr = json.encode(rawMessage);
        } else {
          messageStr = rawMessage.toString();
        }

        _channels.forEach((channelName, handler) {
          debugPrint(
            '[WindowsWebViewController] Forwarding to channel: $channelName',
          );
          handler(messageStr);
        });
      } catch (e) {
        debugPrint('[WindowsWebViewController] Error handling message: $e');
      }
    });
  }

  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    debugPrint(
      '[WindowsWebViewController] Loading HTML string (length: ${html.length})',
    );
    await _controller.loadStringContent(html);
  }

  Future<void> loadUrl(String url) async {
    debugPrint('[WindowsWebViewController] Loading URL: $url');
    await _controller.loadUrl(url);
  }

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      return await _controller.executeScript(script);
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS execution error: $e');
      rethrow;
    }
  }

  @override
  Future<dynamic> runJavaScriptReturningResult(String script) async {
    try {
      final result = await _controller.executeScript(script);

      if (result == null) return null;

      if (result is String) {
        try {
          if (result.startsWith('"') &&
              result.endsWith('"') &&
              result.length > 2) {
            return result.substring(1, result.length - 1);
          }
          if (result.startsWith('{') || result.startsWith('[')) {
            return json.decode(result);
          }
        } catch (_) {
          // If parsing fails, return as is
        }
      }

      return result;
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    debugPrint(
        '[WindowsWebViewController] Registering handler for channel: $name');

    // Store the handler - HTML already defines window.flutterChannel
    _channels[name] = onMessage;

    // No need to inject JavaScript - the HTML already has the channel defined
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
    return null; // No-op in JS; HTML owns flutterChannel
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[WindowsWebViewController] Disposing...');
    _webMessageSubscription?.cancel();
    _channels.clear();
    if (_isInitialized) {
      _controller.dispose();
    }
  }
}

/// Factory for creating platform-specific controllers
class PlatformWebViewFactory {
  static PlatformWebViewController createController() {
    if (kIsWeb) {
      return WebWebViewController();
    } else if (PlatformDetector.isWindows) {
      return WindowsWebViewController();
    } else {
      return FlutterWebViewController();
    }
  }
}
