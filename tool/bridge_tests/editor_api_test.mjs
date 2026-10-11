// Semantic tests for the real editor bridge (assets/monaco/bridge/*.js).
// Run: node --test tool/bridge_tests/
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { bootEditorPage, dispatch, eventsNamed } from './harness.mjs';

function editOnce(model, text = 'x') {
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

test('first edit after docs.open reports dirty', async () => {
  const page = bootEditorPage();
  const opened = await dispatch(page, 'docs.open', {
    text: 'hello',
    language: 'plaintext',
    uri: 'file:///a.txt',
  });
  assert.equal(opened.ok, true);

  editOnce(page.models.get('file:///a.txt'));

  const dirty = await dispatch(page, 'document.isDirty', {
    uri: 'file:///a.txt',
  });
  assert.equal(dirty.ok, true);
  assert.equal(dirty.value, true, 'the FIRST edit must already read dirty');
});

test('first edit of the boot document reports dirty', async () => {
  const page = bootEditorPage();
  editOnce(page.bootModel);

  const dirty = await dispatch(page, 'document.isDirty', { uri: null });
  assert.equal(dirty.ok, true);
  assert.equal(dirty.value, true);
});

test('setText re-baselines: a programmatic load is clean', async () => {
  const page = bootEditorPage();
  editOnce(page.bootModel);
  await dispatch(page, 'document.setText', { uri: null, text: 'fresh' });

  const dirty = await dispatch(page, 'document.isDirty', { uri: null });
  assert.equal(dirty.value, false);
});

test('markSaved re-baselines the edited document', async () => {
  const page = bootEditorPage();
  editOnce(page.bootModel);
  await dispatch(page, 'document.markSaved', { uri: null });

  const dirty = await dispatch(page, 'document.isDirty', { uri: null });
  assert.equal(dirty.value, false);
});

test('close and reopen the same URI starts clean, then dirties on edit', async () => {
  const page = bootEditorPage();
  await dispatch(page, 'docs.open', { text: 'v1', uri: 'file:///b.txt' });
  editOnce(page.models.get('file:///b.txt'));
  await dispatch(page, 'docs.close', { uri: 'file:///b.txt' });

  await dispatch(page, 'docs.open', { text: 'v2', uri: 'file:///b.txt' });
  const clean = await dispatch(page, 'document.isDirty', {
    uri: 'file:///b.txt',
  });
  assert.equal(clean.value, false, 'a reopened URI must not inherit state');

  editOnce(page.models.get('file:///b.txt'));
  const dirty = await dispatch(page, 'document.isDirty', {
    uri: 'file:///b.txt',
  });
  assert.equal(dirty.value, true);
});

test('edits to an INACTIVE document emit contentChanged with its uri', async () => {
  const page = bootEditorPage();
  await dispatch(page, 'docs.open', { text: '', uri: 'file:///bg.txt' });
  // The boot model stays active; edit the background document.
  editOnce(page.models.get('file:///bg.txt'), 'background');

  const events = eventsNamed(page, 'contentChanged');
  assert.equal(events.length, 1);
  assert.equal(events[0].data.uri, 'file:///bg.txt');
  assert.equal(events[0].data.isFlush, false);
});

test('active document edits emit contentChanged with the model uri', async () => {
  const page = bootEditorPage();
  editOnce(page.bootModel, 'typed');

  const events = eventsNamed(page, 'contentChanged');
  assert.equal(events.length, 1);
  assert.equal(events[0].data.uri, page.bootModel.uri.toString());
});

test('closed documents stop emitting contentChanged', async () => {
  const page = bootEditorPage();
  await dispatch(page, 'docs.open', { text: '', uri: 'file:///c.txt' });
  const model = page.models.get('file:///c.txt');
  await dispatch(page, 'docs.close', { uri: 'file:///c.txt' });

  editOnce(model);
  assert.equal(eventsNamed(page, 'contentChanged').length, 0);
});

test('oversized inserted text ships truncated without deltas', async () => {
  const page = bootEditorPage();
  editOnce(page.bootModel, 'x'.repeat(70000));

  const [event] = eventsNamed(page, 'contentChanged');
  assert.equal(event.data.truncated, true);
  assert.equal(event.data.changes, undefined);
});

test('events with more than 1000 changes ship truncated', async () => {
  const page = bootEditorPage();
  page.bootModel.applyEdits(
    Array.from({ length: 1001 }, () => ({
      range: {
        startLineNumber: 1,
        startColumn: 1,
        endLineNumber: 1,
        endColumn: 1,
      },
      text: 'y',
    })),
  );

  const [event] = eventsNamed(page, 'contentChanged');
  assert.equal(event.data.truncated, true);
  assert.equal(event.data.changes, undefined);
});

test('executeAction awaits an asynchronous action run()', async () => {
  const page = bootEditorPage();
  let resolved = false;
  page.sandbox.__testActions = {
    'my.async': {
      run: () =>
        new Promise((resolve) =>
          setTimeout(() => {
            resolved = true;
            resolve();
          }, 25),
        ),
    },
  };

  const response = await dispatch(page, 'editor.executeAction', {
    actionId: 'my.async',
    args: null,
  });
  assert.equal(response.ok, true);
  assert.equal(
    resolved,
    true,
    'the response must not be posted before the action promise settles',
  );
});

test('strict getLines rejects out-of-range lines', async () => {
  const page = bootEditorPage();
  const response = await dispatch(page, 'document.getLines', {
    uri: null,
    startLine: 99,
    endLine: 99,
    strict: true,
  });
  assert.equal(response.ok, false, 'out-of-range strict read must fail');
});

test('non-strict getLines keeps clamping (documented behavior)', async () => {
  const page = bootEditorPage();
  const response = await dispatch(page, 'document.getLines', {
    uri: null,
    startLine: 99,
    endLine: 99,
  });
  assert.equal(response.ok, true);
  assert.deepEqual(response.value, ['boot text']);
});

test('an intentionally empty completion insertText is preserved', async () => {
  const page = bootEditorPage();
  await dispatch(page, 'completions.register', {
    id: 'p1',
    languages: ['plaintext'],
  });

  const { provider } = page.sandbox.__completionProviders[0];
  const resultPromise = provider.provideCompletionItems(
    page.bootModel,
    new page.sandbox.monaco.Position(1, 1),
    { triggerKind: 0 },
    { onCancellationRequested: () => {} },
  );

  // Answer the JS->Dart completion request like the Dart side would.
  const deadline = Date.now() + 2000;
  let request;
  while (!request && Date.now() < deadline) {
    request = page.messages.find((m) => m.kind === 'request');
    if (!request) await new Promise((resolve) => setTimeout(resolve, 1));
  }
  page.sandbox.FlutterMonaco.respond({
    id: request.id,
    ok: true,
    value: {
      suggestions: [{ label: 'wrap-selection', insertText: '' }],
    },
  });

  const result = await resultPromise;
  assert.equal(result.suggestions.length, 1);
  assert.equal(
    result.suggestions[0].insertText,
    '',
    'an empty insertText must not fall back to the label',
  );
});

test('diff.getState reports an uncomputed diff as null, not zero', async () => {
  const page = bootEditorPage();
  const diffCtx = {};
  page.sandbox.__FMB.diffApi(diffCtx);
  const textModel = page.sandbox.monaco.editor.createModel('t', 'plaintext');
  diffCtx.diffState.editor = {
    getModel: () => ({ original: textModel, modified: textModel }),
    getLineChanges: () => null,
    waitForDiff: () => new Promise(() => {}),
  };

  const response = await dispatch(page, 'diff.getState', {});
  assert.equal(response.ok, true);
  assert.equal(
    response.value.lineChangeCount,
    null,
    'an uncomputed diff must be distinguishable from zero changes',
  );
});

// ---- programmatic edits and the undo stack ----

const range = (startLineNumber, startColumn, endLineNumber, endColumn) => ({
  startLineNumber,
  startColumn,
  endLineNumber,
  endColumn,
});

test('document.applyEdits is one undoable step after user typing', async () => {
  const page = bootEditorPage();
  const model = page.bootModel;
  model.setValue('hello');
  // Typing rides pushEditOperations and leaves its undo element open.
  model.pushEditOperations(
    [],
    [{ range: range(1, 6, 1, 6), text: ' abc' }],
    () => null,
  );

  const response = await dispatch(page, 'document.applyEdits', {
    uri: null,
    edits: [{ range: range(1, 1, 1, 1), text: 'XYZ-' }],
  });
  assert.equal(response.ok, true);
  assert.equal(response.value, true, 'the return contract stays true');
  assert.equal(model.getValue(), 'XYZ-hello abc');

  model.undo();
  assert.equal(
    model.getValue(),
    'hello abc',
    'undo must revert exactly the programmatic edit',
  );
  model.undo();
  assert.equal(model.getValue(), 'hello');
  model.redo();
  model.redo();
  assert.equal(model.getValue(), 'XYZ-hello abc');
});

test('document.applyEdits on an inactive pinned document is undoable', async () => {
  const page = bootEditorPage();
  await dispatch(page, 'docs.open', { text: 'abc', uri: 'file:///p.txt' });
  const model = page.models.get('file:///p.txt');

  await dispatch(page, 'document.applyEdits', {
    uri: 'file:///p.txt',
    edits: [{ range: range(1, 4, 1, 4), text: 'd' }],
  });
  assert.equal(model.getValue(), 'abcd');
  model.undo();
  assert.equal(model.getValue(), 'abc');
});

// ---- executeAction ----

/** Collects unhandled rejections raised while [body] runs. */
async function collectUnhandledRejections(body) {
  const seen = [];
  const listener = (reason) => seen.push(reason);
  process.on('unhandledRejection', listener);
  try {
    await body();
    await new Promise((resolve) => setTimeout(resolve, 20));
  } finally {
    process.off('unhandledRejection', listener);
  }
  return seen;
}

test('executeAction rejects an unknown id instead of reporting success', async () => {
  const page = bootEditorPage();
  let response;
  const rejections = await collectUnhandledRejections(async () => {
    response = await dispatch(page, 'editor.executeAction', {
      actionId: 'no.such.command',
      args: null,
    });
  });
  assert.equal(response.ok, false, 'an unknown id must fail');
  assert.match(response.error.message, /no\.such\.command/);
  assert.deepEqual(
    rejections.map(String),
    [],
    'the command-service rejection must not leak as unhandled',
  );
});

test('executeAction awaits a registered command and surfaces its failure', async () => {
  const page = bootEditorPage();
  let ranWith;
  page.sandbox.__testCommands = {
    'my.command': (args) => {
      ranWith = args;
    },
    'my.failing': () => {
      throw new Error('boom from command');
    },
  };

  const ok = await dispatch(page, 'editor.executeAction', {
    actionId: 'my.command',
    args: { n: 1 },
  });
  assert.equal(ok.ok, true);
  assert.equal(ok.value, true);
  assert.deepEqual(ranWith, { n: 1 });

  const failed = await dispatch(page, 'editor.executeAction', {
    actionId: 'my.failing',
    args: null,
  });
  assert.equal(failed.ok, false);
  assert.equal(failed.error.message, 'boom from command');
});

test('executeAction keeps editor commands and trigger handlers working', async () => {
  const page = bootEditorPage();
  const service = page.editor._commandService;
  const executeCommand = service.executeCommand;
  for (const actionId of ['undo', 'cursorDown', 'type']) {
    const response = await dispatch(page, 'editor.executeAction', {
      actionId,
      args: actionId === 'type' ? { text: 'x' } : null,
    });
    assert.equal(response.ok, true, actionId);
    assert.equal(response.value, true, actionId);
  }
  assert.deepEqual(page.sandbox.__triggered, ['undo', 'cursorDown', 'type']);
  assert.equal(
    service.executeCommand,
    executeCommand,
    'the command service must be left exactly as it was',
  );
});

