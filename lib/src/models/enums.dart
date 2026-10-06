import 'package:flutter/widgets.dart';

import 'action.dart';

/// Which navigation paradigm is currently laid out.
enum DockLayoutMode {
  /// Narrower than the breakpoint: bottom tab bar, actions in the app bar.
  compact,

  /// At least the breakpoint wide: side column with action chips and rail.
  wide,
}

/// Which edge the side column sits on in [DockLayoutMode.wide].
/// Resolved against [Directionality]: `end` is the right edge in LTR.
enum DockSide {
  /// Left in left-to-right layouts, right in right-to-left layouts.
  start,

  /// Right in left-to-right layouts, left in right-to-left layouts.
  end,
}

/// Where an [DockAction] is being rendered. Passed to the action builder
/// so one action can look different in each spot.
enum DockActionPlacement {
  /// The back/close slot of the title bar (compact mode).
  barLeading,

  /// The actions area of the title bar.
  barTrailing,

  /// A chip in the side column (wide mode).
  sideColumn,
}
