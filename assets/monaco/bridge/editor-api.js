// flutter_monaco bridge - extracted verbatim from the 2.3.0 generated page
// (lib/src/core/monaco_assets.dart generateIndexHtml). Do not reformat the
// ported bodies; see upcoming/v3.md Section 14 (verbatim-port inventory).
/* eslint-disable */
'use strict';
window.__FMB = window.__FMB || {};

// The typed window.flutterMonaco API surface plus the completion
// provider bridge.
window.__FMB.editorApi = function (ctx) {
  const { E, isMobileInputPlatform, getEditorNode, focusEditorTextAreaNow } = ctx;
                // Typed helpers Flutter will call
                const escapeRegExp = (value) =>
                  (value ?? '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

                // Strict accessors used by the new flutterMonacoInvoke envelope.
                // Helpers that depend on the editor/model should call these so
                // missing-state errors propagate to Dart instead of being
                // silently swallowed.
                const requireEditor = () => {
                  const ed = E();
                  if (!ed) {
                    throw new Error('Monaco editor is not ready.');
                  }
                  return ed;
                };
                const requireModel = () => {
                  const ed = requireEditor();
                  const model = ed.getModel ? ed.getModel() : null;
                  if (!model) {
                    throw new Error('Monaco editor has no active model.');
                  }
                  return model;
                };
                // Programmatic edits as ONE undo step of their own.
                // model.applyEdits bypasses the undo stack, so a later undo
                // replays stale inverse edits over the shifted text and
                // corrupts the document; pushEditOperations alone would
                // merge into the user's still-open typing element. The
                // surrounding stack elements close that element and this
                // one. Model-level, so pinned inactive documents get the
                // same undo semantics as the attached one.
                const applyUndoableEdits = (model, edits) => {
                  model.pushStackElement();
                  model.pushEditOperations([], edits, () => null);
                  model.pushStackElement();
                };

                window.flutterMonaco = {

                  // Basic editor operations
                  focus: () => E().focus(),
                  layout: () => { try { E().layout(); } catch (_) {} },
                  // Force focus robustly: wait for visibility, layout, focus editor and hidden textarea
                  forceFocus: (options = {}) => {
                    try {
                      const ed = E();
                      const node = getEditorNode();
                      if (!ed || !node) return;
                      const replayInputFocus =
                        options && options.replayInputFocus === true;

                      if (isMobileInputPlatform()) {
                        focusEditorTextAreaNow();
                        return;
                      }

                      const attempt = () => {
                        const rect = node.getBoundingClientRect();
                        if (!rect.width || !rect.height) {
                          return requestAnimationFrame(attempt);
                        }
                        // Idempotency guard: if the editor's input already owns
                        // focus, return WITHOUT the document.body.focus() handoff
                        // below. That handoff blurs then refocuses, which flickers
                        // the caret and tears down an open context menu. Refocusing
                        // an already-focused editor must be a no-op - this removes
                        // the flicker for EVERY caller, not just guarded pointers.
                        const input = node.querySelector(
                          'textarea.inputarea, .native-edit-context');
                        if (!replayInputFocus && input && document.activeElement === input) {
                          return;
                        }
                        try { window.focus && window.focus(); } catch (_) {}
                        try {
                          if (document.body && !document.body.hasAttribute('tabindex')) {
                            document.body.setAttribute('tabindex', '-1');
                          }
                          document.body?.focus?.();
                        } catch (_) {}
                        try { ed.layout && ed.layout(); } catch (_) {}
                        try { ed.focus && ed.focus(); } catch (_) {}
                        try {
                          const ta = node.querySelector('textarea.inputarea');
                          if (ta && document.activeElement !== ta) {
                            ta.focus({ preventScroll: true });
                            setTimeout(() => {
                              try { ta.focus({ preventScroll: true }); } catch (_) {}
                            }, 16);
                          }
                        } catch (_) {}
                      };
                      setTimeout(() => requestAnimationFrame(attempt), 0);
                    } catch (_) {}
                  },
                  getValue: () => requireEditor().getValue(),
                  setValue: (v) => {
                    requireEditor().setValue(v || '');
                    return true;
                  },
                  defineTheme: (name, data) => {
                    if (!window.monaco || !monaco.editor) {
                      throw new Error('Monaco editor API is not available.');
                    }
                    if (!name || typeof name !== 'string') {
                      throw new Error('Theme name must be a non-empty string.');
                    }
                    monaco.editor.defineTheme(name, data || {});
                    return true;
                  },
                  setHostPageBackground: (color) => {
                    if (!color) {
                      throw new Error('Host page background color is required.');
                    }
                    const value = String(color);
                    document.documentElement.style.backgroundColor = value;
                    document.body.style.backgroundColor = value;
                    const container = document.getElementById('editor-container');
                    if (container) container.style.backgroundColor = value;
                    return true;
                  },
                  setTheme: (theme) => {
                    if (!theme || typeof theme !== 'string') {
                      throw new Error('Theme id must be a non-empty string.');
                    }
                    monaco.editor.setTheme(theme);
                    return true;
                  },
                  getTheme: () => {
                    if (!window.monaco || !monaco.editor ||
                        typeof monaco.editor.getTheme !== 'function') {
                      return null;
                    }
                    const theme = monaco.editor.getTheme();
                    if (!theme) return null;
                    if (typeof theme === 'string') return theme;
                    return theme.themeName || theme.id || null;
                  },
                  setLanguage: (lang) => {
                    monaco.editor.setModelLanguage(requireModel(), lang);
                    return true;
                  },
                  updateOptions: (opts) => {
                    requireEditor().updateOptions(opts);
                    return true;
                  },
                  executeAction: (actionId, args) => {
                    if (!actionId || typeof actionId !== 'string') {
                      throw new Error('Action id must be a non-empty string.');
                    }
                    const ed = requireEditor();
                    const action = ed.getAction ? ed.getAction(actionId) : null;
                    if (action && typeof action.run === 'function') {
                      // Action runs can be asynchronous; settle the protocol
                      // response only after the returned promise does, so an
                      // async failure surfaces to Dart instead of reporting
                      // success while the action is still running.
                      return Promise.resolve(action.run(args))
                        .then(function () { return true; });
                    }
                    ed.trigger('flutter-bridge', actionId, args);
                    return true;
                  },

                  // Selection
                  getSelection: () => {
                    const s = E().getSelection();
                    return s ? {
                      startLineNumber: s.startLineNumber, startColumn: s.startColumn,
                      endLineNumber: s.endLineNumber, endColumn: s.endColumn
                    } : null;
                  },
                  setSelection: (r) => {
                    requireEditor().setSelection(r);
                    return true;
                  },

                  // Cursor
                  getCursorPosition: () => {
                    const p = E().getPosition();
                    return p ? { lineNumber: p.lineNumber, column: p.column } : null;
                  },
                  setCursorPosition: (line, column) => {
                    requireEditor().setPosition({ lineNumber: line, column: column });
                    return true;
                  },

                  // Navigation
                  revealLine: (ln, center) =>
                    center ? E().revealLineInCenter(ln) : E().revealLine(ln),
                  revealRange: (r, center) =>
                    center ? E().revealRangeInCenter(r) : E().revealRange(r),

                  // Line operations
                  getLineCount: () => requireModel().getLineCount(),
                  getLineContent: (ln) => requireModel().getLineContent(ln),
                  
                  // Word lookup
                  getWordAtPosition: (line, column) => {
                    const m = E().getModel();
                    if (!m) return null;
                    const w = m.getWordAtPosition(new monaco.Position(line, column));
                    return w ? w.word : null;
                  },

                  // Edits
                  applyEdits: (edits) => {
                    applyUndoableEdits(requireModel(), edits || []);
                    return true;
                  },

                  // Decorations
                  deltaDecorations: (oldIds, newDecos) =>
                    requireEditor().deltaDecorations(oldIds || [], newDecos || []),

                  // JSON language diagnostics.
                  // Monaco 0.55 moved the language defaults from
                  // monaco.languages.json to the top-level monaco.json and
                  // deprecated the old path; prefer the new namespace and
                  // fall back so a vendored older build keeps working.
                  setJsonDiagnosticsOptions: (diagnostics) => {
                    const jsonApi = (typeof monaco.json !== 'undefined' && monaco.json) ||
                      (monaco.languages && monaco.languages.json);
                    if (!jsonApi || !jsonApi.jsonDefaults) {
                      throw new Error('Monaco JSON language API is not available.');
                    }
                    jsonApi.jsonDefaults.setDiagnosticsOptions(diagnostics);
                    return true;
                  },

                  // Markers (diagnostics)
                  setModelMarkers: (owner, markers) => {
                    monaco.editor.setModelMarkers(requireModel(), owner || 'flutter', markers || []);
                    return true;
                  },

                  // Find & replace (programmatic)
                  findMatches: (q, options, limit) => {
                    const m = E().getModel();
                    if (!m) return [];
                    const isRegex = !!(options && options.isRegex);
                    const matchCase = !!(options && options.matchCase);
                    const wholeWord = !!(options && options.wholeWord);

                    let search = q ?? '';
                    let useRegex = isRegex;
                    if (wholeWord && !isRegex) {
                      search = '\\b' + escapeRegExp(String(q ?? '')) + '\\b';
                      useRegex = true;
                    }

                    const matches = m.findMatches(
                      search,
                      null,                 // searchScope: null = whole model (FIX: was 'false')
                      useRegex,
                      matchCase,
                      null,
                      false,                // captureMatches
                      limit || 9999
                    );
                    return matches.map(mm => ({ range: mm.range, match: m.getValueInRange(mm.range) }));
                  },

                  replaceMatches: (q, repl, options) => {
                    const m = E().getModel();
                    if (!m) return 0;
                    const isRegex = !!(options && options.isRegex);
                    const matchCase = !!(options && options.matchCase);
                    const wholeWord = !!(options && options.wholeWord);

                    let search = q ?? '';
                    let useRegex = isRegex;
                    if (wholeWord && !isRegex) {
                      search = '\\b' + escapeRegExp(String(q ?? '')) + '\\b';
                      useRegex = true;
                    }

                    const matches = m.findMatches(
                      search,
                      null,                 // searchScope: null = whole model (FIX: was 'false')
                      useRegex,
                      matchCase,
                      null,
                      false,                // captureMatches
                      9999
                    );
                    const edits = matches.map(mm => ({ range: mm.range, text: repl }));
                    applyUndoableEdits(m, edits);
                    return edits.length;
                  },

                  // View state
                  saveViewState: () => E().saveViewState(),
                  restoreViewState: (s) => E().restoreViewState(s),

                  // Stats
                  getStatistics: () => {
                    const e = E(), m = e.getModel(), s = e.getSelection();
                    const position = e.getPosition(); // FIX: Define position in this scope
                    const selections = e.getSelections() || [];
                    return {
                      lineCount: m ? m.getLineCount() : 0,
                      charCount: m ? m.getValueLength() : 0,
                      selLines: (s && !s.isEmpty()) ? (s.endLineNumber - s.startLineNumber + 1) : 0, // FIX: Return 0 for empty selection
                      selChars: (m && s && !s.isEmpty()) ? m.getValueInRange(s).length : 0,
                      caretCount: selections.length,
                      language: m ? (m.getLanguageId ? m.getLanguageId() : monaco.editor.getModelLanguage(m)) : undefined,
                      cursorLine: position?.lineNumber,
                      cursorColumn: position?.column,
                    };
                  },
                  
                  // Dirty tracking (per-model baselines keyed by URI)
                  _baselines: new Map(),
                  _markBaseline(model) {
                    const m = model || E().getModel();
                    if (m && m.uri) {
                      this._baselines.set(m.uri.toString(), m.getAlternativeVersionId());
                    }
                  },
                  hasUnsavedChanges: () => {
                    const m = E().getModel();
                    if (!m || !m.uri) return false;
                    const uri = m.uri.toString();
                    if (!window.flutterMonaco._baselines.has(uri)) {
                      window.flutterMonaco._markBaseline(m);
                    }
                    return m.getAlternativeVersionId() !== window.flutterMonaco._baselines.get(uri);
                  },
                  markSaved: () => window.flutterMonaco._markBaseline(),

                  // Models
                  createModel: (value, language, uri) =>
                    monaco.editor.createModel(value || '', language || 'plaintext', 
                      uri ? monaco.Uri.parse(uri) : undefined).uri.toString(),
                  setModel: (uri) => {
                    const m = monaco.editor.getModel(monaco.Uri.parse(uri));
                    if (m) E().setModel(m);
                  },
                  disposeModel: (uri) => {
                    const m = monaco.editor.getModel(monaco.Uri.parse(uri));
                    if (m) m.dispose();
                  },
                  listModels: () => monaco.editor.getModels().map(m => m.uri.toString()),
                };

                // ---- protocol v3 command registry (upcoming/v3.md 6.3) ----
                // Thin adapters over the ported helpers above: the wire
                // speaks dotted methods with named params; the bodies stay
                // the battle-tested 2.3.0 implementations. document.* takes
                // a uri param: null targets the ACTIVE model (the Dart
                // active-tracking document handle), a string targets that
                // exact model whether or not it is attached to the editor.
                {
                  const FM = window.FlutterMonaco;
                  const api = window.flutterMonaco;

                  const resolveModel = (uri) => {
                    if (uri === null || uri === undefined) return requireModel();
                    const model = monaco.editor.getModel(monaco.Uri.parse(uri));
                    if (!model) {
                      throw new Error('No model for uri: ' + uri);
                    }
                    return model;
                  };
                  const modelLanguage = (model) =>
                    model.getLanguageId ? model.getLanguageId() : monaco.editor.getModelLanguage(model);
                  const searchSpec = (q, opts) => {
                    const isRegex = !!(opts && opts.isRegex);
                    const wholeWord = !!(opts && opts.wholeWord);
                    let search = q ?? '';
                    let useRegex = isRegex;
                    if (wholeWord && !isRegex) {
                      search = '\\b' + escapeRegExp(String(q ?? '')) + '\\b';
                      useRegex = true;
                    }
                    return { search, useRegex, matchCase: !!(opts && opts.matchCase) };
                  };
                  const findMatchesIn = (model, q, opts, limit) => {
                    const s = searchSpec(q, opts);
                    // Second argument selects Monaco's searchOnlyEditableRange
                    // overload; false/null both mean "whole model".
                    return model.findMatches(
                      s.search, !!(opts && opts.searchOnlyEditableRange),
                      s.useRegex, s.matchCase, null, false, limit || 9999);
                  };
                  const markDirtyBaseline = (model) => {
                    if (model && model.uri) {
                      api._baselines.set(model.uri.toString(), model.getAlternativeVersionId());
                    }
                  };
                  const isModelDirty = (model) => {
                    if (!model || !model.uri) return false;
                    const uri = model.uri.toString();
                    // Every model created through the bridge is baselined at
                    // registerDocument time; this lazy fallback only covers
                    // models created behind the bridge's back (page.eval).
                    if (!api._baselines.has(uri)) markDirtyBaseline(model);
                    return model.getAlternativeVersionId() !== api._baselines.get(uri);
                  };

                  // ---- document registry ----
                  // Every model the bridge knows gets (1) a dirty baseline AT
                  // CREATION - baselining lazily on the first isDirty query
                  // records an already-edited version and misses the first
                  // edit - and (2) its own content subscription, so pinned
                  // edits to INACTIVE documents emit contentChanged exactly
                  // like active ones (the editor-level listener only ever saw
                  // the attached model).
                  const emitEvent = ctx.post
                    ? ctx.post
                    : function (name, data) { FM.emit(name, data); };
                  const emitModelContentChange = (model, e) => {
                    var changes = [];
                    var totalLength = 0;
                    for (var i = 0; i < e.changes.length; i++) {
                      var c = e.changes[i];
                      totalLength += (c.text || '').length;
                      changes.push({ range: c.range, text: c.text });
                    }
                    // D15: omit the deltas when the combined inserted text
                    // tops 64 KiB, or when the change COUNT alone would
                    // bloat the envelope (multi-cursor edit storms carry a
                    // range object per change even with tiny text).
                    var truncated = totalLength > 65536 || e.changes.length > 1000;
                    emitEvent('contentChanged', {
                      uri: model && model.uri ? model.uri.toString() : null,
                      isFlush: e.isFlush,
                      changes: truncated ? undefined : changes,
                      truncated: truncated,
                    });
                  };
                  const modelSubscriptions = new Map();
                  const unregisterDocument = (uri) => {
                    const subs = modelSubscriptions.get(uri);
                    if (subs) {
                      try { subs.content.dispose(); } catch (_) {}
                      try { if (subs.willDispose) subs.willDispose.dispose(); } catch (_) {}
                      modelSubscriptions.delete(uri);
                    }
                    // Baselines are keyed by URI, not model: a stale entry
                    // would make a fresh document at the same URI read dirty.
                    api._baselines.delete(uri);
                  };
                  const registerDocument = (model) => {
                    if (!model || !model.uri) return model;
                    const uri = model.uri.toString();
                    if (!api._baselines.has(uri)) {
                      api._baselines.set(uri, model.getAlternativeVersionId());
                    }
                    if (!modelSubscriptions.has(uri)) {
                      const content = model.onDidChangeContent(function (e) {
                        emitModelContentChange(model, e);
                      });
                      const willDispose = model.onWillDispose
                        ? model.onWillDispose(function () { unregisterDocument(uri); })
                        : null;
                      modelSubscriptions.set(uri, {
                        content: content,
                        willDispose: willDispose,
                      });
                    }
                    return model;
                  };
                  // The boot document already exists when this module
                  // installs (boot.js creates it before monaco.editor.create
                  // fires onDidCreateEditor).
                  monaco.editor.getModels().forEach(registerDocument);

                  FM.register('focus.force', (p) =>
                    api.forceFocus(p && p.replayInputFocus ? { replayInputFocus: true } : {}));
                  FM.register('editor.layout', () => api.layout());
                  FM.register('document.getText', (p) => resolveModel(p.uri).getValue());
                  FM.register('document.setText', (p) => {
                    const model = resolveModel(p.uri);
                    model.setValue(p.text || '');
                    // setValue resets Monaco's undo stack and version ids,
                    // which would leave the version-id dirty check
                    // inconsistent; re-baseline so setText always means a
                    // clean programmatic load.
                    markDirtyBaseline(model);
                    return true;
                  });
                  FM.register('document.lineCount', (p) => resolveModel(p.uri).getLineCount());
                  FM.register('document.getLines', (p) => {
                    const model = resolveModel(p.uri);
                    const lineCount = model.getLineCount();
                    if (p.strict &&
                        (p.startLine < 1 || p.startLine > lineCount ||
                         p.endLine > lineCount)) {
                      throw new Error(
                        'Line out of range: ' + p.startLine + '-' + p.endLine +
                        ' (document has ' + lineCount + ' lines).');
                    }
                    const start = Math.min(Math.max(1, p.startLine), lineCount);
                    const end = Math.min(Math.max(start, p.endLine), lineCount);
                    const lines = [];
                    for (let ln = start; ln <= end; ln++) lines.push(model.getLineContent(ln));
                    return lines;
                  });
                  FM.register('document.setLanguage', (p) => {
                    monaco.editor.setModelLanguage(resolveModel(p.uri), p.language);
                    return true;
                  });
                  FM.register('document.getLanguage', (p) => modelLanguage(resolveModel(p.uri)));
                  FM.register('document.applyEdits', (p) => {
                    applyUndoableEdits(resolveModel(p.uri), p.edits || []);
                    return true;
                  });
                  FM.register('document.findMatches', (p) => {
                    const model = resolveModel(p.uri);
                    const matches = findMatchesIn(model, p.query,
                      { isRegex: p.isRegex, matchCase: p.matchCase, wholeWord: p.wholeWord,
                        searchOnlyEditableRange: p.searchOnlyEditableRange }, p.limit);
                    return matches.map((mm) => ({ range: mm.range, match: model.getValueInRange(mm.range) }));
                  });
                  FM.register('document.replaceMatches', (p) => {
                    const model = resolveModel(p.uri);
                    const matches = findMatchesIn(model, p.query,
                      { isRegex: p.isRegex, matchCase: p.matchCase, wholeWord: p.wholeWord,
                        searchOnlyEditableRange: p.searchOnlyEditableRange }, 9999);
                    const edits = matches.map((mm) => ({ range: mm.range, text: p.replacement }));
                    applyUndoableEdits(model, edits);
                    return edits.length;
                  });
                  FM.register('document.getWordAt', (p) => {
                    const w = resolveModel(p.uri).getWordAtPosition(
                      new monaco.Position(p.position.lineNumber, p.position.column));
                    return w ? w.word : null;
                  });
                  FM.register('document.isDirty', (p) => isModelDirty(resolveModel(p.uri)));
                  FM.register('document.markSaved', (p) => {
                    markDirtyBaseline(resolveModel(p.uri));
                    return true;
                  });
                  FM.register('document.setMarkers', (p) => {
                    monaco.editor.setModelMarkers(resolveModel(p.uri), p.owner || 'flutter', p.markers || []);
                    return true;
                  });
                  FM.register('docs.open', (p) => {
                    const uri = api.createModel(p.text, p.language, p.uri);
                    registerDocument(monaco.editor.getModel(monaco.Uri.parse(uri)));
                    return uri;
                  });
                  FM.register('docs.close', (p) => {
                    const model = resolveModel(p.uri);
                    // Unregister BEFORE dispose so a straggling edit on a
                    // stale handle can no longer emit; the onWillDispose hook
                    // covers models disposed behind the bridge's back.
                    unregisterDocument(model.uri.toString());
                    model.dispose();
                    return true;
                  });
                  FM.register('docs.list', () => api.listModels());
                  FM.register('docs.activate', (p) => {
                    requireEditor().setModel(resolveModel(p.uri));
                    return true;
                  });
                  FM.register('docs.activeUri', () => {
                    const ed = E();
                    const model = ed && ed.getModel ? ed.getModel() : null;
                    return model && model.uri ? model.uri.toString() : null;
                  });
                  FM.register('editor.getState', () => {
                    const model = requireModel();
                    return {
                      content: model.getValue(),
                      selection: api.getSelection(),
                      cursorPosition: api.getCursorPosition(),
                      lineCount: model.getLineCount(),
                      isDirty: isModelDirty(model),
                      language: modelLanguage(model),
                      theme: api.getTheme(),
                      stats: api.getStatistics(),
                    };
                  });
                  FM.register('editor.updateOptions', (p) => api.updateOptions(p.options));
                  FM.register('editor.setTheme', (p) => api.setTheme(p.theme));
                  FM.register('editor.getTheme', () => api.getTheme());
                  FM.register('editor.defineTheme', (p) => api.defineTheme(p.id, p.data));
                  FM.register('editor.getSelection', () => api.getSelection());
                  FM.register('editor.setSelection', (p) => api.setSelection(p.range));
                  FM.register('editor.getCursor', () => api.getCursorPosition());
                  FM.register('editor.setCursor', (p) =>
                    api.setCursorPosition(p.position.lineNumber, p.position.column));
                  FM.register('editor.reveal', (p) => {
                    const lineCount = requireModel().getLineCount();
                    const clamp = (ln) => Math.min(Math.max(1, ln), lineCount);
                    const range = {
                      startLineNumber: clamp(p.range.startLineNumber),
                      startColumn: p.range.startColumn,
                      endLineNumber: clamp(p.range.endLineNumber),
                      endColumn: p.range.endColumn,
                    };
                    return api.revealRange(range, !!p.center);
                  });
                  FM.register('editor.scrollToEdge', (p) => {
                    const ed = E();
                    if (!ed) return false;
                    if (p.edge === 'top') {
                      ed.setScrollPosition({ scrollTop: 0, scrollLeft: 0 });
                      ed.setPosition({ lineNumber: 1, column: 1 });
                      ed.revealLineInCenterIfOutsideViewport(1);
                    } else {
                      const model = ed.getModel();
                      if (!model) return false;
                      const lineCount = model.getLineCount();
                      ed.revealLineInCenterIfOutsideViewport(lineCount);
                      ed.setPosition({ lineNumber: lineCount, column: 1 });
                    }
                    return true;
                  });
                  FM.register('editor.executeAction', (p) => api.executeAction(p.actionId, p.args));
                  FM.register('editor.captureViewState', () => api.saveViewState());
                  FM.register('editor.restoreViewState', (p) => api.restoreViewState(p.state));

                  // Decoration sets over createDecorationsCollection: each
                  // Dart MonacoDecorationSet owns one collection; set()
                  // replaces its contents atomically without touching other
                  // sets (the 2.x deltaDecorations id-juggling is gone).
                  const decorationSets = new Map();
                  let nextDecorationSetId = 1;
                  const requireDecorationSet = (setId) => {
                    const collection = decorationSets.get(setId);
                    if (!collection) {
                      throw new Error('Unknown decoration set: ' + setId);
                    }
                    return collection;
                  };
                  FM.register('decorations.create', () => {
                    const id = 'ds' + nextDecorationSetId++;
                    decorationSets.set(id, requireEditor().createDecorationsCollection([]));
                    return id;
                  });
                  FM.register('decorations.set', (p) => {
                    requireDecorationSet(p.setId).set(p.decorations || []);
                    return true;
                  });
                  FM.register('decorations.clear', (p) => {
                    requireDecorationSet(p.setId).clear();
                    return true;
                  });
                  FM.register('decorations.dispose', (p) => {
                    const collection = decorationSets.get(p.setId);
                    if (collection) {
                      collection.clear();
                      decorationSets.delete(p.setId);
                    }
                    return true;
                  });

                  FM.register('json.configureDiagnostics', (p) => api.setJsonDiagnosticsOptions(p.options));
                  FM.register('page.setBackground', (p) => api.setHostPageBackground(p.color));
                }

  ctx.escapeRegExp = escapeRegExp;
  ctx.requireEditor = requireEditor;
  ctx.requireModel = requireModel;
};

window.__FMB.completions = function (ctx) {
  // Completion bridge: JS stays dumb, Flutter drives the data. Every Monaco
  // completion query rides the protocol v3 request channel as a 'completion'
  // request; Dart answers through FlutterMonaco.respond. On Monaco-side
  // cancellation the provider resolves locally with empty suggestions and
  // drops the pending request so the late Dart answer is a no-op.
  (function () {
    const completion = {
      providers: Object.create(null),
      reqSeq: 0,
    };

    function toIRange(r) {
      if (!r) return undefined;
      const sL = r.startLineNumber ?? r.startLine ?? r.from_line ?? r.start ?? 1;
      const sC = r.startColumn ?? r.startCol ?? r.sc ?? 1;
      const eL = r.endLineNumber ?? r.endLine ?? r.to_line ?? r.end ?? sL;
      const eC = r.endColumn ?? r.endCol ?? r.ec ?? sC;
      return {
        startLineNumber: sL,
        startColumn: sC,
        endLineNumber: eL,
        endColumn: eC,
      };
    }

    // Maps Dart's CompletionList JSON to Monaco's CompletionList shape.
    function mapSuggestions(payload, fallbackRange) {
      const items = (payload && payload.suggestions) || [];
      const defaultRange = payload?.defaultRange || fallbackRange;
      const mapped = items.map((it) => {
        let kind = it.kind;
        if (typeof kind === 'string') {
          kind = monaco.languages.CompletionItemKind[kind] ??
            monaco.languages.CompletionItemKind.Text;
        }
        let insertTextRules = it.insertTextRules;
        if (Array.isArray(insertTextRules)) {
          insertTextRules = insertTextRules.reduce((mask, rule) => {
            const value = monaco.languages.CompletionItemInsertTextRule[rule];
            return typeof value === 'number' ? (mask | value) : mask;
          }, 0);
        }
        return {
          label: it.label,
          // Nullish (not falsy) fallback: an intentionally EMPTY insertText
          // must stay empty instead of inserting the label.
          insertText: it.insertText ?? it.label,
          kind: kind || monaco.languages.CompletionItemKind.Text,
          detail: it.detail,
          documentation: it.documentation,
          sortText: it.sortText,
          filterText: it.filterText,
          commitCharacters: it.commitCharacters,
          insertTextRules: insertTextRules || undefined,
          range: toIRange(it.range) || toIRange(defaultRange),
        };
      });
      return { suggestions: mapped, incomplete: !!payload?.isIncomplete };
    }

    // cfg: { id: string, languages: string[], triggerCharacters?: string[] }
    function registerProvider(cfg) {
      if (!cfg || !cfg.id) throw new Error('completions.register requires id');
      const id = cfg.id;
      const langs = Array.isArray(cfg.languages)
        ? cfg.languages
        : [cfg.languages ?? 'plaintext'];
      const triggerCharacters = cfg.triggerCharacters || [];

      const provider = {
        triggerCharacters,
        provideCompletionItems: (model, position, context, token) =>
          new Promise((resolve) => {
            const lang =
              (model.getLanguageId && model.getLanguageId()) ||
              monaco.editor.getModelLanguage(model);
            const word = model.getWordUntilPosition(position);
            const defaultRange = {
              startLineNumber: position.lineNumber,
              startColumn: word.startColumn,
              endLineNumber: position.lineNumber,
              endColumn: word.endColumn,
            };
            const pending = window.FlutterMonaco.request('completion', {
              providerId: id,
              requestId: id + ':' + (++completion.reqSeq),
              language: lang,
              uri: model.uri?.toString(),
              position: {
                lineNumber: position.lineNumber,
                column: position.column,
              },
              defaultRange,
              lineText: model.getLineContent(position.lineNumber),
              triggerKind: context?.triggerKind ?? null,
              triggerCharacter: context?.triggerCharacter ?? null,
            });

            token?.onCancellationRequested?.(() => {
              window.FlutterMonaco.dropRequest(pending.id);
              try {
                resolve({ suggestions: [] });
              } catch (_) {}
            });

            pending.promise.then(
              (payload) => resolve(mapSuggestions(payload, defaultRange)),
              () => resolve({ suggestions: [] }),
            );
          }),
      };

      // Dispose-then-replace on duplicate ids (mirrors actions.register):
      // a transient unregister failure must not leave two live providers
      // answering the same providerId with duplicated suggestions.
      const existing = completion.providers[id];
      if (existing && existing.disposables) {
        for (const d of existing.disposables) {
          try {
            d.dispose();
          } catch (_) {}
        }
      }

      const disposables = langs.map((l) =>
        monaco.languages.registerCompletionItemProvider(l, provider),
      );
      completion.providers[id] = { disposables };
      return true;
    }

    function unregisterProvider(id) {
      const p = completion.providers[id];
      if (p?.disposables) {
        for (const d of p.disposables) {
          try {
            d.dispose();
          } catch (_) {}
        }
      }
      delete completion.providers[id];
      return true;
    }

    window.FlutterMonaco.register('completions.register', (p) =>
      registerProvider(p));
    window.FlutterMonaco.register('completions.unregister', (p) =>
      unregisterProvider(p.id));
  })();
};

window.__FMB.actions = function (ctx) {
  // Dart-defined editor actions (D16): Dart registers an action descriptor
  // with symbolic keybindings; each invocation rides the protocol v3 request
  // channel as an 'action' request and Dart runs the callback. Errors from
  // Dart are logged here and never crash the editor.
  const { requireEditor } = ctx;
  (function () {
    const registered = Object.create(null);

    // {key: 'KeyS', ctrlCmd: true, ...} -> monaco keybinding bitmask.
    function composeKeybinding(kb) {
      const code = monaco.KeyCode[kb.key];
      if (typeof code !== 'number') {
        throw new Error('Unknown key: ' + kb.key);
      }
      let chord = code;
      if (kb.ctrlCmd) chord |= monaco.KeyMod.CtrlCmd;
      if (kb.shift) chord |= monaco.KeyMod.Shift;
      if (kb.alt) chord |= monaco.KeyMod.Alt;
      if (kb.winCtrl) chord |= monaco.KeyMod.WinCtrl;
      return chord;
    }

    window.FlutterMonaco.register('actions.register', (p) => {
      if (!p || !p.id) throw new Error('actions.register requires id');
      const editor = requireEditor();
      const existing = registered[p.id];
      if (existing) {
        try {
          existing.dispose();
        } catch (_) {}
        delete registered[p.id];
      }
      const keybindings = (p.keybindings || []).map(composeKeybinding);
      registered[p.id] = editor.addAction({
        id: p.id,
        label: p.label || p.id,
        keybindings: keybindings.length ? keybindings : undefined,
        contextMenuGroupId: p.contextMenuGroupId || undefined,
        contextMenuOrder: p.contextMenuOrder ?? undefined,
        precondition: p.precondition || undefined,
        run: () => {
          const pending = window.FlutterMonaco.request('action', {
            actionId: p.id,
          });
          return pending.promise.catch((e) => {
            window.FlutterMonaco.log(
              'warn',
              'action ' + p.id + ' failed: ' + ((e && e.message) || e),
            );
          });
        },
      });
      return true;
    });

    window.FlutterMonaco.register('actions.unregister', (p) => {
      const disposable = registered[p && p.id];
      if (disposable) {
        try {
          disposable.dispose();
        } catch (_) {}
        delete registered[p.id];
      }
      return true;
    });
  })();
};
