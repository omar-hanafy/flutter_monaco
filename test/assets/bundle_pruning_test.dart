import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// `.pubignore` keeps some upstream Monaco files out of the published archive
/// (and so out of every app bundle). That is only safe while nothing the
/// runtime loads can reach them. These tests re-derive reachability from
/// the bundle itself so a Monaco upgrade that starts loading a pruned file
/// fails here instead of 404ing in production.
void main() {
  const vsDir = 'assets/monaco/min/vs';

  /// The `.pubignore` patterns that apply below [vsDir].
  List<RegExp> prunePatterns() {
    final patterns = <RegExp>[];
    for (final raw in File('.pubignore').readAsLinesSync()) {
      final line = raw.trim();
      if (!line.startsWith('$vsDir/')) continue;
      var pattern = RegExp.escape(line.substring(vsDir.length + 1));
      pattern = pattern.replaceAll(r'\*', '[^/]*');
      if (pattern.endsWith('/')) pattern = '$pattern.*';
      patterns.add(RegExp('^$pattern\$'));
    }
    return patterns;
  }

  List<String> bundledFiles() => [
    for (final entity in Directory(vsDir).listSync(recursive: true))
      if (entity is File && !p.basename(entity.path).startsWith('.'))
        p.posix.joinAll(p.split(p.relative(entity.path, from: vsDir))),
  ];

  /// Every file reachable from the boot roots through any quoted relative
  /// module id or `require.toUrl` path, which covers static AMD
  /// dependencies, lazily required language chunks and worker URL shims.
  Set<String> reachableFiles() {
    final reference = RegExp(r'"(\.\.?/[^"\s]+)"');
    final reached = <String>{};
    final pending = [
      'loader.js',
      'editor/editor.main.js',
      'editor/editor.main.css',
      'nls.messages-loader.js',
    ];
    while (pending.isNotEmpty) {
      final path = pending.removeLast();
      if (!reached.add(path) || !path.endsWith('.js')) continue;
      final source = File('$vsDir/$path').readAsStringSync();
      for (final match in reference.allMatches(source)) {
        final resolved = p.posix.normalize(
          p.posix.join(p.posix.dirname(path), match[1]!),
        );
        if (resolved.startsWith('..')) continue;
        for (final candidate in [resolved, '$resolved.js']) {
          if (File('$vsDir/$candidate').existsSync()) {
            if (!reached.contains(candidate)) pending.add(candidate);
            break;
          }
        }
      }
    }
    return reached;
  }

  test('.pubignore prunes the unused worker entries and translations', () {
    final patterns = prunePatterns();
    final pruned = bundledFiles()
        .where((f) => patterns.any((r) => r.hasMatch(f)))
        .toList();
    expect(pruned, contains('language/typescript/ts.worker.js'));
    expect(pruned, contains('nls/lang/de.js'));
    expect(
      pruned.where((f) => f.startsWith('assets/')),
      isEmpty,
      reason: 'the hashed worker bundles in vs/assets/ are loaded at runtime',
    );
  });

  test('no pruned file is reachable from what the runtime loads', () {
    final patterns = prunePatterns();
    final reached = reachableFiles();
    expect(reached, contains('editor/editor.main.js'));
    expect(
      reached.where((f) => f.startsWith('assets/') && f.contains('.worker-')),
      isNotEmpty,
      reason: 'worker URL shims should lead to the hashed worker bundles',
    );
    final leaked = reached.where((f) => patterns.any((r) => r.hasMatch(f)));
    expect(
      leaked,
      isEmpty,
      reason:
          'these files are excluded from the archive but the runtime can '
          'load them; remove their .pubignore entries',
    );
  });
}
