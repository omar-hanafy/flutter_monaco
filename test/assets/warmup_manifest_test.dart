import 'dart:io';

import 'package:flutter_monaco/src/assets/warmup_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web warmup discovers Monaco's hash-named editor chunks by walking the
/// AMD dependency graph from `editor.main.js` at runtime. These tests pin
/// the parsing rules and guard against a Monaco upgrade silently changing
/// the module format (which would degrade warmup to the static files only).
void main() {
  group('monacoAmdDependencies', () {
    test('resolves relative ids of a named define against its directory', () {
      const source =
          'define("vs/editor/editor.main",["exports","../json.worker-Bp7U0",'
          '"require","vs/nls.messages-loader!","../editor-BdtEMBbM"],'
          '(function(e,m){}))';
      expect(
        monacoAmdDependencies(source, modulePath: 'editor/editor.main.js'),
        [
          'json.worker-Bp7U0.js',
          'nls.messages-loader.js',
          'editor-BdtEMBbM.js',
        ],
      );
    });

    test('reads anonymous defines and same-directory ids', () {
      const source =
          'define(["exports","./toggleHighContrast-DuqAmExZ"],function(){})';
      expect(monacoAmdDependencies(source, modulePath: 'index-DZH_zysX.js'), [
        'toggleHighContrast-DuqAmExZ.js',
      ]);
    });

    test('skips pseudo-modules, bare aliases and ids leaving min/vs', () {
      const source =
          'define(["require","exports","module","vscode-uri",'
          '"../../outside","./ok"],function(){})';
      expect(monacoAmdDependencies(source, modulePath: 'editor/x.js'), [
        'editor/ok.js',
      ]);
    });

    test('ignores string literals outside define dependency lists', () {
      const source =
          'define([],function(){require(["../abap-D-t0cyap"],function(){})})';
      expect(
        monacoAmdDependencies(source, modulePath: 'basic-languages/m.js'),
        isEmpty,
      );
      expect(monacoAmdDependencies('', modulePath: 'a.js'), isEmpty);
    });
  });

  group('discoverMonacoBootModules', () {
    test('follows transitive dependencies once each', () async {
      final sources = {
        'editor/editor.main.js': 'define(["../a","../b"],function(){})',
        'a.js': 'define(["./c","./b"],function(){})',
        'b.js': 'define([],function(){})',
        'c.js': 'define(["./a"],function(){})',
      };
      final loaded = <String>[];
      final modules = await discoverMonacoBootModules((path) async {
        loaded.add(path);
        return sources[path];
      });
      expect(modules, ['editor/editor.main.js', 'a.js', 'b.js', 'c.js']);
      expect(loaded, hasLength(4), reason: 'each module is fetched once');
    });

    test('reports unreadable modules without following them', () async {
      final modules = await discoverMonacoBootModules(
        (path) async => path == 'editor/editor.main.js'
            ? 'define(["../missing"],function(){})'
            : null,
      );
      expect(modules, ['editor/editor.main.js', 'missing.js']);
    });

    test('stops at the module budget', () async {
      // Every module depends on two fresh ones: an unbounded graph.
      final modules = await discoverMonacoBootModules((path) async {
        final id = path.replaceAll(RegExp(r'\W'), '_');
        final up = path.contains('/') ? '../' : './';
        return 'define(["$up${id}l","$up${id}r"],function(){})';
      }, maxModules: 10);
      expect(modules, hasLength(10));
    });
  });

  group('bundled Monaco', () {
    Future<String?> readBundled(String path) async {
      final file = File('assets/monaco/min/vs/$path');
      return file.existsSync() ? file.readAsStringSync() : null;
    }

    test('the boot graph reaches every hashed editor chunk', () async {
      final modules = await discoverMonacoBootModules(readBundled);

      var totalBytes = 0;
      for (final module in modules) {
        final file = File('assets/monaco/min/vs/$module');
        expect(
          file.existsSync(),
          isTrue,
          reason: '$module is referenced by the boot graph but not bundled',
        );
        totalBytes += file.lengthSync();
      }

      bool reaches(String prefix) => modules.any(
        (m) => RegExp('^$prefix-[A-Za-z0-9_-]+\\.js\$').hasMatch(m),
      );
      for (final chunk in [
        'editor',
        'index',
        'toggleHighContrast',
        'editorWorkerHost',
      ]) {
        expect(
          reaches(chunk),
          isTrue,
          reason:
              'Monaco changed how editor.main.js reaches its "$chunk" chunk; '
              'update discoverMonacoBootModules so web warmup keeps covering '
              'the multi-megabyte download.',
        );
      }
      expect(
        totalBytes,
        greaterThan(3 * 1024 * 1024),
        reason: 'the boot graph should cover the multi-megabyte editor bulk',
      );
    });

    test('lazy language grammars and worker bundles stay out', () async {
      final modules = await discoverMonacoBootModules(readBundled);
      expect(modules.where((m) => m.startsWith('assets/')), isEmpty);
      expect(modules.where((m) => m.startsWith('abap-')), isEmpty);
      expect(modules.length, lessThan(monacoWarmupMaxModules));
    });

    test('static warmup files exist in the bundle', () {
      for (final file in monacoWarmupStaticFiles) {
        expect(
          File('assets/monaco/min/vs/$file').existsSync(),
          isTrue,
          reason: '$file is missing from the Monaco bundle',
        );
      }
    });
  });
}
