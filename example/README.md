# duo_navigation example

A three-tab app that shows every feature of
[duo_navigation](https://pub.dev/packages/duo_navigation), with a fully custom look built
from the public builders.

```sh
flutter run                          # a DockTabNavigator per tab in a DockTabStack
flutter run -t lib/main_go_router.dart   # the same app with go_router
```

Rotate the device, use split screen, or resize an iPad window to switch
between the compact and the wide layout. The example switches by window width
(`DockLayoutPolicy.breakpoint(466)`), so phones in landscape show the column
too; the package's default (`shortestSide(600)`) keeps phones in the bottom-bar
layout.

| Where | Shows |
|---|---|
| **Items** | `DockPage` with actions: drill down, the back chip stays put while per-page actions animate; the "+" chip is highlighted by its role (`DockActionRole.primary`); the tab has a badge (`DockBadge`) |
| **Map** | `DockPage.custom`: the map runs under the tab bar and the side column (`DockBleed`), the floating title bar uses `DockBarLayout` |
| **Profile** | `DockPageScope` with its own `Scaffold` and `DockAppBar`, a gradient `backdrop` under the chrome |
| Profile → **Settings** | a plain `Scaffold` page with its own `AppBar`, no page layer; it reads the layout from `geometry.dart` |
| Profile → **Camera** | an immersive page: `DockPage(visible: false)` hides the navigation; the close button sits at the top right (`leadingAtEnd`) and stays in the bar (`DockHoisting.none`) |
| Profile → **Edit** | a modal with a text "Cancel" leading action and text fields (the column lifts above the keyboard) |
| Profile → **Setup flow** | a multi-step modal with its own navigator (`DockModalScope`): the close chip morphs into back |
| `tabs_home.dart` | typed tab payloads (`DockTab<TabAccent>`) and builders for one shell (`DockShell(builders: ...)`) |
| `main.dart` | the window-edge source (`duo_navigation_window_placement`) and the app's builders |

The custom look lives in `lib/style/custom_style.dart`. It is optional: use
`builders: const DockMaterialBuilders()` in `lib/main.dart` to see the Material
defaults.
