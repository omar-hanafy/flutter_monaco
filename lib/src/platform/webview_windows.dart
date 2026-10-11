part of 'webview_native.dart';

/// WebView implementation for Windows using Microsoft Edge WebView2.
///
/// This controller wraps the `webview_flutter_windows` package to provide Monaco editor
/// hosting on Windows. It requires the WebView2 runtime, which is pre-installed
/// on Windows 11 and available as a separate download for Windows 10.
///
/// ### JavaScript Communication
///
/// Unlike `webview_flutter`, WebView2 uses `chrome.webview.postMessage` for
/// native communication. However, the Monaco HTML defines a `window.flutterChannel`
/// shim that forwards to this API, providing a consistent interface.
///
/// Messages are received via the [ww.WebviewController.webMessage] stream and
/// dispatched to all registered channel handlers in [_channels].
///
/// ### Result Parsing
///
/// WebView2's `ExecuteScript` returns JSON-encoded results, which may need
/// unwrapping. Use [parseWindowsScriptResult] to normalize return values.
///
/// ### Initialization
///
/// The first call to [initialize] may take longer if WebView2 needs to
/// install its runtime. Subsequent initializations are fast.
///
/// ### Page hosting
///
/// The editor page is served from a WebView2 virtual host,
/// `https://flutter-monaco.example/` ([monacoVirtualHostName]), mapped onto
/// the extracted asset cache. WebView2 refuses to let a web worker
/// `importScripts` a `file:` URL, so a page loaded from disk left every
/// Monaco worker hanging: no diff in `MonacoDiffEditor` (issue #43), no
/// links or word suggestions, no JSON/CSS/HTML/TypeScript language service.
/// Over https the workers are ordinary same-origin workers. When the virtual
/// host cannot be used (the mapping call fails, or the first navigation to
/// it fails), the page is loaded from disk as in 3.x, where the page's
/// worker safety net runs the editor worker on the main thread. The page is
/// also loaded from disk when [MonacoPageConfig.allowedConnectSources] names
/// `ws:`/`http:` endpoints off loopback, which a secure https page may not
/// reach (see [connectSourcesNeedInsecurePage]).
///
/// See also:
/// - [FlutterWebViewController] for Android/iOS/macOS implementation.
/// - [ww.WebviewController] for the underlying Windows WebView controller.
/// - [parseWindowsScriptResult] for result normalization.
class WindowsWebViewController extends WebViewController {
  /// Creates a new controller backed by `webview_flutter_windows` (WebView2).
  WindowsWebViewController() : this.withController(ww.WebviewController());

  /// Creates a controller around an existing WebView2 controller.
  ///
  /// Tests pass a fake to observe the virtual host mapping and navigation.
  @visibleForTesting
  WindowsWebViewController.withController(this._controller) : super._();

  @override
  Widget get widget => ww.Webview(_controller);

  final ww.WebviewController _controller;
  final Map<String, void Function(String)> _channels = {};
  StreamSubscription<dynamic>? _webMessageSubscription;
  bool _isInitialized = false;
  bool _disposed = false;

  /// The folder currently mapped to [monacoVirtualHostName], if any.
  String? _mappedCacheRoot;

  /// Set once the virtual host failed in this WebView; later loads use
  /// files directly.
  bool _virtualHostUnavailable = false;

  StreamSubscription<ww.WebErrorStatus>? _navigationErrors;
  StreamSubscription<ww.LoadingState>? _navigationStates;

  /// Provides direct access to the underlying `webview_flutter_windows` controller.
  ///
  /// Use this for advanced operations not exposed by [PlatformWebViewController],
  /// such as custom popup policies or DevTools access.
  ww.WebviewController get windowsController => _controller;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[WindowsWebViewController] Initializing WebView2...');
    await _controller.initialize();
    _isInitialized = true;

    // Set up default configuration
    await _controller.setBackgroundColor(const Color(0xFF1E1E1E));
    await _controller.setPopupWindowPolicy(ww.WebviewPopupWindowPolicy.deny);

    // Set up message handler BEFORE adding any channels
    _setupWebMessageHandler();

    debugPrint('[WindowsWebViewController] WebView2 initialized successfully');
  }

  void _setupWebMessageHandler() {
    _webMessageSubscription?.cancel();

    _webMessageSubscription = _controller.webMessage.listen((
      dynamic rawMessage,
    ) {
      if (kDebugMode) {
        debugPrint(
          '[WindowsWebViewController] Raw message: $rawMessage (${rawMessage.runtimeType})',
        );
      }

      try {
        String messageStr;

        if (rawMessage is String) {
          messageStr = rawMessage;
        } else if (rawMessage is Map) {
          messageStr = json.encode(rawMessage);
        } else {
          messageStr = rawMessage.toString();
        }

        _channels.forEach((channelName, handler) {
          if (kDebugMode) {
            debugPrint(
              '[WindowsWebViewController] Forwarding to channel: $channelName',
            );
          }
          handler(messageStr);
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[WindowsWebViewController] Error handling message: $e');
        }
      }
    });
  }

  /// Loads the given HTML string into the WebView.
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    debugPrint(
      '[WindowsWebViewController] Loading HTML string (length: ${html.length})',
    );
    await _controller.loadStringContent(html);
  }

  @override
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()}) async {
    final htmlFilePath = await monacoIndexHtmlPath(
      cacheKey: page.stableCacheKey(),
    );
    if (connectSourcesNeedInsecurePage(page.allowedConnectSources)) {
      debugPrint(
        '[WindowsWebViewController] allowedConnectSources lists ws:/http: '
        'endpoints that are not on loopback (or *), which an https page may '
        'not reach; loading the editor from file:// as before. Use '
        'wss:/https: to keep the editor on its virtual host.',
      );
      await _loadFromFiles(page);
      return;
    }
    // .../monaco_editor_cache/monaco-<version>/monaco_<key>.html
    final versionDirectory = p.dirname(htmlFilePath);
    if (!await _mapVirtualHost(p.dirname(versionDirectory))) {
      await _loadFromFiles(page);
      return;
    }

    final built = buildVirtualHostMonacoPage(
      versionDirectory: p.basename(versionDirectory),
      htmlFileName: p.basename(htmlFilePath),
      monacoVersion: MonacoAssets.monacoVersion,
      bridgeVersion: await _bridgeFingerprint(versionDirectory),
      customCss: page.customCss,
      allowCdnFonts: page.allowCdnFonts,
      allowedConnectSources: page.allowedConnectSources,
    );
    await writeFileAtomically(htmlFilePath, utf8.encode(built.html));
    _watchVirtualHostNavigation(page);
    debugPrint('[WindowsWebViewController] Loading ${built.url}');
    await _controller.loadUrl(built.url);
  }

  /// Maps [monacoVirtualHostName] onto [cacheRoot], the folder that contains
  /// the versioned `monaco-<version>` directory, so page URLs name the
  /// Monaco version. Returns false when the virtual host cannot be used.
  ///
  /// The access kind is `deny`: the mapping serves only same-origin
  /// requests, which is everything this page makes - the page, its scripts,
  /// styles and fonts are all under the virtual host, and Monaco's `blob:`
  /// workers inherit the page's origin, so their `importScripts` is
  /// same-origin too. No other origin can read the cache.
  Future<bool> _mapVirtualHost(String cacheRoot) async {
    if (_virtualHostUnavailable) return false;
    if (_mappedCacheRoot == cacheRoot) return true;
    try {
      if (_mappedCacheRoot != null) {
        await _controller.removeVirtualHostNameMapping(monacoVirtualHostName);
      }
      await _controller.addVirtualHostNameMapping(
        monacoVirtualHostName,
        cacheRoot,
        ww.WebviewHostResourceAccessKind.deny,
      );
      _mappedCacheRoot = cacheRoot;
      return true;
    } catch (e) {
      _mappedCacheRoot = null;
      _virtualHostUnavailable = true;
      debugPrint(
        '[WindowsWebViewController] Virtual host unavailable ($e); loading '
        'the editor from file:// with Monaco workers on the main thread.',
      );
      return false;
    }
  }

  /// Loads the page from disk, as 3.x did (absolute `file://` URLs).
  Future<void> _loadFromFiles(MonacoPageConfig page) async {
    // No earlier virtual-host navigation may trigger a second fallback.
    _stopNavigationWatch();
    final htmlFilePath = await _ensureHtmlFile(page, isWindows: true);
    await _controller.loadUrl(Uri.file(htmlFilePath).toString());
  }

  /// Fingerprint of the bridge scripts on disk, as the virtual host will
  /// serve them (see [monacoBridgeFingerprint]).
  Future<String> _bridgeFingerprint(String versionDirectory) async {
    final scripts = <String, List<int>?>{};
    for (final name in monacoBridgeScripts) {
      try {
        scripts[name] = await File(p.join(versionDirectory, 'bridge', name))
            .readAsBytes();
      } on FileSystemException {
        scripts[name] = null;
      }
    }
    return monacoBridgeFingerprint(scripts);
  }

  /// Falls back to [_loadFromFiles] when the navigation to the virtual host
  /// fails.
  ///
  /// `webview_flutter_windows` reports a mapping that WebView2 rejected
  /// (an old runtime without `ICoreWebView2_3`, for instance) as success,
  /// and the page's host name then never resolves. WebView2 reports a
  /// failed navigation as a load error immediately followed by
  /// `navigationCompleted`; a navigation superseded by a newer load
  /// completes as `operationCanceled` and is ignored.
  void _watchVirtualHostNavigation(MonacoPageConfig page) {
    _stopNavigationWatch();
    ww.WebErrorStatus? error;
    _navigationErrors = _controller.onLoadError.listen((status) {
      error = status;
    });
    _navigationStates = _controller.loadingState.listen((state) {
      if (state != ww.LoadingState.navigationCompleted) return;
      final failure = error;
      error = null;
      if (failure == ww.WebErrorStatus.operationCanceled) return;
      _stopNavigationWatch();
      if (failure == null || _disposed) return;
      _virtualHostUnavailable = true;
      debugPrint(
        '[WindowsWebViewController] Virtual host navigation failed '
        '($failure); loading the editor from file://.',
      );
      unawaited(
        _loadFromFiles(page).catchError((Object e) {
          debugPrint('[WindowsWebViewController] file:// fallback failed: $e');
        }),
      );
    });
  }

  void _stopNavigationWatch() {
    _navigationErrors?.cancel();
    _navigationStates?.cancel();
    _navigationErrors = null;
    _navigationStates = null;
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    await _controller.setBackgroundColor(color);
  }

  @override
  Future<void> setInteractionEnabled(bool enabled) async {
    // No-op on Windows as WebView2 respects Flutter's overlay stacking.
  }

  @override
  Future<NativeFocusResult> requestNativeFocus() async {
    if (!_isInitialized || _disposed) return NativeFocusResult.failed;
    final alreadyOwned = _controller.hasNativeFocus;
    // Always run the handoff, even when the focus flag reads true: WebView2's
    // MoveFocus is what re-arms keyboard routing after a native boundary.
    // Moves real Win32 keyboard focus to the WebView2 control so that
    // subsequent in-page focus calls (and typing) actually work.
    await _controller.focus();
    return alreadyOwned
        ? NativeFocusResult.alreadyOwned
        : NativeFocusResult.granted;
  }

  @override
  Future<bool?> hasNativeInputFocus() async {
    if (!_isInitialized || _disposed) return null;
    return _controller.hasNativeFocus;
  }

  @override
  Future<void> releaseNativeFocus() async {
    if (!_isInitialized || _disposed) return;
    if (_controller.hasNativeFocus) {
      await ww.WebviewController.releaseFocus();
    }
  }

  @override
  Future<void> enableJavaScript() async {}

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      return await _controller.executeScript(script);
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS execution error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    try {
      final result = await _controller.executeScript(script);
      return parseWindowsScriptResult(result);
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    debugPrint(
      '[WindowsWebViewController] Registering handler for channel: $name',
    );

    // Store the handler - HTML already defines window.flutterChannel
    _channels[name] = onMessage;

    // No need to inject JavaScript - the HTML already has the channel defined
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
    return null; // No-op in JS; HTML owns flutterChannel
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[WindowsWebViewController] Disposing...');
    _stopNavigationWatch();
    _webMessageSubscription?.cancel();
    _channels.clear();
    if (_isInitialized) {
      _controller.dispose();
    }
  }
}
