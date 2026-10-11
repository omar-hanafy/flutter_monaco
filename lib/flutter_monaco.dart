/// A Flutter plugin for integrating the Monaco Editor into Flutter applications.
///
/// Flutter Monaco provides a full-featured code editor powered by the same engine
/// that drives Visual Studio Code. It supports syntax highlighting for 100+ languages,
/// multiple themes, and a comprehensive API for editor manipulation.
///
/// ## Features
///
/// - **100+ Language Support** - Syntax highlighting for all major programming languages
/// - **Language Server Protocol** - Connect real language servers for
///   completions, diagnostics, hover, go-to-definition, rename, and more
/// - **Multiple Themes** - VS Light, VS Dark, High Contrast themes
/// - **Rich API** - Full programmatic control over the editor
/// - **Multi-Editor Support** - Run multiple independent editor instances
/// - **Cross-Platform** - Works on Android, iOS, macOS, Windows, and Web
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_monaco/flutter_monaco.dart';
///
/// // Simple usage with the widget
/// MonacoEditor(
///   options: EditorOptions(
///     language: MonacoLanguage.javascript,
///     theme: MonacoTheme.vsDark,
///   ),
/// )
///
/// // Advanced usage with controller
/// final controller = await MonacoController.create(
///   options: EditorOptions(
///     language: MonacoLanguage.python,
///     fontSize: 16,
///   ),
/// );
///
/// await controller.whenReady;
/// await controller.document.setText('print("Hello, World!")');
/// final content = await controller.document.getText();
/// ```
///
/// ## Platform Support
///
/// - ✅ Android (7.0+, API 24)
/// - ✅ iOS (13.0+)
/// - ✅ macOS (10.15+)
/// - ✅ Windows (10 version 1809+)
/// - ✅ Web (supported)
/// - ❌ Linux (not supported)
///
/// ## Additional Resources
///
/// - [GitHub Repository](https://github.com/omar-hanafy/flutter_monaco)
/// - [API Documentation](https://pub.dev/documentation/flutter_monaco/latest/)
/// - [Example App](https://github.com/omar-hanafy/flutter_monaco/tree/main/example)
/// - [Issue Tracker](https://github.com/omar-hanafy/flutter_monaco/issues)
library;

export 'src/assets/asset_diagnostics.dart' show MonacoAssetDiagnostics;
export 'src/assets/monaco_assets.dart' show MonacoAssets;
// Core exports
export 'src/common/defaults.dart' show MonacoDefaults, MonacoFontStacks;
export 'src/common/exceptions.dart'
    show
        MonacoDisposedError,
        MonacoException,
        MonacoJavaScriptError,
        MonacoPageReloadedError,
        MonacoProtocolError,
        MonacoTimeoutError;
export 'src/common/monaco_page_config.dart'
    show MonacoCapabilities, MonacoPageConfig;
export 'src/diff/diff_controller.dart' show MonacoDiffController;
export 'src/diff/diff_options.dart' show MonacoDiffOptions;
export 'src/editor/completions.dart'
    show CompletionProvider, MonacoCompletionRegistration;
export 'src/editor/controller.dart' show MonacoController;
export 'src/editor/custom_actions.dart' show MonacoActionRegistration;
export 'src/editor/decorations.dart' show MonacoDecorationSet;
export 'src/editor/document.dart' show MonacoDocument;
export 'src/editor/events.dart'
    show
        MonacoContentChanged,
        MonacoEvent,
        MonacoFocusChanged,
        MonacoScrollHandoffEvent,
        MonacoSelectionChanged,
        MonacoUnknownEvent;
export 'src/editor/focus_coordinator.dart' show MonacoFocusIntent;
export 'src/editor/view_state.dart' show MonacoViewState;
// LSP exports
export 'src/lsp/lsp_connection.dart' show LanguageServerConnection;
export 'src/lsp/lsp_server_process.dart' show LspServerProcess;
export 'src/lsp/lsp_stdio_framing.dart'
    show LspStdioMessageDecoder, LspStdioMessageEncoder;
export 'src/lsp/lsp_transport.dart'
    show
        LspBridgedTransport,
        LspCustomTransport,
        LspTransport,
        LspTransportKind,
        LspWebSocketTransport;
export 'src/lsp/lsp_types.dart'
    show LspConnectionState, LspConnectionStatus, LspReconnectPolicy;
// Options exports
export 'src/options/action.dart' show MonacoAction;
export 'src/options/editor_options.dart' show EditorOptions;
export 'src/options/language.dart' show MonacoLanguage;
export 'src/options/option_enums.dart'
    show
        AutoClosingBehavior,
        CursorBlinking,
        CursorStyle,
        DiagnosticsSeverity,
        MonacoAutoFindInSelection,
        MonacoBaseTheme,
        MonacoFindSeedSearchString,
        MonacoFoldingControls,
        MonacoFullwidthCharacterWidth,
        MonacoLineHighlight,
        MonacoLineNumbers,
        MonacoMinimapSide,
        MonacoScrollbarVisibility,
        MonacoWordWrap,
        RenderWhitespace;
export 'src/options/sub_options.dart'
    show
        MonacoFindOptions,
        MonacoGuidesOptions,
        MonacoMinimapOptions,
        MonacoPadding,
        MonacoScrollbarOptions,
        MonacoStickyScroll;
export 'src/options/theme.dart' show MonacoTheme;
export 'src/options/theme_definition.dart'
    show MonacoThemeDefinition, MonacoThemeRule;
// Type exports
export 'src/types/completion.dart'
    show
        CompletionItem,
        CompletionItemKind,
        CompletionList,
        CompletionRequest,
        InsertTextRule;
export 'src/types/decorations.dart' show DecorationOptions;
export 'src/types/geometry.dart' show Position, Range;
export 'src/types/json_diagnostics.dart'
    show JsonDiagnosticsOptions, JsonDiagnosticsSchema;
export 'src/types/keybinding.dart'
    show MonacoActionDescriptor, MonacoKey, MonacoKeybinding;
export 'src/types/markers.dart'
    show MarkerData, MarkerSeverity, RelatedInformation;
export 'src/types/scroll_handoff.dart'
    show
        MonacoScrollBoundaryPolicy,
        MonacoScrollHandoff,
        MonacoScrollHandoffDetails,
        MonacoScrollHandoffMode,
        MonacoScrollHandoffPhase,
        MonacoScrollHandoffSource;
export 'src/types/stats.dart' show EditorState, MonacoLiveStats;
export 'src/types/text.dart'
    show EditOperation, FindMatch, FindOptions, MonacoTextChange;
// Widget exports
export 'src/widgets/monaco_diff_editor.dart' show MonacoDiffEditor;
export 'src/widgets/monaco_editor_theme.dart'
    show MonacoEditorTheme, MonacoEditorThemeData;
export 'src/widgets/monaco_editor_view.dart' show MonacoEditor;
export 'src/widgets/monaco_focus_guard.dart' show MonacoFocusGuard;
export 'src/widgets/monaco_overlay_boundary.dart' show MonacoOverlayBoundary;
export 'src/widgets/monaco_route_observer.dart' show MonacoRouteObserver;
export 'src/widgets/monaco_scaffold.dart' show MonacoScaffold;
