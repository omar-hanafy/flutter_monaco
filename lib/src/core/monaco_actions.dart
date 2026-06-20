// ignore_for_file: public_member_api_docs

/// Pre-built Monaco editor action identifiers.
///
/// These IDs are sourced from the bundled Monaco 0.54.0 assets, plus
/// Flutter Monaco helper actions that are already part of the public API.
class MonacoAction {
  MonacoAction._();

  // General commands (non editor.action)
  static const String acceptAlternativeSelectedSuggestion =
      'acceptAlternativeSelectedSuggestion';
  static const String acceptRenameInput = 'acceptRenameInput';
  static const String acceptRenameInputWithPreview =
      'acceptRenameInputWithPreview';
  static const String acceptSelectedSuggestion = 'acceptSelectedSuggestion';
  static const String acceptSnippet = 'acceptSnippet';
  static const String cancelLinkedEditingInput = 'cancelLinkedEditingInput';
  static const String cancelOperation = 'editor.cancelOperation';
  static const String cancelRenameInput = 'cancelRenameInput';
  static const String cancelSelection = 'cancelSelection';
  static const String closeFindWidget = 'closeFindWidget';
  static const String closeMarkersNavigation = 'closeMarkersNavigation';
  static const String closeParameterHints = 'closeParameterHints';
  static const String closeReferenceSearch = 'closeReferenceSearch';
  static const String codelensShowLensesInCurrentLine =
      'codelens.showLensesInCurrentLine';
  static const String columnSelect = 'columnSelect';
  static const String createCursor = 'createCursor';
  static const String createFoldingRangeFromSelection =
      'editor.createFoldingRangeFromSelection';
  static const String cursorBottom = 'cursorBottom';
  static const String cursorBottomSelect = 'cursorBottomSelect';
  static const String cursorColumnSelectDown = 'cursorColumnSelectDown';
  static const String cursorColumnSelectLeft = 'cursorColumnSelectLeft';
  static const String cursorColumnSelectPageDown = 'cursorColumnSelectPageDown';
  static const String cursorColumnSelectPageUp = 'cursorColumnSelectPageUp';
  static const String cursorColumnSelectRight = 'cursorColumnSelectRight';
  static const String cursorColumnSelectUp = 'cursorColumnSelectUp';
  static const String cursorEnd = 'cursorEnd';
  static const String cursorEndSelect = 'cursorEndSelect';
  static const String cursorHome = 'cursorHome';
  static const String cursorHomeSelect = 'cursorHomeSelect';
  static const String cursorLineEnd = 'cursorLineEnd';
  static const String cursorLineEndSelect = 'cursorLineEndSelect';
  static const String cursorLineStart = 'cursorLineStart';
  static const String cursorLineStartSelect = 'cursorLineStartSelect';
  static const String cursorMove = 'cursorMove';
  static const String cursorRedo = 'cursorRedo';
  static const String cursorTop = 'cursorTop';
  static const String cursorTopSelect = 'cursorTopSelect';
  static const String cursorUndo = 'cursorUndo';
  static const String cursorWordAccessibilityLeft =
      'cursorWordAccessibilityLeft';
  static const String cursorWordAccessibilityLeftSelect =
      'cursorWordAccessibilityLeftSelect';
  static const String cursorWordAccessibilityRight =
      'cursorWordAccessibilityRight';
  static const String cursorWordAccessibilityRightSelect =
      'cursorWordAccessibilityRightSelect';
  static const String cursorWordEndLeft = 'cursorWordEndLeft';
  static const String cursorWordEndLeftSelect = 'cursorWordEndLeftSelect';
  static const String cursorWordEndRight = 'cursorWordEndRight';
  static const String cursorWordEndRightSelect = 'cursorWordEndRightSelect';
  static const String cursorWordLeft = 'cursorWordLeft';
  static const String cursorWordLeftSelect = 'cursorWordLeftSelect';
  static const String cursorWordPartLeft = 'cursorWordPartLeft';
  static const String cursorWordPartLeftSelect = 'cursorWordPartLeftSelect';
  static const String cursorWordPartRight = 'cursorWordPartRight';
  static const String cursorWordPartRightSelect = 'cursorWordPartRightSelect';
  static const String cursorWordRight = 'cursorWordRight';
  static const String cursorWordRightSelect = 'cursorWordRightSelect';
  static const String cursorWordStartLeft = 'cursorWordStartLeft';
  static const String cursorWordStartLeftSelect = 'cursorWordStartLeftSelect';
  static const String cursorWordStartRight = 'cursorWordStartRight';
  static const String cursorWordStartRightSelect = 'cursorWordStartRightSelect';
  static const String deleteAllLeft = 'deleteAllLeft';
  static const String deleteAllRight = 'deleteAllRight';
  static const String deleteInsideWord = 'deleteInsideWord';
  static const String deleteLeft = 'deleteLeft';
  static const String deleteRight = 'deleteRight';
  static const String deleteWordEndLeft = 'deleteWordEndLeft';
  static const String deleteWordEndRight = 'deleteWordEndRight';
  static const String deleteWordLeft = 'deleteWordLeft';
  static const String deleteWordPartLeft = 'deleteWordPartLeft';
  static const String deleteWordPartRight = 'deleteWordPartRight';
  static const String deleteWordRight = 'deleteWordRight';
  static const String deleteWordStartLeft = 'deleteWordStartLeft';
  static const String deleteWordStartRight = 'deleteWordStartRight';
  static const String diffEditorCollapseAllUnchangedRegions =
      'diffEditor.collapseAllUnchangedRegions';
  static const String diffEditorExitCompareMove = 'diffEditor.exitCompareMove';
  static const String diffEditorRevert = 'diffEditor.revert';
  static const String diffEditorShowAllUnchangedRegions =
      'diffEditor.showAllUnchangedRegions';
  static const String diffEditorSwitchSide = 'diffEditor.switchSide';
  static const String diffEditorToggleCollapseUnchangedRegions =
      'diffEditor.toggleCollapseUnchangedRegions';
  static const String diffEditorToggleShowMovedCodeBlocks =
      'diffEditor.toggleShowMovedCodeBlocks';
  static const String diffEditorToggleUseInlineViewWhenSpaceIsLimited =
      'diffEditor.toggleUseInlineViewWhenSpaceIsLimited';
  static const String editorScroll = 'editorScroll';
  static const String expandLineSelection = 'expandLineSelection';
  static const String find = 'actions.find';
  static const String findWithArgs = 'editor.actions.findWithArgs';
  static const String findWithSelection = 'actions.findWithSelection';
  static const String focusAndAcceptSuggestion = 'focusAndAcceptSuggestion';
  static const String focusNextRenameSuggestion = 'focusNextRenameSuggestion';
  static const String focusPreviousRenameSuggestion =
      'focusPreviousRenameSuggestion';
  static const String focusSuggestion = 'focusSuggestion';
  static const String fold = 'editor.fold';
  static const String foldAll = 'editor.foldAll';
  static const String foldAllBlockComments = 'editor.foldAllBlockComments';
  static const String foldAllExcept = 'editor.foldAllExcept';
  static const String foldAllMarkerRegions = 'editor.foldAllMarkerRegions';
  static const String foldLevel1 = 'editor.foldLevel1';
  static const String foldLevel2 = 'editor.foldLevel2';
  static const String foldLevel3 = 'editor.foldLevel3';
  static const String foldLevel4 = 'editor.foldLevel4';
  static const String foldLevel5 = 'editor.foldLevel5';
  static const String foldLevel6 = 'editor.foldLevel6';
  static const String foldLevel7 = 'editor.foldLevel7';
  static const String foldRecursively = 'editor.foldRecursively';
  static const String getContextKeyInfo = 'getContextKeyInfo';
  static const String goToNextReference = 'goToNextReference';
  static const String goToPreviousReference = 'goToPreviousReference';
  static const String gotoNextFold = 'editor.gotoNextFold';
  static const String gotoNextSymbolFromResult =
      'editor.gotoNextSymbolFromResult';
  static const String gotoNextSymbolFromResultCancel =
      'editor.gotoNextSymbolFromResult.cancel';
  static const String gotoParentFold = 'editor.gotoParentFold';
  static const String gotoPreviousFold = 'editor.gotoPreviousFold';
  static const String hideCodeActionWidget = 'hideCodeActionWidget';
  static const String hideDropWidget = 'editor.hideDropWidget';
  static const String hidePasteWidget = 'editor.hidePasteWidget';
  static const String hideSuggestWidget = 'hideSuggestWidget';
  static const String historyShowNext = 'history.showNext';
  static const String historyShowPrevious = 'history.showPrevious';
  static const String insertBestCompletion = 'insertBestCompletion';
  static const String insertNextSuggestion = 'insertNextSuggestion';
  static const String insertPrevSuggestion = 'insertPrevSuggestion';
  static const String internalExecuteCodeActionProvider =
      '_executeCodeActionProvider';
  static const String internalExecuteCodeLensProvider =
      '_executeCodeLensProvider';
  static const String internalExecuteColorPresentationProvider =
      '_executeColorPresentationProvider';
  static const String internalExecuteCompletionItemProvider =
      '_executeCompletionItemProvider';
  static const String internalExecuteDocumentColorProvider =
      '_executeDocumentColorProvider';
  static const String internalExecuteDocumentSymbolProvider =
      '_executeDocumentSymbolProvider';
  static const String internalExecuteFoldingRangeProvider =
      '_executeFoldingRangeProvider';
  static const String internalExecuteFormatDocumentProvider =
      '_executeFormatDocumentProvider';
  static const String internalExecuteFormatOnTypeProvider =
      '_executeFormatOnTypeProvider';
  static const String internalExecuteFormatRangeProvider =
      '_executeFormatRangeProvider';
  static const String internalExecuteInlayHintProvider =
      '_executeInlayHintProvider';
  static const String internalExecuteLinkProvider = '_executeLinkProvider';
  static const String internalExecuteSelectionRangeProvider =
      '_executeSelectionRangeProvider';
  static const String internalExecuteSignatureHelpProvider =
      '_executeSignatureHelpProvider';
  static const String internalGenerateContextKeyInfo =
      '_generateContextKeyInfo';
  static const String internalLastCursorMoveToSelect =
      '_lastCursorMoveToSelect';
  static const String internalLineSelect = '_lineSelect';
  static const String internalLineSelectDrag = '_lineSelectDrag';
  static const String internalMoveTo = '_moveTo';
  static const String internalMoveToSelect = '_moveToSelect';
  static const String internalProvideDocumentRangeSemanticTokens =
      '_provideDocumentRangeSemanticTokens';
  static const String internalProvideDocumentRangeSemanticTokensLegend =
      '_provideDocumentRangeSemanticTokensLegend';
  static const String internalProvideDocumentSemanticTokens =
      '_provideDocumentSemanticTokens';
  static const String internalProvideDocumentSemanticTokensLegend =
      '_provideDocumentSemanticTokensLegend';
  static const String internalSetContext = '_setContext';
  static const String internalWordSelect = '_wordSelect';
  static const String internalWordSelectDrag = '_wordSelectDrag';
  static const String jumpToNextSnippetPlaceholder =
      'jumpToNextSnippetPlaceholder';
  static const String jumpToPrevSnippetPlaceholder =
      'jumpToPrevSnippetPlaceholder';
  static const String lastCursorLineSelect = 'lastCursorLineSelect';
  static const String lastCursorLineSelectDrag = 'lastCursorLineSelectDrag';
  static const String lastCursorWordSelect = 'lastCursorWordSelect';
  static const String leaveEditorMessage = 'leaveEditorMessage';
  static const String leaveSnippet = 'leaveSnippet';
  static const String lineBreakInsert = 'lineBreakInsert';
  static const String noop = 'noop';
  static const String openReference = 'openReference';
  static const String openReferenceToSide = 'openReferenceToSide';
  static const String outdent = 'outdent';
  static const String quickInputAccept = 'quickInput.accept';
  static const String redo = 'redo';
  static const String removeManualFoldingRanges =
      'editor.removeManualFoldingRanges';
  static const String removeSecondaryCursors = 'removeSecondaryCursors';
  static const String revealLine = 'revealLine';
  static const String revealReference = 'revealReference';
  static const String scrollEditorBottom = 'scrollEditorBottom';
  static const String scrollEditorTop = 'scrollEditorTop';
  static const String scrollLeft = 'scrollLeft';
  static const String scrollLineDown = 'scrollLineDown';
  static const String scrollLineUp = 'scrollLineUp';
  static const String scrollPageDown = 'scrollPageDown';
  static const String scrollPageUp = 'scrollPageUp';
  static const String scrollRight = 'scrollRight';
  static const String selectFirstSuggestion = 'selectFirstSuggestion';
  static const String selectLastSuggestion = 'selectLastSuggestion';
  static const String selectNextCodeAction = 'selectNextCodeAction';
  static const String selectNextPageSuggestion = 'selectNextPageSuggestion';
  static const String selectNextSuggestion = 'selectNextSuggestion';
  static const String selectPrevCodeAction = 'selectPrevCodeAction';
  static const String selectPrevPageSuggestion = 'selectPrevPageSuggestion';
  static const String selectPrevSuggestion = 'selectPrevSuggestion';
  static const String setSelection = 'setSelection';
  static const String showNextParameterHint = 'showNextParameterHint';
  static const String showPrevParameterHint = 'showPrevParameterHint';
  static const String tab = 'tab';
  static const String toggleExplainMode = 'toggleExplainMode';
  static const String toggleFindCaseSensitive = 'toggleFindCaseSensitive';
  static const String toggleFindInSelection = 'toggleFindInSelection';
  static const String toggleFindRegex = 'toggleFindRegex';
  static const String toggleFindWholeWord = 'toggleFindWholeWord';
  static const String toggleFold = 'editor.toggleFold';
  static const String toggleFoldRecursively = 'editor.toggleFoldRecursively';
  static const String toggleImportFold = 'editor.toggleImportFold';
  static const String togglePeekWidgetFocus = 'togglePeekWidgetFocus';
  static const String togglePreserveCase = 'togglePreserveCase';
  static const String toggleSuggestionDetails = 'toggleSuggestionDetails';
  static const String toggleSuggestionFocus = 'toggleSuggestionFocus';
  static const String undo = 'undo';
  static const String unfold = 'editor.unfold';
  static const String unfoldAll = 'editor.unfoldAll';
  static const String unfoldAllExcept = 'editor.unfoldAllExcept';
  static const String unfoldAllMarkerRegions = 'editor.unfoldAllMarkerRegions';
  static const String unfoldRecursively = 'editor.unfoldRecursively';
  static const String workbenchActionShowHover = 'workbench.action.showHover';

  // Monaco editor.action commands
  static const String accessibilityHelp = 'editor.action.accessibilityHelp';
  static const String accessibleDiffViewerNext =
      'editor.action.accessibleDiffViewer.next';
  static const String accessibleDiffViewerPrev =
      'editor.action.accessibleDiffViewer.prev';
  static const String accessibleView = 'editor.action.accessibleView';
  static const String addCommentLine = 'editor.action.addCommentLine';
  static const String addCursorsToBottom = 'editor.action.addCursorsToBottom';
  static const String addCursorsToTop = 'editor.action.addCursorsToTop';
  static const String addSelectionToNextFindMatch =
      'editor.action.addSelectionToNextFindMatch';
  static const String addSelectionToPreviousFindMatch =
      'editor.action.addSelectionToPreviousFindMatch';
  static const String autoFix = 'editor.action.autoFix';
  static const String blockComment = 'editor.action.blockComment';
  static const String cancelSelectionAnchor =
      'editor.action.cancelSelectionAnchor';
  static const String changeAll = 'editor.action.changeAll';
  static const String changeTabDisplaySize =
      'editor.action.changeTabDisplaySize';
  static const String clipboardCopyAction = 'editor.action.clipboardCopyAction';
  static const String clipboardCopyWithSyntaxHighlightingAction =
      'editor.action.clipboardCopyWithSyntaxHighlightingAction';
  static const String clipboardCutAction = 'editor.action.clipboardCutAction';
  static const String clipboardPasteAction =
      'editor.action.clipboardPasteAction';
  static const String codeAction = 'editor.action.codeAction';
  static const String commentLine = 'editor.action.commentLine';
  static const String copyLinesDownAction = 'editor.action.copyLinesDownAction';
  static const String copyLinesUpAction = 'editor.action.copyLinesUpAction';
  static const String debugEditorGpuRenderer =
      'editor.action.debugEditorGpuRenderer';
  static const String decreaseHoverVerbosityLevel =
      'editor.action.decreaseHoverVerbosityLevel';
  static const String deleteLines = 'editor.action.deleteLines';
  static const String detectIndentation = 'editor.action.detectIndentation';
  static const String diffReviewNext = 'editor.action.diffReview.next';
  static const String diffReviewPrev = 'editor.action.diffReview.prev';
  static const String duplicateSelection = 'editor.action.duplicateSelection';
  static const String findReferences = 'editor.action.findReferences';
  static const String fixAll = 'editor.action.fixAll';
  static const String focusNextCursor = 'editor.action.focusNextCursor';
  static const String focusPreviousCursor = 'editor.action.focusPreviousCursor';
  static const String focusStickyScroll = 'editor.action.focusStickyScroll';
  static const String fontZoomIn = 'editor.action.fontZoomIn';
  static const String fontZoomOut = 'editor.action.fontZoomOut';
  static const String fontZoomReset = 'editor.action.fontZoomReset';
  static const String forceRetokenize = 'editor.action.forceRetokenize';
  static const String format = 'editor.action.format';
  static const String formatDocument = 'editor.action.formatDocument';
  static const String formatSelection = 'editor.action.formatSelection';
  static const String goToBottomHover = 'editor.action.goToBottomHover';
  static const String goToDeclaration = 'editor.action.goToDeclaration';
  static const String goToFocusedStickyScrollLine =
      'editor.action.goToFocusedStickyScrollLine';
  static const String goToImplementation = 'editor.action.goToImplementation';
  static const String goToLocation = 'editor.action.goToLocation';
  static const String goToLocations = 'editor.action.goToLocations';
  static const String goToMatchFindAction = 'editor.action.goToMatchFindAction';
  static const String goToReferences = 'editor.action.goToReferences';
  static const String goToSelectionAnchor = 'editor.action.goToSelectionAnchor';
  static const String goToTopHover = 'editor.action.goToTopHover';
  static const String goToTypeDefinition = 'editor.action.goToTypeDefinition';
  static const String gotoLine = 'editor.action.gotoLine';
  static const String hideColorPicker = 'editor.action.hideColorPicker';
  static const String hideHover = 'editor.action.hideHover';
  static const String inPlaceReplaceDown = 'editor.action.inPlaceReplace.down';
  static const String inPlaceReplaceUp = 'editor.action.inPlaceReplace.up';
  static const String increaseHoverVerbosityLevel =
      'editor.action.increaseHoverVerbosityLevel';
  static const String indentLines = 'editor.action.indentLines';
  static const String indentUsingSpaces = 'editor.action.indentUsingSpaces';
  static const String indentUsingTabs = 'editor.action.indentUsingTabs';
  static const String indentationToSpaces = 'editor.action.indentationToSpaces';
  static const String indentationToTabs = 'editor.action.indentationToTabs';
  static const String inlineSuggestAcceptNextLine =
      'editor.action.inlineSuggest.acceptNextLine';
  static const String inlineSuggestAcceptNextWord =
      'editor.action.inlineSuggest.acceptNextWord';
  static const String inlineSuggestCancelSnooze =
      'editor.action.inlineSuggest.cancelSnooze';
  static const String inlineSuggestCommit =
      'editor.action.inlineSuggest.commit';
  static const String inlineSuggestDevExtractRepro =
      'editor.action.inlineSuggest.dev.extractRepro';
  static const String inlineSuggestHide = 'editor.action.inlineSuggest.hide';
  static const String inlineSuggestJump = 'editor.action.inlineSuggest.jump';
  static const String inlineSuggestShowNext =
      'editor.action.inlineSuggest.showNext';
  static const String inlineSuggestShowPrevious =
      'editor.action.inlineSuggest.showPrevious';
  static const String inlineSuggestSnooze =
      'editor.action.inlineSuggest.snooze';
  static const String inlineSuggestToggleAlwaysShowToolbar =
      'editor.action.inlineSuggest.toggleAlwaysShowToolbar';
  static const String inlineSuggestToggleShowCollapsed =
      'editor.action.inlineSuggest.toggleShowCollapsed';
  static const String inlineSuggestTrigger =
      'editor.action.inlineSuggest.trigger';
  static const String inlineSuggestTriggerInlineEdit =
      'editor.action.inlineSuggest.triggerInlineEdit';
  static const String inlineSuggestTriggerInlineEditExplicit =
      'editor.action.inlineSuggest.triggerInlineEditExplicit';
  static const String insertColorWithStandaloneColorPicker =
      'editor.action.insertColorWithStandaloneColorPicker';
  static const String insertCursorAbove = 'editor.action.insertCursorAbove';
  static const String insertCursorAtEndOfEachLineSelected =
      'editor.action.insertCursorAtEndOfEachLineSelected';
  static const String insertCursorBelow = 'editor.action.insertCursorBelow';
  static const String insertFinalNewLine = 'editor.action.insertFinalNewLine';
  static const String insertLineAfter = 'editor.action.insertLineAfter';
  static const String insertLineBefore = 'editor.action.insertLineBefore';
  static const String inspectTokens = 'editor.action.inspectTokens';
  static const String joinLines = 'editor.action.joinLines';
  static const String jumpToBracket = 'editor.action.jumpToBracket';
  static const String linkedEditing = 'editor.action.linkedEditing';
  static const String markerNext = 'editor.action.marker.next';
  static const String markerNextInFiles = 'editor.action.marker.nextInFiles';
  static const String markerPrev = 'editor.action.marker.prev';
  static const String markerPrevInFiles = 'editor.action.marker.prevInFiles';
  static const String moveCarretLeftAction =
      'editor.action.moveCarretLeftAction';
  static const String moveCarretRightAction =
      'editor.action.moveCarretRightAction';
  static const String moveLinesDownAction = 'editor.action.moveLinesDownAction';
  static const String moveLinesUpAction = 'editor.action.moveLinesUpAction';
  static const String moveSelectionToNextFindMatch =
      'editor.action.moveSelectionToNextFindMatch';
  static const String moveSelectionToPreviousFindMatch =
      'editor.action.moveSelectionToPreviousFindMatch';
  static const String nextMatchFindAction = 'editor.action.nextMatchFindAction';
  static const String nextSelectionMatchFindAction =
      'editor.action.nextSelectionMatchFindAction';
  static const String openDeclarationToTheSide =
      'editor.action.openDeclarationToTheSide';
  static const String openLink = 'editor.action.openLink';
  static const String organizeImports = 'editor.action.organizeImports';
  static const String outdentLines = 'editor.action.outdentLines';
  static const String pageDownHover = 'editor.action.pageDownHover';
  static const String pageUpHover = 'editor.action.pageUpHover';
  static const String pasteAs = 'editor.action.pasteAs';
  static const String pasteAsText = 'editor.action.pasteAsText';
  static const String peekDeclaration = 'editor.action.peekDeclaration';
  static const String peekDefinition = 'editor.action.peekDefinition';
  static const String peekImplementation = 'editor.action.peekImplementation';
  static const String peekLocations = 'editor.action.peekLocations';
  static const String peekTypeDefinition = 'editor.action.peekTypeDefinition';
  static const String previewDeclaration = 'editor.action.previewDeclaration';
  static const String previousMatchFindAction =
      'editor.action.previousMatchFindAction';
  static const String previousSelectionMatchFindAction =
      'editor.action.previousSelectionMatchFindAction';
  static const String quickCommand = 'editor.action.quickCommand';
  static const String quickFix = 'editor.action.quickFix';
  static const String quickOutline = 'editor.action.quickOutline';
  static const String refactor = 'editor.action.refactor';
  static const String referenceSearchTrigger =
      'editor.action.referenceSearch.trigger';
  static const String reindentlines = 'editor.action.reindentlines';
  static const String reindentselectedlines =
      'editor.action.reindentselectedlines';
  static const String removeBrackets = 'editor.action.removeBrackets';
  static const String removeCommentLine = 'editor.action.removeCommentLine';
  static const String removeDuplicateLines =
      'editor.action.removeDuplicateLines';
  static const String rename = 'editor.action.rename';
  static const String replaceAll = 'editor.action.replaceAll';
  static const String replaceOne = 'editor.action.replaceOne';
  static const String resetSuggestSize = 'editor.action.resetSuggestSize';
  static const String revealDeclaration = 'editor.action.revealDeclaration';
  static const String revealDefinition = 'editor.action.revealDefinition';
  static const String revealDefinitionAside =
      'editor.action.revealDefinitionAside';
  static const String reverseLines = 'editor.action.reverseLines';
  static const String scrollDownHover = 'editor.action.scrollDownHover';
  static const String scrollLeftHover = 'editor.action.scrollLeftHover';
  static const String scrollRightHover = 'editor.action.scrollRightHover';
  static const String scrollUpHover = 'editor.action.scrollUpHover';
  static const String selectAll = 'editor.action.selectAll';
  static const String selectAllMatches = 'editor.action.selectAllMatches';
  static const String selectEditor = 'editor.action.selectEditor';
  static const String selectFromAnchorToCursor =
      'editor.action.selectFromAnchorToCursor';
  static const String selectHighlights = 'editor.action.selectHighlights';
  static const String selectNextStickyScrollLine =
      'editor.action.selectNextStickyScrollLine';
  static const String selectPreviousStickyScrollLine =
      'editor.action.selectPreviousStickyScrollLine';
  static const String selectToBracket = 'editor.action.selectToBracket';
  static const String setSelectionAnchor = 'editor.action.setSelectionAnchor';
  static const String showContextMenu = 'editor.action.showContextMenu';
  static const String showDefinitionPreviewHover =
      'editor.action.showDefinitionPreviewHover';
  static const String showHover = 'editor.action.showHover';
  static const String showOrFocusStandaloneColorPicker =
      'editor.action.showOrFocusStandaloneColorPicker';
  static const String showReferences = 'editor.action.showReferences';
  static const String smartSelectExpand = 'editor.action.smartSelect.expand';
  static const String smartSelectGrow = 'editor.action.smartSelect.grow';
  static const String smartSelectShrink = 'editor.action.smartSelect.shrink';
  static const String sortLinesAscending = 'editor.action.sortLinesAscending';
  static const String sortLinesDescending = 'editor.action.sortLinesDescending';
  static const String sourceAction = 'editor.action.sourceAction';
  static const String startFindReplaceAction =
      'editor.action.startFindReplaceAction';
  static const String toggleHighContrast = 'editor.action.toggleHighContrast';
  static const String toggleScreenReaderAccessibilityMode =
      'editor.action.toggleScreenReaderAccessibilityMode';
  static const String toggleStickyScroll = 'editor.action.toggleStickyScroll';
  static const String toggleTabFocusMode = 'editor.action.toggleTabFocusMode';
  static const String toggleWordWrap = 'editor.action.toggleWordWrap';
  static const String transformToCamelcase =
      'editor.action.transformToCamelcase';
  static const String transformToKebabcase =
      'editor.action.transformToKebabcase';
  static const String transformToLowercase =
      'editor.action.transformToLowercase';
  static const String transformToPascalcase =
      'editor.action.transformToPascalcase';
  static const String transformToSnakecase =
      'editor.action.transformToSnakecase';
  static const String transformToTitlecase =
      'editor.action.transformToTitlecase';
  static const String transformToUppercase =
      'editor.action.transformToUppercase';
  static const String transpose = 'editor.action.transpose';
  static const String transposeLetters = 'editor.action.transposeLetters';
  static const String triggerParameterHints =
      'editor.action.triggerParameterHints';
  static const String triggerSuggest = 'editor.action.triggerSuggest';
  static const String trimTrailingWhitespace =
      'editor.action.trimTrailingWhitespace';
  static const String unicodeHighlightDisableHighlightingOfAmbiguousCharacters =
      'editor.action.unicodeHighlight.disableHighlightingOfAmbiguousCharacters';
  static const String unicodeHighlightDisableHighlightingOfInvisibleCharacters =
      'editor.action.unicodeHighlight.disableHighlightingOfInvisibleCharacters';
  static const String
  unicodeHighlightDisableHighlightingOfNonBasicAsciiCharacters =
      'editor.action.unicodeHighlight.disableHighlightingOfNonBasicAsciiCharacters';
  static const String unicodeHighlightShowExcludeOptions =
      'editor.action.unicodeHighlight.showExcludeOptions';
  static const String wordHighlightNext = 'editor.action.wordHighlight.next';
  static const String wordHighlightPrev = 'editor.action.wordHighlight.prev';
  static const String wordHighlightTrigger =
      'editor.action.wordHighlight.trigger';
}
