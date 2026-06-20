/// Conditional export that provides the platform-appropriate [WebViewController].
///
/// The Dart compiler selects the correct implementation based on available
/// libraries:
///
/// - **`dart.library.js_interop`** (Web): Uses [web.dart] with iframe-based
///   Monaco hosting and `postMessage` communication.
/// - **`dart.library.io`** (Native): Uses [native.dart] which further
///   dispatches to `webview_flutter` or `webview_flutter_windows` based on OS.
/// - **Fallback** (Unsupported): Uses [stub.dart] which throws
///   [UnsupportedError] for all operations.
///
/// **Important:** The order matters - `js_interop` is checked before `io`
/// because web platforms have both libraries available, but we want the
/// web-specific implementation.
///
/// See also:
/// - [PlatformWebViewFactory] which consumes this export.
/// - [PlatformWebViewController] for the interface contract.
library;

export 'package:flutter_monaco/src/platform/web_view_controller/stub.dart'
    if (dart.library.io) 'package:flutter_monaco/src/platform/web_view_controller/native.dart'
    if (dart.library.js_interop) 'package:flutter_monaco/src/platform/web_view_controller/web.dart';
