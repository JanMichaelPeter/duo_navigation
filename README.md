# nav_dock

**Thumb-friendly navigation for apps that run on phones, foldables and tablets, often in one session.**

![One app in one session: bottom tab bar on a phone, a side column at the screen edge on an unfolded foldable, a modal flow, and split screen with the column following the window to the screen edge.](screenshots/nav_dock_demo.gif)

On a phone, navigation sits at the bottom, right under your thumb. Unfold the device, rotate it, or open the app in split screen, and most layouts push back buttons and actions to the top corners, out of reach while you hold a foldable or tablet in both hands.

nav_dock keeps everything reachable. On wide screens tabs, back and page actions dock into one column along the screen edge your hand is already on, and in split screen that column follows your window to the physical screen edge. SwiftUI does this automatically on the iPhone Duo; nav_dock brings the same behavior to Flutter on iOS, iPadOS and Android. The switch happens live whenever the window changes size, without losing navigation or page state.

## What goes where

One navigation code path, two layouts:

| | Compact (< breakpoint) | Wide (≥ breakpoint) |
|---|---|---|
| Tabs | bottom tab bar | vertical pill rail, bottom of side column |
| Leading (back/close) | app bar, left | round chip, directly above the rail |
| Trailing icon actions | app bar, right | round chips, stacked above the leading chip |
| Trailing text actions | app bar, right | stay in the title bar, on the column's side |
| Modal pages | no tab bar | side column with actions, no rail |

The package owns **placement, visibility, insets, identity and animation timing**. Every visual (tab bar, rail, chips, app bar, side column arrangement, transitions) is a builder you can replace.

## Platforms

Every Flutter platform (Flutter >= 3.38); `nav_dock` has no native code. Following the window to the screen edge in split screen needs a window-edge source: `nav_dock_window_placement` provides one for iOS, iPadOS and Android.

## Installation

```sh
flutter pub add nav_dock
```

```dart
import 'package:nav_dock/material.dart'; // the Material visuals
import 'package:nav_dock/nav_dock.dart';
```

## Setup

```dart
MaterialApp(
  // Above the root Navigator, so root-level modals see the config too.
  builder: (context, child) => DockNavigation(
    builders: const DockMaterialBuilders(),
    data: const DockNavigationData(
      layoutPolicy: DockLayoutPolicy.breakpoint(466), // default: 600
    ),
    child: child!,
  ),
  home: ...,
);
```

### go_router

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => DockShell(
    tabs: tabs,
    currentIndex: shell.currentIndex,
    onTabSelected: (i) =>
        shell.goBranch(i, initialLocation: i == shell.currentIndex),
    child: shell,
  ),
  branches: [...],
);

// Modal routes: put them on the root navigator.
GoRoute(
  path: 'edit',
  parentNavigatorKey: rootNavigatorKey,
  pageBuilder: (_, __) => const MaterialPage(
      fullscreenDialog: true, child: EditProfilePage()),
);
```

Without go_router, `DockTabStack` keeps one navigator per tab alive and the inactive ones inert (offstage, not ticking, out of focus and semantics):

```dart
const tabs = <DockTab<Object?>>[
  DockTab(id: 'items', icon: DockIcon(Icons.list_alt), label: 'Items', badge: DockBadge.count(3)),
  DockTab(id: 'profile', icon: DockIcon(Icons.person), label: 'Profile'),
];

DockShell(
  tabs: tabs,
  currentIndex: index,
  onTabSelected: (i) => setState(() => index = i),
  onTabReselected: (i) => navigatorKeys[i].currentState?.popUntil((r) => r.isFirst),
  canSelectTab: (i) async => !hasUnsavedChanges, // optional veto
  child: DockTabStack(index: index, children: [itemsNavigator, profileNavigator]),
)
```

A tab has an `id` (`find.byKey(DockKeys.tab(id))` finds it), icons as `DockIcon` descriptors, an optional `badge`, `semanticLabel`, `key` and a typed `payload` for custom builders (`DockTab<MyItem>`, read as `data.tab.payload` without a cast). The package gives every tab item its semantics: selected state, label, badge and tap action.

### Pages

```dart
DockPage(
  title: const Text('Level 2'),
  trailing: [
    DockAction(id: 'share', icon: const DockIcon(Icons.ios_share), onPressed: share),
    DockAction(id: 'done', label: 'Done', onPressed: done), // stays in bar
  ],
  body: ...,
);
```

The leading action is implied: back for pushed pages, close for `fullscreenDialog`. A text-only leading action such as `DockAction.back(icon: null, label: 'Cancel')` stays in the bar in every mode. `DockPage.custom(builder: (context, bar) => ...)` gives you `DockBarData` to build the whole page yourself (slivers, large titles, floating bars).

An action has an `id` (`find.byKey(DockKeys.action(id))` finds it), a `role` (`back`, `close`, `primary`, `secondary`, `destructive`, `overflow`) that builders can style, an icon as `DockIcon` (`DockIcon.back` and `DockIcon.close` follow the platform), and optionally `label`, `badge`, `enabled`, `semanticLabel`, `key`, `order` (position in the column), `hoist: DockHoist.never` (stays in the bar), `cooldown`, `guarded` and a typed `payload` (`DockAction<MySpec>`, read in builders without a cast; give the shell the types, `DockShell<MyTab, MySpec, MyBar>`).

**Pages with their own `Scaffold`.** `DockPage` is two pieces: `DockPageScope` (the title, actions and bar payload, registered with the frame) and the `page` builder. Use the scope directly to keep your own `Scaffold`, keys, bottom bar or floating action button, and read the bar with `DockAppBar` (`package:nav_dock/material.dart`) or `DockBarData.of(context)` in your own bar:

```dart
DockPageScope(
  title: const Text('Items'),
  trailing: [DockAction(id: 'add', icon: const DockIcon(Icons.add), onPressed: add)],
  child: Scaffold(
    key: const Key('items'),
    appBar: const DockAppBar(),
    bottomNavigationBar: const ItemsToolbar(),
    body: const ItemsList(),
  ),
)
```

`barPayload` passes page data to the bar builder, typed (`DockPageScope<MySpec, MyTitle>(barPayload: MyTitle.large('Inbox'))`, read as `bar.payload`). `DockBarLayout` lays out a custom bar's leading action, title and actions, with start/end mirroring, right-to-left and a centered title.

A page keeps its actions in the column while a dialog or sheet is open above it; their taps are dropped until it closes.

## Adoption levels

Each level works without the ones above it, so an app can adopt nav_dock step by step:

| Level | Use | Works with |
|---|---|---|
| 0 | `DockNavigation.modeOf` / `sideOf`, `DockGeometry` (`package:nav_dock/geometry.dart`) | your own frame and pages |
| 1 | `DockShell` and tabs (`DockTabStack`) | plain `Scaffold` pages with their own `AppBar`; the column holds only the rail |
| 2 | `DockPage` / `DockPageScope` and actions | actions moving into the column, or not (`hoisting: DockHoisting.none`) |
| 3 | custom builders, typed payloads | your design system |

**Keeping actions in the bar.** `DockHoisting.none` (on `DockNavigationData`, `DockShell`, `DockModalScope` or a page) moves nothing into the column: every page keeps all its actions, back included, in its bar, and the bar data is the same in both modes. Per action, `hoist: DockHoist.never` does the same.

## Concepts

### The body sits beside the chrome

By default (`DockBodyMode.inset`) the frame lays the body out in the free area: beside the side column in wide mode, above the tab bar in compact mode. A plain `Scaffold` page works unchanged, and a button at the bottom of a `Column` never ends up under the tab bar.

* Below the frame, `MediaQuery.padding` is zero on the edges the chrome covers and unchanged on the others, so `SafeArea` adds nothing there and still pads the rest.
* On its edge, the column sits inside the safe area: after a cutout or gesture strip, not over it.
* The tab bar builder owns the bottom safe area (home indicator): include `MediaQuery.paddingOf(context).bottom` in the bar's height. A debug error reports a bar that is shorter.
* `MediaQuery.size` stays the window size, as with Flutter's own sub-screens; use `LayoutBuilder` for the available size.

`DockGeometry.of(context)` tells a page the frame's layout: mode, side, how much the chrome covers per edge. Pass an `aspect` to rebuild only when that part changes.

**Content under the chrome.** `DockBodyMode.overlay` (on `DockNavigationData`, `DockShell` or `DockModalScope`) lays the body out under the chrome, as nav_dock 0.0.1 did. The chrome is then published as extra `MediaQuery.padding`, so `SafeArea` content stops beside it and everything else (colors, images, maps) runs underneath.

### Action identity and animation

* `DockAction.back` (and any action with `shared: true`) is matched by `id` across pages. Its widget State survives navigation: no flicker going 4 levels deep and back, and back ↔ close morphs.
* Every other action belongs to its page. On navigation it animates out and the new page's actions animate in, even if both pages use the same id.
* The column is anchored to the bottom and back is always last, so the most-used chip never moves when trailing actions above it change.
* Leaving actions fade out at their old position, with pointers ignored.

### Tap guard

Every action (in the bar and in the column) only fires when:

1. its page is the one currently shown,
2. its route isn't mid-transition or mid-swipe-back, and
3. the same action hasn't fired within its cooldown (default 350 ms). Different actions don't block each other.

Tapping back three times pops one page. Configure it with `DockNavigationData(tapGuard: DockTapGuard(cooldown: ..., clock: ..., onRejected: ...))`: `onRejected` gets every dropped tap and the reason (`notActive`, `transition`, `cooldown`), for example to give feedback. Per action, `cooldown` overrides the guard's and `guarded: false` opts out. `DockTapGuard.disabled` lets every tap through.

### Following the window to the screen edge

Only matters when your app doesn't fill the whole display: iPad Split View / Stage Manager, Android split screen or freeform windows.

**The problem.** If your app is the left half of a split screen and the column sits on the right (`side: end`), it ends up in the middle of the display, right next to the other app. It should sit on the left, where your window meets the physical screen edge.

```
 ┌──────────────── display ────────────────┐
 │┌───── your app ─────┐┌──── other app ───┐│
 ││▐█                  ││                  ││   ▐█ = side column
 ││▐█    content       ││                  ││   moved to the left: only the
 ││▐█                  ││                  ││   window's left edge touches
 │└────────────────────┘└──────────────────┘│   the display
 └──────────────────────────────────────────┘
```

**Setup.** Give `DockNavigation` a window-edge source. `nav_dock_window_placement` asks the [window_placement](https://github.com/JanMichaelPeter/window_placement) plugin which display edges the window touches, and keeps listening:

```dart
final windowEdges = WindowPlacementEdgesSource(); // create once, dispose with the app

DockNavigationData(windowEdgesSource: windowEdges)
```

**What happens.** `side` is a preference; the column only moves to the other edge when the window touches *only* that edge:

| Window touches | Typical case | Column on |
|---|---|---|
| left and right | fullscreen | `side` |
| neither | floating window | `side` |
| only the `side` edge | split screen, that half | `side` |
| only the other edge | split screen, other half | the other edge |
| unknown | not reported yet | `side` |

Title-bar actions follow the column (`DockBarData.trailingAtStart`; `DockAppBar` and `DockBarLayout` handle it).

Without a source, or while it reports nothing, `side` is used.

**Other sources and tests.** `DockWindowEdgesSource` is a small interface (`value` and a `changes` stream), so an app that knows its window geometry another way can implement it. `DockWindowEdgesSource.fixed(DockWindowEdges(left: true, right: false))` pins the edges, for example in tests.

### How pages are tracked

Each `DockPage` registers with the nearest frame (shell or modal). It counts as active while `ModalRoute.isCurrent` and `TickerMode` are true; the most recently activated one owns the column. No router coupling.

## Customizing

The package owns placement, insets, identity and timing; every visual is a builder in `DockBuilders`. `const DockMaterialBuilders()` (`package:nav_dock/material.dart`) sets all of them to Material 3 defaults that your theme styles. Replace single ones with `merge`; the rest keep their defaults:

```dart
DockNavigation(
  builders: const DockMaterialBuilders().merge(DockBuilders(
    tabItem: (context, item) => MyTabItem(...),           // one tab, bar or rail
    tabBar: (context, tabs, items) => MyBottomBar(items), // arranges the items
    rail: (context, tabs, items) => MyPillRail(items),
    action: (context, action, placement) => ...,     // bar vs column
    page: (context, bar, body) => MyScaffold(...),   // app bar look
    sideColumn: (context, actions, rail, hasActions) => ..., // arrangement
    actionTransition: (context, animation, child) => ...,
  )),
  data: const DockNavigationData(
    sideColumnWidth: 76,
    sideItemExtent: 56,          // rail pill + chip width; read it in custom builders
    side: DockSide.end,          // start for left-handed layouts
    actionAnimationDuration: Duration(milliseconds: 250),
  ),
  child: child!,
)
```

**Per shell or subtree.** `DockShell(builders: ...)` and `DockModalScope(builders: ...)` override the app's builders for that frame, field by field; `DockBuildersScope` does the same for any subtree (for example a page builder for one area). Builders run below the shell, so inherited widgets placed around a `DockShell` reach them.

**Tabs.** `tabItem` draws one tab (the package adds its semantics and keys); `tabBar` and `rail` arrange the built items and mark the container with `DockTabBarSemantics` (Material's `NavigationBar` does this itself). When the tabs don't fit the column, the rail scrolls and keeps the selected tab visible; `DockSideColumnLayout` gives the rail its height first in custom `sideColumn` builders. The column grows with the text scale up to `columnTextScaleLimit`.

**Typed tabs.** `DockShell<MyItem>` with `DockBuilders<MyItem>` gives the tab builders `DockTab<MyItem>`. Builders written for `Object?`, such as `DockMaterialBuilders`, work for any payload type; builders for another type fail with an error naming the field.

**Contracts.** Each builder typedef documents what it gets and what it owns: constraints, safe area (the tab bar includes the bottom safe area in its height), keys (the package applies `DockKeys`), semantics and animation. A builder that no scope sets fails with an error naming it.

`DockMaterial.*` are the plain functions behind the defaults; wrap them instead of rewriting. `DockMaterial.morphingIcon` cross-fades icon changes in your own chips.

`example/` uses a fully custom look (`example/lib/style/custom_style.dart`): capsule tab bar, one tab item for bar and rail, square chips, badges via `DockTab.badge`, a highlighted chip via `DockActionRole.primary`, a wrapped default page, its own column layout and chip transition. Use `const DockMaterialBuilders()` in `example/lib/main.dart` to see the defaults.

`DockScope.modeOf(context)` tells any widget which layout is active.

In a custom `page` builder or `DockPage.custom`, lay the bar out with `DockBarLayout(actionsAtStart: bar.trailingAtStart, ...)`: when the side column is at the start edge, the bar's actions belong at the start too.

## Testing

`package:nav_dock/testing.dart` has what widget tests need, without adding a dependency:

```dart
import 'package:nav_dock/testing.dart';

final edges = FakeWindowEdgesSource();
await tester.pumpWidget(MaterialApp(
  builder: (context, child) => DockTestHarness(
    builders: const DockMaterialBuilders(),
    mode: DockLayoutMode.wide,          // whatever the test surface size
    side: DockSide.start,
    textDirection: TextDirection.rtl,
    windowEdgesSource: edges,           // or windowEdges: DockWindowEdges(...)
    child: child!,
  ),
  home: const MyShell(),
));

edges.push(const DockWindowEdges(left: true, right: false)); // split screen
await tester.tap(find.byKey(DockKeys.action('share')));
```

* `DockTestHarness` replaces `DockNavigation` in a test and pins mode, side, window edges and text direction. Its tap guard follows the frames, so `tester.pump(duration)` lets the cooldown pass and tests never wait on real time. `tapGuard: DockTapGuard.disabled` turns it off; `FakeDockClock` controls it directly.
* `DockKeys.bar`, `.column`, `.rail` and `.action(id)` find the chrome, whatever builder draws it.

## Rules and limits

* Modal = pushed on the **root** navigator. A page pushed onto a tab navigator is a subpage and keeps the tab bar.
* Multi-step modals: wrap the modal's own `Navigator` in `DockModalScope` so all steps share one column. Its first page needs an explicit `leading` (e.g. `DockAction.close(onPressed: closeFlow)`) because its route can't pop.
* Trailing ids must be unique per page.
* Android back with nested tab navigators: add `NavigatorPopHandler` (go_router handles this).
* During an interactive iOS swipe-back the column switches when the pop commits, not during the drag.
