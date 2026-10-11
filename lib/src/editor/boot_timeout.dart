import 'package:flutter/foundation.dart';

/// The message of the `MonacoTimeoutError(operation: 'boot')` raised when
/// [subject] (the editor or the diff editor) misses its ready deadline.
///
/// Appends the most likely cause for the current platform:
///
/// * Web: the cold-cache first load downloads the editor bundle, so a slow
///   connection can exceed the deadline.
/// * macOS: a sandboxed app (the `flutter create` default) without the
///   outgoing network connections entitlement cannot load the editor page
///   at all. WKWebView only logs an empty error and the boot silently runs
///   into this deadline, so the message names the entitlement and the fix.
String monacoBootTimeoutMessage({
  required String subject,
  required Duration timeout,
}) {
  final message =
      '$subject did not report ready in ${timeout.inSeconds} seconds.';
  if (kIsWeb) {
    return '$message On web the first load downloads the editor bundle; a '
        'slow connection can exceed this deadline. Retrying resumes from the '
        'browser cache.';
  }
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return '$message On macOS this usually means the app is sandboxed '
        'without the outgoing network connections entitlement, so WKWebView '
        'cannot load the editor page. Enable "Outgoing Connections (Client)" '
        "under App Sandbox in Xcode's Signing & Capabilities, or add "
        '<key>com.apple.security.network.client</key><true/> to '
        'macos/Runner/DebugProfile.entitlements and '
        'macos/Runner/Release.entitlements, then rebuild the app.';
  }
  return message;
}
