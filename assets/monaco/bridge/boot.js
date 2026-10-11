// flutter_monaco bridge - boot orchestration (protocol v3 two-phase boot).
// The stats emitter and event wiring are ported verbatim from the 2.3.0
// generated page; the editor is created from the page.boot command's
// parameters so the first painted frame already uses the requested options,
// text, language, and theme (no markdown/vs-dark flash).
/* eslint-disable */
'use strict';
window.__FMB = window.__FMB || {};

(function () {
  // page.boot arrives from Dart after lifecycle:pageReady. Editor creation
  // needs BOTH editor.main loaded AND the boot parameters; whichever finishes
  // last triggers the create.
  var bootResolve = null;
  var bootPromise = new Promise(function (resolve) { bootResolve = resolve; });
  var booted = false;

  window.FlutterMonaco.register('page.boot', function (params) {
    if (booted) {
      throw new Error('page.boot may only be dispatched once per page.');
    }
    booted = true;
    bootResolve(params || {});
    return true;
  });

  // All bridge scripts have parsed and every command (including page.boot
  // above) is registered - only now is it safe for Dart to dispatch.
  window.FlutterMonaco.announcePageReady();

  function _startMonaco() {
      console.log('[Monaco HTML] Attempting to require editor.main...');
      try {
        require(
          ['vs/editor/editor.main'],
          function () {
            console.log('[Monaco] SUCCESS: editor.main.js has loaded. Initializing editor...');

            bootPromise.then(function (params) {
              window.__FM_BOOT = params;
              if ((params.mode || 'editor') === 'diff') {
                // Diff mode (Phase 11): two models in a createDiffEditor,
                // driven by the diff.* registry. Single-editor emitters and
                // feature sections are skipped by design; diff-api wires a
                // stats-lite feed instead. The onDidCreateEditor handler
                // below is never registered here - it would fire for BOTH
                // inner editors of the diff pair.
                var diffCtx = {};
                (window.__FMB || {}).diffApi(diffCtx);
                diffCtx.bootDiff(params);
                // Edge scroll handoff on diff pages: the modified editor is
                // the vertical scroll master (side-by-side panes are
                // height-aligned by Monaco's alignment zones, and inline
                // mode renders inside the modified editor), while the
                // accepted wheel region covers both panes of the pair.
                diffCtx.E = function () {
                  return window.diffEditor.getModifiedEditor();
                };
                diffCtx.post = function (name, data) {
                  window.FlutterMonaco.emit(name, data);
                };
                diffCtx.handoffScope = {
                  regionRoot: function () {
                    var d = window.diffEditor;
                    return d.getContainerDomNode
                      ? d.getContainerDomNode()
                      : document.getElementById('editor-container');
                  },
                  editorDoms: function () {
                    var d = window.diffEditor;
                    return [
                      d.getOriginalEditor().getDomNode(),
                      d.getModifiedEditor().getDomNode(),
                    ];
                  },
                };
                (window.__FMB || {}).scrollHandoff(diffCtx);
                var diffScrollHandoff = (params || {}).scrollHandoff || {};
                if (diffScrollHandoff.wheel || diffScrollHandoff.touch) {
                  window.flutterMonaco.setScrollHandoff({
                    wheel: !!diffScrollHandoff.wheel,
                    touch: !!diffScrollHandoff.touch,
                    policy: typeof diffScrollHandoff.policy === 'string'
                      ? diffScrollHandoff.policy
                      : undefined,
                  });
                }
                window.FlutterMonaco.lifecycle('ready');
                console.log('[Monaco] Diff Editor is ready and the Flutter bridge is installed.');
                return;
              }

              // onDidCreateEditor fires for EVERY code editor in the page,
              // not just the one created below: the peek widget's embedded
              // editor (Peek Definition, Shift+F12 references, multi-result
              // go-to-definition) and the inner editors of any diff editor
              // page code creates. Re-running the installers for those
              // would retarget window.editor at a short-lived editor, post
              // a second ready lifecycle, and replace every registry (LSP
              // connections, decoration sets, actions, providers). The
              // bridge therefore binds once, to the editor created in
              // #editor-container. The hook fires from the editor
              // constructor - before monaco.editor.create returns and
              // before the boot model is attached - which the installers
              // below rely on.
              var primaryContainer = document.getElementById('editor-container');
              var bridgeInstalled = false;
              var createEditorHook = null;
              createEditorHook = monaco.editor.onDidCreateEditor(function (editor) {
              if (bridgeInstalled) return;
              if (typeof editor.getParentEditor === 'function') return;
              if (editor.getContainerDomNode &&
                  editor.getContainerDomNode() !== primaryContainer) {
                return;
              }
              bridgeInstalled = true;
              if (createEditorHook) {
                try { createEditorHook.dispose(); } catch (_) {}
                createEditorHook = null;
              }
              window.editor = editor;

              var FMB = window.__FMB || {};
              var ctx = {};
              FMB.core(ctx);
              FMB.focusHelpers(ctx);
              const { E, post, postMessageToFlutter } = ctx;

              // Send live statistics updates
              const sendStats = () => {
                if (!editor.getModel() || !editor.getSelection()) return;
                const model = editor.getModel(), selection = editor.getSelection(), selections = editor.getSelections() || [];
                const position = editor.getPosition();
                postMessageToFlutter({
                  event: 'stats',
                  lineCount: model.getLineCount(),
                  charCount: model.getValueLength(),
                  selLines: selection.isEmpty() ? 0 : (selection.endLineNumber - selection.startLineNumber + 1),
                  selChars: selection.isEmpty() ? 0 : model.getValueInRange(selection).length,
                  caretCount: selections.length,
                  language: model.getLanguageId ? model.getLanguageId() : monaco.editor.getModelLanguage(model),
                  cursorLine: position?.lineNumber,
                  cursorColumn: position?.column,
                });
              };
              editor.onDidChangeModelContent(sendStats);
              editor.onDidChangeCursorSelection(sendStats);
              // Live stats must refresh the moment docs.activate swaps the
              // attached model, not on the next keystroke.
              editor.onDidChangeModel(sendStats);
              sendStats();

                // contentChanged is emitted per-model by the document
                // registry in editor-api.js (so INACTIVE pinned documents
                // report their edits too); no editor-level content listener
                // here.
                E().onDidChangeCursorSelection(e => post('selectionChanged', {
                  selection: e.selection && {
                    startLineNumber: e.selection.startLineNumber,
                    startColumn: e.selection.startColumn,
                    endLineNumber: e.selection.endLineNumber,
                    endColumn: e.selection.endColumn
                  }
                }));
                E().onDidFocusEditorWidget(() => post('focusChanged', { focused: true }));
                E().onDidBlurEditorWidget(() => post('focusChanged', { focused: false }));

              FMB.editorApi(ctx);
              FMB.focusMobile(ctx);
              if (FMB.viewportFit) FMB.viewportFit(ctx);
              FMB.completions(ctx);
              FMB.actions(ctx);
              FMB.scrollHandoff(ctx);
              FMB.lsp(ctx);

              // Boot-requested scroll handoff sources (off by default; the
              // module installs listeners only for enabled sources).
              var bootScrollHandoff = (window.__FM_BOOT || {}).scrollHandoff || {};
              if (bootScrollHandoff.wheel || bootScrollHandoff.touch) {
                window.flutterMonaco.setScrollHandoff({
                  wheel: !!bootScrollHandoff.wheel,
                  touch: !!bootScrollHandoff.touch,
                  policy: typeof bootScrollHandoff.policy === 'string'
                    ? bootScrollHandoff.policy
                    : undefined,
                });
              }

              window.FlutterMonaco.lifecycle('ready');
              console.log('[Monaco] Editor is ready and the Flutter bridge is installed.');
            });

              // The editor is born configured: sparse Monaco options from
              // Dart, plus the initial text/language/theme, in one create.
              var options = Object.assign({}, params.options || {});
              options.theme = params.theme || 'vs';
              if (options.automaticLayout === undefined) {
                options.automaticLayout = true;
              }
              // The boot document is created explicitly, NOT via the
              // value/language create options: a standalone editor owns an
              // implicitly created model and DISPOSES it on the first
              // setModel (docs.activate), which would kill the boot
              // document in multi-document use.
              options.model = monaco.editor.createModel(
                typeof params.text === 'string' ? params.text : '',
                params.language || 'plaintext'
              );
              monaco.editor.create(
                document.getElementById('editor-container'),
                options
              );
            }).catch(function (e) {
              console.error('[Monaco] FATAL: editor creation failed. Error:', e);
              window.FlutterMonaco.lifecycle('fatal', {
                error: {
                  name: e && e.name ? String(e.name) : 'Error',
                  message: 'Editor creation failed: ' + (e && e.message ? e.message : e),
                  stack: e && e.stack ? String(e.stack) : null,
                },
              });
            });
          },
          function (error) {
            console.error('[Monaco] FATAL: require() failed to load editor.main.js. Error:', error);
            if (window.FlutterMonaco) {
              window.FlutterMonaco.lifecycle('fatal', {
                error: {
                  name: 'RequireError',
                  message: 'Failed to load editor.main: ' + error,
                  stack: null,
                },
              });
            }
          }
        );
      } catch (e) {
        console.error('[Monaco] FATAL: A critical error occurred trying to call require(). Error:', e);
        if (window.FlutterMonaco) {
          window.FlutterMonaco.lifecycle('fatal', {
            error: {
              name: 'RequireError',
              message: 'require() call failed: ' + e,
              stack: e && e.stack ? String(e.stack) : null,
            },
          });
        }
      }
  }

  if (window.__FM_PAGE && window.__FM_PAGE.platform === 'web') {
    // Web: loader.js is injected dynamically; wait for it before require().
    var _initMonaco = function () {
      if (!window._monacoLoaderReady) {
        window._initMonacoWhenReady = _initMonaco;
        return;
      }
      _startMonaco();
    };
    _initMonaco();
  } else {
    _startMonaco();
  }
})();
