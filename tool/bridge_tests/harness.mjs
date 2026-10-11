// Node harness that executes the REAL bridge JavaScript against a minimal
// Monaco stub. This is the semantic layer the Dart fakes cannot cover: the
// Dart suite proves what gets dispatched; these tests prove what the bridge
// implementations actually do with it (dirty baselines, per-model events,
// action promises, completion mapping).
//
// The stub mirrors the Monaco 0.57 behaviors the bridge depends on and
// exposes nothing real Monaco lacks (there is no monaco.editor.getTheme, for
// instance): model applyEdits bypasses the undo stack while
// pushEditOperations joins the open undo element, findMatches applies
// Monaco's word-separator whole-word rule, editor.trigger drops the command
// service promise, and every created editor fires onDidCreateEditor before
// its model is attached.
//
// Run: node --test tool/bridge_tests/
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';
import vm from 'node:vm';

const repoRoot = path.resolve(
  path.dirname(url.fileURLToPath(import.meta.url)),
  '..',
  '..',
);

/** Monaco 0.57's default `wordSeparators` editor option. */
export const DEFAULT_WORD_SEPARATORS = '`~!@#$%^&*()-=+[{]}\\|;:\'",.<>/?';

/** Creates an isolated "page" context and loads core.js into it. */
export function createPage() {
  const messages = [];
  const sandbox = {
    console,
    setTimeout,
    clearTimeout,
    setInterval,
    clearInterval,
    navigator: { userAgent: 'node-bridge-harness' },
    document: {
      getElementById: () => null,
      body: null,
      addEventListener: () => {},
      querySelector: () => null,
    },
    addEventListener: () => {},
    removeEventListener: () => {},
    flutterChannel: {
      postMessage: (json) => messages.push(JSON.parse(json)),
    },
    __FM_PAGE: { platform: 'test', monacoVersion: 'stub', token: '' },
  };
  sandbox.window = sandbox;
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);

  const load = (relative) =>
    vm.runInContext(
      fs.readFileSync(path.join(repoRoot, relative), 'utf8'),
      sandbox,
      { filename: relative },
    );
  load('assets/monaco/bridge/core.js');
  return { sandbox, messages, load };
}

class Emitter {
  constructor() {
    this.handlers = new Set();
  }

  event = (handler) => {
    this.handlers.add(handler);
    return { dispose: () => this.handlers.delete(handler) };
  };

  fire(event) {
    for (const handler of [...this.handlers]) handler(event);
  }
}

/** Installs a minimal Monaco stub faithful to the APIs the bridge uses. */
export function installMonacoStub(sandbox) {
  const models = new Map();

  class Uri {
    constructor(value) {
      this._value = String(value);
    }

    get scheme() {
      const index = this._value.indexOf(':');
      return index < 0 ? '' : this._value.slice(0, index);
    }

    get path() {
      try {
        return new URL(this._value).pathname;
      } catch (_) {
        return this._value;
      }
    }

    toString() {
      return this._value;
    }

    static parse(value) {
      return new Uri(value);
    }
  }

  const isSeparator = (separators, ch) =>
    ch === ' ' || ch === '\t' || separators.includes(ch);

  // Monaco's whole-word rule (textModelSearch isValidMatch): each match edge
  // must touch the text boundary, a line break, or a separator - on either
  // side of the edge.
  const isWholeWordMatch = (text, start, end, separators) => {
    const left =
      start === 0 ||
      text[start - 1] === '\n' ||
      isSeparator(separators, text[start - 1]) ||
      isSeparator(separators, text[start]);
    const right =
      end === text.length ||
      text[end] === '\n' ||
      isSeparator(separators, text[end]) ||
      isSeparator(separators, text[end - 1]);
    return left && right;
  };

  let modelSeq = 0;
  function createModel(value, language, uri) {
    const modelUri = uri || Uri.parse(`inmemory://model/${++modelSeq}`);
    const contentEmitter = new Emitter();
    const disposeEmitter = new Emitter();
    // Snapshot undo model: an element records the text before its first
    // edit. pushEditOperations joins the OPEN element (as in Monaco, where
    // consecutive edits share one element until pushStackElement closes
    // it); applyEdits never touches the stack.
    const undoStack = [];
    const redoStack = [];
    let openElement = null;
    const model = {
      uri: modelUri,
      _value: value || '',
      _altId: 1,
      _lang: language || 'plaintext',
      isDisposed: false,
      getValue() {
        return this._value;
      },
      setValue(next) {
        this._value = next ?? '';
        this._altId += 1;
        undoStack.length = 0;
        redoStack.length = 0;
        openElement = null;
        contentEmitter.fire({
          isFlush: true,
          changes: [
            {
              range: {
                startLineNumber: 1,
                startColumn: 1,
                endLineNumber: 1,
                endColumn: 1,
              },
              text: this._value,
            },
          ],
        });
      },
      getAlternativeVersionId() {
        return this._altId;
      },
      getLineCount() {
        return this._value.split('\n').length;
      },
      getLineContent(line) {
        return this._value.split('\n')[line - 1] ?? '';
      },
      getValueLength() {
        return this._value.length;
      },
      getLanguageId() {
        return this._lang;
      },
      getOffsetAt(position) {
        const lines = this._value.split('\n');
        const lineNumber = Math.min(
          Math.max(1, position.lineNumber),
          lines.length,
        );
        let offset = 0;
        for (let i = 0; i < lineNumber - 1; i++) offset += lines[i].length + 1;
        const column = Math.min(
          Math.max(1, position.column),
          lines[lineNumber - 1].length + 1,
        );
        return offset + column - 1;
      },
      getPositionAt(offset) {
        const before = this._value.slice(0, offset).split('\n');
        return {
          lineNumber: before.length,
          column: before[before.length - 1].length + 1,
        };
      },
      getValueInRange(range) {
        return this._value.slice(
          this.getOffsetAt({
            lineNumber: range.startLineNumber,
            column: range.startColumn,
          }),
          this.getOffsetAt({
            lineNumber: range.endLineNumber,
            column: range.endColumn,
          }),
        );
      },
      getWordUntilPosition() {
        return { word: '', startColumn: 1, endColumn: 1 };
      },
      getWordAtPosition() {
        return null;
      },
      findMatches(
        searchString,
        _searchScope,
        isRegex,
        matchCase,
        wordSeparators,
        _captureMatches,
        limitResultCount = 999,
      ) {
        (sandbox.__findCalls ??= []).push({
          searchString,
          isRegex,
          matchCase,
          wordSeparators,
          limitResultCount,
        });
        if (!searchString) return [];
        const source = isRegex
          ? searchString
          : searchString.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const regex = new RegExp(source, matchCase ? 'gm' : 'gim');
        const text = this._value;
        const result = [];
        let match;
        while (result.length < limitResultCount &&
            (match = regex.exec(text)) !== null) {
          if (match[0].length === 0) {
            regex.lastIndex += 1;
            continue;
          }
          const start = match.index;
          const end = start + match[0].length;
          if (wordSeparators !== null && wordSeparators !== undefined &&
              !isWholeWordMatch(text, start, end, wordSeparators)) {
            continue;
          }
          const from = this.getPositionAt(start);
          const to = this.getPositionAt(end);
          result.push({
            range: {
              startLineNumber: from.lineNumber,
              startColumn: from.column,
              endLineNumber: to.lineNumber,
              endColumn: to.column,
            },
            matches: null,
          });
        }
        return result;
      },
      _applyRaw(edits) {
        const resolved = (edits || []).map((edit, index) => {
          const range = edit.range || {
            startLineNumber: 1,
            startColumn: 1,
            endLineNumber: 1,
            endColumn: 1,
          };
          return {
            index,
            range,
            text: edit.text || '',
            start: this.getOffsetAt({
              lineNumber: range.startLineNumber,
              column: range.startColumn,
            }),
            end: this.getOffsetAt({
              lineNumber: range.endLineNumber,
              column: range.endColumn,
            }),
          };
        });
        // Apply back to front so earlier offsets stay valid.
        const ordered = [...resolved].sort(
          (a, b) => b.start - a.start || b.index - a.index,
        );
        let next = this._value;
        for (const edit of ordered) {
          next = next.slice(0, edit.start) + edit.text + next.slice(edit.end);
        }
        this._value = next;
        this._altId += 1;
        contentEmitter.fire({
          isFlush: false,
          changes: resolved.map((edit) => ({
            range: edit.range,
            text: edit.text,
          })),
        });
      },
      applyEdits(edits) {
        this._applyRaw(edits);
      },
      pushStackElement() {
        openElement = null;
      },
      // Lines holding only auto-inserted indentation (Monaco records them
      // when the user presses Enter); tests set this directly.
      _trimAutoWhitespaceLines: null,
      pushEditOperations(beforeCursorState, edits) {
        // TextModel._pushEditOperations: unless some cursor of
        // beforeCursorState lies outside every edit, each recorded
        // auto-whitespace line that no edit touches is trimmed - so an
        // EMPTY cursor state always trims.
        if (this._trimAutoWhitespaceLines) {
          const overlaps = (a, b) =>
            !(a.startLineNumber > b.endLineNumber ||
              b.startLineNumber > a.endLineNumber);
          const cursors = beforeCursorState || [];
          const allCursorsEdited = cursors.every((cursor) =>
            (edits || []).some((edit) => overlaps(edit.range, cursor)));
          if (allCursorsEdited) {
            const trims = this._trimAutoWhitespaceLines
              .filter((line) => !(edits || []).some((edit) =>
                line >= edit.range.startLineNumber &&
                line <= edit.range.endLineNumber))
              .map((line) => ({
                range: {
                  startLineNumber: line,
                  startColumn: 1,
                  endLineNumber: line,
                  endColumn: this.getLineContent(line).length + 1,
                },
                text: '',
              }));
            edits = [...(edits || []), ...trims];
          }
          this._trimAutoWhitespaceLines = null;
        }
        if (!openElement) {
          openElement = { before: this._value };
          undoStack.push(openElement);
        }
        redoStack.length = 0;
        this._applyRaw(edits);
        return null;
      },
      undo() {
        openElement = null;
        const element = undoStack.pop();
        if (!element) return;
        redoStack.push({ before: this._value });
        this._restore(element.before);
      },
      redo() {
        openElement = null;
        const element = redoStack.pop();
        if (!element) return;
        undoStack.push({ before: this._value });
        this._restore(element.before);
      },
      _restore(text) {
        this._value = text;
        this._altId += 1;
        contentEmitter.fire({ isFlush: false, changes: [] });
      },
      onDidChangeContent: contentEmitter.event,
      onWillDispose: disposeEmitter.event,
      dispose() {
        disposeEmitter.fire({});
        this.isDisposed = true;
        models.delete(this.uri.toString());
      },
    };
    models.set(modelUri.toString(), model);
    return model;
  }

  const EditorOption = { wordSeparators: 132 };

  // Command ids registered with the (shared) command service. Tests add
  // entries through sandbox.__testCommands; an unknown id rejects exactly
  // like Monaco's StandaloneCommandService.
  const commandService = {
    executeCommand(id, ...args) {
      const command = (sandbox.__testCommands || {})[id];
      if (typeof command !== 'function') {
        return Promise.reject(new Error(`command '${id}' not found`));
      }
      try {
        return Promise.resolve(command(...args));
      } catch (error) {
        return Promise.reject(error);
      }
    },
  };
  // Ids CodeEditorWidget.trigger handles itself, and editor commands it
  // runs through the editor-extension registry (never the command service).
  const triggerHandlers = new Set([
    'compositionStart',
    'compositionEnd',
    'type',
    'replacePreviousChar',
    'compositionType',
    'paste',
    'cut',
  ]);
  const editorCommands = new Set(['undo', 'redo', 'cursorDown']);

  function createStubEditor({ container = null, parent = null } = {}) {
    const modelChangeEmitter = new Emitter();
    const contentEmitter = new Emitter();
    const cursorEmitter = new Emitter();
    const focusEmitter = new Emitter();
    const blurEmitter = new Emitter();
    let attached = null;
    let attachedSubscription = null;
    const editor = {
      getModel: () => attached,
      setModel(model) {
        if (attachedSubscription) attachedSubscription.dispose();
        attached = model || null;
        attachedSubscription = attached
          ? attached.onDidChangeContent((e) => contentEmitter.fire(e))
          : null;
        modelChangeEmitter.fire({});
      },
      onDidChangeModel: modelChangeEmitter.event,
      onDidChangeModelContent: contentEmitter.event,
      onDidChangeCursorSelection: cursorEmitter.event,
      onDidFocusEditorWidget: focusEmitter.event,
      onDidBlurEditorWidget: blurEmitter.event,
      getContainerDomNode: () => container,
      getDomNode: () => container,
      getOption: (id) =>
        id === EditorOption.wordSeparators
          ? (sandbox.__wordSeparators ?? DEFAULT_WORD_SEPARATORS)
          : undefined,
      getAction: (id) => (sandbox.__testActions || {})[id] || null,
      _commandService: commandService,
      // CodeEditorWidget.trigger: the command-service promise is dropped,
      // so an unknown id only ever surfaces as an unhandled rejection.
      trigger(_source, handlerId, payload) {
        (sandbox.__triggered ??= []).push(handlerId);
        if (triggerHandlers.has(handlerId)) return;
        const action = editor.getAction(handlerId);
        if (action) {
          Promise.resolve(action.run(payload)).then(undefined, () => {});
          return;
        }
        if (!attached || editorCommands.has(handlerId)) return;
        editor._commandService.executeCommand(handlerId, payload);
      },
      updateOptions(options) {
        (sandbox.__updatedOptions ??= []).push(options);
        if (options && typeof options.theme === 'string') {
          sandbox.__appliedTheme = options.theme;
        }
      },
      layout() {},
      focus() {},
      getSelection: () => null,
      getSelections: () => sandbox.__selections ?? [],
      getPosition: () => null,
      setSelection() {},
      setPosition() {},
      setScrollPosition() {},
      revealLineInCenterIfOutsideViewport() {},
      saveViewState: () => ({}),
      restoreViewState() {},
      createDecorationsCollection: () => ({ set() {}, clear() {} }),
      deltaDecorations: () => [],
      addAction(descriptor) {
        (sandbox.__addedActions ??= []).push(descriptor);
        return { dispose() {} };
      },
      dispose() {
        editor.setModel(null);
      },
    };
    if (parent) editor.getParentEditor = () => parent;
    return editor;
  }

  // monaco.editor.onDidCreateEditor fires from the CodeEditorWidget
  // constructor, i.e. BEFORE the creating call attaches the model.
  const createEditorEmitter = new Emitter();
  const emitCreated = (editor) => {
    createEditorEmitter.fire(editor);
    return editor;
  };
  const editors = [];

  const editor = createStubEditor();

  sandbox.monaco = {
    Uri,
    MarkerTag: { Unnecessary: 1, Deprecated: 2 },
    Position: class {
      constructor(lineNumber, column) {
        this.lineNumber = lineNumber;
        this.column = column;
      }
    },
    KeyCode: {},
    KeyMod: {},
    editor: {
      EditorOption,
      createModel,
      getModel: (uri) => models.get(uri.toString()) || null,
      getModels: () => [...models.values()],
      setModelLanguage: (model, lang) => {
        model._lang = lang;
      },
      setModelMarkers(model, owner, markers) {
        (sandbox.__markerCalls ??= []).push({ model, owner, markers });
      },
      setTheme(theme) {
        sandbox.__appliedTheme = theme;
      },
      onDidCreateEditor: createEditorEmitter.event,
      create(container, options = {}) {
        const created = emitCreated(createStubEditor({ container }));
        editors.push(created);
        if (typeof options.theme === 'string') {
          sandbox.__appliedTheme = options.theme;
        }
        created.setModel(options.model || null);
        return created;
      },
    },
    languages: {
      CompletionItemKind: { Text: 0 },
      CompletionItemInsertTextRule: {},
      registerCompletionItemProvider(language, provider) {
        (sandbox.__completionProviders ??= []).push({ language, provider });
        return { dispose() {} };
      },
    },
  };

  /**
   * Creates an editor the way Monaco's peek widget does (an
   * EmbeddedCodeEditorWidget with a parent editor): it fires
   * onDidCreateEditor without going through monaco.editor.create.
   */
  const createEmbeddedEditor = (parentEditor, container = {}) => {
    const embedded = emitCreated(
      createStubEditor({ container, parent: parentEditor }),
    );
    editors.push(embedded);
    return embedded;
  };

  return { models, editor, editors, createStubEditor, createEmbeddedEditor };
}

/**
 * Boots an editor-mode page the way boot.js does: boot model first, editor
 * attached, then the bridge modules installed over the shared ctx.
 */
export function bootEditorPage() {
  const page = createPage();
  const stub = installMonacoStub(page.sandbox);
  const bootModel = page.sandbox.monaco.editor.createModel(
    'boot text',
    'plaintext',
  );
  stub.editor.setModel(bootModel);
  page.sandbox.editor = stub.editor;

  page.load('assets/monaco/bridge/editor-api.js');
  const ctx = {};
  page.sandbox.__FMB.core(ctx);
  page.sandbox.__FMB.editorApi(ctx);
  page.load('assets/monaco/bridge/diff-api.js');
  const completionsOk = (() => {
    page.sandbox.__FMB.completions(ctx);
    page.sandbox.__FMB.actions(ctx);
    return true;
  })();
  if (!completionsOk) throw new Error('module install failed');
  return { ...page, ...stub, ctx, bootModel };
}

/** Resolves once [predicate] holds, polling the event loop. */
export async function waitFor(predicate, what = 'condition') {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    if (predicate()) return;
    await new Promise((resolve) => setTimeout(resolve, 1));
  }
  throw new Error(`timed out waiting for ${what}`);
}

/** Lifecycle envelopes with the given name. */
export function lifecyclesNamed(page, name) {
  return page.messages.filter(
    (message) => message.kind === 'lifecycle' && message.name === name,
  );
}

/**
 * Boots a full editor page through the REAL boot.js: every bridge script
 * is loaded in the generated page's order, page.boot is dispatched, and
 * monaco.editor.create fires onDidCreateEditor exactly like Monaco does.
 * Resolves once the page posted lifecycle 'ready'.
 */
export async function bootFullPage(bootParams = {}) {
  const page = createPage();
  const { sandbox } = page;
  const stub = installMonacoStub(sandbox);

  // Window listeners are recorded so tests can detect duplicate installs.
  const windowListeners = [];
  sandbox.addEventListener = (type, handler, options) => {
    windowListeners.push({ type, handler, options });
  };
  sandbox.removeEventListener = (type, handler) => {
    const index = windowListeners.findIndex(
      (entry) => entry.type === type && entry.handler === handler,
    );
    if (index >= 0) windowListeners.splice(index, 1);
  };

  const container = { id: 'editor-container', nodeType: 1, style: {} };
  sandbox.document.getElementById = (id) =>
    id === 'editor-container' ? container : null;
  // AMD loader stand-in: editor.main is already "loaded".
  sandbox.require = (_deps, onLoad) => onLoad();

  for (const file of [
    'focus.js',
    'editor-api.js',
    'diff-api.js',
    'scroll-handoff.js',
    'lsp.js',
    'boot.js',
  ]) {
    page.load(`assets/monaco/bridge/${file}`);
  }
  await waitFor(
    () => lifecyclesNamed(page, 'pageReady').length === 1,
    'pageReady',
  );
  const boot = await dispatch(page, 'page.boot', {
    text: 'boot text',
    language: 'plaintext',
    theme: 'vs',
    options: {},
    ...bootParams,
  });
  if (!boot.ok) throw new Error(`page.boot failed: ${boot.error.message}`);
  await waitFor(() => lifecyclesNamed(page, 'ready').length >= 1, 'ready');

  const primary = sandbox.editor;
  return {
    ...page,
    ...stub,
    container,
    windowListeners,
    primary,
    bootModel: primary.getModel(),
  };
}

/** Dispatches a protocol command and resolves with its response envelope. */
export async function dispatch(page, method, params) {
  const id = `r${Math.random().toString(36).slice(2)}`;
  page.sandbox.FlutterMonaco.dispatch({ id, method, params: params || {} });
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    const response = page.messages.find(
      (message) => message.kind === 'response' && message.id === id,
    );
    if (response) return response;
    await new Promise((resolve) => setTimeout(resolve, 1));
  }
  throw new Error(`no response for ${method}`);
}

/** All emitted events with the given name. */
export function eventsNamed(page, name) {
  return page.messages.filter(
    (message) => message.kind === 'event' && message.name === name,
  );
}
