// Catalog file: verbatim port of the 2.3.0 MonacoAction id catalog.
//
// ignore_for_file: public_member_api_docs

/// Deprecation message for catalog ids that standalone Monaco does not
/// register (verified against the bundled Monaco 0.57.0).
const String _notRegistered =
    'Standalone Monaco does not register this action, so executeAction '
    'throws for it.';

/// Pre-built Monaco editor action identifiers.
///
/// These IDs are sourced from the bundled Monaco editor assets, plus
/// Flutter Monaco helper actions that are already part of the public API.
///
/// This is an extension type over [String]: it erases to a plain [String] at
/// runtime, so `jsonEncode` works on it directly and equality is string
/// equality. Because of the erasure, `is MonacoAction` checks are not
/// meaningful at runtime. Custom action ids are constructed directly, for
/// example `MonacoAction('my.custom.action')`.
extension type const MonacoAction(
  /// The raw action id string sent to the Monaco editor.
  String id,
) {
  // General commands (non editor.action)
  static const acceptAlternativeSelectedSuggestion = MonacoAction(
    'acceptAlternativeSelectedSuggestion',
  );
  static const acceptRenameInput = MonacoAction('acceptRenameInput');
  static const acceptRenameInputWithPreview = MonacoAction(
    'acceptRenameInputWithPreview',
  );
  static const acceptSelectedSuggestion = MonacoAction(
    'acceptSelectedSuggestion',
  );
  static const acceptSnippet = MonacoAction('acceptSnippet');
  static const cancelLinkedEditingInput = MonacoAction(
    'cancelLinkedEditingInput',
  );
  static const cancelOperation = MonacoAction('editor.cancelOperation');
  static const cancelRenameInput = MonacoAction('cancelRenameInput');
  static const cancelSelection = MonacoAction('cancelSelection');
  static const closeFindWidget = MonacoAction('closeFindWidget');
  static const closeMarkersNavigation = MonacoAction('closeMarkersNavigation');
  static const closeParameterHints = MonacoAction('closeParameterHints');
  static const closeReferenceSearch = MonacoAction('closeReferenceSearch');
  static const codelensShowLensesInCurrentLine = MonacoAction(
    'codelens.showLensesInCurrentLine',
  );
  static const columnSelect = MonacoAction('columnSelect');
  static const createCursor = MonacoAction('createCursor');
  static const createFoldingRangeFromSelection = MonacoAction(
    'editor.createFoldingRangeFromSelection',
  );
  static const cursorBottom = MonacoAction('cursorBottom');
  static const cursorBottomSelect = MonacoAction('cursorBottomSelect');
  static const cursorColumnSelectDown = MonacoAction('cursorColumnSelectDown');
  static const cursorColumnSelectLeft = MonacoAction('cursorColumnSelectLeft');
  static const cursorColumnSelectPageDown = MonacoAction(
    'cursorColumnSelectPageDown',
  );
  static const cursorColumnSelectPageUp = MonacoAction(
    'cursorColumnSelectPageUp',
  );
  static const cursorColumnSelectRight = MonacoAction(
    'cursorColumnSelectRight',
  );
  static const cursorColumnSelectUp = MonacoAction('cursorColumnSelectUp');
  static const cursorEnd = MonacoAction('cursorEnd');
  static const cursorEndSelect = MonacoAction('cursorEndSelect');
  static const cursorHome = MonacoAction('cursorHome');
  static const cursorHomeSelect = MonacoAction('cursorHomeSelect');
  static const cursorLineEnd = MonacoAction('cursorLineEnd');
  static const cursorLineEndSelect = MonacoAction('cursorLineEndSelect');
  static const cursorLineStart = MonacoAction('cursorLineStart');
  static const cursorLineStartSelect = MonacoAction('cursorLineStartSelect');
  static const cursorMove = MonacoAction('cursorMove');
  static const cursorRedo = MonacoAction('cursorRedo');
  static const cursorTop = MonacoAction('cursorTop');
  static const cursorTopSelect = MonacoAction('cursorTopSelect');
  static const cursorUndo = MonacoAction('cursorUndo');
  static const cursorWordAccessibilityLeft = MonacoAction(
    'cursorWordAccessibilityLeft',
  );
  static const cursorWordAccessibilityLeftSelect = MonacoAction(
    'cursorWordAccessibilityLeftSelect',
  );
  static const cursorWordAccessibilityRight = MonacoAction(
    'cursorWordAccessibilityRight',
  );
  static const cursorWordAccessibilityRightSelect = MonacoAction(
    'cursorWordAccessibilityRightSelect',
  );
  static const cursorWordEndLeft = MonacoAction('cursorWordEndLeft');
  static const cursorWordEndLeftSelect = MonacoAction(
    'cursorWordEndLeftSelect',
  );
  static const cursorWordEndRight = MonacoAction('cursorWordEndRight');
  static const cursorWordEndRightSelect = MonacoAction(
    'cursorWordEndRightSelect',
  );
  static const cursorWordLeft = MonacoAction('cursorWordLeft');
  static const cursorWordLeftSelect = MonacoAction('cursorWordLeftSelect');
  static const cursorWordPartLeft = MonacoAction('cursorWordPartLeft');
  static const cursorWordPartLeftSelect = MonacoAction(
    'cursorWordPartLeftSelect',
  );
  static const cursorWordPartRight = MonacoAction('cursorWordPartRight');
  static const cursorWordPartRightSelect = MonacoAction(
    'cursorWordPartRightSelect',
  );
  static const cursorWordRight = MonacoAction('cursorWordRight');
  static const cursorWordRightSelect = MonacoAction('cursorWordRightSelect');
  static const cursorWordStartLeft = MonacoAction('cursorWordStartLeft');
  static const cursorWordStartLeftSelect = MonacoAction(
    'cursorWordStartLeftSelect',
  );
  static const cursorWordStartRight = MonacoAction('cursorWordStartRight');
  static const cursorWordStartRightSelect = MonacoAction(
    'cursorWordStartRightSelect',
  );
  static const deleteAllLeft = MonacoAction('deleteAllLeft');
  static const deleteAllRight = MonacoAction('deleteAllRight');
  static const deleteInsideWord = MonacoAction('deleteInsideWord');
  static const deleteLeft = MonacoAction('deleteLeft');
  static const deleteRight = MonacoAction('deleteRight');
  static const deleteWordEndLeft = MonacoAction('deleteWordEndLeft');
  static const deleteWordEndRight = MonacoAction('deleteWordEndRight');
  static const deleteWordLeft = MonacoAction('deleteWordLeft');
  static const deleteWordPartLeft = MonacoAction('deleteWordPartLeft');
  static const deleteWordPartRight = MonacoAction('deleteWordPartRight');
  static const deleteWordRight = MonacoAction('deleteWordRight');
  static const deleteWordStartLeft = MonacoAction('deleteWordStartLeft');
  static const deleteWordStartRight = MonacoAction('deleteWordStartRight');
  static const diffEditorCollapseAllUnchangedRegions = MonacoAction(
    'diffEditor.collapseAllUnchangedRegions',
  );
  static const diffEditorExitCompareMove = MonacoAction(
    'diffEditor.exitCompareMove',
  );
  static const diffEditorRevert = MonacoAction('diffEditor.revert');
  static const diffEditorShowAllUnchangedRegions = MonacoAction(
    'diffEditor.showAllUnchangedRegions',
  );
  static const diffEditorSwitchSide = MonacoAction('diffEditor.switchSide');
  static const diffEditorToggleCollapseUnchangedRegions = MonacoAction(
    'diffEditor.toggleCollapseUnchangedRegions',
  );
  static const diffEditorToggleShowMovedCodeBlocks = MonacoAction(
    'diffEditor.toggleShowMovedCodeBlocks',
  );
  static const diffEditorToggleUseInlineViewWhenSpaceIsLimited = MonacoAction(
    'diffEditor.toggleUseInlineViewWhenSpaceIsLimited',
  );
  static const editorScroll = MonacoAction('editorScroll');
  static const expandLineSelection = MonacoAction('expandLineSelection');
  static const find = MonacoAction('actions.find');
  static const findWithArgs = MonacoAction('editor.actions.findWithArgs');
  static const findWithSelection = MonacoAction('actions.findWithSelection');
  static const focusAndAcceptSuggestion = MonacoAction(
    'focusAndAcceptSuggestion',
  );
  static const focusNextRenameSuggestion = MonacoAction(
    'focusNextRenameSuggestion',
  );
  static const focusPreviousRenameSuggestion = MonacoAction(
    'focusPreviousRenameSuggestion',
  );
  static const focusSuggestion = MonacoAction('focusSuggestion');
  static const fold = MonacoAction('editor.fold');
  static const foldAll = MonacoAction('editor.foldAll');
  static const foldAllBlockComments = MonacoAction(
    'editor.foldAllBlockComments',
  );
  static const foldAllExcept = MonacoAction('editor.foldAllExcept');
  static const foldAllMarkerRegions = MonacoAction(
    'editor.foldAllMarkerRegions',
  );
  static const foldLevel1 = MonacoAction('editor.foldLevel1');
  static const foldLevel2 = MonacoAction('editor.foldLevel2');
  static const foldLevel3 = MonacoAction('editor.foldLevel3');
  static const foldLevel4 = MonacoAction('editor.foldLevel4');
  static const foldLevel5 = MonacoAction('editor.foldLevel5');
  static const foldLevel6 = MonacoAction('editor.foldLevel6');
  static const foldLevel7 = MonacoAction('editor.foldLevel7');
  static const foldRecursively = MonacoAction('editor.foldRecursively');
  static const getContextKeyInfo = MonacoAction('getContextKeyInfo');
  static const goToNextReference = MonacoAction('goToNextReference');
  static const goToPreviousReference = MonacoAction('goToPreviousReference');
  static const gotoNextFold = MonacoAction('editor.gotoNextFold');
  static const gotoNextSymbolFromResult = MonacoAction(
    'editor.gotoNextSymbolFromResult',
  );
  static const gotoNextSymbolFromResultCancel = MonacoAction(
    'editor.gotoNextSymbolFromResult.cancel',
  );
  static const gotoParentFold = MonacoAction('editor.gotoParentFold');
  static const gotoPreviousFold = MonacoAction('editor.gotoPreviousFold');
  static const hideCodeActionWidget = MonacoAction('hideCodeActionWidget');
  static const hideDropWidget = MonacoAction('editor.hideDropWidget');
  static const hidePasteWidget = MonacoAction('editor.hidePasteWidget');
  static const hideSuggestWidget = MonacoAction('hideSuggestWidget');
  static const historyShowNext = MonacoAction('history.showNext');
  static const historyShowPrevious = MonacoAction('history.showPrevious');
  static const insertBestCompletion = MonacoAction('insertBestCompletion');
  static const insertNextSuggestion = MonacoAction('insertNextSuggestion');
  static const insertPrevSuggestion = MonacoAction('insertPrevSuggestion');
  static const internalExecuteCodeActionProvider = MonacoAction(
    '_executeCodeActionProvider',
  );
  static const internalExecuteCodeLensProvider = MonacoAction(
    '_executeCodeLensProvider',
  );
  static const internalExecuteColorPresentationProvider = MonacoAction(
    '_executeColorPresentationProvider',
  );
  static const internalExecuteCompletionItemProvider = MonacoAction(
    '_executeCompletionItemProvider',
  );
  static const internalExecuteDocumentColorProvider = MonacoAction(
    '_executeDocumentColorProvider',
  );
  static const internalExecuteDocumentSymbolProvider = MonacoAction(
    '_executeDocumentSymbolProvider',
  );
  static const internalExecuteFoldingRangeProvider = MonacoAction(
    '_executeFoldingRangeProvider',
  );
  static const internalExecuteFormatDocumentProvider = MonacoAction(
    '_executeFormatDocumentProvider',
  );
  static const internalExecuteFormatOnTypeProvider = MonacoAction(
    '_executeFormatOnTypeProvider',
  );
  static const internalExecuteFormatRangeProvider = MonacoAction(
    '_executeFormatRangeProvider',
  );
  static const internalExecuteInlayHintProvider = MonacoAction(
    '_executeInlayHintProvider',
  );
  static const internalExecuteLinkProvider = MonacoAction(
    '_executeLinkProvider',
  );
  static const internalExecuteSelectionRangeProvider = MonacoAction(
    '_executeSelectionRangeProvider',
  );
  static const internalExecuteSignatureHelpProvider = MonacoAction(
    '_executeSignatureHelpProvider',
  );
  static const internalGenerateContextKeyInfo = MonacoAction(
    '_generateContextKeyInfo',
  );
  static const internalLastCursorMoveToSelect = MonacoAction(
    '_lastCursorMoveToSelect',
  );
  static const internalLineSelect = MonacoAction('_lineSelect');
  static const internalLineSelectDrag = MonacoAction('_lineSelectDrag');
  static const internalMoveTo = MonacoAction('_moveTo');
  static const internalMoveToSelect = MonacoAction('_moveToSelect');
  static const internalProvideDocumentRangeSemanticTokens = MonacoAction(
    '_provideDocumentRangeSemanticTokens',
  );
  static const internalProvideDocumentRangeSemanticTokensLegend = MonacoAction(
    '_provideDocumentRangeSemanticTokensLegend',
  );
  static const internalProvideDocumentSemanticTokens = MonacoAction(
    '_provideDocumentSemanticTokens',
  );
  static const internalProvideDocumentSemanticTokensLegend = MonacoAction(
    '_provideDocumentSemanticTokensLegend',
  );
  static const internalSetContext = MonacoAction('_setContext');
  static const internalWordSelect = MonacoAction('_wordSelect');
  static const internalWordSelectDrag = MonacoAction('_wordSelectDrag');
  static const jumpToNextSnippetPlaceholder = MonacoAction(
    'jumpToNextSnippetPlaceholder',
  );
  static const jumpToPrevSnippetPlaceholder = MonacoAction(
    'jumpToPrevSnippetPlaceholder',
  );
  static const lastCursorLineSelect = MonacoAction('lastCursorLineSelect');
  static const lastCursorLineSelectDrag = MonacoAction(
    'lastCursorLineSelectDrag',
  );
  static const lastCursorWordSelect = MonacoAction('lastCursorWordSelect');
  static const leaveEditorMessage = MonacoAction('leaveEditorMessage');
  static const leaveSnippet = MonacoAction('leaveSnippet');
  static const lineBreakInsert = MonacoAction('lineBreakInsert');
  static const noop = MonacoAction('noop');
  static const openReference = MonacoAction('openReference');
  static const openReferenceToSide = MonacoAction('openReferenceToSide');
  static const outdent = MonacoAction('outdent');
  static const quickInputAccept = MonacoAction('quickInput.accept');
  static const redo = MonacoAction('redo');
  static const removeManualFoldingRanges = MonacoAction(
    'editor.removeManualFoldingRanges',
  );
  static const removeSecondaryCursors = MonacoAction('removeSecondaryCursors');
  static const revealLine = MonacoAction('revealLine');
  static const revealReference = MonacoAction('revealReference');
  static const scrollEditorBottom = MonacoAction('scrollEditorBottom');
  static const scrollEditorTop = MonacoAction('scrollEditorTop');
  static const scrollLeft = MonacoAction('scrollLeft');
  static const scrollLineDown = MonacoAction('scrollLineDown');
  static const scrollLineUp = MonacoAction('scrollLineUp');
  static const scrollPageDown = MonacoAction('scrollPageDown');
  static const scrollPageUp = MonacoAction('scrollPageUp');
  static const scrollRight = MonacoAction('scrollRight');
  static const selectFirstSuggestion = MonacoAction('selectFirstSuggestion');
  static const selectLastSuggestion = MonacoAction('selectLastSuggestion');
  static const selectNextCodeAction = MonacoAction('selectNextCodeAction');
  static const selectNextPageSuggestion = MonacoAction(
    'selectNextPageSuggestion',
  );
  static const selectNextSuggestion = MonacoAction('selectNextSuggestion');
  static const selectPrevCodeAction = MonacoAction('selectPrevCodeAction');
  static const selectPrevPageSuggestion = MonacoAction(
    'selectPrevPageSuggestion',
  );
  static const selectPrevSuggestion = MonacoAction('selectPrevSuggestion');
  static const setSelection = MonacoAction('setSelection');
  static const showNextParameterHint = MonacoAction('showNextParameterHint');
  static const showPrevParameterHint = MonacoAction('showPrevParameterHint');
  static const tab = MonacoAction('tab');
  static const toggleExplainMode = MonacoAction('toggleExplainMode');
  static const toggleFindCaseSensitive = MonacoAction(
    'toggleFindCaseSensitive',
  );
  static const toggleFindInSelection = MonacoAction('toggleFindInSelection');
  static const toggleFindRegex = MonacoAction('toggleFindRegex');
  static const toggleFindWholeWord = MonacoAction('toggleFindWholeWord');
  static const toggleFold = MonacoAction('editor.toggleFold');
  static const toggleFoldRecursively = MonacoAction(
    'editor.toggleFoldRecursively',
  );
  static const toggleImportFold = MonacoAction('editor.toggleImportFold');
  static const togglePeekWidgetFocus = MonacoAction('togglePeekWidgetFocus');
  static const togglePreserveCase = MonacoAction('togglePreserveCase');
  static const toggleSuggestionDetails = MonacoAction(
    'toggleSuggestionDetails',
  );
  static const toggleSuggestionFocus = MonacoAction('toggleSuggestionFocus');
  static const undo = MonacoAction('undo');
  static const unfold = MonacoAction('editor.unfold');
  static const unfoldAll = MonacoAction('editor.unfoldAll');
  static const unfoldAllExcept = MonacoAction('editor.unfoldAllExcept');
  static const unfoldAllMarkerRegions = MonacoAction(
    'editor.unfoldAllMarkerRegions',
  );
  static const unfoldRecursively = MonacoAction('editor.unfoldRecursively');
  static const workbenchActionShowHover = MonacoAction(
    'workbench.action.showHover',
  );

  // Monaco editor.action commands

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it.
  @Deprecated(_notRegistered)
  static const accessibilityHelp = MonacoAction(
    'editor.action.accessibilityHelp',
  );
  static const accessibleDiffViewerNext = MonacoAction(
    'editor.action.accessibleDiffViewer.next',
  );
  static const accessibleDiffViewerPrev = MonacoAction(
    'editor.action.accessibleDiffViewer.prev',
  );

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it.
  @Deprecated(_notRegistered)
  static const accessibleView = MonacoAction('editor.action.accessibleView');
  static const addCommentLine = MonacoAction('editor.action.addCommentLine');
  static const addCursorsToBottom = MonacoAction(
    'editor.action.addCursorsToBottom',
  );
  static const addCursorsToTop = MonacoAction('editor.action.addCursorsToTop');
  static const addSelectionToNextFindMatch = MonacoAction(
    'editor.action.addSelectionToNextFindMatch',
  );
  static const addSelectionToPreviousFindMatch = MonacoAction(
    'editor.action.addSelectionToPreviousFindMatch',
  );
  static const autoFix = MonacoAction('editor.action.autoFix');
  static const blockComment = MonacoAction('editor.action.blockComment');
  static const cancelSelectionAnchor = MonacoAction(
    'editor.action.cancelSelectionAnchor',
  );
  static const changeAll = MonacoAction('editor.action.changeAll');
  static const changeTabDisplaySize = MonacoAction(
    'editor.action.changeTabDisplaySize',
  );
  static const clipboardCopyAction = MonacoAction(
    'editor.action.clipboardCopyAction',
  );
  static const clipboardCopyWithSyntaxHighlightingAction = MonacoAction(
    'editor.action.clipboardCopyWithSyntaxHighlightingAction',
  );
  static const clipboardCutAction = MonacoAction(
    'editor.action.clipboardCutAction',
  );
  static const clipboardPasteAction = MonacoAction(
    'editor.action.clipboardPasteAction',
  );
  static const codeAction = MonacoAction('editor.action.codeAction');
  static const commentLine = MonacoAction('editor.action.commentLine');
  static const copyLinesDownAction = MonacoAction(
    'editor.action.copyLinesDownAction',
  );
  static const copyLinesUpAction = MonacoAction(
    'editor.action.copyLinesUpAction',
  );
  static const debugEditorGpuRenderer = MonacoAction(
    'editor.action.debugEditorGpuRenderer',
  );
  static const decreaseHoverVerbosityLevel = MonacoAction(
    'editor.action.decreaseHoverVerbosityLevel',
  );
  static const deleteLines = MonacoAction('editor.action.deleteLines');
  static const detectIndentation = MonacoAction(
    'editor.action.detectIndentation',
  );
  static const diffReviewNext = MonacoAction('editor.action.diffReview.next');
  static const diffReviewPrev = MonacoAction('editor.action.diffReview.prev');
  static const duplicateSelection = MonacoAction(
    'editor.action.duplicateSelection',
  );
  static const findReferences = MonacoAction('editor.action.findReferences');
  static const fixAll = MonacoAction('editor.action.fixAll');
  static const focusNextCursor = MonacoAction('editor.action.focusNextCursor');
  static const focusPreviousCursor = MonacoAction(
    'editor.action.focusPreviousCursor',
  );
  static const focusStickyScroll = MonacoAction(
    'editor.action.focusStickyScroll',
  );
  static const fontZoomIn = MonacoAction('editor.action.fontZoomIn');
  static const fontZoomOut = MonacoAction('editor.action.fontZoomOut');
  static const fontZoomReset = MonacoAction('editor.action.fontZoomReset');
  static const forceRetokenize = MonacoAction('editor.action.forceRetokenize');
  static const format = MonacoAction('editor.action.format');
  static const formatDocument = MonacoAction('editor.action.formatDocument');
  static const formatSelection = MonacoAction('editor.action.formatSelection');
  static const goToBottomHover = MonacoAction('editor.action.goToBottomHover');
  static const goToDeclaration = MonacoAction('editor.action.goToDeclaration');
  static const goToFocusedStickyScrollLine = MonacoAction(
    'editor.action.goToFocusedStickyScrollLine',
  );
  static const goToImplementation = MonacoAction(
    'editor.action.goToImplementation',
  );

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it.
  @Deprecated(_notRegistered)
  static const goToLocation = MonacoAction('editor.action.goToLocation');
  static const goToLocations = MonacoAction('editor.action.goToLocations');
  static const goToMatchFindAction = MonacoAction(
    'editor.action.goToMatchFindAction',
  );
  static const goToReferences = MonacoAction('editor.action.goToReferences');
  static const goToSelectionAnchor = MonacoAction(
    'editor.action.goToSelectionAnchor',
  );
  static const goToTopHover = MonacoAction('editor.action.goToTopHover');
  static const goToTypeDefinition = MonacoAction(
    'editor.action.goToTypeDefinition',
  );
  static const gotoLine = MonacoAction('editor.action.gotoLine');
  static const hideColorPicker = MonacoAction('editor.action.hideColorPicker');
  static const hideHover = MonacoAction('editor.action.hideHover');
  static const inPlaceReplaceDown = MonacoAction(
    'editor.action.inPlaceReplace.down',
  );
  static const inPlaceReplaceUp = MonacoAction(
    'editor.action.inPlaceReplace.up',
  );
  static const increaseHoverVerbosityLevel = MonacoAction(
    'editor.action.increaseHoverVerbosityLevel',
  );
  static const indentLines = MonacoAction('editor.action.indentLines');
  static const indentUsingSpaces = MonacoAction(
    'editor.action.indentUsingSpaces',
  );
  static const indentUsingTabs = MonacoAction('editor.action.indentUsingTabs');
  static const indentationToSpaces = MonacoAction(
    'editor.action.indentationToSpaces',
  );
  static const indentationToTabs = MonacoAction(
    'editor.action.indentationToTabs',
  );
  static const inlineSuggestAcceptNextLine = MonacoAction(
    'editor.action.inlineSuggest.acceptNextLine',
  );
  static const inlineSuggestAcceptNextWord = MonacoAction(
    'editor.action.inlineSuggest.acceptNextWord',
  );
  static const inlineSuggestCancelSnooze = MonacoAction(
    'editor.action.inlineSuggest.cancelSnooze',
  );
  static const inlineSuggestCommit = MonacoAction(
    'editor.action.inlineSuggest.commit',
  );
  static const inlineSuggestDevExtractRepro = MonacoAction(
    'editor.action.inlineSuggest.dev.extractRepro',
  );
  static const inlineSuggestHide = MonacoAction(
    'editor.action.inlineSuggest.hide',
  );
  static const inlineSuggestJump = MonacoAction(
    'editor.action.inlineSuggest.jump',
  );
  static const inlineSuggestShowNext = MonacoAction(
    'editor.action.inlineSuggest.showNext',
  );
  static const inlineSuggestShowPrevious = MonacoAction(
    'editor.action.inlineSuggest.showPrevious',
  );
  static const inlineSuggestSnooze = MonacoAction(
    'editor.action.inlineSuggest.snooze',
  );
  static const inlineSuggestToggleAlwaysShowToolbar = MonacoAction(
    'editor.action.inlineSuggest.toggleAlwaysShowToolbar',
  );
  static const inlineSuggestToggleShowCollapsed = MonacoAction(
    'editor.action.inlineSuggest.toggleShowCollapsed',
  );
  static const inlineSuggestTrigger = MonacoAction(
    'editor.action.inlineSuggest.trigger',
  );

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it.
  @Deprecated(_notRegistered)
  static const inlineSuggestTriggerInlineEdit = MonacoAction(
    'editor.action.inlineSuggest.triggerInlineEdit',
  );

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it.
  @Deprecated(_notRegistered)
  static const inlineSuggestTriggerInlineEditExplicit = MonacoAction(
    'editor.action.inlineSuggest.triggerInlineEditExplicit',
  );
  static const insertColorWithStandaloneColorPicker = MonacoAction(
    'editor.action.insertColorWithStandaloneColorPicker',
  );
  static const insertCursorAbove = MonacoAction(
    'editor.action.insertCursorAbove',
  );
  static const insertCursorAtEndOfEachLineSelected = MonacoAction(
    'editor.action.insertCursorAtEndOfEachLineSelected',
  );
  static const insertCursorBelow = MonacoAction(
    'editor.action.insertCursorBelow',
  );
  static const insertFinalNewLine = MonacoAction(
    'editor.action.insertFinalNewLine',
  );
  static const insertLineAfter = MonacoAction('editor.action.insertLineAfter');
  static const insertLineBefore = MonacoAction(
    'editor.action.insertLineBefore',
  );
  static const inspectTokens = MonacoAction('editor.action.inspectTokens');
  static const joinLines = MonacoAction('editor.action.joinLines');
  static const jumpToBracket = MonacoAction('editor.action.jumpToBracket');
  static const linkedEditing = MonacoAction('editor.action.linkedEditing');
  static const markerNext = MonacoAction('editor.action.marker.next');
  static const markerNextInFiles = MonacoAction(
    'editor.action.marker.nextInFiles',
  );
  static const markerPrev = MonacoAction('editor.action.marker.prev');
  static const markerPrevInFiles = MonacoAction(
    'editor.action.marker.prevInFiles',
  );
  static const moveCarretLeftAction = MonacoAction(
    'editor.action.moveCarretLeftAction',
  );
  static const moveCarretRightAction = MonacoAction(
    'editor.action.moveCarretRightAction',
  );
  static const moveLinesDownAction = MonacoAction(
    'editor.action.moveLinesDownAction',
  );
  static const moveLinesUpAction = MonacoAction(
    'editor.action.moveLinesUpAction',
  );
  static const moveSelectionToNextFindMatch = MonacoAction(
    'editor.action.moveSelectionToNextFindMatch',
  );
  static const moveSelectionToPreviousFindMatch = MonacoAction(
    'editor.action.moveSelectionToPreviousFindMatch',
  );
  static const nextMatchFindAction = MonacoAction(
    'editor.action.nextMatchFindAction',
  );
  static const nextSelectionMatchFindAction = MonacoAction(
    'editor.action.nextSelectionMatchFindAction',
  );
  static const openDeclarationToTheSide = MonacoAction(
    'editor.action.openDeclarationToTheSide',
  );
  static const openLink = MonacoAction('editor.action.openLink');
  static const organizeImports = MonacoAction('editor.action.organizeImports');
  static const outdentLines = MonacoAction('editor.action.outdentLines');
  static const pageDownHover = MonacoAction('editor.action.pageDownHover');
  static const pageUpHover = MonacoAction('editor.action.pageUpHover');
  static const pasteAs = MonacoAction('editor.action.pasteAs');
  static const pasteAsText = MonacoAction('editor.action.pasteAsText');
  static const peekDeclaration = MonacoAction('editor.action.peekDeclaration');
  static const peekDefinition = MonacoAction('editor.action.peekDefinition');
  static const peekImplementation = MonacoAction(
    'editor.action.peekImplementation',
  );
  static const peekLocations = MonacoAction('editor.action.peekLocations');
  static const peekTypeDefinition = MonacoAction(
    'editor.action.peekTypeDefinition',
  );
  static const previewDeclaration = MonacoAction(
    'editor.action.previewDeclaration',
  );
  static const previousMatchFindAction = MonacoAction(
    'editor.action.previousMatchFindAction',
  );
  static const previousSelectionMatchFindAction = MonacoAction(
    'editor.action.previousSelectionMatchFindAction',
  );
  static const quickCommand = MonacoAction('editor.action.quickCommand');
  static const quickFix = MonacoAction('editor.action.quickFix');
  static const quickOutline = MonacoAction('editor.action.quickOutline');
  static const refactor = MonacoAction('editor.action.refactor');
  static const referenceSearchTrigger = MonacoAction(
    'editor.action.referenceSearch.trigger',
  );
  static const reindentlines = MonacoAction('editor.action.reindentlines');
  static const reindentselectedlines = MonacoAction(
    'editor.action.reindentselectedlines',
  );
  static const removeBrackets = MonacoAction('editor.action.removeBrackets');
  static const removeCommentLine = MonacoAction(
    'editor.action.removeCommentLine',
  );
  static const removeDuplicateLines = MonacoAction(
    'editor.action.removeDuplicateLines',
  );
  static const rename = MonacoAction('editor.action.rename');
  static const replaceAll = MonacoAction('editor.action.replaceAll');
  static const replaceOne = MonacoAction('editor.action.replaceOne');
  static const resetSuggestSize = MonacoAction(
    'editor.action.resetSuggestSize',
  );
  static const revealDeclaration = MonacoAction(
    'editor.action.revealDeclaration',
  );
  static const revealDefinition = MonacoAction(
    'editor.action.revealDefinition',
  );
  static const revealDefinitionAside = MonacoAction(
    'editor.action.revealDefinitionAside',
  );
  static const reverseLines = MonacoAction('editor.action.reverseLines');
  static const scrollDownHover = MonacoAction('editor.action.scrollDownHover');
  static const scrollLeftHover = MonacoAction('editor.action.scrollLeftHover');
  static const scrollRightHover = MonacoAction(
    'editor.action.scrollRightHover',
  );
  static const scrollUpHover = MonacoAction('editor.action.scrollUpHover');
  static const selectAll = MonacoAction('editor.action.selectAll');
  static const selectAllMatches = MonacoAction(
    'editor.action.selectAllMatches',
  );
  static const selectEditor = MonacoAction('editor.action.selectEditor');
  static const selectFromAnchorToCursor = MonacoAction(
    'editor.action.selectFromAnchorToCursor',
  );
  static const selectHighlights = MonacoAction(
    'editor.action.selectHighlights',
  );
  static const selectNextStickyScrollLine = MonacoAction(
    'editor.action.selectNextStickyScrollLine',
  );
  static const selectPreviousStickyScrollLine = MonacoAction(
    'editor.action.selectPreviousStickyScrollLine',
  );
  static const selectToBracket = MonacoAction('editor.action.selectToBracket');
  static const setSelectionAnchor = MonacoAction(
    'editor.action.setSelectionAnchor',
  );
  static const showContextMenu = MonacoAction('editor.action.showContextMenu');
  static const showDefinitionPreviewHover = MonacoAction(
    'editor.action.showDefinitionPreviewHover',
  );
  static const showHover = MonacoAction('editor.action.showHover');
  static const showOrFocusStandaloneColorPicker = MonacoAction(
    'editor.action.showOrFocusStandaloneColorPicker',
  );
  static const showReferences = MonacoAction('editor.action.showReferences');
  static const smartSelectExpand = MonacoAction(
    'editor.action.smartSelect.expand',
  );
  static const smartSelectGrow = MonacoAction('editor.action.smartSelect.grow');
  static const smartSelectShrink = MonacoAction(
    'editor.action.smartSelect.shrink',
  );
  static const sortLinesAscending = MonacoAction(
    'editor.action.sortLinesAscending',
  );
  static const sortLinesDescending = MonacoAction(
    'editor.action.sortLinesDescending',
  );
  static const sourceAction = MonacoAction('editor.action.sourceAction');
  static const startFindReplaceAction = MonacoAction(
    'editor.action.startFindReplaceAction',
  );
  static const toggleHighContrast = MonacoAction(
    'editor.action.toggleHighContrast',
  );

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it.
  @Deprecated(_notRegistered)
  static const toggleScreenReaderAccessibilityMode = MonacoAction(
    'editor.action.toggleScreenReaderAccessibilityMode',
  );
  static const toggleStickyScroll = MonacoAction(
    'editor.action.toggleStickyScroll',
  );
  static const toggleTabFocusMode = MonacoAction(
    'editor.action.toggleTabFocusMode',
  );

  /// Not registered by standalone Monaco; `MonacoController.executeAction`
  /// throws for it. Set `EditorOptions.wordWrap` with
  /// `MonacoController.updateOptions` instead.
  @Deprecated(
    'Standalone Monaco does not register this action, so executeAction '
    'throws for it. Set EditorOptions.wordWrap with updateOptions instead.',
  )
  static const toggleWordWrap = MonacoAction('editor.action.toggleWordWrap');
  static const transformToCamelcase = MonacoAction(
    'editor.action.transformToCamelcase',
  );
  static const transformToKebabcase = MonacoAction(
    'editor.action.transformToKebabcase',
  );
  static const transformToLowercase = MonacoAction(
    'editor.action.transformToLowercase',
  );
  static const transformToPascalcase = MonacoAction(
    'editor.action.transformToPascalcase',
  );
  static const transformToSnakecase = MonacoAction(
    'editor.action.transformToSnakecase',
  );
  static const transformToTitlecase = MonacoAction(
    'editor.action.transformToTitlecase',
  );
  static const transformToUppercase = MonacoAction(
    'editor.action.transformToUppercase',
  );
  static const transpose = MonacoAction('editor.action.transpose');
  static const transposeLetters = MonacoAction(
    'editor.action.transposeLetters',
  );
  static const triggerParameterHints = MonacoAction(
    'editor.action.triggerParameterHints',
  );
  static const triggerSuggest = MonacoAction('editor.action.triggerSuggest');
  static const trimTrailingWhitespace = MonacoAction(
    'editor.action.trimTrailingWhitespace',
  );
  static const unicodeHighlightDisableHighlightingOfAmbiguousCharacters =
      MonacoAction(
        'editor.action.unicodeHighlight.disableHighlightingOfAmbiguousCharacters',
      );
  static const unicodeHighlightDisableHighlightingOfInvisibleCharacters =
      MonacoAction(
        'editor.action.unicodeHighlight.disableHighlightingOfInvisibleCharacters',
      );
  static const unicodeHighlightDisableHighlightingOfNonBasicAsciiCharacters =
      MonacoAction(
        'editor.action.unicodeHighlight.disableHighlightingOfNonBasicAsciiCharacters',
      );
  static const unicodeHighlightShowExcludeOptions = MonacoAction(
    'editor.action.unicodeHighlight.showExcludeOptions',
  );
  static const wordHighlightNext = MonacoAction(
    'editor.action.wordHighlight.next',
  );
  static const wordHighlightPrev = MonacoAction(
    'editor.action.wordHighlight.prev',
  );
  static const wordHighlightTrigger = MonacoAction(
    'editor.action.wordHighlight.trigger',
  );
}
