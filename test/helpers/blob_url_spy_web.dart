import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Wraps `URL.createObjectURL` so a test can count the blob URLs created
/// after this call. Returns the counter; the wrapper forwards to the real
/// implementation and stays installed for the rest of the test run.
int? Function() spyOnCreateObjectUrl() {
  final url = globalContext['URL']! as JSObject;
  final original = url['createObjectURL']! as JSFunction;
  var count = 0;
  url['createObjectURL'] = ((JSAny blob) {
    count++;
    return original.callAsFunction(url, blob);
  }).toJS;
  return () => count;
}
