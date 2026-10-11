import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/src/common/monaco_page_config.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';

/// Matcher function type for determining if a script should trigger an action.
typedef ScriptMatcher = bool Function(String script);

/// Resolver function type for returning results for scripts.
typedef ScriptResultResolver = Object? Function(String script);

/// A fake implementation of [PlatformWebViewController] for testing.
///
/// This fake allows tests to:
/// - Track executed JavaScript scripts
/// - Enqueue specific results for scripts
/// - Simulate errors
/// - Emit messages to channels
/// - Verify channel registration
class FakePlatformWebViewController implements PlatformWebViewController {
  /// Creates a fake WebView controller.
  ///
  /// [widget] - Optional widget to return from [widget] getter.
  FakePlatformWebViewController({Widget? widget})
    : _widget = widget ?? const SizedBox.shrink();

  /// All executed JavaScript scripts in order.
  final List<String> executed = [];

  /// Registered channels and their handlers.
  final Map<String, void Function(String)> _channels = {};

  final Widget _widget;

  /// Whether [initialize] was called.
  bool initialized = false;

  /// Whether [enableJavaScript] was called.
  bool jsEnabled = false;

  /// Whether [dispose] was called.
  bool disposed = false;

  /// Whether interaction is currently enabled.
  bool interactionEnabled = true;

  /// When set, [setBackgroundColor] throws this error instead of recording.
  /// Used to simulate macOS native WebView background failures.
  Object? setBackgroundColorError;

  /// Queue of results to return for specific scripts.
  final Map<String, Queue<Object?>> _resultsQueue = {};

  /// Dynamic result resolver called when no queued result exists.
  ScriptResultResolver? resultResolver;

  /// Matchers for scripts that should throw errors.
  final List<ScriptMatcher> _throwMatchers = [];

  /// Per-method `flutterMonacoInvoke` outcomes (FIFO when stacked).
  final List<_CommandInjection> _commandInjections = [];

  /// Loaded file paths.
  final List<String> loadedFiles = [];

  /// Every parsed dispatch call, in order ({id, method, params}).
  final List<Map<String, Object?>> dispatched = [];

  /// Every parsed `FlutterMonaco.respond` payload, in order
  /// ({id, ok, value?/error?}). These are Dart's answers to JS-initiated
  /// requests (completions, custom actions).
  final List<Map<String, Object?>> responded = [];

  /// Dynamic responder consulted before the default success envelope.
  /// Return a non-null value to answer the method with it.
  Object? Function(String method, Map<String, Object?> params)?
  dispatchResolver;

  /// When false, dispatch calls are recorded but never answered (tests that
  /// drive responses manually or assert timeout behavior).
  bool autoRespond = true;

  int _eventSeq = 0;

  @override
  Future<void> initialize() async {
    if (disposed) {
      throw StateError('Cannot initialize disposed controller');
    }
    initialized = true;
  }

  @override
  Future<void> enableJavaScript() async {
    if (disposed) {
      throw StateError('Cannot enable JS on disposed controller');
    }
    jsEnabled = true;
  }

  @override
  Future<void> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    if (disposed) {
      throw StateError('Cannot add channel to disposed controller');
    }
    _channels[name] = onMessage;
  }

  @override
  Future<void> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
  }

  @override
  Future<void> load({MonacoPageConfig page = const MonacoPageConfig()}) async {
    if (disposed) {
      throw StateError('Cannot load file on disposed controller');
    }
    final connectSources = page.allowedConnectSources.isEmpty
        ? ''
        : ':${page.allowedConnectSources.join(',')}';
    loadedFiles.add(
      'LOAD_FILE:${page.customCss}:${page.allowCdnFonts}$connectSources',
    );
    executed.add(
      'LOAD_FILE:${page.customCss}:${page.allowCdnFonts}$connectSources',
    );
    if (emitPageReadyOnLoad) {
      scheduleMicrotask(() {
        tryEmitToChannel(
          'flutterChannel',
          jsonEncode({
            'v': 3,
            'kind': 'lifecycle',
            'name': 'pageReady',
            'protocolVersion': 3,
            'monacoVersion': 'test',
            'capabilities': ['lsp', 'diff'],
          }),
        );
      });
    }
  }

  /// When true (default), load() emits a pageReady lifecycle envelope like a
  /// real page shell, letting the boot flow proceed to page.boot.
  bool emitPageReadyOnLoad = true;

  @override
  Future<void> setBackgroundColor(Color color) async {
    if (disposed) {
      throw StateError('Cannot set background color on disposed controller');
    }
    final error = setBackgroundColorError;
    if (error != null) {
      throw error;
    }
    executed.add('SET_BACKGROUND_COLOR:$color');
  }

  @override
  Future<void> setInteractionEnabled(bool enabled) async {
    if (disposed) {
      throw StateError('Cannot set interaction on disposed controller');
    }
    interactionEnabled = enabled;
    executed.add('SET_INTERACTION:$enabled');
  }

  /// Result returned by [requestNativeFocus].
  ///
  /// Defaults to [NativeFocusResult.unsupported], which matches the real
  /// controllers in headless test environments (no native plugin registered)
  /// and therefore exercises the macOS in-page focus replay fallback. Set to
  /// [NativeFocusResult.granted] or [NativeFocusResult.alreadyOwned] to
  /// simulate a working native first-responder handoff.
  NativeFocusResult nativeFocusResult = NativeFocusResult.unsupported;

  /// Value returned by [hasNativeInputFocus].
  bool? nativeInputFocus;

  @override
  Future<NativeFocusResult> requestNativeFocus() async {
    executed.add('REQUEST_NATIVE_FOCUS');
    return nativeFocusResult;
  }

  @override
  Future<bool?> hasNativeInputFocus() async {
    executed.add('HAS_NATIVE_INPUT_FOCUS');
    return nativeInputFocus;
  }

  @override
  Future<void> releaseNativeFocus() async {
    executed.add('RELEASE_NATIVE_FOCUS');
  }

  @override
  Future<void> runJavaScript(String script) async {
    if (disposed) {
      throw StateError('Cannot run JS on disposed controller');
    }
    if (_shouldThrow(script)) {
      throw StateError('Fake runJavaScript error for: $script');
    }
    executed.add(script);
    _maybeRespondToDispatch(script);
    final respondPayload = _parseCall(script, 'FlutterMonaco.respond(');
    if (respondPayload != null) {
      responded.add(respondPayload);
    }
  }

  /// Parses a `FlutterMonaco.dispatch({...})` script and posts the matching
  /// protocol v3 response envelope through the channel, like the real page.
  void _maybeRespondToDispatch(String script) {
    final call = parseDispatch(script);
    if (call == null) return;

    dispatched.add(call);
    if (!autoRespond) return;

    final id = call['id'] as String;
    final method = call['method'] as String;

    for (var i = 0; i < _commandInjections.length; i++) {
      final injection = _commandInjections[i];
      if (method.contains(injection.methodMatch)) {
        _commandInjections.removeAt(i);
        _postResponse(id, injection);
        return;
      }
    }

    final resolver = dispatchResolver;
    if (resolver != null) {
      final result = resolver(method, call['params'] as Map<String, Object?>);
      if (result != null) {
        _postResponse(
          id,
          _CommandInjection.success(methodMatch: method, value: result),
        );
        _maybeEmitReadyAfterBoot(method);
        return;
      }
    }

    _postResponse(
      id,
      _CommandInjection.success(methodMatch: method, isUndefined: true),
    );
    _maybeEmitReadyAfterBoot(method);
  }

  /// Like a real page: the editor reports ready after page.boot lands.
  void _maybeEmitReadyAfterBoot(String method) {
    if (method != 'page.boot') return;
    scheduleMicrotask(() {
      tryEmitToChannel(
        'flutterChannel',
        jsonEncode({'v': 3, 'kind': 'lifecycle', 'name': 'ready'}),
      );
    });
  }

  /// Extracts the dispatch payload from [script], or null when the script is
  /// not a dispatch call.
  static Map<String, Object?>? parseDispatch(String script) {
    return _parseCall(script, 'FlutterMonaco.dispatch(');
  }

  /// Extracts the single JSON argument of a `<marker>{...})` call from
  /// [script], or null when the script is not such a call.
  static Map<String, Object?>? _parseCall(String script, String marker) {
    final start = script.indexOf(marker);
    if (start < 0) return null;
    final jsonStart = start + marker.length;
    final jsonEnd = script.lastIndexOf(')');
    if (jsonEnd <= jsonStart) return null;
    try {
      final decoded = jsonDecode(script.substring(jsonStart, jsonEnd));
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void _postResponse(String id, _CommandInjection injection) {
    final envelope = injection.toResponseEnvelope(id);
    scheduleMicrotask(() {
      tryEmitToChannel('flutterChannel', envelope);
    });
  }

  /// Emits a protocol v3 event envelope through the channel.
  void emitEvent(String name, Map<String, Object?> data) {
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({
        'v': 3,
        'kind': 'event',
        'seq': ++_eventSeq,
        'name': name,
        'data': data,
      }),
    );
  }

  /// Emits a protocol v3 JS-to-Dart request envelope through the channel
  /// (completion provider queries, custom action invocations). Dart's answer
  /// lands in [responded].
  void emitRequest(String id, String name, Map<String, Object?> data) {
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({
        'v': 3,
        'kind': 'request',
        'id': id,
        'name': name,
        'data': data,
      }),
    );
  }

  /// Emits only the `pageReady` lifecycle: a (re)loaded page shell whose
  /// editor does not exist until `page.boot` creates it. After a first
  /// handshake this is how the protocol detects a page reload.
  void emitPageReady({String monacoVersion = 'test'}) {
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({
        'v': 3,
        'kind': 'lifecycle',
        'name': 'pageReady',
        'protocolVersion': 3,
        'monacoVersion': monacoVersion,
        'capabilities': ['lsp', 'diff'],
      }),
    );
  }

  /// Emits a bare lifecycle envelope such as `ready` or `fatal`.
  void emitLifecycle(String name, {Map<String, Object?>? error}) {
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({
        'v': 3,
        'kind': 'lifecycle',
        'name': name,
        'error': ?error,
      }),
    );
  }

  /// Answers the dispatch with [id] by hand (for tests that set
  /// [autoRespond] to false): a success with [value], or a JavaScript error
  /// when [errorMessage] is set.
  void respondTo(String id, {Object? value, String? errorMessage}) {
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({
        'v': 3,
        'kind': 'response',
        'id': id,
        'ok': errorMessage == null,
        if (errorMessage == null) 'value': value,
        if (errorMessage != null)
          'error': {'name': 'Error', 'message': errorMessage},
      }),
    );
  }

  /// The methods of every dispatched command, in order.
  List<String> get dispatchedMethods => [
    for (final call in dispatched) call['method']! as String,
  ];

  /// Emits the pageReady + ready lifecycle pair (a booted page).
  void emitReadyLifecycle({String monacoVersion = 'test'}) {
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({
        'v': 3,
        'kind': 'lifecycle',
        'name': 'pageReady',
        'protocolVersion': 3,
        'monacoVersion': monacoVersion,
        'capabilities': ['lsp', 'diff'],
      }),
    );
    tryEmitToChannel(
      'flutterChannel',
      jsonEncode({'v': 3, 'kind': 'lifecycle', 'name': 'ready'}),
    );
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    if (disposed) {
      throw StateError('Cannot run JS on disposed controller');
    }
    if (_shouldThrow(script)) {
      throw StateError('Fake runJavaScriptReturningResult error for: $script');
    }
    executed.add(script);
    return _getResult(script);
  }

  @override
  Widget get widget => _widget;

  @override
  void dispose() {
    disposed = true;
  }

  // Test utilities

  /// Returns true if a channel with [name] is registered.
  bool hasChannel(String name) => _channels.containsKey(name);

  /// Returns a list of all registered channel names.
  List<String> get channelNames => _channels.keys.toList();

  /// Enqueues a result to return for a specific [script].
  ///
  /// Results are returned in FIFO order for each script key.
  void enqueueResult(String script, Object? result) {
    _resultsQueue.putIfAbsent(script, () => Queue<Object?>()).add(result);
  }

  /// Enqueues multiple results for a script.
  void enqueueResults(String script, List<Object?> results) {
    for (final result in results) {
      enqueueResult(script, result);
    }
  }

  /// Configures scripts matching [matcher] to throw errors.
  void throwOn(ScriptMatcher matcher) {
    _throwMatchers.add(matcher);
  }

  /// Configures scripts containing [substring] to throw errors.
  void throwOnContains(String substring) {
    throwOn((script) => script.contains(substring));
  }

  /// Clears all throw matchers.
  void clearThrowMatchers() {
    _throwMatchers.clear();
  }

  /// Registers a success response for a dispatched command whose dotted
  /// method name contains [methodMatch].
  ///
  /// Use this when a test needs a specific return [value] (or
  /// `isUndefined: true`) from a command. By default the fake auto-responds
  /// with an undefined success envelope to any dispatch, so most tests only
  /// need explicit injections for non-default values.
  ///
  /// Outcomes are consumed FIFO within a single test - the first matching
  /// injection is removed after it fires.
  void injectCommandSuccess(
    String methodMatch, {
    Object? value,
    bool isUndefined = false,
  }) {
    _commandInjections.add(
      _CommandInjection.success(
        methodMatch: methodMatch,
        value: value,
        isUndefined: isUndefined,
      ),
    );
  }

  /// Registers a failure response for a dispatched command whose dotted
  /// method name contains [methodMatch].
  ///
  /// The Dart side decodes this as a `MonacoJavaScriptError` with the
  /// supplied [message], [name], and [stack] fields. Use this to assert
  /// failure propagation from the JS bridge into Dart command methods.
  void injectCommandFailure(
    String methodMatch, {
    required String message,
    String name = 'Error',
    String? stack,
  }) {
    _commandInjections.add(
      _CommandInjection.failure(
        methodMatch: methodMatch,
        name: name,
        message: message,
        stack: stack,
      ),
    );
  }

  /// Clears all command-invoke injections.
  void clearCommandInjections() {
    _commandInjections.clear();
  }

  /// Emits a message to a registered channel.
  ///
  /// Throws if the channel is not registered.
  void emitToChannel(String name, String message) {
    final handler = _channels[name];
    if (handler == null) {
      throw StateError('No channel registered for $name');
    }
    handler(message);
  }

  /// Tries to emit a message, returning false if channel doesn't exist.
  bool tryEmitToChannel(String name, String message) {
    final handler = _channels[name];
    if (handler == null) return false;
    handler(message);
    return true;
  }

  /// Clears all executed scripts.
  void clearExecuted() {
    executed.clear();
  }

  /// Clears all state (executed, queues, matchers, channels).
  void reset() {
    executed.clear();
    _resultsQueue.clear();
    _throwMatchers.clear();
    _commandInjections.clear();
    _channels.clear();
    resultResolver = null;
    dispatchResolver = null;
    autoRespond = true;
    dispatched.clear();
    _eventSeq = 0;
    initialized = false;
    jsEnabled = false;
    disposed = false;
    interactionEnabled = true;
    nativeFocusResult = NativeFocusResult.unsupported;
    nativeInputFocus = null;
    loadedFiles.clear();
  }

  /// Returns scripts containing [substring].
  List<String> scriptsContaining(String substring) {
    return executed.where((s) => s.contains(substring)).toList();
  }

  /// Returns true if any executed script contains [substring].
  bool hasExecuted(String substring) {
    return executed.any((s) => s.contains(substring));
  }

  /// Returns the count of scripts containing [substring].
  int executionCount(String substring) {
    return executed.where((s) => s.contains(substring)).length;
  }

  bool _shouldThrow(String script) {
    return _throwMatchers.any((matcher) => matcher(script));
  }

  Object? _getResult(String script) {
    // Check queued results first
    final queued = _resultsQueue[script];
    if (queued != null && queued.isNotEmpty) {
      return queued.removeFirst();
    }

    // Fall back to resolver for raw scripts.
    return resultResolver?.call(script);
  }
}

class _CommandInjection {
  _CommandInjection._({
    required this.methodMatch,
    required this.ok,
    this.value,
    this.isUndefined = false,
    this.errorName,
    this.errorMessage,
    this.errorStack,
  });

  factory _CommandInjection.success({
    required String methodMatch,
    Object? value,
    bool isUndefined = false,
  }) {
    return _CommandInjection._(
      methodMatch: methodMatch,
      ok: true,
      value: value,
      isUndefined: isUndefined,
    );
  }

  factory _CommandInjection.failure({
    required String methodMatch,
    required String name,
    required String message,
    String? stack,
  }) {
    return _CommandInjection._(
      methodMatch: methodMatch,
      ok: false,
      errorName: name,
      errorMessage: message,
      errorStack: stack,
    );
  }

  final String methodMatch;
  final bool ok;
  final Object? value;
  final bool isUndefined;
  final String? errorName;
  final String? errorMessage;
  final String? errorStack;

  String toResponseEnvelope(String id) {
    if (ok) {
      return jsonEncode({
        'v': 3,
        'kind': 'response',
        'id': id,
        'ok': true,
        'undefined': isUndefined,
        'value': isUndefined ? null : value,
      });
    }
    return jsonEncode({
      'v': 3,
      'kind': 'response',
      'id': id,
      'ok': false,
      'error': {
        'name': errorName,
        'message': errorMessage,
        if (errorStack != null) 'stack': errorStack,
      },
    });
  }
}

/// Extension methods for easier test assertions.
extension FakePlatformWebViewControllerAssertions
    on FakePlatformWebViewController {
  /// Asserts that a script containing [substring] was executed.
  void assertExecuted(String substring) {
    if (!hasExecuted(substring)) {
      throw TestFailure(
        'Expected script containing "$substring" to be executed.\n'
        'Executed scripts:\n${executed.map((s) => '  - $s').join('\n')}',
      );
    }
  }

  /// Asserts that no script containing [substring] was executed.
  void assertNotExecuted(String substring) {
    if (hasExecuted(substring)) {
      final matching = scriptsContaining(substring);
      throw TestFailure(
        'Expected no script containing "$substring" to be executed.\n'
        'Found ${matching.length} matching scripts:\n${matching.map((s) => '  - $s').join('\n')}',
      );
    }
  }

  /// Asserts the exact execution count for scripts containing [substring].
  void assertExecutionCount(String substring, int expected) {
    final actual = executionCount(substring);
    if (actual != expected) {
      throw TestFailure(
        'Expected $expected executions of scripts containing "$substring", '
        'but found $actual.',
      );
    }
  }
}

/// A simple test failure exception for assertions.
class TestFailure implements Exception {
  TestFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
