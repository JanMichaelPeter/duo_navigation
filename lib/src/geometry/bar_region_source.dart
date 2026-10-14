import 'dart:ui' show Rect;

/// A physical edge of the window.
enum DuoScreenEdge {
  /// The left edge.
  left,

  /// The top edge.
  top,

  /// The right edge.
  right,

  /// The bottom edge.
  bottom,
}

/// Tells where the system lets a bar of a given thickness sit along an edge
/// of the window, clear of the status icons, the rounded corners and the home
/// indicator.
///
/// On devices that show the status icons in a column at the side (iPhone
/// Duo), the safe area gives up that whole column; a bar region on that edge
/// starts below the icons instead. Where the icons sit in a band at the top,
/// a top bar region ends before them. duo_navigation uses it to start the
/// side column's actions below the icons and to place the title bar on the
/// top edge, beside them.
///
/// Set one on `DuoNavigationData.barRegionSource`. The package
/// `duo_navigation_window_placement` provides one backed by the native
/// window_placement plugin (iOS 27.1 and later).
abstract interface class DuoBarRegionSource {
  /// The region for a bar [extent] logical pixels thick along [edge], in
  /// window coordinates, or null where the platform can't tell (then the
  /// safe area is used).
  ///
  /// `DuoNavigation` asks again whenever the window's size or padding
  /// changes (rotation, folding, split screen), so the answer only needs to
  /// be right for the current window.
  Future<Rect?> barRegion(DuoScreenEdge edge, double extent);
}
