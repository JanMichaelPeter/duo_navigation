## 0.2.0

* `WindowPlacementEdgesSource` is also a `DuoBarRegionSource`: pass it as
  `barRegionSource` too, so the side column and the title bar keep clear of
  the status icons on the iPhone Duo (iOS 27.1+). Requires duo_navigation
  0.2.0 and window_placement 0.0.3.

## 0.1.0

First release.

* `WindowPlacementEdgesSource`: the window-edge source for duo_navigation 0.1.0,
  backed by the window_placement plugin. In nav_dock 0.0.1, the predecessor of
  duo_navigation, this detection was built in.
