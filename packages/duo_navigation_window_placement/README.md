# duo_navigation_window_placement

Window-edge source for [duo_navigation](https://pub.dev/packages/duo_navigation), backed by
the [window_placement](https://pub.dev/packages/window_placement) plugin. It
tells duo_navigation which display edges the app window touches, so the side column
follows the window to the screen edge in split screen and windowing.

```dart
final windowEdges = WindowPlacementEdgesSource(); // create once, dispose with the app

DuoNavigation(
  data: DuoNavigationData(windowEdgesSource: windowEdges),
  child: ...,
)
```

Detection runs on iOS, iPadOS and Android. On other platforms, and in widget
tests without a fake plugin, the source reports nothing and duo_navigation uses its
preferred side.
