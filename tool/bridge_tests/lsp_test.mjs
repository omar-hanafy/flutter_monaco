// Semantic tests for the real LSP bridge (assets/monaco/bridge/lsp.js)
// against a stub monaco.lsp client.
// Run: node --test tool/bridge_tests/lsp_test.mjs
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { bootEditorPage, dispatch } from './harness.mjs';

/** Boots an editor page with lsp.js installed over a counting client. */
function bootLspPage() {
  const page = bootEditorPage();
  const { sandbox } = page;
  const log = { clients: 0, storesDisposed: 0, transportsDisposed: 0 };
  sandbox.monaco.lsp = {
    MonacoLspClient: class {
      constructor(transport) {
        log.clients++;
        this._transport = transport;
        this.createFeatures();
        this._initPromise = Promise.resolve();
      }

      createFeatures() {
        return {
          dispose() {
            log.storesDisposed++;
          },
        };
      }
    },
  };
  page.load('assets/monaco/bridge/lsp.js');
  sandbox.__FMB.lsp(page.ctx);
  return { page, sandbox, log };
}

function countingTransport(log) {
  return {
    state: { value: { state: 'open' }, onChange: () => ({ dispose() {} }) },
    send() {
      return Promise.resolve();
    },
    setListener() {},
    dispose() {
      log.transportsDisposed++;
    },
  };
}

test('a disconnect during transport construction leaves no live client', async () => {
  const { page, sandbox, log } = bootLspPage();
  let resolveFactory;
  sandbox.flutterMonacoLspTransports = {
    slow: () =>
      new Promise((resolve) => {
        resolveFactory = resolve;
      }),
  };

  const connecting = dispatch(page, 'lsp.connect', {
    id: 'a',
    transport: { kind: 'custom', factoryName: 'slow', config: {} },
  });
  await new Promise((resolve) => setTimeout(resolve, 5));
  // The Dart connect timeout fires and disconnects while the factory is
  // still pending.
  const disconnect = await dispatch(page, 'lsp.disconnect', { id: 'a' });
  assert.equal(disconnect.value, true);

  resolveFactory(countingTransport(log));
  const connect = await connecting;
  // The connect settled at the disconnect; the late transport is released
  // once its factory resolves.
  await new Promise((resolve) => setTimeout(resolve, 0));

  assert.equal(connect.ok, false, 'the abandoned connect must fail');
  assert.match(connect.error.message, /disposed during initialization/);
  assert.equal(log.clients, 0, 'no client may be built for a dead entry');
  assert.equal(log.transportsDisposed, 1, 'the late transport is disposed');
  assert.deepEqual([...sandbox.flutterMonaco.lsp.listConnections()], []);
});

test('a disconnect settles a connect whose transport never resolves', async () => {
  const { page, sandbox, log } = bootLspPage();
  sandbox.flutterMonacoLspTransports = {
    // A WebSocket stuck connecting, or a custom factory that never settles.
    stuck: () => new Promise(() => {}),
  };

  const connecting = dispatch(page, 'lsp.connect', {
    id: 'a',
    transport: { kind: 'custom', factoryName: 'stuck', config: {} },
  });
  await new Promise((resolve) => setTimeout(resolve, 5));
  await dispatch(page, 'lsp.disconnect', { id: 'a' });

  const connect = await Promise.race([
    connecting,
    new Promise((resolve) => setTimeout(() => resolve({ ok: 'hung' }), 500)),
  ]);
  assert.equal(connect.ok, false, 'the abandoned connect must settle');
  assert.match(connect.error.message, /disposed during initialization/);
  assert.equal(log.clients, 0);
  assert.deepEqual([...sandbox.flutterMonaco.lsp.listConnections()], []);
});

test('a reconnect under the same id survives the abandoned attempt', async () => {
  const { page, sandbox, log } = bootLspPage();
  let resolveFactory;
  sandbox.flutterMonacoLspTransports = {
    slow: () =>
      new Promise((resolve) => {
        resolveFactory = resolve;
      }),
  };

  const abandoned = dispatch(page, 'lsp.connect', {
    id: 'a',
    transport: { kind: 'custom', factoryName: 'slow', config: {} },
  });
  await new Promise((resolve) => setTimeout(resolve, 5));
  await dispatch(page, 'lsp.disconnect', { id: 'a' });

  const retry = await dispatch(page, 'lsp.connect', {
    id: 'a',
    transport: { kind: 'bridged' },
  });
  assert.equal(retry.ok, true);

  resolveFactory(countingTransport(log));
  assert.equal((await abandoned).ok, false);

  assert.deepEqual([...sandbox.flutterMonaco.lsp.listConnections()], ['a']);
  const delivered = await dispatch(page, 'lsp.deliverServerMessage', {
    id: 'a',
    message: { jsonrpc: '2.0', method: 'window/logMessage', params: {} },
  });
  assert.equal(delivered.value, true);
  assert.equal(log.clients, 1, 'only the retry built a client');
  assert.equal(log.transportsDisposed, 1);
});

test('a disconnect during initialize disposes the client and transport', async () => {
  const { page, sandbox, log } = bootLspPage();
  let resolveInit;
  const Base = sandbox.monaco.lsp.MonacoLspClient;
  sandbox.monaco.lsp.MonacoLspClient = class extends Base {
    constructor(transport) {
      super(transport);
      this._initPromise = new Promise((resolve) => {
        resolveInit = resolve;
      });
    }
  };
  sandbox.flutterMonacoLspTransports = {
    fast: () => countingTransport(log),
  };

  const connecting = dispatch(page, 'lsp.connect', {
    id: 'b',
    transport: { kind: 'custom', factoryName: 'fast', config: {} },
  });
  await new Promise((resolve) => setTimeout(resolve, 5));
  await dispatch(page, 'lsp.disconnect', { id: 'b' });
  // Monaco's client never settles `initialized` once its transport is
  // closed, so the connect call must settle on the disconnect alone.
  assert.equal(typeof resolveInit, 'function');

  const connect = await Promise.race([
    connecting,
    new Promise((resolve) => setTimeout(() => resolve({ ok: 'hung' }), 500)),
  ]);
  assert.equal(connect.ok, false, 'connect must fail, not hang');
  assert.match(connect.error.message, /disposed during initialization/);
  assert.equal(log.clients, 1);
  assert.equal(log.storesDisposed, 1, 'the client providers are disposed');
  assert.equal(log.transportsDisposed, 1);
});
