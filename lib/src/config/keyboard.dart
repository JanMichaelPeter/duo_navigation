import 'package:flutter/foundation.dart';

/// What the bar or the column does while the software keyboard is open.
enum DockKeyboardBehavior {
  /// Moves above the keyboard: the column is laid out in the height above it,
  /// the bar sits on top of it.
  lift,

  /// Hides (with the visibility animation) while the keyboard is open.
  hide,

  /// Stays where it is and is covered, like `Scaffold.bottomNavigationBar`.
  ignore,
}

/// How the bar and the column handle the software keyboard.
///
/// The frame reads the keyboard from `MediaQuery.viewInsets` above it. If an
/// ancestor already made room (a `Scaffold` with `resizeToAvoidBottomInset`),
/// it sees no keyboard, so nothing moves twice. In `DockBodyMode.inset` the
/// frame also lays the body out above the keyboard and reports no keyboard
/// below it, so a page's own `Scaffold` does not shrink a second time.
@immutable
class DockKeyboard {
  /// The default: the column lifts, the bar is covered.
  const DockKeyboard({
    this.column = DockKeyboardBehavior.lift,
    this.bar = DockKeyboardBehavior.ignore,
  });

  /// The side column in wide mode. Default: [DockKeyboardBehavior.lift], so the
  /// page's actions stay reachable while typing.
  final DockKeyboardBehavior column;

  /// The tab bar in compact mode. Default: [DockKeyboardBehavior.ignore].
  final DockKeyboardBehavior bar;

  @override
  bool operator ==(Object other) =>
      other is DockKeyboard && other.column == column && other.bar == bar;

  @override
  int get hashCode => Object.hash(column, bar);
}
