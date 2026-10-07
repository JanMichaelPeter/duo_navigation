## 0.1.0

Unreleased. A redesign; see the
[architecture document](https://github.com/JanMichaelPeter/nav_dock/blob/main/doc/design/architecture.md).

* **BREAKING** `DockNavigationData.breakpoint` is replaced by `layoutPolicy`:
  `DockLayoutPolicy.breakpoint(600)` (default, based on the window width) or
  `DockLayoutPolicy.fixed(mode)`.
* **BREAKING** `nav_dock` no longer depends on window_placement and has no
  native code. `windowEdges` and `detectWindowEdges` are replaced by
  `windowEdgesSource`: pass `WindowPlacementEdgesSource()` from the new
  `nav_dock_window_placement` package, `DockWindowEdgesSource.fixed(...)`, or
  your own source. Without a source the preferred `side` is used.
* **BREAKING** `DockNavigation.of` throws a `FlutterError` when there is no
  `DockNavigation` above, instead of silently using defaults. Use
  `DockNavigation.maybeOf` where none is expected.
* **BREAKING** The body is laid out beside the tab bar and side column
  (`DockBodyMode.inset`, the new default) instead of under them. Plain
  `Scaffold` pages no longer need `SafeArea` to stay clear of the chrome.
  `DockBodyMode.overlay` on `DockNavigationData`, `DockShell` or
  `DockModalScope` restores the 0.0.1 layout.
* **BREAKING** On its edge, the side column sits after the system inset
  (cutout, gesture strip) instead of overlapping it.
* New `DockGeometry.of(context)`: the frame's mode, side and chrome per edge,
  with aspects so widgets rebuild only for what they read.
* A debug error reports a tab bar that is shorter than the bottom safe area.
* New `package:nav_dock/geometry.dart`: layout mode, side and window edges
  without the page, action or builder types.
* `DockNavigation.modeOf`, `sideOf`, `sideOnRight` and `windowEdgesOf` work
  without a frame. Window-edge changes rebuild only widgets that read them.
* `DockNavigationData` has value equality, so rebuilding `DockNavigation` with
  equal data no longer rebuilds every dependent.
* `DockNavigationData.copyWith` and `DockAction.copyWith` can reset nullable
  fields to null.

## 0.0.1

Initial release.

* `DockShell` and `DockPage`: bottom tab bar and app bar on compact
  screens; a thumb-reachable side column (action chips above a pill rail) on
  wide screens. Modals get the column without the rail (`DockModalScope`).
* Side column and tab bar are reported as extra safe-area padding, so
  `SafeArea` content stops beside them and full-bleed content runs under them.
* Action identity and animation: back/close is shared across pages and morphs;
  other actions animate out and in per page. Tap guard against double taps and
  taps during route transitions.
* Side column follows the window to the screen edge in split screen and
  windowing (via `window_placement`); title-bar actions follow the column.
* Every visual is a builder in `DockNavigationData`, with Material 3
  defaults in `DockDefaults`.
* iOS, iPadOS and Android.
