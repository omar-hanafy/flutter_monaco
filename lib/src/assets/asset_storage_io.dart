import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/src/assets/asset_diagnostics.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where extraction reads the bundled Monaco assets from.
///
/// Production reads the app's asset bundle; tests substitute a source they
/// control (for example one that pauses mid-copy).
abstract interface class MonacoAssetSource {
  /// Every asset key in the bundle.
  Future<List<String>> listAssets();

  /// The bytes of the asset [key].
  Future<Uint8List> load(String key);
}

/// [MonacoAssetSource] over Flutter's [rootBundle].
class _RootBundleAssetSource implements MonacoAssetSource {
  const _RootBundleAssetSource();

  @override
  Future<List<String>> listAssets() async =>
      (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();

  @override
  Future<Uint8List> load(String key) async =>
      (await rootBundle.load(key)).buffer.asUint8List();
}

const MonacoAssetSource _rootBundleSource = _RootBundleAssetSource();

/// Extracts bundled Monaco assets to application support storage if needed.
///
/// Extraction never exposes a partial tree: assets are copied into a
/// private staging directory that is renamed into place only once complete
/// (sentinel included). Several engines or windows in one app may run this
/// concurrently; whichever finishes first installs its tree and the others
/// discard theirs, so a WebView that already loaded the installed tree is
/// never pulled out from under. An existing tree that fails validation is
/// replaced only after its replacement is complete.
Future<void> ensureMonacoAssetsReady({
  required String assetBaseDir,
  required String cacheSubDir,
  required String htmlFileName,
  required String monacoVersion,
  @visibleForTesting MonacoAssetSource? source,
}) async {
  final targetDir = await monacoAssetCacheDir(
    assetBaseDir: assetBaseDir,
    cacheSubDir: cacheSubDir,
    monacoVersion: monacoVersion,
  );

  if (await _isCompleteExtraction(targetDir, monacoVersion)) {
    debugPrint(
      '[MonacoAssets] Monaco already extracted at: $targetDir (version $monacoVersion)',
    );
    await _removeAbandonedSiblings(targetDir);
    return;
  }

  debugPrint(
    '[MonacoAssets] Monaco not found or incomplete, copying assets...',
  );
  await _extractAllAssets(
    targetDir: targetDir,
    assetBaseDir: assetBaseDir,
    htmlFileName: htmlFileName,
    monacoVersion: monacoVersion,
    source: source ?? _rootBundleSource,
  );
  await _removeAbandonedSiblings(targetDir);
}

/// Rewrites the bridge JavaScript files in the native asset cache.
///
/// Unlike the sentinel-guarded `min/` tree, the bridge files are small and
/// are refreshed on every launch, so upgrading the package can never leave a
/// stale JS bridge next to a current Dart side. Each file is replaced
/// atomically (see [writeFileAtomically]) and only when its content
/// changed, so a WebView loading the bridge never reads a truncated file.
Future<void> refreshMonacoBridgeAssets({
  required String assetBaseDir,
  required String cacheSubDir,
  required String monacoVersion,
  @visibleForTesting MonacoAssetSource? source,
}) async {
  final assets = source ?? _rootBundleSource;
  final targetDir = await monacoAssetCacheDir(
    assetBaseDir: assetBaseDir,
    cacheSubDir: cacheSubDir,
    monacoVersion: monacoVersion,
  );

  final bridgeAssets = (await assets.listAssets())
      .where((key) => key.startsWith('$assetBaseDir/bridge/'))
      .where((key) => !key.endsWith('.DS_Store'))
      .toList();

  if (bridgeAssets.isEmpty) {
    // Mirrors the `min/` copy behavior: in a consuming app the manifest
    // always lists the bridge, but the package's own test harness keys
    // assets without the `packages/flutter_monaco/` prefix and finds none.
    debugPrint(
      '[MonacoAssets] No bridge assets under $assetBaseDir/bridge/ in the '
      'asset manifest; skipping bridge refresh.',
    );
    return;
  }

  var written = 0;
  for (final assetKey in bridgeAssets) {
    final relativePath = assetKey.substring('$assetBaseDir/'.length);
    if (await writeFileAtomically(
      p.join(targetDir, relativePath),
      await assets.load(assetKey),
    )) {
      written++;
    }
  }

  debugPrint(
    '[MonacoAssets] Bridge refreshed ($written of ${bridgeAssets.length} '
    'files changed)',
  );
}

/// Writes [bytes] to [path] so that no reader ever observes a partial file.
///
/// The content is written and flushed to a temporary sibling, which is then
/// renamed over [path]: a reader that opened the previous file keeps
/// reading it whole, and a later reader gets the new file whole. Writing in
/// place would truncate the file first, and a WebView loading it at that
/// moment would run a truncated script or page. A file that already holds
/// exactly [bytes] is left untouched. Returns whether the file was written.
Future<bool> writeFileAtomically(String path, List<int> bytes) async {
  final target = File(path);
  if (target.existsSync() && listEquals(await target.readAsBytes(), bytes)) {
    return false;
  }
  await target.parent.create(recursive: true);
  final temp = File(
    p.join(p.dirname(path), '.${p.basename(path)}.${_uniqueSuffix()}.tmp'),
  );
  try {
    await temp.writeAsBytes(bytes, flush: true);
    await _renameReplacing(temp, path);
  } catch (_) {
    await _deleteQuietly(temp);
    rethrow;
  }
  return true;
}

/// Renames [file] over [path], retrying briefly: on Windows the replace
/// fails while another process (a WebView reading the previous version)
/// holds the target open without delete sharing.
Future<void> _renameReplacing(File file, String path) async {
  for (var attempt = 1; ; attempt++) {
    try {
      await file.rename(path);
      return;
    } on FileSystemException {
      if (attempt >= 5) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 25 * attempt));
    }
  }
}

/// A name component no other writer in this or another process will pick.
String _uniqueSuffix() =>
    '$pid-${DateTime.now().microsecondsSinceEpoch}-'
    '${Random().nextInt(1 << 32).toRadixString(16)}';

Future<void> _deleteQuietly(FileSystemEntity entity) async {
  try {
    if (entity.existsSync()) await entity.delete(recursive: true);
  } catch (_) {
    // Best effort: a leftover is cleaned up by a later run.
  }
}

/// Whether [targetDir] holds a complete extraction of [monacoVersion].
Future<bool> _isCompleteExtraction(
  String targetDir,
  String monacoVersion,
) async {
  final loader = File(p.join(targetDir, 'min', 'vs', 'loader.js'));
  final sentinel = File(p.join(targetDir, '.monaco_complete'));
  try {
    return loader.existsSync() &&
        sentinel.existsSync() &&
        (await sentinel.readAsString()).trim() == monacoVersion;
  } on FileSystemException {
    return false;
  }
}

/// Name prefix of a staging directory being filled by an extraction.
String _stagingPrefix(String targetDir) =>
    '${p.basename(targetDir)}.extracting-';

/// Name prefix of a replaced tree awaiting deletion.
String _retiredPrefix(String targetDir) => '${p.basename(targetDir)}.retired-';

/// Deletes retired trees and staging directories abandoned by a crashed
/// run (an hour old; a live extraction finishes in seconds).
Future<void> _removeAbandonedSiblings(String targetDir) async {
  final parent = Directory(p.dirname(targetDir));
  if (!parent.existsSync()) return;
  final staging = _stagingPrefix(targetDir);
  final retired = _retiredPrefix(targetDir);
  final cutoff = DateTime.now().subtract(const Duration(hours: 1));
  try {
    await for (final entity in parent.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith(retired) ||
          (name.startsWith(staging) &&
              entity.statSync().modified.isBefore(cutoff))) {
        await _deleteQuietly(entity);
      }
    }
  } on FileSystemException {
    // Best effort.
  }
}

/// Returns the native cache directory used for extracted Monaco assets.
Future<String> monacoAssetCacheDir({
  required String assetBaseDir,
  required String cacheSubDir,
  required String monacoVersion,
}) async {
  return p.join(
    (await getApplicationSupportDirectory()).path,
    cacheSubDir,
    'monaco-$monacoVersion',
  );
}

/// Returns the native generated HTML path for a configuration cache key.
Future<String> monacoAssetHtmlPath({
  required String cacheKey,
  required String assetBaseDir,
  required String cacheSubDir,
  required String monacoVersion,
}) async {
  final targetDir = await monacoAssetCacheDir(
    assetBaseDir: assetBaseDir,
    cacheSubDir: cacheSubDir,
    monacoVersion: monacoVersion,
  );
  return p.join(targetDir, 'monaco_$cacheKey.html');
}

/// Returns diagnostics for the extracted native Monaco asset cache.
Future<MonacoAssetDiagnostics> monacoAssetInfo({
  required String assetBaseDir,
  required String cacheSubDir,
  required String monacoVersion,
}) async {
  final targetDir = await monacoAssetCacheDir(
    assetBaseDir: assetBaseDir,
    cacheSubDir: cacheSubDir,
    monacoVersion: monacoVersion,
  );
  final directory = Directory(targetDir);

  if (!directory.existsSync()) {
    return MonacoAssetDiagnostics(
      exists: false,
      path: targetDir,
      monacoVersion: monacoVersion,
    );
  }

  var fileCount = 0;
  var totalSize = 0;
  var generatedHtmlCount = 0;

  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) {
      fileCount++;
      totalSize += await entity.length();

      final fileName = p.basename(entity.path);
      if (fileName.startsWith('monaco_') && fileName.endsWith('.html')) {
        generatedHtmlCount++;
      }
    }
  }

  return MonacoAssetDiagnostics(
    exists: true,
    path: targetDir,
    monacoVersion: monacoVersion,
    fileCount: fileCount,
    totalSizeBytes: totalSize,
    generatedHtmlCount: generatedHtmlCount,
  );
}

/// Deletes the native Monaco asset cache directory when present.
///
/// The tree is first renamed aside, so it disappears at once: a concurrent
/// reader sees either the whole tree or none of it, never a half-deleted
/// one that still passes the sentinel check.
Future<void> clearMonacoAssetCache({
  required String assetBaseDir,
  required String cacheSubDir,
  required String monacoVersion,
}) async {
  final targetDir = await monacoAssetCacheDir(
    assetBaseDir: assetBaseDir,
    cacheSubDir: cacheSubDir,
    monacoVersion: monacoVersion,
  );
  final directory = Directory(targetDir);
  if (!directory.existsSync()) return;

  final retired = Directory(
    p.join(
      p.dirname(targetDir),
      '${_retiredPrefix(targetDir)}${_uniqueSuffix()}',
    ),
  );
  try {
    await directory.rename(retired.path);
  } on FileSystemException {
    // Renaming can fail on Windows while a file inside is open; deleting in
    // place is what 3.x always did. The sentinel goes first, so a delete
    // that stops partway at another open file never leaves a tree that
    // still passes the sentinel check.
    await _deleteQuietly(File(p.join(targetDir, '.monaco_complete')));
    await directory.delete(recursive: true);
    debugPrint('[MonacoAssets] Monaco assets cleaned');
    return;
  }
  await retired.delete(recursive: true);
  debugPrint('[MonacoAssets] Monaco assets cleaned');
}

Future<void> _extractAllAssets({
  required String targetDir,
  required String assetBaseDir,
  required String htmlFileName,
  required String monacoVersion,
  required MonacoAssetSource source,
}) async {
  final stopwatch = Stopwatch()..start();
  final failures = <String>[];

  final staging = Directory(
    p.join(
      p.dirname(targetDir),
      '${_stagingPrefix(targetDir)}${_uniqueSuffix()}',
    ),
  );
  await staging.create(recursive: true);

  try {
    final monacoAssets = (await source.listAssets())
        .where((key) => key.startsWith('$assetBaseDir/'))
        .where((key) => !key.endsWith('.DS_Store'))
        .where((key) => !key.endsWith('/$htmlFileName'))
        .toList();

    debugPrint(
      '[MonacoAssets] Found ${monacoAssets.length} Monaco assets to copy',
    );

    var copiedCount = 0;
    for (final assetKey in monacoAssets) {
      try {
        final relativePath = assetKey.substring('$assetBaseDir/'.length);
        if (relativePath.isEmpty) continue;

        final targetFile = File(p.join(staging.path, relativePath));
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(await source.load(assetKey));

        copiedCount++;

        if (copiedCount % 100 == 0) {
          debugPrint(
            '[MonacoAssets] Progress: $copiedCount/${monacoAssets.length} files copied',
          );
        }
      } catch (e) {
        debugPrint('[MonacoAssets] Error copying $assetKey: $e');
        failures.add('$assetKey: $e');
      }
    }

    stopwatch.stop();
    debugPrint(
      '[MonacoAssets] Completed: $copiedCount files copied in ${stopwatch.elapsedMilliseconds}ms',
    );

    if (copiedCount != monacoAssets.length || failures.isNotEmpty) {
      throw StateError(
        '[MonacoAssets] Copy incomplete ($copiedCount/${monacoAssets.length}). '
        'Failures: ${failures.length}',
      );
    }

    await File(p.join(staging.path, '.monaco_complete'))
        .writeAsString(monacoVersion, flush: true);
    await _installExtraction(staging, targetDir, monacoVersion);
    debugPrint(
      '[MonacoAssets] Sentinel file written for version $monacoVersion',
    );
  } finally {
    await _deleteQuietly(staging);
  }
}

/// Moves the complete [staging] tree to [targetDir].
///
/// The rename is atomic while [targetDir] does not exist. When it does,
/// either a concurrent extraction installed a complete tree first (kept:
/// it is identical, and a WebView may already be using it) or an invalid
/// tree is in the way (renamed aside, then replaced).
Future<void> _installExtraction(
  Directory staging,
  String targetDir,
  String monacoVersion,
) async {
  // On Windows a directory cannot be renamed while any file inside it is
  // open, and antivirus scanners and the search indexer open freshly
  // written files for a moment; back off for up to ~6s before giving up.
  for (var attempt = 1; ; attempt++) {
    try {
      await staging.rename(targetDir);
      return;
    } on FileSystemException {
      if (attempt >= 8) rethrow;
    }
    if (await _isCompleteExtraction(targetDir, monacoVersion)) return;
    if (Directory(targetDir).existsSync()) {
      final retired = p.join(
        p.dirname(targetDir),
        '${_retiredPrefix(targetDir)}${_uniqueSuffix()}',
      );
      try {
        await Directory(targetDir).rename(retired);
        await _deleteQuietly(Directory(retired));
        continue;
      } on FileSystemException {
        // Locked, or moved or replaced concurrently: wait and re-check.
      }
    }
    await Future<void>.delayed(Duration(milliseconds: 50 << (attempt - 1)));
  }
}
