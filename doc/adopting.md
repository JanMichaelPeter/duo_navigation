# Adopting nav_dock in an existing app

Most apps don't start from scratch. They have a `Scaffold` with a `NavigationBar` (or their own bar), an `IndexedStack`
of tabs, a `Navigator` per tab, and pages with their own `AppBar`. This guide moves such an app to nav_dock step by
step. Each step ships on its own, and the app keeps working in between. (Coming from nav_dock 0.0.1, see the
[migration guide](migration_0.1.md) instead.)

The order:

1. [`DockNavigation` above the root navigator](#1-docknavigation)
2. [The tab scaffold becomes a `DockShell`](#2-the-tab-scaffold)
3. [Pages, one at a time](#3-pages-one-at-a-time)
4. [Your design system's tab bar and title bar](#4-your-design-system)
5. [Content under the chrome](#5-content-under-the-chrome)
6. [Tests](#6-tests)

## 1. DockNavigation

Put a `DockNavigation` above the root `Navigator`, so pages pushed on it (modals, full-screen flows) see it too. Use
the Material visuals to begin with; your own come in step 4.

```dart
import 'package:nav_dock/material.dart'; // nav_dock and its Material visuals

MaterialApp(
  builder: (context, child) => DockNavigation(
    builders: const DockMaterialBuilders(),
    child: child!,
  ),
  home: const AppShell(),
)
```

Nothing changes on screen yet. For the side column to follow the window to the screen edge in split screen, add
`windowEdgesSource: WindowPlacementEdgesSource()` from `nav_dock_window_placement` to `DockNavigationData`. Create it
once, in app state, and dispose it with the app.

## 2. The tab scaffold

The `Scaffold` that holds the tab bar and the `IndexedStack` becomes a `DockShell`. It draws the bottom bar in compact
mode and the rail in the side column in wide mode.

```dart
// Before
Scaffold(
  body: IndexedStack(index: index, children: navigators),
  bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: select, destinations: ...),
)

// After
DockShell(
  tabs: const [
    DockTab(id: 'home', icon: DockIcon(Icons.home_outlined), selectedIcon: DockIcon(Icons.home), label: 'Home'),
    DockTab(id: 'me', icon: DockIcon(Icons.person_outline), selectedIcon: DockIcon(Icons.person), label: 'Me'),
  ],
  currentIndex: index,
  onTabSelected: select,
  // A tap on the current tab pops it to its root.
  onTabReselected: (i) => navigatorKeys[i].currentState?.popUntil((route) => route.isFirst),
  child: DockTabStack(
    index: index,
    children: [
      for (final (i, root) in roots.indexed)
        DockTabNavigator(
          navigatorKey: navigatorKeys[i],
          onGenerateRoute: (settings) => MaterialPageRoute(settings: settings, builder: (_) => root),
        ),
    ],
  ),
)
```

**`IndexedStack` → `DockTabStack`.** Both keep every tab's state, and neither paints, hit-tests, focuses or exposes
semantics for the hidden tabs. The differences:

| | `IndexedStack` | `DockTabStack` |
|---|---|---|
| Builds tabs | all at once | when first shown (`lazy: false` builds all) |
| Tickers in hidden tabs | keep running | paused (`maintainTickers: true` keeps them running) |
| Heroes in hidden tabs | fly | off |
| Pages in hidden tabs | claim the side column, unless each tab is under `TickerMode(enabled: false)` | don't |

A tab with a long-running animation (a video, a map camera) that relied on `IndexedStack` keeping it running needs
`maintainTickers: true`.

**`Navigator` → `DockTabNavigator`.** It takes the same arguments and adds two things:

* Android's system back pops the shown tab's pages before it leaves the app. A hidden tab's pages don't keep the app
  from closing. With a plain `Navigator` per tab, you had to wire this yourself with `NavigatorPopHandler`.
* It doesn't clip. A plain `Navigator` clips its pages to its bounds, which cuts off content that should run under
  the bar and the column (step 5).

**go_router.** `StatefulShellRoute.indexedStack` already keeps tabs alive and handles system back. Pass its `shell`
as the `DockShell`'s child, as `example/lib/main_go_router.dart` does.

The pages don't change in this step. In inset mode (the default) the body is laid out beside the bar and the column,
so a page's own `Scaffold` and `AppBar` lay out as before. Remove what only kept content clear of the old bar, such as
bottom padding.

## 3. Pages, one at a time

A page with its own `Scaffold` and `AppBar` works in the shell as it is. Migrate it when you want its actions to move
into the side column in wide mode. Wrap it in a `DockPageScope`, and replace `AppBar` with `DockAppBar`:

```dart
// Before
Scaffold(
  appBar: AppBar(
    title: const Text('Items'),
    actions: [IconButton(icon: const Icon(Icons.add), onPressed: add)],
  ),
  body: const ItemsList(),
)

// After
DockPageScope(
  title: const Text('Items'),
  trailing: [DockAction(id: 'add', icon: const DockIcon(Icons.add), tooltip: 'Add', onPressed: add)],
  child: Scaffold(appBar: const DockAppBar(), body: const ItemsList()),
)
```

The `Scaffold` keeps its keys, `bottomNavigationBar`, `floatingActionButton` and everything else. `DockPage` is the same
thing in one widget, for pages that don't need their own `Scaffold`.

* **Back and close are implied.** Back for pushed pages, close for full-screen dialogs.
  `impliedLeading: DockImpliedLeading.close` asks for close on other routes, such as a custom modal route. The first
  page of a `Navigator` inside a `DockModalScope` gets an action that dismisses the whole modal.
* **"Cancel" and a close button at the top right.** `DockAction.back(icon: null, label: 'Cancel')` is a text-only leading
  action that stays in the bar in every mode. `leadingAtEnd: true` puts the leading action at the end of the bar.
* **Actions that should never move** get `hoist: DockHoist.never`. `DockHoisting.none` on `DockNavigationData`, a
  shell or a page keeps all of them in the bar.

**Pages that are also shown outside the shell.** Pages, shells and modal frames need a `DockNavigation` above them and
fail loudly without one. During a migration, some pages can also be reached from places that have none, such as a
route pushed by a plugin or a second `MaterialApp`. Wrap those in a `DockStandalone`:

```dart
DockStandalone(
  builders: const DockMaterialBuilders(),
  child: const ItemDetailsPage(), // uses DockPageScope
)
```

Where there is no `DockNavigation`, it provides a compact one: the page shows its title bar with all its actions.
Below the app's `DockNavigation` it does nothing. Existing tests that pump such a page directly keep working: the tap
guard's default clock follows the test's time (see step 6).

**The keyboard.** Pages keep handling it as before. The body keeps its height, and its `MediaQuery` reports the part of
the keyboard the tab bar doesn't already cover. A `Scaffold` resizes for it, and one with
`resizeToAvoidBottomInset: false` (a form with a sticky action area, a full-height map) doesn't. The frame only moves
its own chrome: the column lifts above the keyboard, and the bar stays covered (`DockNavigationData.keyboard`). For
bodies that don't handle the keyboard themselves, `DockShell(keyboard: DockKeyboard(body: DockBodyKeyboardBehavior.lift))`
lays them out above it instead, for that shell's pages only.

## 4. Your design system

Every visual is a builder in `DockBuilders`. Replace the Material ones one at a time with `merge`:

```dart
DockNavigation(
  builders: const DockMaterialBuilders().merge(myBuilders),
  child: child!,
)
```

Each builder's typedef documents its contract: what it gets, its constraints, what the package owns (keys, semantics)
and what the builder owns (visuals, animation, the bottom safe area of the bar).

**Build `DockBuilders` once.** `DockBuilders` compare their builders by identity. A `DockBuilders(...)` created in
`build()` with closures is new on every build, and rebuilds everything below it. Make it `const`, a top-level or
`static final` value, or keep it in a `State` and create a new one only when its inputs change:

```dart
class _ShellState extends State<Shell> {
  late DockBuilders<Object?, Object?, Object?> _builders = _make(widget.options);

  @override
  void didUpdateWidget(Shell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options != oldWidget.options) _builders = _make(widget.options);
  }

  static DockBuilders<Object?, Object?, Object?> _make(MyBarOptions options) =>
      DockBuilders(tabBar: (context, tabs, items) => MyTabBar(options: options, children: items));

  @override
  Widget build(BuildContext context) => DockShell(builders: _builders, ...);
}
```

### The tab bar

The `tabBar` and `rail` builders get the package's built `items`, one per tab (drawn by `tabItem`), and arrange them.
Mark the widget that holds them with `DockTabBarSemantics`.

**A bar that builds its children from data.** Some design systems' tab bars take a list of item descriptions instead
of widgets. Such a bar can't place `items`. It builds its own children, wraps each with `tabs.wrap(i, child)`, and
reports taps through `tabs.itemData(i).onTap`. `wrap` applies the same keys (`DockKeys.tab(id)`, `DockTab.key`) and
semantics as the package's items. `itemData(i).onTap` applies the shell's selection, re-selection and veto rules:

```dart
tabBar: (context, tabs, items) => DockTabBarSemantics(
  child: MyTabBar(
    children: [
      for (var i = 0; i < tabs.tabs.length; i++)
        tabs.wrap(i, MyTabButton(spec: tabs.tabs[i].payload! as MyTabSpec, onTap: tabs.itemData(i).onTap)),
    ],
  ),
),
```

Such a bar needs no `tabItem` builder (the rail still does, unless it is built the same way). Carry the design
system's item description in `DockTab.payload`, typed with `DockShell<MyTabSpec, ...>` if you like.

**A bar that builds its item widgets itself.** Some bars take only the item descriptions and build every item widget
inside, so nothing can be wrapped around an item. If the item description has a semantics hook, pass it the tab's
semantics as a value, `tabs.itemData(i).semanticsOf(context)`. It carries the tab role, the selected state, the label,
the badge, the position and the tap action:

```dart
tabBar: (context, tabs, items) => DockTabBarSemantics(
  child: MyTabBar(
    items: [
      for (var i = 0; i < tabs.tabs.length; i++)
        MyTabBarItem(
          spec: tabs.tabs[i].payload! as MyTabSpec,
          onTap: tabs.itemData(i).onTap,
          additionalSemantics: tabs.itemData(i).semanticsOf(context),
        ),
    ],
  ),
),
```

`DockTabBarSemantics` requires every semantics node directly below it to be a tab. Flutter reports
"Children of TabBar must have the tab role" when one isn't, for example around a bar whose items carry no tab semantics.
A bar without any per-item hook keeps its own semantics and goes without `DockTabBarSemantics`. Its items then read as
buttons rather than tabs.

**The bottom safe area.** The bar owns it: its height includes `MediaQuery.paddingOf(context).bottom`, and a debug error
reports a bar that is shorter. Its `MediaQuery` has no top padding, so a bar that wraps itself in `SafeArea` grows only
by the bottom inset. To make the tap targets reach the screen edge, put the inset inside each item, under its
`InkWell`, instead of a `SafeArea` around the bar:

```dart
tabItem: (context, item) => InkWell(
  onTap: item.onTap,
  child: Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
    child: MyTabContent(tab: item.tab, selected: item.selected),
  ),
),
```

### The title bar

A design system's title bar reads the page's `DockBarData`. It's written for pages of any payload type, so it reads the
data as `DockBarData.of<Object?, Object?>(context)` and checks its own payload type:

```dart
class MyNavBar extends StatelessWidget implements PreferredSizeWidget {
  const MyNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final bar = DockBarData.of<Object?, Object?>(context);
    final title = bar.payload;
    assert(title == null || title is MyTitleSpec, 'MyNavBar needs a MyTitleSpec as barPayload.');
    final leading = bar.leading;
    // Scaffold gives an app bar its preferred height plus the status bar.
    return SafeArea(
      bottom: false,
      child: DockBarLayout(
        leading: leading == null ? null : bar.buildAction(leading, DockActionPlacement.barLeading),
        title: title is MyTitleSpec ? MyTitle(title) : bar.title,
        trailing: [for (final a in bar.trailing) bar.buildAction(a, DockActionPlacement.barTrailing)],
        actionsAtStart: bar.trailingAtStart,
        leadingAtEnd: bar.leadingAtEnd,
      ),
    );
  }
}
```

`DockBarLayout` mirrors in right-to-left layouts. It also follows the column to the start edge and handles the leading
action at the end. In the `action` builder, `DockIconMorph(icon: action.icon!, builder: ...)` cross-fades back into
close with your own icon rendering.

## 5. Content under the chrome

In inset mode the body stops beside the bar and the column. What used to run under them on purpose (a map, a hero image,
a header background) needs one of these:

* **A backdrop** for the whole window: `DockShell(backdrop: ...)`, or a page's own `backdrop`. No clip can cut it.
* **`DockBleed`** for one component: it widens its child toward the column and the bar, and keeps its own size.

Recipes:

**A bleed in a tab.** A plain `Navigator` clips its pages, so a `DockBleed` in a tab page stops at the body's edge. Use
`DockTabNavigator` (it doesn't clip), or give your navigator `clipBehavior: Clip.none`. Scroll views clip too: wrap the
scroll view in the bleed, not an item in it. In debug mode a bleed that is clipped names the clipping ancestor.

**A header whose background bleeds while its actions don't.** Put the bleed in a `Positioned.fill` behind the header's
content. `bar: false` keeps it out of the bar's strip:

```dart
Stack(
  children: [
    Positioned.fill(child: DockBleed(bar: false, child: HeaderBackground())),
    const HeaderContent(), // actions stay beside the column and can be tapped
  ],
)
```

**A list with a few bleeding rows.** Wrap the list in one `DockBleed`, and the rows in `DockInset.wrapAll`. Rows inside a
`DockBleedItem` bleed, and the others stay beside the chrome:

```dart
DockBleed(
  child: ListView(
    children: DockInset.wrapAll([
      DockBleedItem(child: Image.asset('hero.webp', fit: BoxFit.cover)),
      const Text('Details'),
      const SummaryRow(),
    ]),
  ),
)
```

`wrapAll` recognizes `DockBleedItem` by its type, so it must be the list entry itself. A `DockBleedItem` inside a
`Padding`, or inside your own wrapper widget, is wrapped in a `DockInset` like any other row.

**The available size.** `MediaQuery.sizeOf(context)` stays the window size, as everywhere in Flutter. In wide mode the
body is narrower by the column. Use a `LayoutBuilder` for the size the page has, and `DockGeometry.of(context)` for the
mode and the strip the chrome covers.

## 6. Tests

Widget tests that pump a migrated page need a `DockNavigation`. Use `DockTestHarness` from
`package:nav_dock/testing.dart`. It pins the layout mode, the window edges and the text direction, and its tap guard
follows `tester.pump`:

```dart
await tester.pumpWidget(MaterialApp(
  builder: (context, child) => DockTestHarness(
    builders: const DockMaterialBuilders(), // or your design system's
    mode: DockLayoutMode.compact,
    child: child!,
  ),
  home: const ItemDetailsPage(),
));
await tester.tap(find.byKey(DockKeys.action('add')));
```

A shared test helper that pumps pages can add the harness in one place. Pages wrapped in `DockStandalone` work under
the harness too: there the `DockStandalone` does nothing. Tests that pump a `DockStandalone` page without the harness
also work. The tap guard's default clock (`DockClock.system()`) follows `tester.pump(duration)` and `pumpAndSettle`, so
two taps on one action with `pumpAndSettle` in between both fire. A double tap with only `tester.pump()` in between is
dropped, as on a device. Test both modes by pumping with `mode: DockLayoutMode.wide`.
`DockKeys.bar`, `.column`, `.rail`, `.tab(id)` and `.action(id)` find the chrome, whatever builder draws it.
