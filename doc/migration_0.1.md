# Migrating from nav_dock 0.0.1 to duo_navigation 0.1.0

(Adding duo_navigation to an app that didn't use it? See [adopting duo_navigation in an existing app](adopting.md).)

0.1.0 is a redesign, published under a new name: nav_dock is now duo_navigation. Most apps change their setup, their
tab and action declarations, and their custom builders; pages built with `DuoPage` mostly keep working. Work through
the sections below in order.

## 0. The new name

Replace the dependency and the imports, and rename the types: every `Dock` prefix is now `Duo` (`DockNavigation` →
`DuoNavigation`, `DockShell` → `DuoShell`, `DockPage` → `DuoPage`, `DockAction` → `DuoAction`, ...; `FakeDockClock` →
`FakeDuoClock`). A find-and-replace of the regular expression `\bDock([A-Z])` with `Duo$1` does it. The rest of this
guide shows 0.0.1 code with its old names.

```yaml
# pubspec.yaml
dependencies:
  duo_navigation: ^0.1.0 # was nav_dock: ^0.0.1
```

```dart
import 'package:duo_navigation/duo_navigation.dart'; // was package:nav_dock/nav_dock.dart
```

## 1. Setup: builders and the window-edge source

The visuals moved out of `DuoNavigationData` into `DuoBuilders`, and window-edge detection moved into its own
package.

```dart
// 0.0.1
DockNavigation(
  data: const DockNavigationData(breakpoint: 466),
  child: child!,
)

// 0.1.0
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation_window_placement/duo_navigation_window_placement.dart';

final windowEdges = WindowPlacementEdgesSource(); // create once (app state), dispose with the app

DuoNavigation(
  builders: const DuoMaterialBuilders(),
  data: DuoNavigationData(
    layoutPolicy: const DuoLayoutPolicy.breakpoint(466),
    windowEdgesSource: windowEdges,
  ),
  child: child!,
)
```

| 0.0.1 | 0.1.0 |
|---|---|
| `breakpoint: 600` | `layoutPolicy: DuoLayoutPolicy.breakpoint(600)`; the breakpoint now applies to the **window** width. The new default, `DuoLayoutPolicy.shortestSide(600)`, looks at the window's shorter side instead, so phones keep the bottom bar in landscape |
| detection built in; `windowEdges:` / `detectWindowEdges:` | `windowEdgesSource:` with `WindowPlacementEdgesSource()` (`duo_navigation_window_placement`), `DuoWindowEdgesSource.fixed(...)`, or none (always `side`) |
| `tapCooldown:` | `tapGuard: DuoTapGuard(cooldown: ...)`; the cooldown now applies per action |
| `tabBarBuilder:`, `railBuilder:`, `actionBuilder:`, `pageBuilder:`, `sideColumnBuilder:`, `actionTransitionBuilder:` | `DuoNavigation(builders: DuoBuilders(tabBar:, rail:, action:, page:, sideColumn:, actionTransition:, backdrop:))`, see section 5 |
| `DockDefaults.*` | `DuoMaterial.*` in `package:duo_navigation/material.dart`; `DuoMaterialBuilders()` sets all of them |
| `DockNavigation.of` fell back to defaults | it throws without a `DuoNavigation`; use `maybeOf` where none is expected, `DuoStandalone` around pages that may have none, and `DuoTestHarness` in tests |

## 2. Layout: the body is beside the chrome

0.0.1 laid the body out under the tab bar and the column and reported them as extra `MediaQuery.padding`. 0.1.0
lays the body out beside them (`DuoBodyMode.inset`).

* `SafeArea` in pages that only kept content clear of the chrome is no longer needed (it does no harm).
* Content that ran under the chrome on purpose (a map, a background) now stops beside it. Use a backdrop
  (`DuoShell.backdrop`, `DuoPage.backdrop`) for backgrounds and `DuoBleed` for components; give tab navigators
  `clipBehavior: Clip.none` so a bleed isn't clipped.
* The strip beside the chrome now shows the frame's backdrop instead of your page. `DuoMaterialBuilders` paints the
  theme's scaffold background there. With fully custom builders, set `DuoBuilders.backdrop`, or a bar or column that
  doesn't fill its strip edge to edge (a floating capsule, round chips) sits on the bare, often black, window.
* To keep the 0.0.1 layout, set `bodyMode: DuoBodyMode.overlay` on `DuoNavigationData`, a `DuoShell` or a
  `DuoModalScope`.
* On its edge, the column still sits at the window edge, over the system inset. To keep it clear of a cutout or
  Android's button bar in landscape, set `columnInset: DuoColumnInset.safeArea` on `DuoNavigationData`.
* The frame now handles the software keyboard for the chrome: the column lifts above it
  (`DuoNavigationData.keyboard`). The body stays the page's business, so a page's `Scaffold` resizes for the keyboard
  (or doesn't, with `resizeToAvoidBottomInset: false`) as before; `DuoKeyboard(body: DuoBodyKeyboardBehavior.lift)`
  makes the frame lift every body instead.

## 3. Tabs

```dart
// 0.0.1
DockTab(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: 'Items', data: 3)

// 0.1.0
DuoTab(
  id: 'items',
  icon: DuoIcon(Icons.list_alt),
  selectedIcon: DuoIcon(Icons.list),
  label: 'Items',
  badge: DuoBadge.count(3),
)
```

* `id` is required. Icons are `DuoIcon` descriptors (`DuoIcon(iconData)`, `.image`, `.widget`).
* `data` is `payload`, typed: `DuoTab<MyItem>`. Badges, keys and semantic labels have their own fields.
* Re-taps still reach `onTabSelected` unless you pass `onTabReselected`. `canSelectTab` can veto a switch.
* Your own `Offstage` + `TickerMode` stack can become `DuoTabStack(index:, children:)`, and each tab's `Navigator` a
  `DuoTabNavigator`, which handles Android's system back and doesn't clip.

## 4. Pages and actions

```dart
// 0.0.1
DockAction(id: 'share', icon: const Icon(Icons.share), pinToBar: true, data: Highlight.on, onPressed: share)
DockAction.back(icon: const Icon(Icons.close), onPressed: closeFlow)

// 0.1.0
DuoAction(id: 'share', icon: const DuoIcon(Icons.share), hoist: DuoHoist.never, payload: Highlight.on, onPressed: share)
DuoAction.close(onPressed: closeFlow)
```

| 0.0.1 | 0.1.0 |
|---|---|
| `icon: Icon(...)` | `icon: DuoIcon(...)`; `DuoIcon.back` / `DuoIcon.close` follow the platform |
| `pinToBar: true` | `hoist: DuoHoist.never`; or `DuoHoisting.none` for a whole app, shell or page |
| `data:` | `payload:`, typed (`DuoAction<MySpec>`), or `role:` for styling (`DuoActionRole.primary`, …) |
| leading actions needed an icon | a text-only leading action (`DuoAction.back(icon: null, label: 'Cancel')`) stays in the bar in every mode |
| `DockAction.back(icon: Icon(Icons.close))` | `DuoAction.close()` (same identity as back, so the two morph) |
| `DockPage.custom(builder: (context, bar) => Scaffold(...))` for own scaffold slots | `DuoPageScope(child: Scaffold(appBar: const DuoAppBar(), ...))` |
| `bar.trailingAtStart` handled by hand | `DuoBarLayout(actionsAtStart: bar.trailingAtStart, ...)` |
| `DockScope.modeOf(context)` | `DuoGeometry.of(context).mode` in a frame, `DuoNavigation.modeOf(context)` anywhere |
| `DockActionHost`, `DockActionRegistration` for custom pages | `DuoPageScope` |

* A page now keeps its column chips while a dialog or sheet is open above it.
* The tap guard's cooldown applies per action, so two different actions in quick succession both fire.

## 5. Custom builders

```dart
// 0.0.1
DockNavigationData(
  tabBarBuilder: (context, data) => MyBar(tabs: data.tabs, ...),
  actionBuilder: (context, action, placement) => MyChip(icon: action.icon!, ...),
)

// 0.1.0
DuoNavigation(
  builders: const DuoMaterialBuilders().merge(DuoBuilders(
    tabItem: (context, item) => MyTabItem(tab: item.tab, selected: item.selected, onTap: item.onTap),
    tabBar: (context, data, items) => MyBar(children: items),
    action: (context, action, placement) => MyChip(icon: DuoMaterial.icon(action.icon!), ...),
  )),
  child: child!,
)
```

* Tab builders are split: `tabItem` draws one tab, `tabBar` and `rail` arrange the built `items`. The package adds
  each item's semantics and keys; mark custom containers with `DuoTabBarSemantics`.
* The package now owns the semantics of tabs and actions, replacing what builders draw. Builders no longer need
  their own `Semantics` for them.
* `DuoBuilders` can be set per shell (`DuoShell(builders:)`) or subtree (`DuoBuildersScope`).
* With typed payloads, give the shell the types: `DuoShell<MyTab, MyAction, MyBar>` and
  `DuoBuilders<MyTab, MyAction, MyBar>`.

## 6. Tests

Replace `DockNavigation` with `DuoTestHarness` in widget tests: it pins the layout mode (no more surprises from the
800×600 test surface), side, window edges and text direction, and its tap guard follows `tester.pump`. Find the
chrome with `DuoKeys`:

```dart
DuoTestHarness(
  builders: const DuoMaterialBuilders(),
  mode: DuoLayoutMode.compact,
  child: child!,
)

await tester.tap(find.byKey(DuoKeys.action('share')));
```

Fakes of the window_placement platform are no longer needed in duo_navigation tests: use `FakeWindowEdgesSource` or
`windowEdges:` on the harness.
