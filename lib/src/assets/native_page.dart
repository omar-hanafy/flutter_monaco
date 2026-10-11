/// Where native WebViews load the generated editor page from, and the page
/// each hosting mode needs.
///
/// Pure Dart with no Flutter imports, so `dart run` tooling (the browser
/// regression tests under `tool/browser_tests/`) generates exactly the pages
/// the platform controllers do.
library;

import 'dart:convert';

import 'package:flutter_monaco/src/assets/content_hash.dart';
import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:path/path.dart' as p;

/// Host name the Windows WebView2 maps onto the extracted asset cache.
///
/// `.example` is a reserved top-level domain (RFC 2606, RFC 6761): it never
/// resolves, so the mapping cannot shadow a real site, and WebView2
/// recommends a reserved name for virtual hosts (names under `.local` also
/// wait on a multi-second mDNS lookup before every navigation).
const String monacoVirtualHostName = 'flutter-monaco.example';

/// A generated page and the URL its WebView navigates to.
class NativeMonacoPage {
  /// Creates a page description.
  const NativeMonacoPage({required this.html, required this.url});

  /// The page source, written to disk next to the extracted assets.
  final String html;

  /// The URL that loads [html].
  final String url;
}

/// Fingerprint of the bridge scripts as they will be served.
///
/// [scripts] maps each bridge file name to its bytes, or null when the file
/// is missing. Any change to any file changes the result.
String monacoBridgeFingerprint(Map<String, List<int>?> scripts) {
  final names = scripts.keys.toList()..sort();
  final manifest = names
      .map((name) {
        final bytes = scripts[name];
        return '$name:${bytes == null ? '-' : contentHash64(bytes)}';
      })
      .join('\n');
  return contentHash64(utf8.encode(manifest));
}

/// The page WebView2 serves from [monacoVirtualHostName].
///
/// The virtual host maps the cache root that *contains* the versioned
/// `monaco-<version>` directory ([versionDirectory]), so every asset URL
/// names the Monaco version: an engine upgrade changes every URL and can
/// never be served from a stale HTTP cache. The bridge scripts and the page
/// itself are rewritten in place under that same directory when the package
/// is upgraded, so their URLs carry content fingerprints instead
/// ([bridgeVersion] for the scripts, a hash of the page source for the
/// page).
///
/// Served over https, the page's workers are same-origin `blob:` workers
/// that load their bundles normally: WebView2 refuses `importScripts` of a
/// `file:` URL, which is what left Monaco's workers hanging when the page
/// was loaded from disk (issue #43).
NativeMonacoPage buildVirtualHostMonacoPage({
  required String versionDirectory,
  required String htmlFileName,
  required String monacoVersion,
  required String bridgeVersion,
  String? customCss,
  bool allowCdnFonts = false,
  List<String> allowedConnectSources = const [],
}) {
  final base = Uri(
    scheme: 'https',
    host: monacoVirtualHostName,
    pathSegments: [versionDirectory],
  ).toString();
  final html = buildMonacoIndexHtml(
    vsPath: '$base/min/vs',
    bridgeBase: '$base/bridge',
    monacoVersion: monacoVersion,
    isWindows: true,
    customCss: customCss,
    allowCdnFonts: allowCdnFonts,
    allowedConnectSources: allowedConnectSources,
    bridgeVersion: bridgeVersion,
  );
  final url = Uri(
    scheme: 'https',
    host: monacoVirtualHostName,
    pathSegments: [versionDirectory, htmlFileName],
    queryParameters: {'v': contentHash64(utf8.encode(html))},
  ).toString();
  return NativeMonacoPage(html: html, url: url);
}

/// Whether an https page would be refused connections to some of
/// [connectSources] (`MonacoPageConfig.allowedConnectSources`).
///
/// The virtual host page is a secure context, and browsers block insecure
/// `ws:` and `http:` connections from it as mixed content - except to
/// loopback hosts, which they treat as potentially trustworthy. The 3.x
/// Windows page was loaded from `file:`, where no such check applies, so a
/// language server at `ws://192.168.1.5:3000` worked there, including
/// through a bare `*` source.
///
/// Loopback endpoints stay on the virtual host because WebView2 ships
/// Chromium's Local Network Access checks disabled (WebView2Announcements
/// issue 126). If a runtime enables them, connections from the https page
/// to loopback or local network hosts need that permission, which a
/// `file:` page does not.
bool connectSourcesNeedInsecurePage(List<String> connectSources) {
  final insecureHost = RegExp(r'^(?:ws|http)://(\[[^\]]*\]|[^/:]+)');
  for (final raw in connectSources) {
    final source = raw.trim().toLowerCase();
    if (source == 'ws:' || source == 'http:' || source == '*') return true;
    final match = insecureHost.firstMatch(source);
    if (match != null && !_isLoopbackHost(match.group(1)!)) return true;
  }
  return false;
}

bool _isLoopbackHost(String host) =>
    host == 'localhost' ||
    host.endsWith('.localhost') ||
    host == '[::1]' ||
    RegExp(r'^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(host);

/// The page a native WebView loads from disk at [htmlFilePath], next to the
/// extracted `min/` and `bridge/` directories.
///
/// Android, iOS and macOS reference the assets relative to the page. Windows
/// uses this only when its virtual host is unavailable, with absolute
/// `file:` asset URLs as it always has; such a page relies on the worker
/// safety net (see `buildMonacoIndexHtml`).
NativeMonacoPage buildFileMonacoPage({
  required String htmlFilePath,
  required String monacoVersion,
  bool isWindows = false,
  bool isIosOrMacOS = false,
  String? customCss,
  bool allowCdnFonts = false,
  List<String> allowedConnectSources = const [],
}) {
  final String vsPath;
  final String bridgeBase;
  if (isWindows) {
    final directory = p.dirname(htmlFilePath);
    vsPath = Uri.file(p.join(directory, 'min', 'vs')).toString();
    bridgeBase = Uri.file(p.join(directory, 'bridge')).toString();
  } else {
    vsPath = 'min/vs';
    bridgeBase = 'bridge';
  }
  final html = buildMonacoIndexHtml(
    vsPath: vsPath,
    bridgeBase: bridgeBase,
    monacoVersion: monacoVersion,
    isWindows: isWindows,
    isIosOrMacOS: isIosOrMacOS,
    customCss: customCss,
    allowCdnFonts: allowCdnFonts,
    allowedConnectSources: allowedConnectSources,
  );
  return NativeMonacoPage(html: html, url: Uri.file(htmlFilePath).toString());
}
