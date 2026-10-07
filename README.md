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
import 'package:nav_dock/nav_dock.dart';
```

## Setup

```dart
MaterialApp(
  // Above the root Navigator, so root-level modals see the config too.
  builder: (context, child) => DockNavigation(
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

Without go_router: see `example/` (a Navigator per tab, inactive tabs wrapped in `Offstage` + `TickerMode(enabled: false)`).

### Pages

```dart
DockPage(
  title: const Text('Level 2'),
  trailing: [
    DockAction(id: 'share', icon: const Icon(Icons.ios_share), onPressed: share),
    DockAction(id: 'done', label: 'Done', onPressed: done), // stays in bar
  ],
  body: ...,
);
```

The leading action is implied: back for pushed pages, close for `fullscreenDialog`. `DockPage.custom(builder: (context, bar) => ...)` gives you `DockBarData` to build the whole page yourself (slivers, large titles, floating bars).

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
3. the cooldown (default 350 ms) has passed since the last action in this frame.

Tapping back three times pops one page. Configure it with `DockNavigationData(tapGuard: DockTapGuard(cooldown: ..., clock: ...))`; `DockTapGuard.disabled` lets every tap through.

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

Title-bar actions follow the column (`DockBarData.trailingAtStart`).

Without a source, or while it reports nothing, `side` is used.

**Other sources and tests.** `DockWindowEdgesSource` is a small interface (`value` and a `changes` stream), so an app that knows its window geometry another way can implement it. `DockWindowEdgesSource.fixed(DockWindowEdges(left: true, right: false))` pins the edges, for example in tests.

### How pages are tracked

Each `DockPage` registers with the nearest frame (shell or modal). It counts as active while `ModalRoute.isCurrent` and `TickerMode` are true; the most recently activated one owns the column. No router coupling.

## Customizing

Optional. With a plain `DockNavigationData()` you get Material 3 defaults (`DockDefaults`) and your app theme styles them. Override only the builders you want; the rest keep their defaults.

`example/` deliberately uses a fully custom look (`example/lib/style/custom_style.dart`): capsule tab bar, square chips, badges via `DockTab.data`, a highlighted chip via `DockAction.data`, a wrapped default page, its own column layout and chip transition. Drop the `CustomStyle.data(...)` call in `example/lib/main.dart` to see the defaults.

```dart
DockNavigationData(
  layoutPolicy: DockLayoutPolicy.breakpoint(600),
  sideColumnWidth: 76,
  sideItemExtent: 56,              // rail pill + chip width; read it in custom builders
  side: DockSide.end,          // start for left-handed layouts
  tabBarBuilder: (context, tabs) => MyBottomBar(...),
  railBuilder: (context, tabs) => MyPillRail(...),
  actionBuilder: (context, action, placement) => ...,   // bar vs column
  pageBuilder: (context, bar, body) => MyScaffold(...), // app bar look
  sideColumnBuilder: (context, actions, rail, hasActions) => ..., // arrangement
  actionTransitionBuilder: (context, animation, child) => ...,
  actionAnimationDuration: const Duration(milliseconds: 250),
  tapGuard: const DockTapGuard(cooldown: Duration(milliseconds: 350)),
);
```

`DockDefaults.*` are plain functions; wrap them instead of rewriting. `DockDefaults.morphingIcon` cross-fades icon changes in your own chips.

`DockScope.modeOf(context)` tells any widget which layout is active.

In a custom `pageBuilder` or `DockPage.custom`, check `bar.trailingAtStart`: when the side column is at the start edge, put the bar's trailing actions at the start too (the default page does this).

## Testing

`package:nav_dock/testing.dart` has what widget tests need, without adding a dependency:

```dart
import 'package:nav_dock/testing.dart';

final edges = FakeWindowEdgesSource();
await tester.pumpWidget(MaterialApp(
  builder: (context, child) => DockTestHarness(
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
* Multi-step modals: wrap the modal's own `Navigator` in `DockModalScope` so all steps share one column. Its first page needs an explicit `leading` (e.g. `DockAction.back(icon: Icon(Icons.close), onPressed: closeFlow)`) because its route can't pop.
* Leading actions need an icon. Trailing ids must be unique per page.
* Android back with nested tab navigators: add `NavigatorPopHandler` (go_router handles this).
* During an interactive iOS swipe-back the column switches when the pop commits, not during the drag.
