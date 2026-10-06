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
