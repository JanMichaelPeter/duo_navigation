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

/// What the body does while the software keyboard is open, in
/// `DockBodyMode.inset`.
enum DockBodyKeyboardBehavior {
  /// The body keeps its height and the page decides, as without nav_dock:
  /// `MediaQuery.viewInsets.bottom` below the frame is the part of the
  /// keyboard that the bar doesn't already cover, so a `Scaffold` resizes for
  /// it (or not, with `resizeToAvoidBottomInset: false`). The default.
  passThrough,

  /// The frame lays the body out above the keyboard and reports no keyboard
  /// below it, also to a page that opted out of resizing. For bodies that
  /// don't handle the keyboard themselves.
  lift,
}

/// How the bar, the column and the body handle the software keyboard.
///
/// The frame reads the keyboard from `MediaQuery.viewInsets` above it. If an
/// ancestor already made room (a `Scaffold` with `resizeToAvoidBottomInset`),
/// it sees no keyboard, so nothing moves twice. The body follows [body].
@immutable
class DockKeyboard {
  /// The default: the column lifts, the bar is covered, the page decides
  /// about its body.
  const DockKeyboard({
    this.column = DockKeyboardBehavior.lift,
    this.bar = DockKeyboardBehavior.ignore,
    this.body = DockBodyKeyboardBehavior.passThrough,
  });

  /// The side column in wide mode. Default: [DockKeyboardBehavior.lift], so the
  /// page's actions stay reachable while typing.
  final DockKeyboardBehavior column;

  /// The tab bar in compact mode. Default: [DockKeyboardBehavior.ignore].
  final DockKeyboardBehavior bar;

  /// The body, in `DockBodyMode.inset`. Default:
  /// [DockBodyKeyboardBehavior.passThrough], so a page's `Scaffold` and its
  /// `resizeToAvoidBottomInset` decide. In `DockBodyMode.overlay` the page
  /// always handles the keyboard itself.
  final DockBodyKeyboardBehavior body;

  @override
  bool operator ==(Object other) =>
      other is DockKeyboard &&
      other.column == column &&
      other.bar == bar &&
      other.body == body;

  @override
  int get hashCode => Object.hash(column, bar, body);
}
