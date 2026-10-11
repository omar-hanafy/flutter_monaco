# Integration patterns

## Widget-owned editor

Use the widget path unless the controller must exist outside the editor subtree.

```dart
MonacoEditor(
  initialText: source,
  options: const EditorOptions(language: MonacoLanguage.dart),
  onReady: (controller) {
    // Store the controller only if later UI actions need it.
  },
)
```

`MonacoEditor` creates, mounts, awaits, renders, and disposes its controller.

## App-owned controller

Create the controller, publish it to widget state so the platform view can render, and only then await readiness. A minimal `State` owner follows this order:

```dart
const appEditorOptions = EditorOptions(
  language: MonacoLanguage.dart,
  theme: MonacoTheme.vsDark,
);

Future<void> initializeEditor() async {
  final controller = await MonacoController.create(
    initialText: source,
    options: appEditorOptions,
  );
  if (!mounted) {
    controller.dispose();
    return;
  }
  setState(() => _controller = controller);
  await controller.whenReady;
}

Widget build(BuildContext context) {
  final controller = _controller;
  if (controller == null) return const CircularProgressIndicator();
  return MonacoEditor(
    controller: controller,
    options: appEditorOptions,
  );
}
```

An opaque loading child in a `Stack` may cover the editor while keeping the platform view painted. Do not use `Offstage` or hide the platform view until `whenReady` completes.

An externally supplied controller owns creation, disposal, and boot-time page policy, but `MonacoEditor` still owns its current widget configuration. On first readiness it applies `options`, resolved theme/language, `initialText`, background, interaction, and scroll settings. After a page reload it reapplies configuration but deliberately leaves app-owned content alone. Pass matching controller/widget options or intentionally make the widget the live configuration owner. Set `MonacoPageConfig` in `MonacoController.create`; the widget's `page` is ignored when `controller` is supplied.

Dispose the controller in the same owner that created it.

## Documents

The boot document is `controller.document`. Open additional files once and retain their handles.

```dart
final file = await controller.openDocument(
  text: source,
  language: MonacoLanguage.dart,
  uri: Uri.parse('file:///workspace/lib/main.dart'),
);
await controller.activateDocument(file);
```

A pinned `MonacoDocument` continues to address its model when another file is active. After a page reload, restore app-owned document state and LSP connections from `onPageReloaded`; stale handles fail loudly.

## Save and reload ownership

Treat application storage as the durable source of truth. Read editor text, persist it, and call `markSaved()` only after the write succeeds:

```dart
late final String text;
try {
  text = await document.getText();
} on MonacoException catch (error) {
  reportEditorFailure(error);
  return;
}

try {
  await repository.save(uri, text);
} catch (error, stackTrace) {
  reportStorageFailure(error);
  reportStorageStackTrace(stackTrace);
  return;
}
await document.markSaved();
```

Adapt the storage exception to the app's repository layer; do not claim `markSaved()` before durable success. After `onPageReloaded`, rebuild extra documents and post-boot state from the app model, then reconnect LSP. The boot document alone is replayed by the controller. Replace stale document handles rather than retrying through them.

## Options and appearance

`EditorOptions` is sparse. A partial update changes only supplied fields:

```dart
await controller.updateOptions(const EditorOptions(fontSize: 16));
```

Leave the theme unset to follow Flutter brightness. Use `MonacoPageConfig` for page policy such as `allowedConnectSources`, `customCss`, and font policy.

## Focus

Focus has three layers: Flutter focus, the platform WebView's native input focus, and Monaco DOM focus. `onFocusChanged` covers only the DOM layer. For desktop keyboard readiness, use `hasNativeInputFocus` or `requestFocus` completion. Request focus when entering the editor or recovering from app/route lifecycle changes, not on every pointer event.

## Overlay choice

| Overlay | Protection |
| --- | --- |
| Dialog, menu, dropdown, modal route | `MonacoRouteObserver` and `MonacoFocusGuard` |
| FAB, drawer, persistent `Stack` child | `MonacoScaffold` or `MonacoOverlayBoundary` |
| Snackbar, toast, temporary `OverlayEntry` | `runWithInteractionDisabled` |

On Web, an iframe receives browser pointer input before a visually higher Flutter canvas. Visual z-order alone does not make an overlay interactive.

## Platform floors

Flutter 3.47 and the transitive WebView implementations set the effective deployment floors for 4.x: Android API 24, iOS 15, and macOS 12 (3.x: iOS 13 and macOS 10.15). Windows needs the WebView2 Runtime. Web is supported. Linux is not supported.

A sandboxed macOS app (the `flutter create` default) must enable `com.apple.security.network.client` in both `DebugProfile.entitlements` and `Release.entitlements`. Without it, WKWebView cannot load the editor page and boot times out.
