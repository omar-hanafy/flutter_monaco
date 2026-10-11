/// Counts `URL.createObjectURL` calls on web; reports `null` elsewhere.
library;

export 'blob_url_spy_stub.dart'
    if (dart.library.js_interop) 'blob_url_spy_web.dart';
