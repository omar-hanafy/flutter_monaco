/// A minimal Content-Security-Policy parser and matcher for the generated
/// editor page.
///
/// Substring assertions on the policy test its formatting rather than its
/// meaning: they break when sources are reordered, and they pass while a URL
/// the page actually fetches goes unadmitted. This models what a browser
/// does instead - with one deliberate deviation, see [admitsWithoutSelf].
library;

/// The policy carried by the page's `<meta http-equiv>` element.
class PageCsp {
  PageCsp._(this.directives);

  /// Parses the CSP out of [html]. The policy can never contain a `"`
  /// (source expressions are validated), so the attribute is delimited
  /// unambiguously.
  factory PageCsp.fromHtml(String html) {
    final match = RegExp(
      r'http-equiv="Content-Security-Policy"\s*content="([^"]*)"',
      dotAll: true,
    ).firstMatch(html);
    if (match == null) {
      throw StateError('No Content-Security-Policy meta element in the page');
    }
    final directives = <String, List<String>>{};
    for (final part in match.group(1)!.split(';')) {
      final tokens = part.trim().split(RegExp(r'\s+'));
      if (tokens.isEmpty || tokens.first.isEmpty) continue;
      directives[tokens.first] = tokens.skip(1).toList();
    }
    return PageCsp._(Map.unmodifiable(directives));
  }

  /// Directive name to its source expressions, in declared order.
  final Map<String, List<String>> directives;

  /// The declared fetch directives, excluding the `default-src` fallback.
  Iterable<String> get fetchDirectives =>
      directives.keys.where((name) => name != 'default-src');

  /// Whether [directive] admits [url] **without** relying on `'self'`.
  ///
  /// `'self'` is treated as matching nothing. That is exactly Firefox's
  /// behaviour inside the `blob:` document this page is served from, and
  /// asserting against it is what proves the page does not depend on a
  /// keyword whose meaning varies by browser and delivery scheme.
  ///
  /// Falls back to `default-src` when [directive] is not declared, as a
  /// browser does for fetch directives.
  bool admitsWithoutSelf(String directive, String url) {
    final sources = directives[directive] ?? directives['default-src'] ?? [];
    return sources.any((source) => _sourceMatches(source, url));
  }

  static bool _sourceMatches(String source, String url) {
    // Keyword sources ('self', 'unsafe-inline', 'unsafe-eval') never admit a
    // URL here: 'self' is inert by design, the others govern inline content.
    if (source.startsWith("'")) return false;

    final target = Uri.tryParse(url);
    if (target == null) return false;

    // Scheme-source, e.g. `file:`, `data:`, `blob:`, `https:`.
    if (!source.contains('//')) {
      return source.endsWith(':') &&
          source.substring(0, source.length - 1) == target.scheme;
    }

    // Host-source, e.g. `https://app.example` or `ws://127.0.0.1:3000`.
    final expected = Uri.tryParse(source);
    if (expected == null) return false;
    return expected.scheme == target.scheme &&
        expected.host == target.host &&
        expected.port == target.port;
  }
}

/// Every script URL the generated page references literally: `<script src>`
/// attributes plus the dynamically assigned `loaderScript.src` used on web.
///
/// Derived from the page rather than restated as literals, so a `<script>`
/// added later pointing at a new asset root is covered automatically.
List<String> scriptUrlsIn(String html) => [
  ...RegExp(r'<script[^>]*\ssrc="([^"]+)"')
      .allMatches(html)
      .map((m) => m.group(1)!),
  ...RegExp(r"""\.src\s*=\s*'([^']+)'""")
      .allMatches(html)
      .map((m) => m.group(1)!),
];
