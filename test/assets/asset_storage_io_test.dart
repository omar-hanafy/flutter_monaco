import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_monaco/src/assets/asset_storage_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.baseDir);

  final Directory baseDir;

  @override
  Future<String?> getApplicationSupportPath() async => baseDir.path;
}

const _base = 'pkg/monaco';
const _version = '9.9.9';

/// An asset bundle whose content is chosen per test and whose [load] can be
/// held at one key, to observe the cache while an extraction is mid-copy.
class _GatedSource implements MonacoAssetSource {
  _GatedSource(this.files);

  final Map<String, String> files;
  String? gatedKey;
  final Completer<void> reached = Completer<void>();
  final Completer<void> release = Completer<void>();

  @override
  Future<List<String>> listAssets() async =>
      files.keys.map((path) => '$_base/$path').toList();

  @override
  Future<Uint8List> load(String key) async {
    if (key == gatedKey) {
      reached.complete();
      await release.future;
    }
    return Uint8List.fromList(
      utf8.encode(files[key.substring(_base.length + 1)]!),
    );
  }
}

Map<String, String> _bundle(String tag) => {
  'min/vs/loader.js': 'loader $tag',
  'min/vs/editor.js': 'editor $tag',
  'bridge/core.js': 'core $tag',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPlatform;
  late Directory supportDir;
  late String cacheRoot;
  late String target;

  setUp(() async {
    originalPlatform = PathProviderPlatform.instance;
    supportDir = await Directory.systemTemp.createTemp('fm_storage_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(supportDir);
    cacheRoot = p.join(supportDir.path, 'cache');
    target = p.join(cacheRoot, 'monaco-$_version');
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPlatform;
    await supportDir.delete(recursive: true);
  });

  Future<void> extract(MonacoAssetSource source) => ensureMonacoAssetsReady(
    assetBaseDir: _base,
    cacheSubDir: 'cache',
    htmlFileName: 'index.html',
    monacoVersion: _version,
    source: source,
  );

  String read(String relative) =>
      File(p.join(target, relative)).readAsStringSync();

  bool complete() =>
      File(p.join(target, '.monaco_complete')).existsSync() &&
      read('.monaco_complete') == _version &&
      _bundle('').keys.every((f) => File(p.join(target, f)).existsSync());

  List<String> cacheEntries() =>
      Directory(cacheRoot).listSync().map((e) => p.basename(e.path)).toList()
        ..sort();

  group('asset extraction', () {
    test('never exposes a partially copied tree', () async {
      final source = _GatedSource(_bundle('new'))
        ..gatedKey = '$_base/min/vs/editor.js';
      final extraction = extract(source);
      await source.reached.future;

      // A WebView in another engine checks the sentinel and loads whatever
      // is there: mid-copy, the cache must hold nothing or a whole tree.
      expect(!Directory(target).existsSync() || complete(), isTrue);

      source.release.complete();
      await extraction;
      expect(complete(), isTrue);
      expect(read('min/vs/editor.js'), 'editor new');
      expect(cacheEntries(), ['monaco-$_version']);
    });

    test('keeps an invalid tree until its replacement is complete', () async {
      await Directory(p.join(target, 'min', 'vs')).create(recursive: true);
      File(p.join(target, 'min', 'vs', 'loader.js')).writeAsStringSync('old');
      File(p.join(target, '.monaco_complete')).writeAsStringSync('0.0.0');
      File(p.join(target, 'monaco_page.html')).writeAsStringSync('in use');

      final source = _GatedSource(_bundle('new'))
        ..gatedKey = '$_base/min/vs/editor.js';
      final extraction = extract(source);
      await source.reached.future;

      expect(read('min/vs/loader.js'), 'old');
      expect(read('monaco_page.html'), 'in use');

      source.release.complete();
      await extraction;
      expect(complete(), isTrue);
      expect(read('min/vs/loader.js'), 'loader new');
      expect(File(p.join(target, 'monaco_page.html')).existsSync(), isFalse);
      expect(cacheEntries(), ['monaco-$_version']);
    });

    test('does not rewrite a tree a concurrent extraction installed', () async {
      // Two engines start on a cold cache. The first to finish installs its
      // tree and its WebView starts reading it; the slower one must not
      // rewrite those files underneath it.
      final slow = _GatedSource(_bundle('slow'))
        ..gatedKey = '$_base/min/vs/loader.js';
      final slowExtraction = extract(slow);
      await slow.reached.future;

      await extract(_GatedSource(_bundle('fast')));
      expect(complete(), isTrue);
      expect(read('min/vs/loader.js'), 'loader fast');

      slow.release.complete();
      await slowExtraction;
      expect(read('min/vs/loader.js'), 'loader fast');
      expect(read('min/vs/editor.js'), 'editor fast');
      expect(cacheEntries(), ['monaco-$_version']);
    });

    test('removes trees abandoned by an earlier crash', () async {
      final abandoned = Directory(
        p.join(cacheRoot, 'monaco-$_version.retired-123'),
      )..createSync(recursive: true);
      await extract(_GatedSource(_bundle('new')));
      expect(abandoned.existsSync(), isFalse);
      expect(cacheEntries(), ['monaco-$_version']);
    });
  });

  group('bridge refresh', () {
    Future<void> refresh(Map<String, String> files) =>
        refreshMonacoBridgeAssets(
          assetBaseDir: _base,
          cacheSubDir: 'cache',
          monacoVersion: _version,
          source: _GatedSource(files),
        );

    test('replaces a file without rewriting it in place', () async {
      final core = File(p.join(target, 'bridge', 'core.js'))
        ..createSync(recursive: true)
        ..writeAsStringSync('core old');
      // A WebView that opened the previous file must keep reading it whole;
      // an in-place write truncates the very file it is reading.
      final reader = await core.open();
      try {
        await refresh({'bridge/core.js': 'core new'});
        expect(core.readAsStringSync(), 'core new');
        await reader.setPosition(0);
        expect(utf8.decode(await reader.read(64)), 'core old');
      } finally {
        await reader.close();
      }
      expect(
        Directory(p.join(target, 'bridge')).listSync().map((e) => e.path),
        [core.path],
      );
    }, skip: Platform.isWindows ? 'POSIX rename semantics' : null);

    test('leaves unchanged files untouched', () async {
      final core = File(p.join(target, 'bridge', 'core.js'))
        ..createSync(recursive: true)
        ..writeAsStringSync('core same');
      final past = DateTime(2020);
      core.setLastModifiedSync(past);

      await refresh({'bridge/core.js': 'core same'});
      expect(core.lastModifiedSync(), past);
    });
  });

  group('writeFileAtomically', () {
    test('writes, replaces, and skips identical content', () async {
      final path = p.join(supportDir.path, 'dir', 'page.html');
      expect(await writeFileAtomically(path, utf8.encode('one')), isTrue);
      expect(File(path).readAsStringSync(), 'one');
      expect(await writeFileAtomically(path, utf8.encode('two')), isTrue);
      expect(File(path).readAsStringSync(), 'two');
      expect(await writeFileAtomically(path, utf8.encode('two')), isFalse);
      expect(
        Directory(p.dirname(path)).listSync().map((e) => p.basename(e.path)),
        ['page.html'],
      );
    });
  });

  group('clearMonacoAssetCache', () {
    test('removes the tree and leaves nothing behind', () async {
      await extract(_GatedSource(_bundle('new')));
      await clearMonacoAssetCache(
        assetBaseDir: _base,
        cacheSubDir: 'cache',
        monacoVersion: _version,
      );
      expect(cacheEntries(), isEmpty);
    });
  });
}
