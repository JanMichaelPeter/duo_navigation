import 'action.dart';

/// Where an [DuoAction] is being rendered. Passed to the action builder
/// so one action can look different in each spot.
enum DuoActionPlacement {
  /// The back/close slot of the title bar (compact mode).
  barLeading,

  /// The actions area of the title bar.
  barTrailing,

  /// A chip in the side column (wide mode).
  sideColumn,
}
