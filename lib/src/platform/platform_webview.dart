/// @docImport 'package:flutter_monaco/src/editor/controller.dart';
/// @docImport 'package:flutter_monaco/src/platform/webview_native.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/src/common/monaco_page_config.dart';
import 'package:flutter_monaco/src/platform/webview_stub.dart'
    if (dart.library.io) 'package:flutter_monaco/src/platform/webview_native.dart'
    if (dart.library.js_interop) 'package:flutter_monaco/src/platform/webview_web.dart'
    as base;

/// Outcome of a [PlatformWebViewController.requestNativeFocus] handoff.
///
/// Native focus means the OS-level keyboard routing target: the Win32 focus
/// HWND on Windows, or the NSWindow first responder on macOS. It is layer 2
/// of the three-layer focus model (Flutter focus, native focus, DOM focus)
/// and the only layer Flutter cannot observe or drive by itself on desktop
/// platform views.
enum NativeFocusResult {
  /// Native keyboard focus was handed to the WebView by this call.
  granted,

  /// The WebView already owned native keyboard focus; nothing changed.
  alreadyOwned,

  /// The platform (or the current embedding) has no native focus handoff.
  ///
  /// Android, iOS, and Web return this: their WebViews participate in the
  /// regular platform focus system and need no explicit handoff. macOS also
  /// returns this when the `flutter_monaco` native plugin is not registered
  /// (for example in widget tests or headless runs).
  unsupported,

  /// A handoff was attempted but did not take effect (the WebView could not
  /// be located in the window, the window refused the first-responder
  /// change, or the platform call failed).
  failed,
}

/// Abstract interface defining the contract for platform-specific WebView
/// implementations.
///
/// This interface provides a unified API for interacting with WebViews across
/// different platforms (Android, iOS, macOS, Windows, and Web). Each platform
/// has its own concrete implementation that handles the platform-specific
/// details while exposing this consistent interface.
///
/// ### Platform Implementations
///
/// - **Android/iOS/macOS:** Uses `webview_flutter` via [FlutterWebViewController]
/// - **Windows:** Uses `webview_flutter_windows` (WebView2) via [WindowsWebViewController]
/// - **Web:** Uses an iframe with `dart:js_interop` via web-specific controller
///
/// ### Lifecycle
///
/// 1. Create the controller via [PlatformWebViewFactory.createController]
/// 2. Call [initialize] to set up the native WebView
/// 3. Call [enableJavaScript] and [addJavaScriptChannel] for communication
/// 4. Call [load] to load the Monaco editor HTML
/// 5. Use [runJavaScript] / [runJavaScriptReturningResult] for JS execution
/// 6. Call [dispose] when finished to release native resources
///
/// See also:
/// - [PlatformWebViewFactory] for creating platform-appropriate controllers.
/// - [MonacoController] which orchestrates this interface for the editor.
abstract class PlatformWebViewController {
  /// The Flutter widget that renders the WebView.
  ///
  /// This widget should be placed in the widget tree after [initialize] is
  /// called. The widget's size determines the Monaco editor's viewport.
  Widget get widget;

  /// Enables unrestricted JavaScript execution in the WebView.
  ///
  /// Must be called before [load] to ensure Monaco's JavaScript can execute.
  /// On some platforms (like Windows WebView2), this is a no-op as JavaScript
  /// is enabled by default.
  Future<void> enableJavaScript();

  /// Executes JavaScript code without expecting a return value.
  ///
  /// Use this for fire-and-forget operations like setting editor content
  /// or triggering actions. For operations that need a result, use
  /// [runJavaScriptReturningResult] instead.
  ///
  /// Throws platform-specific exceptions if the script fails to execute.
  Future<Object?> runJavaScript(String script);

  /// Executes JavaScript code and returns the result.
  ///
  /// Return-type behavior varies by platform:
  ///
  /// - iOS and macOS via WKWebView usually return native Dart values.
  /// - Android WebView may return JSON-encoded strings.
  /// - Windows WebView2 may return strings where numeric and boolean literals
  ///   remain strings after platform normalization.
  /// - Web iframe returns the result of JS interop conversion.
  ///
  /// `MonacoController.evaluateJavaScript<T>` normalizes these differences for
  /// JSON-serializable values. Prefer that method at the controller layer
  /// unless raw platform output is specifically required.
  ///
  /// Throws platform-specific exceptions if the script fails to execute.
  Future<Object?> runJavaScriptReturningResult(String script);

  /// Registers a JavaScript channel for bidirectional communication.
  ///
  /// Creates a `window.[name]` object in JavaScript that can send messages
  /// to Flutter via `postMessage`. The [onMessage] callback receives the
  /// message string whenever JavaScript calls `window.[name].postMessage(msg)`.
  ///
  /// The primary channel used by Monaco is `flutterChannel`, which handles
  /// all editor events (ready, content changes, selection, etc.).
  ///
  /// Returns platform-specific result or `null` on success.
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  );

  /// Removes a previously registered JavaScript channel.
  ///
  /// After removal, the `window.[name]` object will no longer be available
  /// in JavaScript, and no further messages will be received.
  Future<Object?> removeJavaScriptChannel(String name);

  /// Initializes the WebView and prepares it for use.
  ///
  /// This must be called before any other methods. It creates the native
  /// WebView instance and configures platform-specific settings like
  /// popup policies and console logging.
  ///
  /// On Windows, this triggers WebView2 initialization which may take
  /// longer on first run while the runtime is installed.
  Future<void> initialize();

  /// Releases all resources held by this controller.
  ///
  /// After calling dispose, the controller cannot be reused. Create a new
  /// controller if needed. This method cancels any pending subscriptions,
  /// clears JavaScript channels, and disposes the native WebView.
  void dispose();

  /// Loads the Monaco editor HTML into the WebView.
  ///
  /// This generates platform-appropriate HTML (with correct paths and
  /// worker shims) and loads it into the WebView. The page shell reports
  /// `lifecycle: pageReady` through the `flutterChannel`; the editor itself
  /// is created later by the `page.boot` protocol command.
  ///
  /// [page] carries the HTML-affecting settings (custom CSS, CSP opt-ins);
  /// changing them requires recreating the controller.
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()});

  /// Sets the background color of the WebView container.
  ///
  /// This color is visible while the editor is loading or if the editor
  /// content doesn't fill the entire view. Set this to match your app's
  /// theme for a seamless appearance.
  Future<void> setBackgroundColor(Color color);

  /// Toggles whether the WebView intercepts pointer events.
  ///
  /// On Web, this is used to allow Flutter overlays (like dialogs) to
  /// receive pointer events even when they overlap the Monaco iframe.
  /// When disabled, `pointer-events: none` is applied to the iframe.
  ///
  /// On native platforms, this may be a no-op or implemented via
  /// platform-specific pointer transparency APIs.
  Future<void> setInteractionEnabled(bool enabled);

  /// Requests native keyboard focus for the WebView host.
  ///
  /// On Windows, WebView2 must hold real Win32 keyboard focus before any
  /// in-page (JavaScript) focus call has an effect, so this moves native
  /// focus to the WebView2 control.
  ///
  /// On macOS, the WKWebView must be the NSWindow's first responder to
  /// receive typing; this performs that handoff through the `flutter_monaco`
  /// native plugin (`window.makeFirstResponder(webView)`).
  ///
  /// On Android, iOS, and Web the WebView participates in the regular
  /// platform focus system, so this returns [NativeFocusResult.unsupported].
  /// Callers should still run the in-page Monaco focus helper after this
  /// method; that helper is idempotent when DOM focus is already correct.
  Future<NativeFocusResult> requestNativeFocus();

  /// Whether the native layer currently routes keyboard input to this
  /// WebView.
  ///
  /// Returns `true`/`false` where the platform can answer authoritatively
  /// (macOS: the WKWebView is the window's first responder; Windows: WebView2
  /// reports native focus), and `null` where it cannot (Android, iOS, Web,
  /// headless runs, or when the WebView cannot be located).
  ///
  /// This is the real input-readiness signal that Monaco's DOM
  /// `onFocus`/`onBlur` stream cannot provide on desktop platform views.
  Future<bool?> hasNativeInputFocus();

  /// Hands native keyboard focus back to the Flutter view if this WebView
  /// currently holds it.
  ///
  /// macOS makes the Flutter view first responder; Windows asks WebView2 to
  /// release focus to the Flutter view. No-op on other platforms or when the
  /// WebView does not own native focus.
  Future<void> releaseNativeFocus();
}

/// Factory for creating platform-specific [PlatformWebViewController] instances.
///
/// This factory abstracts away platform detection and returns the appropriate
/// WebView implementation for the current platform. Use this instead of
/// directly instantiating platform-specific controllers.
///
/// ### Example
///
/// ```dart
/// final controller = PlatformWebViewFactory.createController();
/// await controller.initialize();
/// await controller.load();
/// ```
///
/// ### Testing
///
/// Use [debugCreateOverride] to inject mock controllers in tests:
///
/// ```dart
/// PlatformWebViewFactory.debugCreateOverride = () => MockWebViewController();
/// ```
///
/// See also:
/// - [PlatformWebViewController] for the interface contract.
/// - [WebViewController] for the forwarding implementation.
class PlatformWebViewFactory {
  /// Test hook to override controller creation with a mock implementation.
  ///
  /// Set this before creating controllers in tests, and reset to `null`
  /// after each test to avoid cross-test contamination.
  @visibleForTesting
  static PlatformWebViewController Function()? debugCreateOverride;

  /// Creates a new [PlatformWebViewController] for the current platform.
  ///
  /// On native platforms, this returns a controller backed by `webview_flutter`
  /// (Android/iOS/macOS) or `webview_flutter_windows` (Windows). On web, it returns
  /// an iframe-based controller.
  ///
  /// If [debugCreateOverride] is set, returns the result of that function
  /// instead, allowing test mocking.
  static PlatformWebViewController createController() {
    final override = debugCreateOverride;
    if (override != null) {
      return override();
    }

    return WebViewController();
  }
}

/// Forwarding implementation of [PlatformWebViewController].
///
/// This class delegates all operations to the platform-specific
/// [base.WebViewController] selected at compile time via conditional exports.
/// It provides a stable API surface while allowing the underlying
/// implementation to vary by platform.
///
/// **Note:** This class is internal. Use [PlatformWebViewFactory.createController]
/// to obtain instances.
///
/// See also:
/// - the conditional `base` import at the top of this file for the
///   platform selection logic (stub / native / web).
/// - [FlutterWebViewController] for Android/iOS/macOS implementation.
/// - [WindowsWebViewController] for Windows implementation.
class WebViewController implements PlatformWebViewController {
  /// Creates a controller that forwards to the platform-specific implementation.
  WebViewController() : _controller = base.WebViewController();

  final base.WebViewController _controller;

  @override
  Widget get widget => _controller.widget;

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()}) {
    return _controller.load(page: page);
  }

  @override
  void dispose() {
    return _controller.dispose();
  }

  @override
  Future<void> enableJavaScript() => _controller.enableJavaScript();

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String p1) onMessage,
  ) {
    return _controller.addJavaScriptChannel(name, onMessage);
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) {
    return _controller.removeJavaScriptChannel(name);
  }

  @override
  Future<Object?> runJavaScript(String script) {
    return _controller.runJavaScript(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) {
    return _controller.runJavaScriptReturningResult(script);
  }

  @override
  Future<void> setBackgroundColor(Color color) =>
      _controller.setBackgroundColor(color);

  @override
  Future<void> setInteractionEnabled(bool enabled) =>
      _controller.setInteractionEnabled(enabled);

  @override
  Future<NativeFocusResult> requestNativeFocus() =>
      _controller.requestNativeFocus();

  @override
  Future<bool?> hasNativeInputFocus() => _controller.hasNativeInputFocus();

  @override
  Future<void> releaseNativeFocus() => _controller.releaseNativeFocus();
}

/// Normalizes WebView2 `ExecuteScript` results to Dart-friendly types.
///
/// WebView2 wraps JavaScript return values in JSON encoding, which means:
/// - Strings come back double-quoted: `"hello"` instead of `hello`
/// - `null` comes back as the literal string `"null"`
/// - Objects/arrays may already be JSON strings
///
/// This function handles these cases:
/// 1. Non-string results are returned as-is
/// 2. The literal string `"null"` becomes Dart `null`
/// 3. JSON-encoded strings (`"value"`) are decoded to plain strings
/// 4. Other values are returned unchanged
///
/// ### Example
///
/// ```dart
/// // WebView2 returns: "\"hello\""
/// parseWindowsScriptResult('"hello"'); // Returns: 'hello'
///
/// // WebView2 returns: "null"
/// parseWindowsScriptResult('null'); // Returns: null
///
/// // WebView2 returns: "42"
/// parseWindowsScriptResult('42'); // Returns: '42' (still a string)
/// ```
///
/// See also:
/// - [WindowsWebViewController.runJavaScriptReturningResult] which uses this.
Object? parseWindowsScriptResult(Object? result) {
  if (result is! String) return result;

  final trimmed = result.trim();
  if (trimmed.isEmpty) return result;

  if (trimmed == 'null') return null;

  if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
    try {
      return json.decode(trimmed);
    } catch (_) {
      return trimmed.substring(1, trimmed.length - 1);
    }
  }

  return result;
}
