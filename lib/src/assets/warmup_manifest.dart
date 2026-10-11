/// Which Monaco files are worth warming into the browser's HTTP cache
/// before the first editor boots on web.
///
/// Internal: consumed by the web precache implementation and its tests; not
/// exported by the barrel.
library;

/// Files (relative to `min/vs/`) that every boot loads and whose names are
/// stable across Monaco releases.
///
/// The list is ordered smallest-first so the boot-critical loader is cached
/// even if warmup is interrupted early.
const List<String> monacoWarmupStaticFiles = [
  'loader.js',
  'editor/editor.main.js',
  'editor/editor.main.css',
];

/// The AMD entry module every boot requires, relative to `min/vs/`.
const String monacoWarmupEntryModule = 'editor/editor.main.js';

/// Upper bound on the modules [discoverMonacoBootModules] visits, so a
/// malformed or unexpectedly large graph cannot turn warmup into a crawl.
const int monacoWarmupMaxModules = 64;

final RegExp _defineDependencies = RegExp(
  r'define\(\s*(?:"[^"]*"\s*,\s*)?\[([^\]]*)\]',
);
final RegExp _quotedId = RegExp(r'"([^"]+)"');

/// The modules `moduleSource` declares as dependencies in its AMD
/// `define(...)` calls, as paths relative to `min/vs/`.
///
/// `modulePath` is the module's own path relative to `min/vs/` (for example
/// `editor/editor.main.js`); relative ids resolve against its directory.
/// Absolute `vs/...` ids resolve against `min/vs/`. Loader plugin suffixes
/// (`!`) are dropped, and the AMD pseudo-modules `require`, `exports` and
/// `module` are skipped. Ids that would leave `min/vs/` are ignored.
List<String> monacoAmdDependencies(
  String moduleSource, {
  required String modulePath,
}) {
  final slash = modulePath.lastIndexOf('/');
  final baseDir = slash < 0
      ? <String>[]
      : modulePath.substring(0, slash).split('/');
  final result = <String>{};
  for (final define in _defineDependencies.allMatches(moduleSource)) {
    for (final quoted in _quotedId.allMatches(define[1]!)) {
      var id = quoted[1]!;
      final bang = id.indexOf('!');
      if (bang >= 0) id = id.substring(0, bang);
      if (id.isEmpty || id == 'require' || id == 'exports' || id == 'module') {
        continue;
      }
      final List<String> segments;
      if (id.startsWith('./') || id.startsWith('../')) {
        segments = [...baseDir, ...id.split('/')];
      } else if (id.startsWith('vs/')) {
        segments = id.substring(3).split('/');
      } else {
        // Bare ids (e.g. "vscode-uri") are loader-config aliases, not files.
        continue;
      }
      final resolved = _normalize(segments);
      if (resolved == null) continue;
      result.add(resolved.endsWith('.js') ? resolved : '$resolved.js');
    }
  }
  return result.toList();
}

String? _normalize(List<String> segments) {
  final out = <String>[];
  for (final segment in segments) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (out.isEmpty) return null;
      out.removeLast();
    } else {
      out.add(segment);
    }
  }
  return out.isEmpty ? null : out.join('/');
}

/// Walks the AMD dependency graph that the boot loads, starting at
/// [monacoWarmupEntryModule], and returns every module it reaches (entry
/// included) as paths relative to `min/vs/`.
///
/// Monaco 0.57 splits the editor across several content-hashed chunks, some
/// of them only reachable transitively (`editor.main` -> `index-<hash>` ->
/// `toggleHighContrast-<hash>` -> `editorWorkerHost-<hash>`). The hashes
/// change with every release, so the graph is recovered from the modules
/// themselves instead of a hard-coded list.
///
/// [load] returns a module's source, or `null` when it cannot be read; an
/// unreadable module is still reported (the boot will request it) but its
/// dependencies are not followed. Lazily loaded modules - language grammars
/// and worker bundles - are not `define` dependencies, so they stay out of
/// the result. Each level is loaded concurrently.
Future<List<String>> discoverMonacoBootModules(
  Future<String?> Function(String path) load, {
  int maxModules = monacoWarmupMaxModules,
}) async {
  final visited = <String>{monacoWarmupEntryModule};
  var frontier = [monacoWarmupEntryModule];
  while (frontier.isNotEmpty) {
    final sources = await Future.wait(frontier.map(load));
    final next = <String>[];
    for (var i = 0; i < frontier.length; i++) {
      final source = sources[i];
      if (source == null) continue;
      for (final dependency in monacoAmdDependencies(
        source,
        modulePath: frontier[i],
      )) {
        if (visited.length >= maxModules) break;
        if (visited.add(dependency)) next.add(dependency);
      }
    }
    frontier = next;
  }
  return visited.toList();
}
