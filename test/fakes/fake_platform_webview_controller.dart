import 'dart:collection';
import 'dart:convert';

import 'package:flutter/widgets.dart';
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
  Future<void> load({String? customCss, bool allowCdnFonts = false}) async {
    if (disposed) {
      throw StateError('Cannot load file on disposed controller');
    }
    loadedFiles.add('LOAD_FILE:$customCss:$allowCdnFonts');
    executed.add('LOAD_FILE:$customCss:$allowCdnFonts');
  }

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

  @override
  Future<void> requestNativeFocus() async {
    executed.add('REQUEST_NATIVE_FOCUS');
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

  /// Registers a success envelope outcome for a `flutterMonacoInvoke(...)`
  /// call whose method name matches [methodMatch].
  ///
  /// Use this when a test needs a specific return [value] (or
  /// `isUndefined: true`) from a converted command method. By default the
  /// fake auto-responds with a `null`/undefined success envelope to any
  /// `flutterMonacoInvoke` script, so most tests only need explicit
  /// injections for non-default values.
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

  /// Registers a failure envelope outcome for a `flutterMonacoInvoke(...)`
  /// call whose method name matches [methodMatch].
  ///
  /// The Dart side decodes this as a `MonacoJavaScriptException` with the
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
    initialized = false;
    jsEnabled = false;
    disposed = false;
    interactionEnabled = true;
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

    // flutterMonacoInvoke dispatcher: match per-method injections, then
    // fall back to a default success envelope so converted commands return
    // a usable result without per-test setup.
    if (_isInvokeScript(script)) {
      for (var i = 0; i < _commandInjections.length; i++) {
        final injection = _commandInjections[i];
        if (script.contains('"${injection.methodMatch}"')) {
          _commandInjections.removeAt(i);
          return injection.toEnvelopeJson();
        }
      }

      // Defer to resolver before applying the default. Tests that install a
      // resolver for invoke scripts can still override the default.
      final resolverResult = resultResolver?.call(script);
      if (resolverResult != null) return resolverResult;

      return _defaultInvokeSuccessEnvelope;
    }

    // Fall back to resolver for non-invoke scripts.
    return resultResolver?.call(script);
  }

  bool _isInvokeScript(String script) {
    return script.contains('window.flutterMonacoInvoke(');
  }

  static final String _defaultInvokeSuccessEnvelope = jsonEncode({
    '__flutterMonacoEval': true,
    'ok': true,
    'isUndefined': true,
    'value': null,
  });
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

  String toEnvelopeJson() {
    if (ok) {
      return jsonEncode({
        '__flutterMonacoEval': true,
        'ok': true,
        'isUndefined': isUndefined,
        'value': isUndefined ? null : value,
      });
    }
    return jsonEncode({
      '__flutterMonacoEval': true,
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
