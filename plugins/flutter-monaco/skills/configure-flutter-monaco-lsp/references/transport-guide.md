# LSP transport guide

## Decision table

| Situation | Transport | Important constraint |
| --- | --- | --- |
| Remote or proxied server speaks `ws`/`wss` | `LspWebSocketTransport` | Allow the exact origin in page CSP |
| Local stdio binary on macOS/Windows | `LspServerProcess` | Process distribution and macOS sandbox |
| App supplies a JS worker/iframe/socket adapter | `LspCustomTransport` | Factory must implement Monaco `IMessageTransport` |
| Raw stdio server on mobile or Web | None directly | Add a remote WebSocket proxy or redesign ownership |

## WebSocket example

```dart
Future<void> connectLsp(MonacoController controller) async {
  try {
    final connection = await controller.connectLanguageServer(
      id: 'dart',
      transport: LspWebSocketTransport(
        url: Uri.parse('wss://lsp.example.com/dart'),
      ),
      reconnectPolicy: const LspReconnectPolicy.exponentialBackoff(),
    );
    observeConnection(connection);
  } catch (error, stackTrace) {
    reportLspFailure(error, stackTrace);
  }
}

MonacoEditor(
  initialText: source,
  page: const MonacoPageConfig(
    allowedConnectSources: ['wss://lsp.example.com'],
  ),
  onReady: (controller) {
    unawaited(connectLsp(controller));
  },
);
```

Import `dart:async` for `unawaited`. `MonacoEditor.onReady` does not await an async callback, so the helper must catch and surface connection failures itself.

The endpoint in `allowedConnectSources` is a CSP source, not the whole socket path. Keep it exact. Browser WebSocket APIs do not support arbitrary request headers.

## Desktop stdio example

```dart
final server = await LspServerProcess.start(
  'pyright-langserver',
  ['--stdio'],
);
final connection = await controller.connectLanguageServer(
  id: 'pyright',
  transport: server.transport,
);
```

Disconnecting the connection or disposing the controller stops the process. If the process exits unexpectedly, create a new process and connection; do not reuse the terminated transport.

## Stable documents

```dart
final mainFile = await controller.openDocument(
  text: source,
  language: MonacoLanguage.python,
  uri: Uri.parse('file:///workspace/app.py'),
);
final helpersFile = await controller.openDocument(
  text: helpers,
  language: MonacoLanguage.python,
  uri: Uri.parse('file:///workspace/helpers.py'),
);

await controller.activateDocument(mainFile);
await helpersFile.insert(
  const Position(line: 1, column: 1),
  'from typing import Final\n',
);

// Close a retained handle when the app closes that file.
await helpersFile.close();
```

Retain one handle per open file and close it with the app tab. Monaco synchronizes model open/change/close notifications to the initialized server. Use paths meaningful to the server's workspace. Default `inmemory://` models weaken diagnostics, imports, definitions, and cross-file features.

## Page reload recovery

`controller.onPageReloaded` fires after the rebuilt editor is ready. Serialize one recovery routine that restores extra documents from app-owned state, replaces stale `MonacoDocument` handles, and then connects again with the intended id. From 4.0 the reload has already ended each connection as `failed` with `MonacoPageReloadedError` and freed its id; disconnecting the stale handle is optional and waits for its `onClose`. On 3.x, disconnect the stale registered connection first. Store and cancel the stream subscription with the controller owner. Transport reconnect policies cover unexpected transport drops; they do not replace this full page-state recovery.

## Failure matrix

| Symptom | Inspect first |
| --- | --- |
| CSP error in browser console | Exact origin in `MonacoPageConfig.allowedConnectSources` |
| Socket opens, initialize times out | Proxy framing, server command, stderr, LSP headers |
| No diagnostics for a visible file | URI, language id, document selector, workspace root |
| Desktop `Operation not permitted` | macOS sandbox and executable entitlements |
| Connection repeatedly fails after process exit | App must respawn bridged process |
| Duplicate or overwritten diagnostics | Concurrent servers share marker owner `lsp` |

Do not log tokens, complete environment maps, document contents, or unredacted server stderr in production diagnostics.
