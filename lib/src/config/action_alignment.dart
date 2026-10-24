/// Where the side column's action stack is anchored.
enum DuoActionAlignment {
  /// The actions start at the top of the column, below the safe area (or
  /// below the status icons, with a `DuoNavigationData.barRegionSource`).
  /// The back button comes first, at the top, and new actions appear below
  /// it. The default.
  top,

  /// The actions sit at the bottom of their space, right above the rail,
  /// within thumb reach. The back button comes last, right above the rail,
  /// and new actions appear above it.
  bottom,
}
