/// How the side column treats the system inset on its own edge: a display
/// cutout, Android's button navigation bar in landscape, or the iPhone's
/// landscape safe area.
enum DuoColumnInset {
  /// The column sits at the window edge, over the inset, as wide as
  /// `DuoNavigationData.sideColumnWidth`. Chips can sit under a cutout or
  /// the system buttons on that edge. The body keeps any part of the inset
  /// that is wider than the column.
  overlap,

  /// The column sits after the inset, so nothing of it is under a cutout or
  /// the system buttons; it covers the inset plus
  /// `DuoNavigationData.sideColumnWidth`, and its builder sees the inset in
  /// `MediaQuery.padding` to paint a background under it.
  safeArea,
}
