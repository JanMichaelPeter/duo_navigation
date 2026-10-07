/// How a frame lays out its body relative to the tab bar and the side column.
enum DockBodyMode {
  /// The body is laid out in the free area beside the column or above the
  /// bar. Below the frame, `MediaQuery.padding` is zero on the edges the
  /// chrome covers, so `SafeArea` and `Scaffold` work unchanged.
  inset,

  /// The body covers the whole frame and the chrome is drawn over it. The
  /// chrome is published as extra `MediaQuery.padding`, so `SafeArea` content
  /// stops beside it and other content runs under it.
  overlay,
}
