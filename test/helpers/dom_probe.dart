/// DOM inspection helpers for web-only widget tests; the non-web stubs throw.
library;

export 'dom_probe_stub.dart' if (dart.library.js_interop) 'dom_probe_web.dart';
