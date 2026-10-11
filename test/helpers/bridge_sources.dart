import 'dart:io';

import 'package:path/path.dart' as p;

/// Reads a bridge JavaScript source file from the package assets.
///
/// The 3.0 bridge lives in real files under `assets/monaco/bridge/`; source
/// contract tests read them directly instead of scraping generated HTML.
String bridgeSource(String fileName) {
  return File(p.join('assets', 'monaco', 'bridge', fileName))
      .readAsStringSync();
}

/// Names of every bridge JavaScript file, in page load order.
const List<String> bridgeFileNames = [
  'core.js',
  'focus.js',
  'editor-api.js',
  'diff-api.js',
  'scroll-handoff.js',
  'lsp.js',
  'viewport-fit.js',
  'boot.js',
];

/// Concatenation of every bridge source, for assertions that span files.
String allBridgeSources() {
  return bridgeFileNames.map(bridgeSource).join('\n');
}
