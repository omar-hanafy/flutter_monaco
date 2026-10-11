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
}) {
  final extraConnectSources = sanitizeConnectSources(allowedConnectSources);

  // The page's whole fetch surface, named explicitly so nothing load-bearing
  // depends on 'self' (see _cspAssetOrigins). Both asset roots contribute:
  // the Monaco bundle and the bridge scripts are resolved by separate
  // functions on web and are same-origin only by convention, so deriving the
  // policy from one of them would leave the other unadmitted.
  final selfSources = <String>[
    "'self'",
    ..._cspAssetOrigins([vsPath, bridgeBase]),
  ];

  // Every directive is emitted through here, so one added later cannot
  // silently omit the asset origins. `default-src` is no safety net for
  // that: it only backstops directives that are NOT declared.
  String directive(String name, List<String> extra) =>
      '$name ${[...selfSources, ...extra].join(' ')}';

  final contentSecurityPolicy =
      '${[
        directive('default-src', ['file:', "'unsafe-inline'", "'unsafe-eval'"]),
        directive('script-src', ['file:', "'unsafe-inline'", "'unsafe-eval'"]),
        directive('style-src', ["'unsafe-inline'", if (allowCdnFonts) 'https:']),
        directive('font-src', ['file:', 'data:', if (allowCdnFonts) 'https:']),
        directive('img-src', ['data:', 'blob:', 'file:']),
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

  final bridgeScriptNames = [
    ...monacoBridgeScripts.sublist(0, monacoBridgeScripts.length - 1),
    if (isWeb) 'viewport-fit.js',
    monacoBridgeScripts.last,
  ];
  final bridgeScriptTags = bridgeScriptNames
      .map(
        (name) =>
            '    <script src="${_htmlAttribute('$bridgeBase/$name')}"></script>',
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

$bridgeScriptTags
  </body>
</html>
''';
}
