import 'package:flutter/foundation.dart';

/// Which physical display edges (left / right of the screen, not the window)
/// the app window touches.
///
/// Used for split screen and windowing: if the app is the left half of the
/// display, only [left] is true, and the side column should sit on the left
/// rather than in the middle of the display next to the other app.
///
/// [DockNavigation] detects this itself on iOS and Android (via the
/// window_placement plugin); construct one only to override detection.
/// Fullscreen = both true; a floating window touching nothing = both false.
@immutable
class DockWindowEdges {
  /// Whether the window touches the display's [left] and [right] edges.
  const DockWindowEdges({required this.left, required this.right});

  /// The window reaches the left edge of the display.
  final bool left;

  /// The window reaches the right edge of the display.
  final bool right;

  /// Whether the column goes on the right, given the preferred edge: the
  /// preferred edge if the window touches it, else the other edge if that
  /// one touches, else (both or neither) the preferred edge.
  bool resolveRight({required bool preferRight}) {
    final touchesPreferred = preferRight ? right : left;
    final touchesOther = preferRight ? left : right;
    return touchesPreferred || !touchesOther ? preferRight : !preferRight;
  }

  @override
  bool operator ==(Object other) =>
      other is DockWindowEdges && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(left, right);
}
