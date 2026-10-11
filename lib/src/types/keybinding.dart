// MonacoKey is a catalog enum: one self-describing entry per Monaco KeyCode
// member; per-entry docs would only restate the names.
// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter_monaco/src/options/action.dart';

/// Keys usable in a [MonacoKeybinding].
///
/// Each entry maps to a `monaco.KeyCode` member via [jsName]
/// (e.g. `MonacoKey.keyS.jsName == 'KeyS'`).
enum MonacoKey {
  keyA('KeyA'),
  keyB('KeyB'),
  keyC('KeyC'),
  keyD('KeyD'),
  keyE('KeyE'),
  keyF('KeyF'),
  keyG('KeyG'),
  keyH('KeyH'),
  keyI('KeyI'),
  keyJ('KeyJ'),
  keyK('KeyK'),
  keyL('KeyL'),
  keyM('KeyM'),
  keyN('KeyN'),
  keyO('KeyO'),
  keyP('KeyP'),
  keyQ('KeyQ'),
  keyR('KeyR'),
  keyS('KeyS'),
  keyT('KeyT'),
  keyU('KeyU'),
  keyV('KeyV'),
  keyW('KeyW'),
  keyX('KeyX'),
  keyY('KeyY'),
  keyZ('KeyZ'),
  digit0('Digit0'),
  digit1('Digit1'),
  digit2('Digit2'),
  digit3('Digit3'),
  digit4('Digit4'),
  digit5('Digit5'),
  digit6('Digit6'),
  digit7('Digit7'),
  digit8('Digit8'),
  digit9('Digit9'),
  f1('F1'),
  f2('F2'),
  f3('F3'),
  f4('F4'),
  f5('F5'),
  f6('F6'),
  f7('F7'),
  f8('F8'),
  f9('F9'),
  f10('F10'),
  f11('F11'),
  f12('F12'),
  enter('Enter'),
  escape('Escape'),
  tab('Tab'),
  space('Space'),
  backspace('Backspace'),
  delete('Delete'),
  insert('Insert'),
  home('Home'),
  end('End'),
  pageUp('PageUp'),
  pageDown('PageDown'),
  arrowUp('UpArrow'),
  arrowDown('DownArrow'),
  arrowLeft('LeftArrow'),
  arrowRight('RightArrow'),
  semicolon('Semicolon'),
  equal('Equal'),
  comma('Comma'),
  minus('Minus'),
  period('Period'),
  slash('Slash'),
  backquote('Backquote'),
  bracketLeft('BracketLeft'),
  backslash('Backslash'),
  bracketRight('BracketRight'),
  quote('Quote');

  const MonacoKey(this.jsName);

  /// The matching `monaco.KeyCode` member name.
  final String jsName;
}

/// A key chord for a custom editor action.
///
/// [ctrlCmd] maps to `monaco.KeyMod.CtrlCmd` (Cmd on macOS, Ctrl
/// elsewhere); [winCtrl] maps to `monaco.KeyMod.WinCtrl` (Ctrl on macOS,
/// Windows key on Windows).
@immutable
final class MonacoKeybinding {
  /// Creates a key chord.
  const MonacoKeybinding({
    required this.key,
    this.ctrlCmd = false,
    this.shift = false,
    this.alt = false,
    this.winCtrl = false,
  });

  /// The main key of the chord.
  final MonacoKey key;

  /// Whether the platform primary modifier (Cmd/Ctrl) is part of the chord.
  final bool ctrlCmd;

  /// Whether Shift is part of the chord.
  final bool shift;

  /// Whether Alt/Option is part of the chord.
  final bool alt;

  /// Whether the secondary modifier (Ctrl on macOS) is part of the chord.
  final bool winCtrl;

  /// Wire payload consumed by the bridge's keybinding encoder.
  Map<String, Object?> toJson() {
    return {
      'key': key.jsName,
      'ctrlCmd': ctrlCmd,
      'shift': shift,
      'alt': alt,
      'winCtrl': winCtrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is MonacoKeybinding &&
      other.key == key &&
      other.ctrlCmd == ctrlCmd &&
      other.shift == shift &&
      other.alt == alt &&
      other.winCtrl == winCtrl;

  @override
  int get hashCode => Object.hash(key, ctrlCmd, shift, alt, winCtrl);

  @override
  String toString() =>
      'MonacoKeybinding(${[if (ctrlCmd) 'CtrlCmd', if (shift) 'Shift', if (alt) 'Alt', if (winCtrl) 'WinCtrl', key.jsName].join('+')})';
}

/// Describes a custom editor action for `MonacoController.addAction`.
@immutable
final class MonacoActionDescriptor {
  /// Creates an action descriptor.
  const MonacoActionDescriptor({
    required this.id,
    required this.label,
    this.keybindings = const [],
    this.contextMenuGroupId,
    this.contextMenuOrder,
    this.precondition,
  });

  /// Unique action id (also usable with `executeAction`).
  final MonacoAction id;

  /// Human-readable label shown in the command palette and context menu.
  final String label;

  /// Key chords that trigger the action.
  final List<MonacoKeybinding> keybindings;

  /// Context menu group (e.g. `'navigation'`, `'9_cutcopypaste'`); the
  /// action appears in the context menu only when this is set.
  final String? contextMenuGroupId;

  /// Sort order within the context menu group.
  final double? contextMenuOrder;

  /// Monaco context-key expression gating the action (e.g.
  /// `'editorTextFocus'`).
  final String? precondition;

  /// Wire form for the `actions.register` bridge command.
  Map<String, Object?> toJson() => {
    'id': id.id,
    'label': label,
    'keybindings': [for (final kb in keybindings) kb.toJson()],
    if (contextMenuGroupId != null) 'contextMenuGroupId': contextMenuGroupId,
    if (contextMenuOrder != null) 'contextMenuOrder': contextMenuOrder,
    if (precondition != null) 'precondition': precondition,
  };
}
