import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_monaco/src/assets/content_hash.dart';
import 'package:flutter_monaco/src/assets/monaco_assets.dart';
import 'package:flutter_monaco/src/common/monaco_page_config.dart';
import 'package:flutter_monaco/src/platform/webview_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as ww;

import '../helpers/csp.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.baseDir);

  final Directory baseDir;

  @override
  Future<String?> getApplicationSupportPath() async => baseDir.path;
}

/// Records what the Windows controller asks of WebView2.
class _FakeWebview extends Fake implements ww.WebviewController {
  final mappings = <(String, String, ww.WebviewHostResourceAccessKind)>[];
  final removedMappings = <String>[];
  final loadedUrls = <String>[];
  Object? mappingError;

  final loadErrors = StreamController<ww.WebErrorStatus>.broadcast();
  final loadingStates = StreamController<ww.LoadingState>.broadcast();
  final messages = StreamController<dynamic>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPopupWindowPolicy(
    ww.WebviewPopupWindowPolicy popupPolicy,
  ) async {}

  @override
  Stream<dynamic> get webMessage => messages.stream;

  @override
  Stream<ww.WebErrorStatus> get onLoadError => loadErrors.stream;

  @override
  Stream<ww.LoadingState> get loadingState => loadingStates.stream;

  @override
  Future<void> addVirtualHostNameMapping(
    String hostName,
    String folderPath,
    ww.WebviewHostResourceAccessKind accessKind,
  ) async {
    final error = mappingError;
    if (error != null) throw error;
    mappings.add((hostName, folderPath, accessKind));
  }

  @override
  Future<void> removeVirtualHostNameMapping(String hostName) async {
    removedMappings.add(hostName);
  }

  @override
  Future<void> loadUrl(String url) async {
    loadedUrls.add(url);
  }

  @override
  Future<void> dispose() async {}

  /// What WebView2 reports for a finished top-level navigation.
  Future<void> completeNavigation({ww.WebErrorStatus? error}) async {
    if (error != null) loadErrors.add(error);
    loadingStates.add(ww.LoadingState.navigationCompleted);
    await pumpEventQueue();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPlatform;
  late Directory supportDir;
  late _FakeWebview webview;
  late WindowsWebViewController controller;

  const config = MonacoPageConfig();
  const version = MonacoAssets.monacoVersion;
  const origin = 'https://flutter-monaco.example';

  String cacheRoot() => p.join(supportDir.path, monacoCacheSubDir);
  String versionDir() => p.join(cacheRoot(), 'monaco-$version');
  String pagePath([MonacoPageConfig page = config]) =>
      p.join(versionDir(), 'monaco_${page.stableCacheKey()}.html');
  String pageOnDisk([MonacoPageConfig page = config]) =>
      File(pagePath(page)).readAsStringSync();

  void writeBridge(String core) {
    final bridge = Directory(p.join(versionDir(), 'bridge'))
      ..createSync(recursive: true);
    for (final name in ['core.js', 'boot.js', 'lsp.js']) {
      File(p.join(bridge.path, name)).writeAsStringSync('// $name');
    }
    File(p.join(bridge.path, 'core.js')).writeAsStringSync(core);
  }

  setUp(() async {
    originalPlatform = PathProviderPlatform.instance;
    supportDir = await Directory.systemTemp.createTemp('fm_windows_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(supportDir);
    await MonacoAssets.clearCache();
    webview = _FakeWebview();
    controller = WindowsWebViewController.withController(webview);
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await MonacoAssets.clearCache();
    PathProviderPlatform.instance = originalPlatform;
    await supportDir.delete(recursive: true);
  });

  group('virtual host', () {
    test('maps the cache root that contains the versioned directory', () async {
      await controller.load();

      // The root, not monaco-<version>: every URL then names the engine
      // version, so an upgrade can never be served from a stale cache.
      expect(webview.mappings, [
        (
          'flutter-monaco.example',
          cacheRoot(),
          ww.WebviewHostResourceAccessKind.deny,
        ),
      ]);
    });

    test('loads the page over https with the page fingerprint', () async {
      writeBridge('// core v1');
      await controller.load();

      final url = Uri.parse(webview.loadedUrls.single);
      expect(url.origin, origin);
      expect(url.pathSegments, [
        'monaco-$version',
        'monaco_${config.stableCacheKey()}.html',
      ]);
      expect(
        url.queryParameters['v'],
        contentHash64(utf8.encode(pageOnDisk())),
      );
    });

    test('the page references its assets on the virtual host', () async {
      writeBridge('// core v1');
      await controller.load();
      final html = pageOnDisk();

      final scripts = scriptUrlsIn(html);
      expect(scripts, contains('$origin/monaco-$version/min/vs/loader.js'));
      final boot = Uri.parse(
        scripts.singleWhere((url) => url.contains('/bridge/boot.js')),
      );
      expect(boot.origin, origin);
      expect(boot.path, '/monaco-$version/bridge/boot.js');
      expect(boot.queryParameters['v'], isNotEmpty);

      final csp = PageCsp.fromHtml(html);
      for (final directive in csp.fetchDirectives) {
        expect(
          csp.admitsWithoutSelf(
            directive,
            '$origin/monaco-$version/min/vs/editor/editor.main.js',
          ),
          isTrue,
          reason: directive,
        );
      }
      // Served over https, workers load normally: no safety net.
      expect(html, isNot(contains('__FM_WORKERS')));
    });

    test('URLs change exactly when the bridge or the page changes', () async {
      String bridgeQuery() => Uri.parse(
        scriptUrlsIn(pageOnDisk())
            .singleWhere((url) => url.contains('/bridge/core.js')),
      ).queryParameters['v']!;

      writeBridge('// core v1');
      await controller.load();
      final firstUrl = webview.loadedUrls.last;
      final firstBridge = bridgeQuery();

      // Unchanged content keeps its URLs, so WebView2 may cache them.
      await controller.load();
      expect(webview.loadedUrls.last, firstUrl);
      expect(bridgeQuery(), firstBridge);
      expect(webview.mappings, hasLength(1));

      // A package upgrade rewrites the bridge in place under the same
      // Monaco version directory: both URLs must change.
      writeBridge('// core v2');
      await controller.load();
      expect(bridgeQuery(), isNot(firstBridge));
      expect(webview.loadedUrls.last, isNot(firstUrl));
    });

    test('replaces the page without rewriting it in place', () async {
      await controller.load();
      final page = File(pagePath());
      page.writeAsStringSync('stale page');
      // Another editor with the same configuration is reading the page.
      final reader = await page.open();
      try {
        await controller.load();
        expect(page.readAsStringSync(), isNot('stale page'));
        await reader.setPosition(0);
        expect(utf8.decode(await reader.read(64)), 'stale page');
      } finally {
        await reader.close();
      }
    }, skip: Platform.isWindows ? 'POSIX rename semantics' : null);
  });

  group('file:// fallback', () {
    void expectFilePage(String url) {
      expect(url, Uri.file(pagePath()).toString());
      final html = pageOnDisk();
      expect(
        scriptUrlsIn(html),
        contains(
          Uri.file(p.join(versionDir(), 'min', 'vs', 'loader.js')).toString(),
        ),
      );
      // Workers cannot load scripts from file: in WebView2.
      expect(html, contains('__FM_WORKERS'));
    }

    test('when the mapping throws', () async {
      webview.mappingError = PlatformException(code: 'invalid_args');
      await controller.load();
      expectFilePage(webview.loadedUrls.single);

      // The failure is remembered: later loads go straight to files.
      webview.mappingError = null;
      await controller.load();
      expect(webview.mappings, isEmpty);
      expectFilePage(webview.loadedUrls.last);
    });

    test('when the navigation to the virtual host fails', () async {
      // webview_flutter_windows reports a mapping WebView2 rejected as
      // success; the host name then never resolves.
      await controller.load();
      expect(webview.loadedUrls.single, startsWith('$origin/'));

      await webview.completeNavigation(
        error: ww.WebErrorStatus.hostNameNotResolved,
      );
      expect(webview.loadedUrls, hasLength(2));
      expectFilePage(webview.loadedUrls.last);

      await controller.load();
      expectFilePage(webview.loadedUrls.last);
    });

    test('not for a superseded or successful navigation', () async {
      await controller.load();
      await controller.load();
      // The first navigation is canceled by the second.
      await webview.completeNavigation(
        error: ww.WebErrorStatus.operationCanceled,
      );
      await webview.completeNavigation();
      // Later navigations (the page's own) are not the controller's concern.
      await webview.completeNavigation(error: ww.WebErrorStatus.timeout);

      expect(webview.loadedUrls, hasLength(2));
      expect(webview.loadedUrls, everyElement(startsWith('$origin/')));
    });
  });
}
