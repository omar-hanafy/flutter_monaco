// Lays out a native asset cache and generates the editor pages the native
// hosts load in it, through the package's own page builders, for the
// browser regression tests.
//
// Usage (from the package root):
//   dart run tool/browser_tests/generate_pages.dart <cache-root> <report.json>
//
// Creates <cache-root>/monaco-<version>/ the way the native hosts extract
// it (min/ and bridge/, linked to this checkout's assets), writes one page
// per hosting mode into it, and writes <report.json> naming the Monaco
// version, the version directory, and each page's path and the URL its
// host navigates to. (A file, not stdout: `dart run` prints its own
// progress there.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_monaco/src/assets/html_builder.dart';
import 'package:flutter_monaco/src/assets/native_page.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: generate_pages.dart <cache-root> <report.json>');
    exit(64);
  }
  final packageRoot = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..', '..'),
  );
  final monacoVersion = _bundledMonacoVersion(packageRoot);
  final versionDirectory = p.join(
    p.absolute(args.first),
    'monaco-$monacoVersion',
  );
  Directory(versionDirectory).createSync(recursive: true);
  for (final folder in ['min', 'bridge']) {
    Link(p.join(versionDirectory, folder))
        .createSync(p.join(packageRoot, 'assets', 'monaco', folder));
  }

  final pages = <String, (String, NativeMonacoPage)>{
    // Android, iOS and macOS: loaded from disk, assets relative to the page.
    'file': (
      'monaco_file.html',
      buildFileMonacoPage(
        htmlFilePath: p.join(versionDirectory, 'monaco_file.html'),
        monacoVersion: monacoVersion,
      ),
    ),
    // Windows without its virtual host: absolute file:// asset URLs.
    'windowsFile': (
      'monaco_windows_file.html',
      buildFileMonacoPage(
        htmlFilePath: p.join(versionDirectory, 'monaco_windows_file.html'),
        monacoVersion: monacoVersion,
        isWindows: true,
      ),
    ),
    // Windows: served by WebView2 from https://flutter-monaco.example/.
    'virtualHost': (
      'monaco_virtual_host.html',
      buildVirtualHostMonacoPage(
        versionDirectory: p.basename(versionDirectory),
        htmlFileName: 'monaco_virtual_host.html',
        monacoVersion: monacoVersion,
        bridgeVersion: monacoBridgeFingerprint({
          for (final name in monacoBridgeScripts)
            name: File(p.join(versionDirectory, 'bridge', name))
                .readAsBytesSync(),
        }),
      ),
    ),
  };

  final report = <String, Object>{};
  pages.forEach((name, entry) {
    final (fileName, page) = entry;
    final path = p.join(versionDirectory, fileName);
    File(path).writeAsStringSync(page.html);
    report[name] = {'path': path, 'url': page.url};
  });
  File(args.last).writeAsStringSync(
    jsonEncode({
      'monacoVersion': monacoVersion,
      'versionDirectory': versionDirectory,
      'virtualHost': monacoVirtualHostName,
      'pages': report,
    }),
  );
}

/// `MonacoAssets.monacoVersion`, read from source: that library imports
/// Flutter and cannot run under `dart run`.
String _bundledMonacoVersion(String packageRoot) {
  final source = File(
    p.join(packageRoot, 'lib', 'src', 'assets', 'monaco_assets.dart'),
  ).readAsStringSync();
  final match = RegExp(r"static const String monacoVersion = '([^']+)';")
      .firstMatch(source);
  if (match == null) {
    throw StateError('MonacoAssets.monacoVersion not found in $packageRoot');
  }
  return match.group(1)!;
}
