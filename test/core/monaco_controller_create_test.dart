import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.baseDir);

  final Directory baseDir;

  @override
  Future<String?> getApplicationSupportPath() async => baseDir.path;
}

class _ThrowingWebViewController implements PlatformWebViewController {
  _ThrowingWebViewController({this.throwOnLoadFile = false});

  final bool throwOnLoadFile;
  bool disposed = false;
  bool initialized = false;
  bool jsEnabled = false;
  bool interactionEnabled = true;
  final Map<String, void Function(String)> _channels = {};

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> load({String? customCss, bool allowCdnFonts = false}) async {
    if (throwOnLoadFile) {
      throw StateError('loadFile failed');
    }
  }

  @override
  Future<void> enableJavaScript() async {
    jsEnabled = true;
  }

  @override
  Future<void> runJavaScript(String script) async {}

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async => null;

  @override
  Future<void> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    _channels[name] = onMessage;
  }

  @override
  Future<void> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
  }

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setInteractionEnabled(bool enabled) async {
    interactionEnabled = enabled;
  }

  @override
  Future<void> requestNativeFocus() async {}

  @override
  Widget get widget => const SizedBox.shrink();

  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MonacoController.create cleanup', () {
    late PathProviderPlatform originalPlatform;
    late Directory tempDir;

    setUp(() async {
      originalPlatform = PathProviderPlatform.instance;
      tempDir = await Directory.systemTemp.createTemp('monaco_create_test_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
      await MonacoAssets.clearCache();
    });

    tearDown(() async {
      PlatformWebViewFactory.debugCreateOverride = null;
      await MonacoAssets.clearCache();
      PathProviderPlatform.instance = originalPlatform;
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('disposes webview when loadFile throws', () async {
      final webview = _ThrowingWebViewController(throwOnLoadFile: true);
      PlatformWebViewFactory.debugCreateOverride = () => webview;

      await expectLater(
        () => MonacoController.create(),
        throwsA(isA<StateError>()),
      );

      expect(webview.disposed, true);
    });

    test('disposes webview when ready times out', () async {
      final webview = _ThrowingWebViewController();
      PlatformWebViewFactory.debugCreateOverride = () => webview;

      await expectLater(
        () => MonacoController.create(
          readyTimeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(webview.disposed, true);
    });
  });
}
