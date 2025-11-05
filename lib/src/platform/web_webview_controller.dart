import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'platform_webview_interface.dart';

/// Direct DOM implementation for web - no IFrame needed!
class WebWebViewController implements PlatformWebViewController {
  WebWebViewController() {
    _initialize();
  }

  final Map<String, void Function(String)> _channels = {};
  bool _disposed = false;
  bool _isReady = false;
  final Completer<void> _readyCompleter = Completer<void>();
  html.DivElement? _container;
  String? _viewId;

  void _initialize() {
    _viewId = 'monaco-container-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[WebWebViewController] Initializing direct DOM approach');

    // Create container for Monaco and add it to body immediately
    _container = html.DivElement()
      ..id = _viewId!
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.right = '0'
      ..style.bottom = '0';

    // Add container to DOM immediately so Monaco can find it
    html.document.body!.append(_container!);

    // Register the view factory
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) => _container!,
    );

    // Setup Flutter channel in global scope
    js.context['flutterChannel'] = js.JsObject.jsify({
      'postMessage': js.allowInterop((String message) {
        _handleFlutterMessage(message);
      }),
    });

    debugPrint('[WebWebViewController] Container added to DOM with ID: $_viewId');
  }

  void _handleFlutterMessage(String message) {
    debugPrint('[WebWebViewController] Received message: $message');

    // Check if this is the ready event (either old format or new JSON format)
    if (message == 'ready' || message.contains('"event":"onEditorReady"') || message.contains('"event": "onEditorReady"')) {
      _isReady = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      debugPrint('[WebWebViewController] Monaco ready!');
      // Don't return - let the message be forwarded to channels
    }

    // Handle channel messages
    for (final entry in _channels.entries) {
      final handler = entry.value;
      handler(message);
    }
  }

  Future<void> loadHtmlString(String htmlContent, {String? baseUrl}) async {
    debugPrint('[WebWebViewController] Loading Monaco via direct DOM');

    // Check if Monaco is already loaded (for hot reload)
    if (js.context.hasProperty('monaco') && js.context['monaco'] != null) {
      debugPrint('[WebWebViewController] Monaco already loaded, sending ready signal');
      _handleFlutterMessage('{\"event\":\"onEditorReady\"}');
      await _ensureReady();
      return;
    }

    // Load Monaco loader script directly into the page
    final loaderPath =
        '/assets/packages/flutter_monaco/assets/monaco/min/vs/loader.js';

    final script = html.ScriptElement()
      ..src = loaderPath
      ..async = false;

    final completer = Completer<void>();

    script.onLoad.listen((_) {
      debugPrint('[WebWebViewController] Loader.js loaded');

      // Configure require.js and load Monaco
      final vsPath = '/assets/packages/flutter_monaco/assets/monaco/min/vs';
      final containerId = _viewId!;

      js.context.callMethod('eval', [
        '''
        require.config({
          paths: { 'vs': '$vsPath' }
        });

        require(['vs/editor/editor.main'], function() {
          console.log('[Monaco] Editor loaded successfully!');

          // Wait for container to be added to DOM by Flutter
          const containerId = '$containerId';

          // First check if it already exists
          let container = document.getElementById(containerId);
          if (container) {
            console.log('[Monaco] Container already exists');
            initializeEditor(container);
            return;
          }

          console.log('[Monaco] Waiting for container:', containerId);

          // Use MutationObserver to wait for the container to be added
          const observer = new MutationObserver(function(mutations) {
            const container = document.getElementById(containerId);
            if (container) {
              observer.disconnect();
              console.log('[Monaco] Container found via MutationObserver');
              initializeEditor(container);
            }
          });

          // Observe the entire document for added nodes
          observer.observe(document.documentElement, {
            childList: true,
            subtree: true
          });

          // Timeout after 10 seconds
          setTimeout(function() {
            observer.disconnect();
            if (!document.getElementById(containerId)) {
              console.error('[Monaco] Container not found after 10 seconds:', containerId);
            }
          }, 10000);

          function initializeEditor(container) {
            // Create Monaco editor instance
            const editor = monaco.editor.create(container, {
              value: '',
              language: 'plaintext',
              theme: 'vs-dark',
              automaticLayout: true,
            });

            // Initialize Monaco API
            _initializeMonacoAPI(editor);
          }

          function _initializeMonacoAPI(editor) {

          // Create flutterMonaco API
          window.flutterMonaco = {
            editor: editor,

            getValue: function() {
              return editor.getValue();
            },

            setValue: function(value) {
              editor.setValue(value);
            },

            setLanguage: function(language) {
              const model = editor.getModel();
              if (model) {
                monaco.editor.setModelLanguage(model, language);
              }
            },

            setTheme: function(theme) {
              monaco.editor.setTheme(theme);
            },

            updateOptions: function(options) {
              editor.updateOptions(options);
            },

            executeAction: function(actionId, args) {
              editor.trigger('flutter', actionId, args);
            },

            forceFocus: function() {
              editor.focus();
            },

            layout: function() {
              editor.layout();
            },

            getSelection: function() {
              return editor.getSelection();
            },

            setSelection: function(range) {
              editor.setSelection(range);
            },

            revealLine: function(line, center) {
              if (center) {
                editor.revealLineInCenter(line);
              } else {
                editor.revealLine(line);
              }
            },

            revealRange: function(range, center) {
              if (center) {
                editor.revealRangeInCenter(range);
              } else {
                editor.revealRange(range);
              }
            },

            getLineCount: function() {
              const model = editor.getModel();
              return model ? model.getLineCount() : 0;
            },

            getLineContent: function(line) {
              const model = editor.getModel();
              return model ? model.getLineContent(line) : '';
            },

            applyEdits: function(edits) {
              editor.executeEdits('flutter', edits);
            },

            deltaDecorations: function(oldDecorations, newDecorations) {
              return editor.deltaDecorations(oldDecorations, newDecorations);
            },

            setModelMarkers: function(owner, markers) {
              const model = editor.getModel();
              if (model) {
                monaco.editor.setModelMarkers(model, owner, markers);
              }
            },

            findMatches: function(query, options, limit) {
              const model = editor.getModel();
              if (!model) return [];
              return model.findMatches(query, false, options.isRegex, options.matchCase, options.matchWholeWord ? options.wordSeparators : null, true, limit);
            },

            replaceMatches: function(query, replacement, options) {
              const model = editor.getModel();
              if (!model) return 0;
              const matches = model.findMatches(query, false, options.isRegex, options.matchCase, options.matchWholeWord ? options.wordSeparators : null, true);
              const edits = matches.map(match => ({
                range: match.range,
                text: replacement
              }));
              editor.executeEdits('flutter', edits);
              return matches.length;
            },
          };

          console.log('[Monaco] flutterMonaco API created');

          if (window.flutterChannel && window.flutterChannel.postMessage) {
            window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady'}));
          }
          } // end of _initializeMonacoAPI
        });
        '''
      ]);

      completer.complete();
    });

    script.onError.listen((event) {
      debugPrint('[WebWebViewController] Failed to load loader.js from: $loaderPath');
      completer.completeError(Exception('Failed to load Monaco loader.js'));
    });

    html.document.head!.append(script);

    await completer.future;
    await _ensureReady();
  }

  Future<void> loadUrl(String url) async {
    debugPrint('[WebWebViewController] loadUrl not supported in direct DOM mode');
  }

  Future<void> _ensureReady() async {
    if (!_isReady) {
      await _readyCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Monaco editor failed to initialize');
        },
      );
    }
  }

  @override
  Future<Object?> runJavaScript(String script) async {
    if (_disposed) return null;

    try {
      return js.context.callMethod('eval', [script]);
    } catch (e) {
      debugPrint('[WebWebViewController] JS execution error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    return runJavaScript(script);
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    debugPrint('[WebWebViewController] Adding JS channel: $name');
    _channels[name] = onMessage;
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
    return null;
  }

  Widget build() {
    // View factory is already registered in _initialize()
    return HtmlElementView(viewType: _viewId!);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[WebWebViewController] Disposing...');
    _channels.clear();
    _container?.remove();
    _container = null;
  }
}
