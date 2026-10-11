// flutter_monaco bridge - extracted verbatim from the 2.3.0 generated page
// (lib/src/core/monaco_assets.dart generateIndexHtml). Do not reformat the
// ported bodies; see upcoming/v3.md Section 14 (verbatim-port inventory).
/* eslint-disable */
'use strict';
window.__FMB = window.__FMB || {};

// LSP bridge: bridged transport pump, the Monaco 0.57.0 client wrapper
// (adds the missing dispose()), benign refresh handlers. VERBATIM PORT.
window.__FMB.lsp = function (ctx) {
  const { serialize, postMessageToFlutter } = ctx;
                // LSP bridge: Dart owns transports and connection lifecycle,
                // Monaco's built-in monaco.lsp.MonacoLspClient owns every
                // language feature (completions, hover, diagnostics, rename,
                // formatting, semantic tokens, ...). Nothing here mirrors LSP
                // capabilities into Dart - once a connection is open the
                // editor "just works".
                (function () {
                  const connections = new Map(); // id -> entry

                  const lspAvailable = () =>
                    !!(window.monaco && monaco.lsp && monaco.lsp.MonacoLspClient);

                  function toErrorInfo(error) {
                    if (!error) return null;
                    return {
                      name: error.name ? String(error.name) : 'Error',
                      message: error.message ? String(error.message) : String(error),
                    };
                  }

                  function postStatus(id, status, error) {
                    postMessageToFlutter({
                      event: 'lspStatus',
                      connectionId: id,
                      status: status,
                      error: toErrorInfo(error),
                    });
                  }

                  // Minimal IValueWithChangeEvent implementation - the shape
                  // monaco.lsp transports expose via their `state` member.
                  function createTransportState(initial) {
                    const listeners = new Set();
                    let current = initial;
                    return {
                      get value() { return current; },
                      set value(next) {
                        current = next;
                        for (const listener of Array.from(listeners)) {
                          try { listener(next); } catch (_) {}
                        }
                      },
                      get onChange() {
                        return (listener) => {
                          listeners.add(listener);
                          return { dispose: () => listeners.delete(listener) };
                        };
                      },
                    };
                  }

                  // IMessageTransport whose wire is the Flutter bridge:
                  // client->server messages surface as 'lspMessage' events;
                  // server->client messages arrive via deliverServerMessage.
                  function createBridgedTransport(id) {
                    let listener = null;
                    let closed = false;
                    const state = createTransportState({ state: 'open' });
                    return {
                      state: state,
                      send(message) {
                        if (closed) {
                          return Promise.reject(
                            new Error('Bridged LSP transport is closed: ' + id));
                        }
                        postMessageToFlutter({
                          event: 'lspMessage',
                          connectionId: id,
                          message: message,
                        });
                        return Promise.resolve();
                      },
                      setListener(next) { listener = next; },
                      deliver(message) {
                        if (!closed && listener) listener(message);
                      },
                      close(error) {
                        if (closed) return;
                        closed = true;
                        state.value = { state: 'closed', error: error };
                      },
                      dispose() { this.close(undefined); },
                      toString() {
                        return 'FlutterMonacoBridgedTransport(' + id + ')';
                      },
                    };
                  }

                  // Monaco 0.57.0's MonacoLspClient exposes no dispose() and
                  // discards the feature DisposableStore it creates in its
                  // constructor, so a stock client can never unregister its
                  // providers. This wrapper captures the store and reaches
                  // into the private fields (_initPromise, _bridge,
                  // _capabilitiesRegistry, _connection) - all verified against
                  // the 0.57.0 sources. Kept in this one block so future
                  // Monaco upgrades have a single place to re-verify.
                  let FlutterLspClientClass = null;
                  function getClientClass() {
                    if (FlutterLspClientClass) return FlutterLspClientClass;
                    FlutterLspClientClass = class extends monaco.lsp.MonacoLspClient {
                      // Called from the base constructor, before subclass
                      // field initializers run - stash on a lazily created
                      // property instead of a declared field (a declared
                      // field initializer would overwrite this afterwards).
                      createFeatures() {
                        const store = super.createFeatures();
                        if (!this.__flutterFeatureStores) {
                          this.__flutterFeatureStores = [];
                        }
                        this.__flutterFeatureStores.push(store);
                        return store;
                      }
                      get initialized() { return this._initPromise; }
                      get lspConnection() { return this._connection; }
                      dispose() {
                        for (const store of this.__flutterFeatureStores || []) {
                          try { store.dispose(); } catch (_) {}
                        }
                        this.__flutterFeatureStores = [];
                        try {
                          this._bridge && this._bridge.dispose && this._bridge.dispose();
                        } catch (_) {}
                        try {
                          this._capabilitiesRegistry &&
                            this._capabilitiesRegistry.dispose &&
                            this._capabilitiesRegistry.dispose();
                        } catch (_) {}
                      }
                    };
                    return FlutterLspClientClass;
                  }

                  async function buildTransport(id, payload) {
                    switch (payload && payload.kind) {
                      case 'webSocket':
                        // Rejected by the browser when the URL is not in the
                        // page's connect-src (see allowedConnectSources).
                        return await monaco.lsp.WebSocketTransport.connectTo({
                          address: String(payload.url),
                        });
                      case 'bridged':
                        return createBridgedTransport(id);
                      case 'custom': {
                        const registry = window.flutterMonacoLspTransports || {};
                        const factory = registry[payload.factoryName];
                        if (typeof factory !== 'function') {
                          throw new Error(
                            'Unknown LSP transport factory "' + payload.factoryName +
                            '". Register it on window.flutterMonacoLspTransports ' +
                            'before connecting.');
                        }
                        return await factory(payload.config || {});
                      }
                      default:
                        throw new Error(
                          'Unknown LSP transport kind: ' + (payload && payload.kind));
                    }
                  }

                  // Monaco 0.57.0's client leaves several optional
                  // server->client requests unhandled and answers them with
                  // a method-not-found error. Some servers treat that error
                  // as fatal - pyright (vscode-languageserver) dies on the
                  // unhandled promise rejection when its
                  // workspace/diagnostic/refresh call is rejected. These are
                  // void requests per the LSP spec, so acknowledge them with
                  // a null result instead. Monaco re-pulls diagnostics and
                  // tokens on edits, so ignoring the hint is safe.
                  function registerBenignRefreshHandlers(entry) {
                    let channel = null;
                    try {
                      channel = entry.client.lspConnection &&
                        entry.client.lspConnection.connection;
                    } catch (_) {}
                    if (!channel ||
                        typeof channel.registerRequestHandler !== 'function') {
                      return;
                    }
                    const passthrough = {
                      serializeToJson: (v) => (typeof v === 'undefined' ? null : v),
                      deserializeFromJson: (v) => ({ hasErrors: false, value: v }),
                    };
                    const methods = [
                      'workspace/diagnostic/refresh',
                      'workspace/semanticTokens/refresh',
                      'workspace/codeLens/refresh',
                      'workspace/inlineValue/refresh',
                      'workspace/foldingRange/refresh',
                      'workspace/inlayHint/refresh',
                    ];
                    for (const method of methods) {
                      try {
                        channel.registerRequestHandler({
                          method: method,
                          paramsSerializer: passthrough,
                          resultSerializer: passthrough,
                          errorSerializer: passthrough,
                          isOptional: true,
                        }, async () => ({ ok: null }));
                      } catch (_) {
                        // Monaco already handles this method - keep its
                        // handler.
                      }
                    }
                  }

                  function watchTransportClose(entry) {
                    const transport = entry.transport;
                    try {
                      if (transport && transport.state &&
                          typeof transport.state.onChange === 'function') {
                        entry.stateWatch = transport.state.onChange((s) => {
                          if (s && s.state === 'closed' && !entry.disposed) {
                            postStatus(entry.id, 'closed', s.error);
                          }
                        });
                      }
                    } catch (_) {}
                  }

                  // Disposes whatever the entry holds right now and forgets
                  // it, so a second call only releases what was built
                  // since the first.
                  function releaseResources(entry) {
                    try {
                      entry.stateWatch && entry.stateWatch.dispose &&
                        entry.stateWatch.dispose();
                    } catch (_) {}
                    try {
                      entry.client && entry.client.dispose && entry.client.dispose();
                    } catch (_) {}
                    try {
                      entry.transport && entry.transport.dispose &&
                        entry.transport.dispose();
                    } catch (_) {}
                    entry.stateWatch = null;
                    entry.client = null;
                    entry.transport = null;
                  }

                  function disposeEntry(entry) {
                    if (entry.disposed) return;
                    entry.disposed = true;
                    if (entry.abandon) {
                      entry.abandon(new Error(
                        'LSP connection "' + entry.id +
                        '" was disposed during initialization.'));
                    }
                    releaseResources(entry);
                    connections.delete(entry.id);
                    if (connections.size === 0) {
                      // Monaco's LSP diagnostics all publish under the fixed
                      // marker owner 'lsp'. Clear them when the last
                      // connection goes away so stale squiggles don't outlive
                      // their server.
                      try {
                        for (const model of monaco.editor.getModels()) {
                          monaco.editor.setModelMarkers(model, 'lsp', []);
                        }
                      } catch (_) {}
                    }
                  }

                  // A disconnect (the Dart connect timeout, or an explicit
                  // disconnect) can land while connect() is awaiting. Once
                  // the entry is disposed, connect() must stop building and
                  // release whatever it built after disposeEntry ran -
                  // without touching the connections map, where the id may
                  // already belong to a newer connect.
                  function throwIfAbandoned(entry) {
                    if (entry.disposed) {
                      throw new Error(
                        'LSP connection "' + entry.id +
                        '" was disposed during initialization.');
                    }
                  }

                  window.flutterMonaco.lsp = {
                    isAvailable: () => lspAvailable(),

                    async connect(id, transportPayload) {
                      if (!lspAvailable()) {
                        throw new Error(
                          'monaco.lsp is not available in this Monaco build.');
                      }
                      if (connections.has(id)) {
                        throw new Error('LSP connection already exists: ' + id);
                      }
                      const entry = {
                        id: id,
                        client: null,
                        transport: null,
                        bridged: null,
                        stateWatch: null,
                        disposed: false,
                        abandon: null,
                      };
                      // Rejected by disposeEntry. Monaco's LSP client never
                      // settles `initialized` once its transport is closed,
                      // so a disconnect during the handshake would otherwise
                      // leave this call - and Dart's pending lsp.connect
                      // request - waiting forever.
                      const abandoned = new Promise((_, reject) => {
                        entry.abandon = reject;
                      });
                      abandoned.catch(() => {});
                      // Register synchronously (before any await) so bridged
                      // server->client messages can be delivered while the
                      // initialize handshake is still in flight - the
                      // handshake cannot complete without them.
                      connections.set(id, entry);
                      try {
                        if (transportPayload && transportPayload.kind === 'bridged') {
                          entry.bridged = createBridgedTransport(id);
                          entry.transport = entry.bridged;
                        } else {
                          const building = buildTransport(id, transportPayload);
                          // A transport that never settles (a WebSocket stuck
                          // connecting, a factory that never resolves) must not
                          // hold this call after a disconnect; one that settles
                          // after the disconnect is released here.
                          building.then((transport) => {
                            if (entry.disposed && transport) {
                              try {
                                transport.dispose && transport.dispose();
                              } catch (_) {}
                            }
                          }, () => {});
                          entry.transport = await Promise.race([building, abandoned]);
                          throwIfAbandoned(entry);
                        }
                        if (!entry.transport ||
                            typeof entry.transport.send !== 'function' ||
                            typeof entry.transport.setListener !== 'function') {
                          throw new Error(
                            'LSP transport for "' + id +
                            '" does not implement IMessageTransport ' +
                            '(state/send/setListener).');
                        }
                        const ClientClass = getClientClass();
                        entry.client = new ClientClass(entry.transport);
                        registerBenignRefreshHandlers(entry);
                        watchTransportClose(entry);
                        await Promise.race([entry.client.initialized, abandoned]);
                        throwIfAbandoned(entry);
                        postStatus(id, 'open', null);
                        return true;
                      } catch (e) {
                        if (entry.disposed) {
                          releaseResources(entry);
                        } else {
                          disposeEntry(entry);
                        }
                        throw e;
                      }
                    },

                    disconnect(id) {
                      const entry = connections.get(id);
                      if (!entry) return false;
                      disposeEntry(entry);
                      postStatus(id, 'closed', null);
                      return true;
                    },

                    disconnectAll() {
                      for (const entry of Array.from(connections.values())) {
                        disposeEntry(entry);
                        postStatus(entry.id, 'closed', null);
                      }
                      return true;
                    },

                    // Dart -> JS delivery for bridged transports
                    // (server -> client direction).
                    deliverServerMessage(id, message) {
                      const entry = connections.get(id);
                      if (!entry || !entry.bridged) return false;
                      entry.bridged.deliver(message);
                      return true;
                    },

                    listConnections() {
                      return Array.from(connections.keys());
                    },

                    // EXPERIMENTAL escape hatch for non-standard server
                    // extensions. Depends on Monaco-internal channel plumbing
                    // (verified against 0.57.0); may break on future Monaco
                    // upgrades, in which case it throws a descriptive error.
                    async sendRequest(id, method, params) {
                      const entry = connections.get(id);
                      if (!entry || !entry.client) {
                        throw new Error('No such LSP connection: ' + id);
                      }
                      const lspConnection = entry.client.lspConnection;
                      const channel = lspConnection && lspConnection.connection;
                      if (!channel || typeof channel.request !== 'function') {
                        throw new Error(
                          'Generic LSP requests are not supported by this ' +
                          'Monaco build.');
                      }
                      const passthrough = {
                        serializeToJson: (v) => (typeof v === 'undefined' ? null : v),
                        deserializeFromJson: (v) => ({ hasErrors: false, value: v }),
                      };
                      return await channel.request({
                        method: String(method),
                        paramsSerializer: passthrough,
                        resultSerializer: passthrough,
                        errorSerializer: passthrough,
                        isOptional: false,
                      }, params);
                    },

                    async sendNotification(id, method, params) {
                      const entry = connections.get(id);
                      if (!entry || !entry.client) {
                        throw new Error('No such LSP connection: ' + id);
                      }
                      const lspConnection = entry.client.lspConnection;
                      const channel = lspConnection && lspConnection.connection;
                      if (!channel || typeof channel.notify !== 'function') {
                        throw new Error(
                          'Generic LSP notifications are not supported by ' +
                          'this Monaco build.');
                      }
                      const passthrough = {
                        serializeToJson: (v) => (typeof v === 'undefined' ? null : v),
                      };
                      channel.notify({
                        method: String(method),
                        paramsSerializer: passthrough,
                      }, params);
                      return true;
                    },
                  };
                })();

                // ---- protocol v3 command registry ----
                {
                  const FM = window.FlutterMonaco;
                  const lspApi = () => window.flutterMonaco.lsp;
                  FM.register('lsp.connect', (p) => lspApi().connect(p.id, p.transport));
                  FM.register('lsp.disconnect', (p) => lspApi().disconnect(p.id));
                  FM.register('lsp.disconnectAll', () => lspApi().disconnectAll());
                  FM.register('lsp.deliverServerMessage', (p) => lspApi().deliverServerMessage(p.id, p.message));
                  FM.register('lsp.sendRequest', (p) => lspApi().sendRequest(p.id, p.method, p.params));
                  FM.register('lsp.sendNotification', (p) => lspApi().sendNotification(p.id, p.method, p.params));
                  FM.register('lsp.listConnections', () => lspApi().listConnections());
                }
};
