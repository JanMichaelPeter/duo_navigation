# duo_navigation example

A three-tab app that shows every feature of
[duo_navigation](https://pub.dev/packages/duo_navigation), with a fully custom look built
from the public builders.

```sh
flutter run                          # a DuoTabNavigator per tab in a DuoTabStack
flutter run -t lib/main_go_router.dart   # the same app with go_router
```

Rotate the device, use split screen, or resize an iPad window to switch
between the compact and the wide layout. The example switches by window width
(`DuoLayoutPolicy.breakpoint(466)`), so phones in landscape show the column
too; the package's default (`shortestSide(600)`) keeps phones in the bottom-bar
layout.

| Where | Shows |
|---|---|
| **Items** | `DuoPage` with actions: drill down, the back chip stays put while per-page actions animate; the "+" chip is highlighted by its role (`DuoActionRole.primary`); the tab has a badge (`DuoBadge`) |
| **Map** | `DuoPage.custom`: the map runs under the tab bar and the side column (`DuoBleed`), the floating title bar uses `DuoBarLayout` |
| **Profile** | `DuoPageScope` with its own `Scaffold` and `DuoAppBar`, a gradient `backdrop` under the chrome |
| Profile → **Settings** | a plain `Scaffold` page with its own `AppBar`, no page layer; it reads the layout from `geometry.dart` |
| Profile → **Camera** | an immersive page: `DuoPage(visible: false)` hides the navigation; the close button sits at the top right (`leadingAtEnd`) and stays in the bar (`DuoHoisting.none`) |
| Profile → **Edit** | a modal with a text "Cancel" leading action and text fields (the column lifts above the keyboard) |
| Profile → **Setup flow** | a multi-step modal with its own navigator (`DuoModalScope`): the close chip morphs into back |
| `tabs_home.dart` | typed tab payloads (`DuoTab<TabAccent>`) and builders for one shell (`DuoShell(builders: ...)`) |
| `main.dart` | the window-edge source (`duo_navigation_window_placement`) and the app's builders |

The custom look lives in `lib/style/custom_style.dart`. It is optional: use
`builders: const DuoMaterialBuilders()` in `lib/main.dart` to see the Material
defaults.
