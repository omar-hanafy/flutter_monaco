import 'dart:convert';

/// A CSP scheme-source, e.g. `wss:` or `https:`.
final RegExp _cspSchemeSource = RegExp(r'^[A-Za-z][A-Za-z0-9+.\-]*:$');

/// A CSP host-source: `[scheme "://"] host [":" port] [path]`, where host is
/// `*`, an optionally `*.`-prefixed DNS name or IPv4 address, or a bracketed
/// IPv6 literal, port is digits or `*`, and the path holds only URL path
/// characters.
///
/// An allow-list of the CSP source-expression grammar (CSP3 section 2.3.1)
/// rather than a deny-list of dangerous characters: every character outside
/// it is refused, so nothing that HTML decodes inside the policy attribute
/// (`&#59;` is `;`, `&#32;` a space) and nothing that ends a source expression
/// (whitespace, `;`, `,`, quotes) can reach the policy. The path deliberately
/// omits `&`, `'`, `;` and `,`, which the grammar would otherwise allow.
final RegExp _cspHostSource = RegExp(
  r'^(?:[A-Za-z][A-Za-z0-9+.\-]*://)?'
  r'(?:\*|(?:\*\.)?[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)*\.?|\[[0-9A-Fa-f:.]+\])'
  r'(?::(?:[0-9]+|\*))?'
  r'(?:/(?:[A-Za-z0-9\-._~!$()*+=:@]|%[0-9A-Fa-f]{2})*)*$',
);

/// Whether [source] may be spliced into the page's CSP.
///
/// The single definition of what is admissible, applied to every source
/// expression that reaches the policy - both caller-supplied
/// ([sanitizeConnectSources]) and derived from asset URLs ([_cspAssetOrigins]).
bool _isSafeCspSource(String source) =>
    _cspSchemeSource.hasMatch(source) || _cspHostSource.hasMatch(source);

/// Validates extra CSP `connect-src` source expressions.
///
/// Returns the non-empty entries, ready to append to the `connect-src`
/// directive. Throws [ArgumentError] for any entry that is not a single CSP
/// scheme-source or host-source (see [_cspHostSource]): whitespace, quotes,
/// `;`, `,`, `&`, `#`, `<` and `>` can never reach the policy attribute, so
/// no entry can widen another directive or smuggle in a new one.
List<String> sanitizeConnectSources(List<String> sources) {
  final cleaned = <String>[];
  for (final raw in sources) {
    final source = raw.trim();
    if (source.isEmpty) continue;
    if (!_isSafeCspSource(source)) {
      throw ArgumentError.value(
        raw,
        'allowedConnectSources',
        'Each entry must be a single CSP source expression: a scheme such '
            'as "wss:", or a host source such as "wss://lsp.example.com" or '
            '"ws://127.0.0.1:3000"',
      );
    }
    cleaned.add(source);
  }
  return cleaned;
}

/// CSP host-sources for every origin the generated page fetches from.
///
/// The policy must never depend on `'self'`. This document is usually
/// delivered over a local scheme - a `blob:` URL on web (see
/// `webview_web.dart`) and a `file:` URL on Android, Apple platforms and the
/// Windows fallback (see `webview_native.dart`) - and `'self'` is not
/// dependable there: Firefox does not resolve it to the creating document's
/// origin inside a `blob:` document, so every same-origin fetch the page
/// makes (`loader.js`, the bridge scripts, `editor.main.css`, the workers) is
/// blocked while Chrome allows it. File-served pages name `file:` in every
/// directive; pages with http(s) assets (web, and the WebView2 virtual host
/// on Windows) name the origins they actually reference.
///
/// Only absolute http(s) URLs carry an origin, so relative and `file:` asset
/// paths contribute nothing and leave the policy unchanged.
/// [Uri.origin] rather than `authority` is deliberate: it is
/// `scheme://host[:port]` with no userinfo, which is the only form valid as a
/// CSP host-source - `authority` would emit `https://user:pass@host`, an
/// expression browsers discard, silently restoring the failure.
List<String> _cspAssetOrigins(List<String> assetUrls) {
  final origins = <String>{};
  for (final url in assetUrls) {
    if (!_isHttpUrl(url)) continue;
    final origin = Uri.parse(url).origin;
    if (_isSafeCspSource(origin)) origins.add(origin);
  }
  return origins.toList()..sort();
}

/// Whether [url] is an absolute http(s) URL with a host.
bool _isHttpUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// Encodes [value] as a JavaScript string literal that is safe inside an
/// inline `<script>` element.
///
/// Asset paths come from the file system (a Windows profile such as
/// `C:\Users\O'Brien`, an app named "Bob's Editor") or from the web page's
/// base URL, so they may hold any character a quoted literal or the HTML
/// parser treats specially. JSON string syntax is valid JavaScript; `<` is
/// escaped so a value can never form `</script>` or `<!--`, and the two
/// Unicode line terminators so older engines accept the literal.
String _jsString(String value) =>
    jsonEncode(value)
        .replaceAll('<', r'\u003c')
        .replaceAll('\u2028', r'\u2028')
        .replaceAll('\u2029', r'\u2029');

/// Escapes [value] for use inside a double-quoted HTML attribute.
///
/// `&` must be escaped too: the parser decodes character references in
/// attribute values, so an unescaped `&#59;` in the CSP `content` would reach
/// the policy as `;`.
String _htmlAttribute(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Neutralizes `</` sequences so injected CSS can never terminate its
/// `<style>` element early (an embedded `</style>` would promote the rest
/// of the block to markup, i.e. script injection). `\/` is a valid CSS
/// escape for `/`, so legitimate CSS - including content strings such as
/// `"</b>"` - keeps its meaning.
String _escapeStyleText(String css) => css.replaceAll('</', r'<\/');

/// The bridge JavaScript files referenced by the generated page, in load
/// order. `boot.js` must stay last: it runs the installers the other files
/// define. `viewport-fit.js` is only emitted on web.
const List<String> monacoBridgeScripts = [
  'core.js',
  'focus.js',
  'editor-api.js',
  'diff-api.js',
  'scroll-handoff.js',
  'lsp.js',
  // 'viewport-fit.js' (web only, inserted by the builder)
  'boot.js',
];

/// Builds the HTML document that hosts the Monaco Editor.
///
/// The page contains only platform shims and `<script src>` references; the
/// bridge logic lives in real JavaScript files under `assets/monaco/bridge/`
/// (see upcoming/v3.md Section 6.7). [bridgeBase] is the URL prefix for those
/// files, without a trailing slash: relative (`bridge`) on Android/iOS/macOS,
/// `https://<virtual host>/monaco-<version>/bridge` on Windows (an absolute
/// `file://` directory URL when the virtual host is unavailable), and a
/// resolved asset URL on web.
///
/// [monacoVersion] is stamped into `window.__FM_PAGE` for the protocol
/// handshake.
/// [vsPath] is the path to the Monaco `vs/` directory (platform-specific,
/// same semantics as 2.3.0). [messageToken] is the web postMessage
/// authentication token. [customCss] is injected into a `<style>` tag.
/// [allowCdnFonts] relaxes CSP for `https:` styles/fonts.
/// [allowedConnectSources] extends the CSP `connect-src` list and is
/// validated by [sanitizeConnectSources].
/// [bridgeVersion], when given, is appended to every bridge script URL as
/// `?v=<bridgeVersion>`. Hosts that serve the page over HTTP pass a content
/// fingerprint of the bridge files: those files are rewritten in place under
/// the same Monaco version directory when the package is upgraded, and an
/// HTTP cache would otherwise keep serving the previous bridge.
///
/// Pages whose assets are not served over http(s) - every native page except
/// the Windows virtual host - also carry the worker safety net described at
/// [_workerSafetyNetScript].
String buildMonacoIndexHtml({
  required String vsPath,
  required String bridgeBase,
  required String monacoVersion,
  bool isWindows = false,
  bool isIosOrMacOS = false,
  bool isWeb = false,
  String? messageToken,
  String? customCss,
  bool allowCdnFonts = false,
  List<String> allowedConnectSources = const [],
  String? bridgeVersion,
}) {
  final extraConnectSources = sanitizeConnectSources(allowedConnectSources);

  // A native page loaded from the file system (Android, Apple platforms,
  // and Windows when its virtual host is unavailable). The WebView2 virtual
  // host serves the same page over https, like web.
  final servedFromFiles =
      !isWeb && !(_isHttpUrl(vsPath) && _isHttpUrl(bridgeBase));

  // The page's whole fetch surface, named explicitly so nothing load-bearing
  // depends on 'self' (see _cspAssetOrigins). Both asset roots contribute:
  // the Monaco bundle and the bridge scripts are resolved by separate
  // functions on web and are same-origin only by convention, so deriving the
  // policy from one of them would leave the other unadmitted.
  final selfSources = <String>[
    "'self'",
    ..._cspAssetOrigins([vsPath, bridgeBase]),
  ];

  // `file:` is admitted only where assets are files. Web keeps the policy it
  // has always had; the Windows virtual host page loads nothing from disk
  // directly, so it does not admit `file:` at all.
  final fileSources = servedFromFiles || isWeb
      ? const ['file:']
      : const <String>[];

  // Every directive is emitted through here, so one added later cannot
  // silently omit the asset origins. `default-src` is no safety net for
  // that: it only backstops directives that are NOT declared.
  String directive(String name, List<String> extra) =>
      '$name ${[...selfSources, ...extra].join(' ')}';

  final contentSecurityPolicy =
      '${[
        directive('default-src', [...fileSources, "'unsafe-inline'", "'unsafe-eval'"]),
        directive('script-src', [...fileSources, "'unsafe-inline'", "'unsafe-eval'"]),
        directive('style-src', ["'unsafe-inline'", if (allowCdnFonts) 'https:']),
        directive('font-src', [...fileSources, 'data:', if (allowCdnFonts) 'https:']),
        directive('img-src', ['data:', 'blob:', ...fileSources]),
        directive('worker-src', ['blob:']),
        directive('connect-src', ['blob:', ...extraConnectSources]),
      ].join('; ')};';

  final platform = isWeb
      ? 'web'
      : isWindows
      ? 'windows'
      : isIosOrMacOS
      ? 'apple'
      : 'other';

  // Page facts the external bridge files read instead of having values
  // interpolated into their source (which must stay static assets).
  final pageConfig =
      '''
<script>
  window.__FM_PAGE = {
    platform: ${_jsString(platform)},
    vsPath: ${_jsString(vsPath)},
    monacoVersion: ${_jsString(monacoVersion)},
    token: ${messageToken == null ? 'null' : _jsString(messageToken)}
  };
</script>
''';

  // Channel shims. They must run before any external script loads, so they
  // stay inline in the head. No page sets MonacoEnvironment: editor.main.js
  // assigns its own (a getWorker covering every worker label) while it
  // loads, replacing anything set earlier.
  String platformScript;

  if (isWeb) {
    platformScript =
        '''
<script>
  console.log('[Web Init] Setting up for iframe mode');
  window.flutterChannel = {
    postMessage: function(msg) {
      window.parent.postMessage(msg, '*');
    }
  };
  window.flutterMonacoToken = ${_jsString(messageToken ?? '')};
  window.flutterMonacoPostMessage = function(message) {
    var token = window.flutterMonacoToken;
    if (typeof message !== 'string') {
      if (token && message && typeof message === 'object') {
        message._flutterToken = token;
      }
      message = JSON.stringify(message);
    } else {
      try {
        var parsed = JSON.parse(message);
        if (parsed && typeof parsed === 'object') {
          if (token) parsed._flutterToken = token;
          message = JSON.stringify(parsed);
        }
      } catch (_) {}
    }
    if (window.flutterChannel && window.flutterChannel.postMessage) {
      window.flutterChannel.postMessage(message);
    }
  };
  console.log('[Web Init] flutterChannel created successfully');
</script>
''';
  } else if (isWindows) {
    platformScript = '''
<script>
  // Windows: Create flutterChannel immediately when document is created
  console.log('[Windows Init] Creating flutterChannel on document creation');
  window.flutterChannel = {
    postMessage: function(msg) {
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(msg);
      } else {
        console.error('[flutterChannel] WebView2 API not available!');
      }
    }
  };
  console.log('[Windows Init] flutterChannel created successfully');
</script>
''';
  } else {
    // Android, iOS and macOS: webview_flutter injects flutterChannel.
    platformScript = '';
  }

  final workerSafetyNet = servedFromFiles
      ? '<script>\n$_workerSafetyNetScript</script>\n'
      : '';
  // Runs after loader.js has defined the global AMD `require` and before
  // boot.js uses it.
  final editorMainGate = servedFromFiles
      ? '    <script>\n$_editorMainGateScript    </script>\n'
      : '';

  final bridgeQuery = bridgeVersion == null
      ? ''
      : '?v=${Uri.encodeQueryComponent(bridgeVersion)}';
  final bridgeScriptNames = [
    ...monacoBridgeScripts.sublist(0, monacoBridgeScripts.length - 1),
    if (isWeb) 'viewport-fit.js',
    monacoBridgeScripts.last,
  ];
  final bridgeScriptTags = bridgeScriptNames
      .map(
        (name) =>
            '    <script src="${_htmlAttribute('$bridgeBase/$name$bridgeQuery')}"></script>',
      )
      .join('\n');

  return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta
      http-equiv="Content-Security-Policy"
      content="${_htmlAttribute(contentSecurityPolicy)}"
    />
    <!-- NOTE: connect-src intentionally limits in-page requests to this
         page's own asset origins and blob:. Opt into remote endpoints (e.g.
         WebSocket language servers) via the allowedConnectSources parameter
         instead of editing this policy. -->
    <script>
      // A CSP block is this page's most likely load failure: it is served
      // over a local scheme and fetches everything else from the app origin.
      // Unrecorded, it surfaces only as "Failed to load Monaco loader.js",
      // which names neither the directive that refused nor the URL it
      // refused - the difference between a one-line report and a
      // cross-browser hunt. Must precede every governed load.
      window.__FM_CSP_VIOLATIONS = [];
      document.addEventListener('securitypolicyviolation', function (e) {
        if (window.__FM_CSP_VIOLATIONS.length >= 5) return;
        window.__FM_CSP_VIOLATIONS.push(
          (e.effectiveDirective || e.violatedDirective) + ' blocked ' + e.blockedURI
        );
      });
      window.__fmCspDetail = function () {
        var v = window.__FM_CSP_VIOLATIONS;
        return v && v.length ? ' (CSP: ' + v.join('; ') + ')' : '';
      };
    </script>
    <style>
      html, body, #editor-container {
        width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden;
      }
      ${isWeb ? '''
      /* Scroll containment for the iframe embed (issue #11). Monaco only
         preventDefault()s touches that start on its text surface or
         scrollbar sliders; touches that start on the margin, a scrollbar
         track, or before Monaco loads fall through to the browser's native
         pan. Nothing in this document can scroll, so mobile Safari chains
         that pan to the host Flutter page. Declaring the policy here removes
         the native pan for every touch in this document; Monaco's own touch
         scrolling is JS-driven and unaffected by touch-action. */
      html, body, #editor-container {
        touch-action: none;
        overscroll-behavior: none;
      }''' : ''}
    </style>
    ${customCss != null ? '<style id="flutter-monaco-custom">\n${_escapeStyleText(customCss)}\n</style>' : ''}
    $pageConfig
    $workerSafetyNet
    $platformScript
  </head>
  <body>
    <div id="editor-container"></div>

    <script>
      var require = { paths: { vs: ${_jsString(vsPath)} } };
      console.log('[Monaco HTML] Require config set. VS_PATH is: ' + require.paths.vs);
    </script>

    ${isWeb ? '''
    <script>
      // Web: Load loader.js dynamically to ensure proper timing in blob URL context
      var loaderScript = document.createElement('script');
      loaderScript.src = ${_jsString('$vsPath/loader.js')};
      loaderScript.onload = function() {
        console.log('[Monaco HTML] loader.js dynamically loaded.');
        window._monacoLoaderReady = true;
        if (window._initMonacoWhenReady) window._initMonacoWhenReady();
      };
      loaderScript.onerror = function() {
        // This error event and securitypolicyviolation are dispatched
        // independently, so yield once: a CSP block is then already recorded
        // when the report is built. The host is waiting on a 20s readiness
        // timeout, so one task is free.
        setTimeout(function () {
          var detail = window.__fmCspDetail ? window.__fmCspDetail() : '';
          console.error('[Monaco HTML] FATAL: loader.js FAILED TO LOAD.' + detail);
          var payload = { event: 'error', message: 'Failed to load Monaco loader.js' + detail };
          if (window.flutterMonacoPostMessage) {
            window.flutterMonacoPostMessage(payload);
          } else if (window.flutterChannel) {
            window.flutterChannel.postMessage(JSON.stringify(payload));
          }
        }, 0);
      };
      document.head.appendChild(loaderScript);
    </script>
    ''' : '''
    <script src="${_htmlAttribute('$vsPath/loader.js')}"
            onload="console.log('[Monaco HTML] loader.js successfully loaded.')"
            onerror="console.error('[Monaco HTML] FATAL: loader.js FAILED TO LOAD.' + (window.__fmCspDetail ? window.__fmCspDetail() : ''))"
    ></script>
    '''}
$editorMainGate
$bridgeScriptTags
  </body>
</html>
''';
}

/// Inline page script that keeps Monaco's web workers from hanging on hosts
/// where a worker cannot load scripts from `file:` URLs.
///
/// Monaco 0.57's `editor.main.js` assigns `self.MonacoEnvironment =
/// { getWorker }`, which starts every worker as a `blob:` worker that
/// `importScripts` its bundle from the page's asset directory and then posts
/// `vscode-worker-ready`. A WebView2 page loaded from `file:` (the Windows
/// fallback when the virtual host is unavailable), like desktop Chromium,
/// rejects that `importScripts`: the worker never reports ready, Monaco's
/// first request to it never settles, and diffs, links, word suggestions and
/// every language-service request wait forever. Monaco runs the editor
/// worker on the main thread only when creating the worker *throws*
/// (`_getOrCreateWorker` catches it); a returned worker or promise that
/// later fails is never retried.
///
/// The script is a safety net for those hosts. It does nothing unless the
/// page is a `file:` page. It then probes once whether a `blob:` worker can
/// `importScripts` a bundled script (`vs/loader.js`: Monaco's AMD loader,
/// always bundled, already loaded by this page and written to run inside a
/// worker), and wraps the `getWorker` that `editor.main.js` assigns:
///
/// - Workers can load scripts (as on WKWebView and Android WebView):
///   Monaco's own `getWorker` runs unchanged.
/// - They cannot: `getWorker` throws. The editor worker then runs on the
///   main thread, so diffs, links and word suggestions still work. The
///   JSON, CSS, HTML and TypeScript language services have no main-thread
///   version; for them the error carries Monaco's cancellation shape
///   (`name` and `message` `Canceled`), which Monaco treats as "no result"
///   rather than rethrowing as an uncaught error on every edit and hover.
///   One console warning per worker label says why.
///
/// No worker can be requested before the probe answers: Monaco's refusal
/// would stick (the TypeScript client caches the failure for the life of
/// the page, the editor worker stays on the main thread until it idles),
/// so [_editorMainGateScript] holds the `editor.main` load until then. A
/// request that still arrives early is refused like an incapable host's.
///
/// `window.__FM_WORKERS` records the outcome (`mode` is `probing`,
/// `workers` or `main-thread`) for diagnostics.
const String _workerSafetyNetScript = r'''
  (function () {
    if (location.protocol !== 'file:') return;
    var page = window.__FM_PAGE || {};
    // The labels editor.main.js routes to a language-service bundle; every
    // other label is the editor worker.
    var languageLabels = {
      json: true, css: true, scss: true, less: true, html: true,
      handlebars: true, razor: true, typescript: true, javascript: true
    };
    var status = (window.__FM_WORKERS = { mode: 'probing', detail: null });
    var waiters = [];
    // Runs [callback] once the probe has answered (at once if it has).
    status.whenSettled = function (callback) {
      if (status.mode === 'probing') waiters.push(callback);
      else callback();
    };
    var settle = function (mode, detail) {
      if (status.mode !== 'probing') return;
      status.mode = mode;
      status.detail = detail;
      if (mode === 'main-thread') {
        console.warn('[flutter_monaco] Web workers cannot load scripts on this page (' +
          detail + '). The editor worker runs on the main thread; the JSON, CSS, ' +
          'HTML and TypeScript language services are unavailable.');
      }
      var pending = waiters;
      waiters = [];
      for (var i = 0; i < pending.length; i++) pending[i]();
    };
    try {
      var probeUrl = new URL(page.vsPath + '/loader.js', document.baseURI).href;
      var source = 'try { importScripts(' + JSON.stringify(probeUrl) + '); ' +
        'postMessage("ok"); } catch (e) { ' +
        'postMessage("importScripts failed: " + (e && e.name)); }';
      var blobUrl = URL.createObjectURL(new Blob([source], { type: 'text/javascript' }));
      var probe = new Worker(blobUrl);
      var timer;
      var finish = function (mode, detail) {
        clearTimeout(timer);
        probe.onmessage = null;
        probe.onerror = null;
        probe.terminate();
        URL.revokeObjectURL(blobUrl);
        settle(mode, detail);
      };
      // Bounds how long the editor.main gate below can delay boot.
      timer = setTimeout(function () {
        finish('main-thread', 'the worker check timed out');
      }, 4000);
      probe.onmessage = function (event) {
        finish(event.data === 'ok' ? 'workers' : 'main-thread', String(event.data));
      };
      probe.onerror = function (event) {
        if (event && event.preventDefault) event.preventDefault();
        finish('main-thread', 'the worker check failed: ' + (event && event.message));
      };
    } catch (e) {
      settle('main-thread', 'the worker check could not start: ' + e);
    }

    var warned = {};
    var unavailable = function (label) {
      var language = languageLabels[label] === true;
      if (!warned[label]) {
        warned[label] = true;
        console.warn('[flutter_monaco] No web worker for "' + label + '" (' +
          (status.mode === 'probing'
            ? 'the worker check has not finished'
            : 'workers cannot load scripts on this page') + '); ' +
          (language
            ? 'its language service is unavailable.'
            : 'it runs on the main thread.'));
      }
      if (language) {
        var canceled = new Error('Canceled');
        canceled.name = 'Canceled';
        return canceled;
      }
      return new Error('flutter_monaco: no web worker for "' + label +
        '"; Monaco runs it on the main thread.');
    };

    var environment;
    Object.defineProperty(self, 'MonacoEnvironment', {
      configurable: true,
      enumerable: true,
      get: function () { return environment; },
      set: function (value) {
        if (value && typeof value.getWorker === 'function') {
          var getWorker = value.getWorker;
          value.getWorker = function (workerId, label) {
            if (status.mode === 'workers') return getWorker.apply(this, arguments);
            throw unavailable(label);
          };
        }
        environment = value;
      }
    });
  })();
''';

/// Inline page script, on the same pages as [_workerSafetyNetScript], that
/// defers `require([...], callback)` calls on the global AMD `require` -
/// boot.js's load of `vs/editor/editor.main` - until the worker probe has
/// answered, so Monaco never asks for a worker while the answer is unknown.
///
/// The probe starts in the page head and normally answers before the
/// bridge scripts finish loading, so this rarely waits; the probe's own
/// timeout bounds the wait. Only the global function is wrapped: the
/// loader keeps its own reference for the `require` that modules receive,
/// and every other call form and property (`config`, `toUrl`, ...) passes
/// straight through.
const String _editorMainGateScript = r'''
      (function () {
        var status = window.__FM_WORKERS;
        var amdRequire = window.require;
        if (!status || typeof status.whenSettled !== 'function') return;
        if (typeof amdRequire !== 'function') return;
        var gated = function (dependencies) {
          var receiver = this;
          var args = arguments;
          if (status.mode === 'probing' && Array.isArray(dependencies)) {
            status.whenSettled(function () { amdRequire.apply(receiver, args); });
            return;
          }
          return amdRequire.apply(receiver, args);
        };
        for (var key in amdRequire) {
          if (Object.prototype.hasOwnProperty.call(amdRequire, key)) {
            gated[key] = amdRequire[key];
          }
        }
        window.require = gated;
      })();
''';
