import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/src/assets/asset_diagnostics.dart';
import 'package:flutter_monaco/src/assets/asset_storage.dart';
import 'package:flutter_monaco/src/assets/web_precache_stub.dart'
    if (dart.library.js_interop) 'package:flutter_monaco/src/assets/web_precache_web.dart';

/// The Flutter asset path where Monaco Editor files are bundled.
///
/// Internal: shared with the platform layer; not exported by the barrel.
const String monacoAssetBaseDir = 'packages/flutter_monaco/assets/monaco';

/// Subdirectory name within application support for extracted assets.
const String monacoCacheSubDir = 'monaco_editor_cache';

/// File name of the default generated page inside the extraction directory.
const String monacoHtmlFileName = 'index.html';

/// Returns the path to the Monaco HTML file for a given configuration.
///
/// Internal: called by the platform WebView controllers; not exported by
/// the barrel. The [cacheKey] is derived from configuration options that
/// affect HTML generation (`MonacoPageConfig.stableCacheKey`), enabling multiple
/// cached HTML variants. Native platforms get
/// `{appSupport}/monaco_editor_cache/monaco-{version}/monaco_{key}.html`
/// (the file itself is written lazily by the WebView controller); web gets
/// the static asset path and ignores [cacheKey] (HTML is generated as a
/// blob URL there).
Future<String> monacoIndexHtmlPath({required String cacheKey}) async {
  if (kIsWeb) {
    return 'assets/$monacoAssetBaseDir/index.html';
  }

  await MonacoAssets.ensureReady();

  return monacoAssetHtmlPath(
    cacheKey: cacheKey,
    assetBaseDir: monacoAssetBaseDir,
    cacheSubDir: monacoCacheSubDir,
    monacoVersion: MonacoAssets.monacoVersion,
  );
}

/// Manages Monaco Editor assets across all platforms.
///
/// This class is the single source of truth for Monaco asset locations,
/// versions, and extraction:
///
/// - **Asset extraction:** Copies bundled Monaco files to the app support
///   directory on native platforms for WebView access.
/// - **Version management:** Tracks the Monaco version and re-extracts on
///   updates.
/// - **Caching:** Avoids redundant extraction and HTML generation.
///
/// ### Platform Behavior
///
/// - **Native (Android/iOS/macOS/Windows):** Assets are extracted from the
///   app bundle to the application support directory on first use. A
///   sentinel file tracks the version to detect when re-extraction is
///   needed.
/// - **Web:** Assets are served directly from the `assets/` directory. No
///   extraction is needed.
///
/// ### Usage
///
/// ```dart
/// // Optional: warm up assets before creating the first editor.
/// await MonacoAssets.ensureReady();
/// ```
///
/// See also:
/// - `MonacoController.create`, which calls [ensureReady] automatically.
/// - [MonacoAssetDiagnostics] for the [assetInfo] shape.
class MonacoAssets {
  /// The Monaco Editor version bundled with this package.
  ///
  /// When this version changes, [ensureReady] will re-extract assets on
  /// native platforms to ensure the correct version is used.
  static const String monacoVersion = '0.57.0';

  static Completer<void>? _initCompleter;

  /// Ensures Monaco assets are extracted and ready for use on native
  /// platforms.
  ///
  /// This method performs the following checks and operations:
  ///
  /// 1. **Existence check:** Verifies `loader.js` exists in the target
  ///    directory
  /// 2. **Version check:** Compares sentinel file content with
  ///    [monacoVersion]
  /// 3. **Extraction:** Copies all assets from the bundle if missing or
  ///    outdated
  ///
  /// ### Thread Safety
  ///
  /// This method is idempotent and thread-safe. Multiple concurrent calls
  /// will share the same [Completer], ensuring extraction happens only
  /// once. Subsequent calls return immediately if assets are already ready.
  ///
  /// ### Web Platform
  ///
  /// On web, this method completes immediately without any file operations,
  /// as assets are served directly from the web server.
  ///
  /// ### Error Handling
  ///
  /// Throws [StateError] if asset extraction fails (e.g., insufficient disk
  /// space or permission issues). The error includes details about which
  /// files failed to copy.
  static Future<void> ensureReady() async {
    if (_initCompleter != null) return _initCompleter!.future;

    final completer = _initCompleter = Completer<void>();

    try {
      await ensureMonacoAssetsReady(
        assetBaseDir: monacoAssetBaseDir,
        cacheSubDir: monacoCacheSubDir,
        htmlFileName: monacoHtmlFileName,
        monacoVersion: monacoVersion,
      );
      // The sentinel guards only the large Monaco `min/` tree. The bridge
      // JavaScript is rewritten on every launch so a package upgrade can
      // never ship stale bridge code (replaces the 2.x
      // `htmlGenerationVersion` cache-bust constant).
      await refreshMonacoBridgeAssets(
        assetBaseDir: monacoAssetBaseDir,
        cacheSubDir: monacoCacheSubDir,
        monacoVersion: monacoVersion,
      );
      completer.complete();
    } catch (e, st) {
      _initCompleter = null;
      completer.completeError(e, st);
    }

    return completer.future;
  }

  /// Prepares this platform so the first editor boots as fast as possible.
  ///
  /// On **native** platforms this is [ensureReady]: Monaco's files are
  /// extracted from the app bundle to local storage (and any extraction
  /// error propagates, exactly as from [ensureReady]).
  ///
  /// On **web** it additionally warms the browser's HTTP cache with the
  /// files the boot will request - the AMD loader, `editor.main.js`/`.css`,
  /// and the hash-named editor chunk (~3.6MB) that dominates a cold first
  /// load. The warmup is best-effort and never throws: if any fetch fails,
  /// the boot simply downloads those files itself as usual. When several
  /// editors boot at once they all hit the warmed cache, so the bundle is
  /// downloaded once no matter how many editors mount.
  ///
  /// Call it early - fire-and-forget from `main()` is the intended use, so
  /// the download overlaps app startup instead of starting when the first
  /// editor mounts:
  ///
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   unawaited(MonacoAssets.precache());
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// For web apps that want the warmup to start even before the Flutter
  /// engine downloads, see the "Web performance" section of the README for
  /// an equivalent `index.html` snippet.
  static Future<void> precache() async {
    await ensureReady();
    if (kIsWeb) {
      await precacheMonacoWebAssets();
    }
  }

  /// Returns typed diagnostics about the extracted Monaco assets.
  ///
  /// Useful for debugging asset extraction issues or displaying version
  /// information in an about dialog.
  ///
  /// ```dart
  /// final info = await MonacoAssets.assetInfo();
  /// print('Monaco ${info.monacoVersion} - '
  ///     '${info.totalSizeMB.toStringAsFixed(2)} MB');
  /// ```
  static Future<MonacoAssetDiagnostics> assetInfo() async {
    return monacoAssetInfo(
      assetBaseDir: monacoAssetBaseDir,
      cacheSubDir: monacoCacheSubDir,
      monacoVersion: monacoVersion,
    );
  }

  /// Deletes all extracted Monaco assets and resets initialization state.
  ///
  /// This method:
  /// 1. Recursively deletes the Monaco asset directory
  /// 2. Clears the in-memory HTML cache
  /// 3. Resets the init state so [ensureReady] will re-extract
  ///
  /// ### Use Cases
  ///
  /// - **Corruption recovery:** If Monaco fails to load, clearing and
  ///   re-extracting may fix the issue.
  /// - **Storage cleanup:** Frees ~5-10MB of disk space.
  /// - **Development:** Forces fresh extraction after updating Monaco
  ///   assets.
  ///
  /// ### Web Platform
  ///
  /// On web, this method only clears the in-memory state since assets are
  /// served directly from the web server and cannot be deleted.
  ///
  /// **Note:** Any existing `MonacoController` instances will become
  /// invalid after clearing. Dispose and recreate them after calling this
  /// method.
  static Future<void> clearCache() async {
    // Let any in-flight ensureReady finish first: deleting the tree while
    // extraction is mid-write leaves whichever finishes last inconsistent
    // (a failure of that extraction is irrelevant to clearing).
    final inFlight = _initCompleter;
    if (inFlight != null && !inFlight.isCompleted) {
      try {
        await inFlight.future;
      } catch (_) {}
    }

    // On web, only clear in-memory caches (no file system access)
    if (kIsWeb) {
      _initCompleter = null;
      debugPrint('[MonacoAssets] Web cache cleared (in-memory only)');
      return;
    }

    await clearMonacoAssetCache(
      assetBaseDir: monacoAssetBaseDir,
      cacheSubDir: monacoCacheSubDir,
      monacoVersion: monacoVersion,
    );

    // Reset the init completer so ensureReady will re-extract.
    _initCompleter = null;
  }
}
