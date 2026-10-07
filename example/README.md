# nav_dock example

A three-tab app showing every feature of
[nav_dock](https://pub.dev/packages/nav_dock), with a
fully custom look built from the public builder hooks.

* **Items**: drill-down navigation; the back chip stays put while per-page
  actions animate. The "+" chip is highlighted via its role (`DockActionRole.primary`).
* **Map**: a full-bleed page (`DockPage.custom`) that runs under the tab
  bar and side column.
* **Profile**: a single modal (Edit), a subpage (Settings) and a multi-step
  modal with its own navigator (setup flow).

The custom style lives in `lib/style/custom_style.dart`. It is optional: drop
the `CustomStyle.data(...)` call in `lib/main.dart` to see the Material
defaults.

Rotate the device, use split screen, or resize an iPad window to switch
between the compact and wide layouts.

```sh
flutter run
```
