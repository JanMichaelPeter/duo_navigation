# nav_dock_window_placement

Window-edge source for [nav_dock](https://pub.dev/packages/nav_dock), backed by
the [window_placement](https://pub.dev/packages/window_placement) plugin. It
tells nav_dock which display edges the app window touches, so the side column
follows the window to the screen edge in split screen and windowing.

```dart
final windowEdges = WindowPlacementEdgesSource(); // create once, dispose with the app

DockNavigation(
  data: DockNavigationData(windowEdgesSource: windowEdges),
  child: ...,
)
```

Detection runs on iOS, iPadOS and Android. On other platforms, and in widget
tests without a fake plugin, the source reports nothing and nav_dock uses its
preferred side.
