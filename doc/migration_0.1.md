# Migrating from nav_dock 0.0.1 to 0.1.0

0.1.0 is a redesign. Most apps change their setup, their tab and action declarations, and their custom builders;
pages built with `DockPage` mostly keep working. Work through the sections below in order.

## 1. Setup: builders and the window-edge source

The visuals moved out of `DockNavigationData` into `DockBuilders`, and window-edge detection moved into its own
package.

```dart
// 0.0.1
DockNavigation(
  data: const DockNavigationData(breakpoint: 466),
  child: child!,
)

// 0.1.0
import 'package:nav_dock/material.dart';
import 'package:nav_dock_window_placement/nav_dock_window_placement.dart';

final windowEdges = WindowPlacementEdgesSource(); // create once (app state), dispose with the app

DockNavigation(
  builders: const DockMaterialBuilders(),
  data: DockNavigationData(
    layoutPolicy: const DockLayoutPolicy.breakpoint(466),
    windowEdgesSource: windowEdges,
  ),
  child: child!,
)
```

| 0.0.1 | 0.1.0 |
|---|---|
| `breakpoint: 600` | `layoutPolicy: DockLayoutPolicy.breakpoint(600)`; the breakpoint now applies to the **window** width |
| detection built in; `windowEdges:` / `detectWindowEdges:` | `windowEdgesSource:` with `WindowPlacementEdgesSource()` (`nav_dock_window_placement`), `DockWindowEdgesSource.fixed(...)`, or none (always `side`) |
| `tapCooldown:` | `tapGuard: DockTapGuard(cooldown: ...)`; the cooldown now applies per action |
| `tabBarBuilder:`, `railBuilder:`, `actionBuilder:`, `pageBuilder:`, `sideColumnBuilder:`, `actionTransitionBuilder:` | `DockNavigation(builders: DockBuilders(tabBar:, rail:, action:, page:, sideColumn:, actionTransition:))`, see section 5 |
| `DockDefaults.*` | `DockMaterial.*` in `package:nav_dock/material.dart`; `DockMaterialBuilders()` sets all of them |
| `DockNavigation.of` fell back to defaults | it throws without a `DockNavigation`; use `maybeOf` where none is expected, and `DockTestHarness` in tests |

## 2. Layout: the body is beside the chrome

0.0.1 laid the body out under the tab bar and the column and reported them as extra `MediaQuery.padding`. 0.1.0
lays the body out beside them (`DockBodyMode.inset`).

* `SafeArea` in pages that only kept content clear of the chrome is no longer needed (it does no harm).
* Content that ran under the chrome on purpose (a map, a background) now stops beside it. Use a backdrop
  (`DockShell.backdrop`, `DockPage.backdrop`) for backgrounds and `DockBleed` for components; give tab navigators
  `clipBehavior: Clip.none` so a bleed isn't clipped.
* To keep the 0.0.1 layout, set `bodyMode: DockBodyMode.overlay` on `DockNavigationData`, a `DockShell` or a
  `DockModalScope`.
* On its edge, the column now sits after the system inset (cutout, gesture strip) instead of overlapping it, so it
  is that inset wider in total.
* The frame now handles the software keyboard: the column lifts above it (`DockNavigationData.keyboard`), and in
  inset mode the body ends above it, so a page's `Scaffold` no longer needs to resize for it.

## 3. Tabs

```dart
// 0.0.1
DockTab(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: 'Items', data: 3)

// 0.1.0
DockTab(
  id: 'items',
  icon: DockIcon(Icons.list_alt),
  selectedIcon: DockIcon(Icons.list),
  label: 'Items',
  badge: DockBadge.count(3),
)
```

* `id` is required. Icons are `DockIcon` descriptors (`DockIcon(iconData)`, `.image`, `.widget`).
* `data` is `payload`, typed: `DockTab<MyItem>`. Badges, keys and semantic labels have their own fields.
* Re-taps still reach `onTabSelected` unless you pass `onTabReselected`. `canSelectTab` can veto a switch.
* Your own `Offstage` + `TickerMode` stack can become `DockTabStack(index:, children:)`.

## 4. Pages and actions

```dart
// 0.0.1
DockAction(id: 'share', icon: const Icon(Icons.share), pinToBar: true, data: Highlight.on, onPressed: share)
DockAction.back(icon: const Icon(Icons.close), onPressed: closeFlow)

// 0.1.0
DockAction(id: 'share', icon: const DockIcon(Icons.share), hoist: DockHoist.never, payload: Highlight.on, onPressed: share)
DockAction.close(onPressed: closeFlow)
```

| 0.0.1 | 0.1.0 |
|---|---|
| `icon: Icon(...)` | `icon: DockIcon(...)`; `DockIcon.back` / `DockIcon.close` follow the platform |
| `pinToBar: true` | `hoist: DockHoist.never`; or `DockHoisting.none` for a whole app, shell or page |
| `data:` | `payload:`, typed (`DockAction<MySpec>`), or `role:` for styling (`DockActionRole.primary`, …) |
| leading actions needed an icon | a text-only leading action (`DockAction.back(icon: null, label: 'Cancel')`) stays in the bar in every mode |
| `DockAction.back(icon: Icon(Icons.close))` | `DockAction.close()` (same identity as back, so the two morph) |
| `DockPage.custom(builder: (context, bar) => Scaffold(...))` for own scaffold slots | `DockPageScope(child: Scaffold(appBar: const DockAppBar(), ...))` |
| `bar.trailingAtStart` handled by hand | `DockBarLayout(actionsAtStart: bar.trailingAtStart, ...)` |
| `DockScope.modeOf(context)` | `DockGeometry.of(context).mode` in a frame, `DockNavigation.modeOf(context)` anywhere |
| `DockActionHost`, `DockActionRegistration` for custom pages | `DockPageScope` |

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
DockNavigation(
  builders: const DockMaterialBuilders().merge(DockBuilders(
    tabItem: (context, item) => MyTabItem(tab: item.tab, selected: item.selected, onTap: item.onTap),
    tabBar: (context, data, items) => MyBar(children: items),
    action: (context, action, placement) => MyChip(icon: DockMaterial.icon(action.icon!), ...),
  )),
  child: child!,
)
```

* Tab builders are split: `tabItem` draws one tab, `tabBar` and `rail` arrange the built `items`. The package adds
  each item's semantics and keys; mark custom containers with `DockTabBarSemantics`.
* The package now owns the semantics of tabs and actions, replacing what builders draw. Builders no longer need
  their own `Semantics` for them.
* `DockBuilders` can be set per shell (`DockShell(builders:)`) or subtree (`DockBuildersScope`).
* With typed payloads, give the shell the types: `DockShell<MyTab, MyAction, MyBar>` and
  `DockBuilders<MyTab, MyAction, MyBar>`.

## 6. Tests

Replace `DockNavigation` with `DockTestHarness` in widget tests: it pins the layout mode (no more surprises from the
800×600 test surface), side, window edges and text direction, and its tap guard follows `tester.pump`. Find the
chrome with `DockKeys`:

```dart
DockTestHarness(
  builders: const DockMaterialBuilders(),
  mode: DockLayoutMode.compact,
  child: child!,
)

await tester.tap(find.byKey(DockKeys.action('share')));
```

Fakes of the window_placement platform are no longer needed in nav_dock tests: use `FakeWindowEdgesSource` or
`windowEdges:` on the harness.
