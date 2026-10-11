// Executes the REAL boot.js plus every editor-mode bridge module against the
// Monaco stub, so the editor-creation hook is covered end to end. Monaco
// fires monaco.editor.onDidCreateEditor for EVERY code editor in the page:
// the peek widget's embedded editor (Peek Definition, Shift+F12 references,
// multi-result go-to-definition) and the inner editors of any diff editor
// page code creates. Only the primary editor may install the bridge.
//
// Run: node --test tool/bridge_tests/boot_test.mjs
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  bootFullPage,
  dispatch,
  eventsNamed,
  lifecyclesNamed,
} from './harness.mjs';

function editAtStart(model, text) {
  model.applyEdits([
    {
      range: {
        startLineNumber: 1,
        startColumn: 1,
        endLineNumber: 1,
        endColumn: 1,
      },
      text,
    },
  ]);
}

/** Minimal monaco.lsp stub: a client whose initialize settles at once. */
function installLspStub(sandbox) {
  sandbox.monaco.lsp = {
    MonacoLspClient: class {
      constructor(transport) {
        this._transport = transport;
        this.createFeatures();
        this._initPromise = Promise.resolve();
      }

      createFeatures() {
        return { dispose() {} };
      }
    },
  };
}

function wheelListeners(page) {
  return page.windowListeners.filter((entry) => entry.type === 'wheel');
}

/**
 * Captures bridge state before a foreign editor appears, then asserts that
 * nothing was reinstalled and every registry still answers.
 */
async function assertBridgeSurvives(page, createForeignEditor) {
  const { sandbox, primary, bootModel } = page;
  installLspStub(sandbox);
  const api = sandbox.flutterMonaco;
  const decorationSet = await dispatch(page, 'decorations.create');
  assert.equal(decorationSet.ok, true);
  const connect = await dispatch(page, 'lsp.connect', {
    id: 'srv',
    transport: { kind: 'bridged' },
  });
  assert.equal(connect.ok, true);
  assert.equal(wheelListeners(page).length, 1);

  const foreign = createForeignEditor();

  assert.equal(
    lifecyclesNamed(page, 'ready').length,
    1,
    'a foreign editor must not post a second ready lifecycle',
  );
  assert.equal(sandbox.editor, primary, 'window.editor must stay primary');
  assert.equal(
    sandbox.flutterMonaco,
    api,
    'window.flutterMonaco must not be rebuilt',
  );
  assert.equal(
    wheelListeners(page).length,
    1,
    'scroll handoff wheel listeners must not be installed twice',
  );

  editAtStart(bootModel, 'x');
  assert.equal(
    eventsNamed(page, 'contentChanged').length,
    1,
    'one edit must emit exactly one contentChanged',
  );

  // Closing the peek / diff disposes the foreign editor.
  foreign.dispose();

  const text = await dispatch(page, 'document.getText', { uri: null });
  assert.equal(text.ok, true, text.error && text.error.message);
  assert.equal(text.value, 'xboot text');

  const setDecorations = await dispatch(page, 'decorations.set', {
    setId: decorationSet.value,
    decorations: [],
  });
  assert.equal(
    setDecorations.ok,
    true,
    setDecorations.error && setDecorations.error.message,
  );

  const delivered = await dispatch(page, 'lsp.deliverServerMessage', {
    id: 'srv',
    message: { jsonrpc: '2.0', method: 'window/logMessage', params: {} },
  });
  assert.equal(delivered.ok, true);
  assert.equal(
    delivered.value,
    true,
    'the LSP connection registry must survive',
  );
}

test('boot posts ready once and binds window.editor to the primary editor', async () => {
  const page = await bootFullPage();
  assert.equal(lifecyclesNamed(page, 'ready').length, 1);
  assert.equal(page.sandbox.editor, page.editors[0]);
  assert.equal(page.primary.getContainerDomNode(), page.container);
  assert.equal(page.bootModel.getValue(), 'boot text');
});

test('a peek widget editor does not reinstall the bridge', async () => {
  const page = await bootFullPage({ scrollHandoff: { wheel: true } });
  await assertBridgeSurvives(page, () => {
    // Monaco's peek widget embeds an editor whose parent is the primary;
    // Shift+F12 on a same-file symbol shows the primary's own model.
    const peek = page.createEmbeddedEditor(page.primary);
    peek.setModel(page.bootModel);
    return peek;
  });
});

test('editors created by page code (a diff editor pair) are ignored', async () => {
  const page = await bootFullPage({ scrollHandoff: { wheel: true } });
  await assertBridgeSurvives(page, () => {
    const create = page.sandbox.monaco.editor.create;
    const original = create({ id: 'diff-original' }, {});
    const modified = create({ id: 'diff-modified' }, {});
    return {
      dispose() {
        original.dispose();
        modified.dispose();
      },
    };
  });
});
