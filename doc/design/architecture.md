# duo_navigation 0.1.0 architecture

Status: accepted, implemented in 0.1.0 · Tracking: #42 · This document: #4

0.1.0 is a redesign of duo_navigation. This document fixes the model the 0.1.0 issues build on: what the package owns, how
the frame lays out the body and the chrome, how configuration and visuals are provided, and how payloads are typed.
Signatures are sketches. Names may still change in review, but the rules should not.

## 1. Purpose and non-goals

**Purpose.** Keep primary navigation and page actions within reach on phones, foldables and tablets. Compact
layouts get a bottom bar. Wide layouts get one column on the screen edge the hand is already on. The switch is live
and loses no state.

**Non-goals.**

- Not a router. It works with any navigation stack.
- No dependency on a state-management library, a DI container or a design system.
- It does not own the `Scaffold`, the page content or the theme.
- The core ships no visuals. Default visuals are a separate, replaceable entry point.
- Not a general responsive-layout kit.

## 2. Principles

| Principle | Consequence |
|-----------|-------------|
| Layered. Every layer can be adopted alone. | Geometry, frame and shell, page layer and default visuals have their own entry points and tests (section 4). |
| The body is never laid out under the chrome by default. | The frame lays the body out in the free area. Running content under the chrome is opt-in: per frame, per page, per component (sections 6, 12). |
| Nothing is silently global. | Every default that changes layout or behavior can be overridden per shell. A missing precondition fails loudly (section 16). |
| Typed in, typed out. | Builders receive typed, immutable data. Apps pass their own payload types without casts (section 8). |
| Testable by construction. | Time, window edges and layout mode are injectable (section 14). |
| Removal cost follows adoption. | Dropping the package touches only the layers an app adopted. No route or `Scaffold` subclassing is required. |
| No native code in the core. | Window-edge detection is a separate package (section 3). |

## 3. Packages and entry points

The repository is a pub workspace. The repository root is both the workspace root and the `duo_navigation` package:

```
pubspec.yaml                          duo_navigation, and the workspace root
lib/, test/                           duo_navigation
packages/duo_navigation_window_placement/   window-edge source backed by window_placement (native)
example/                              depends on both
```

`.pubignore` keeps `packages/` and `doc/design/` out of the `duo_navigation` archive. Each package is released with its
own tag, `<package>-v<version>` (`tool/release.sh`).

`duo_navigation` has four entry points:

| Entry point | Contents | Imports |
|-------------|----------|---------|
| `package:duo_navigation/geometry.dart` | `DuoGeometry`, `DuoLayoutMode`, `DuoSide`, `DuoBodyMode`, `DuoWindowEdges`, `DuoWindowEdgesSource`, `DuoLayoutPolicy`, `DuoBleed`, `DuoInset` | widgets |
| `package:duo_navigation/duo_navigation.dart` | `geometry.dart` plus configuration, shell, modal scope, tabs, actions, page layer, builders, `DuoKeys`, `DuoSemantics` | widgets |
| `package:duo_navigation/material.dart` | `DuoMaterialBuilders`, `DuoAppBar` and the Material visuals | material |
| `package:duo_navigation/testing.dart` | `DuoTestHarness`, `FakeWindowEdgesSource`, `FakeDuoClock`, `DuoKeys` | widgets |

`testing.dart` does not import `flutter_test`, so the package has no test dependency. Finders use keys:
`find.byKey(DuoKeys.tab('home'))`.

`duo_navigation_window_placement` exports one class, `WindowPlacementEdgesSource`, which implements
`DuoWindowEdgesSource`. An app that never leaves compact mode does not depend on it.

A test in `duo_navigation` fails if a file outside `src/material/` imports `material.dart` or `cupertino.dart`, or if
`geometry.dart` exports a page, action or builder type.

## 4. Layers and modules

```
src/geometry/   modes, sides, window edges and their source, layout policy, DuoGeometry      (layer 0)
src/config/     DuoNavigation and DuoNavigationData (non-visual configuration)            (layer 0)
src/builders/   DuoBuilders and their scope                                                (layer 1)
src/frame/      frame render object, body scope, shell, modal scope, visibility, keyboard  (layer 1)
src/tabs/       DuoTab, tab data, tab item wrapper, DuoTabStack                          (layer 1)
src/actions/    DuoAction, DuoIcon, DuoBadge, host, registration, tap guard, column     (layer 2)
src/page/       DuoPageScope, DuoBarData, DuoBarLayout, DuoPage                        (layer 2)
src/bleed/      DuoBackdrop handling, DuoBleed, DuoInset, scroll helpers                 (layer 1)
src/a11y/       DuoSemantics, traversal order, focus registry
src/material/   default visuals (only material.dart imports this)
src/testing/    harness and fakes (only testing.dart imports this)
```

A module imports only modules of its own layer or below. The adoption levels map onto the layers:

| Level | The app uses | Works with |
|-------|--------------|------------|
| 0 | Geometry and mode only (read-only) | Its own frame and its own pages |
| 1 | Frame and tabs | Plain `Scaffold` pages, no page-layer types |
| 2 | Page layer and actions | Actions moved into the column or kept in the bar, text-only leading actions |
| 3 | Custom builders, backdrop, bleed | Per-shell overrides, any design system |

## 5. Geometry

### 5.1 Layout mode

```dart
abstract class DuoLayoutPolicy {
  const DuoLayoutPolicy();
  const factory DuoLayoutPolicy.shortestSide(double size) = _ShortestSidePolicy; // default: 600
  const factory DuoLayoutPolicy.breakpoint(double width) = _BreakpointPolicy;
  const factory DuoLayoutPolicy.fixed(DuoLayoutMode mode) = _FixedPolicy;
  DuoLayoutMode resolve({required Size window, required Size frame});
}
```

The policies look at the **window** (`MediaQuery.sizeOf`), not the frame, so nested frames (a modal frame over a shell)
agree on the mode. The default, `shortestSide(600)`, uses the window's shorter side: phones keep the bottom bar in
landscape, where the column would meet the camera cutout or the system buttons on a short screen, while tablets and
unfolded foldables get the column. `breakpoint` uses the window width, and `fixed` serves tests and products that want
one mode.

### 5.2 Side and window edges

`DuoSide.start` / `end` is the preferred edge, resolved against `Directionality`. A `DuoWindowEdgesSource` reports
which physical display edges the window touches:

```dart
abstract interface class DuoWindowEdgesSource {
  DuoWindowEdges? get value;            // null = unknown
  Stream<DuoWindowEdges?> get changes;
  const factory DuoWindowEdgesSource.fixed(DuoWindowEdges? edges) = _FixedEdgesSource;
}
```

The column moves to the other edge only when the window touches that edge and not the preferred one
(`DuoWindowEdges.resolveRight`, kept from 0.0.1). No source, or an unknown value, means the preferred edge.
`DuoNavigation` owns the single subscription, so nested scopes never start a second platform listener.

`DuoNavigation.modeOf`, `sideOf`, `sideOnRight` and `windowEdgesOf` resolve mode, side and edges without a frame
(level 0). Window-edge changes notify only widgets that read the side or the edges.

### 5.3 DuoGeometry

Each frame publishes one immutable geometry object to its body:

```dart
@immutable
class DuoGeometry {
  final DuoLayoutMode mode;
  final DuoSide side;            // logical, after window-edge resolution
  final bool columnOnRight;       // physical
  final DuoBodyMode bodyMode;    // inset | overlay
  final double visibility;        // 0 = hidden, 1 = shown; animates
  final EdgeInsets systemPadding; // MediaQuery.padding above the frame
  final EdgeInsets chrome;        // area the bar or column covers, per edge, scaled by visibility
  final double keyboard;          // viewInsets.bottom the frame consumed

  /// What the body is inset by, and what a DuoBleed widens into. Zero in overlay mode and when hidden.
  EdgeInsets get strip;

  static DuoGeometry of(BuildContext context, {DuoGeometryAspect? aspect});
  static DuoGeometry? maybeOf(BuildContext context, {DuoGeometryAspect? aspect});
}

enum DuoGeometryAspect { mode, side, chrome, visibility }
```

It is provided as an `InheritedModel`, so a widget that only reads the mode does not rebuild while the bar animates.
The body also gets an adjusted `MediaQuery` (section 6.3), so existing widgets work without reading the geometry.

## 6. The frame

### 6.1 Slots

`DuoShell` and `DuoModalScope` build one frame render object with four slots
(`SlottedMultiChildRenderObjectWidget`):

| Slot | Laid out | Painted |
|------|----------|---------|
| `backdrop` (with #28) | the whole frame | first |
| `body` | the free area (inset) or the whole frame (overlay) | second |
| `bar` | compact mode: full width, its own height, at the bottom | third |
| `column` | wide mode: its width, frame height minus the keyboard, on the resolved edge | third |

Slots are stable, so a mode switch never remounts the body: tab, route, scroll positions, text and focus survive a
rotation or unfold. Bar and column are laid out first. The body is laid out last with constraints that carry the
resulting geometry (`DuoFrameConstraints`, a `BoxConstraints` subclass, as in 0.0.1). A body scope reads them during
layout and provides `DuoGeometry` and `MediaQuery` to the page subtree. The page subtree itself is the same widget
instance, so only geometry dependents rebuild.

Hit testing runs in reverse paint order. Chrome that is fully hidden is neither painted nor hit-tested.

### 6.2 The inset rule

On its edge, the column sits **at the window edge, over the system inset** by default (`DuoColumnInset.overlap`),
and the free area starts after the column. The body keeps any part of the inset wider than the column. With
`DuoColumnInset.safeArea` it sits after the inset (cutout, button bar), and the free area starts after both.
Overlap is the default because iOS reports a landscape inset on both sides, which would push the column far inward
on the side without a cutout.

| Mode | Chrome on the covered edge | Body rect (inset mode) |
|------|----------------------------|------------------------|
| wide, column right | `chrome.right = (columnWidth [+ systemPadding.right with safeArea]) × visibility` | `[0, width − chrome.right]` |
| wide, column left | mirrored | `[chrome.left, width]` |
| compact | `chrome.bottom = barHeight × visibility` | `[0, height − bottomReserve]` (section 6.4) |

- With safeArea, the column slot is `systemPadding + columnWidth` wide and gets the system inset as its
  `MediaQuery.padding` on that edge. With overlap it is `columnWidth` wide and that padding is zero. Its builder can paint a background under the cutout while its content stays clear of it. Vertically, the
  column keeps the system padding (status bar, home indicator).
- `columnWidth` grows with the text scale (`sideColumnWidth × clamp(textScale, 1, maxColumnScale)`).
- The bar builder owns the bottom safe area: it gets the system padding in its `MediaQuery`, without the top
  (the status bar is above the page, as with `Scaffold`'s bottom bar), and must include `padding.bottom` in its height. A debug assertion fires when the measured bar is shorter than `padding.bottom`.
- The measured bar height is used on every layout, so a bar that animates its own height moves the body with it.

This changes 0.0.1's behavior: there, the column overlapped the system inset (`max(columnWidth, inset)`). The
migration guide lists it.

### 6.3 What the body sees

**Inset mode (default).** Per edge: `padding = max(0, systemPadding − chrome)`, and the same for `viewPadding`. Edges
the chrome covers report zero. The others keep the system value. `SafeArea` and `Scaffold` in a page work
unchanged, and a plain `Column([Expanded(...), button])` never has the button under the chrome.

**Overlay mode.** The body covers the whole frame. Per edge: `padding = max(systemPadding, chrome)`, which is the
0.0.1 behavior. `SafeArea` content stops beside the chrome. Other content runs under it.

In both modes `MediaQuery.size` stays the window size, as with Flutter's `DisplayFeatureSubScreen`. Use
`LayoutBuilder` for the available size.

`bodyMode` is set on `DuoNavigationData` (app default), on `DuoShell` / `DuoModalScope` (null inherits) and on
`DuoPageScope`. A page's body mode applies while that page owns the frame (section 10.2). The change animates with
the visibility animation, so a page transition never makes the body jump.

### 6.4 Keyboard

```dart
enum DuoKeyboardBehavior { lift, hide, ignore }

enum DuoBodyKeyboardBehavior { passThrough, lift }

class DuoKeyboard {
  const DuoKeyboard({
    this.column = DuoKeyboardBehavior.lift,
    this.bar = DuoKeyboardBehavior.ignore,
    this.body = DuoBodyKeyboardBehavior.passThrough,
  });
}
```

The frame reads `viewInsets.bottom` (`k`) from the `MediaQuery` above it. If an ancestor (`Scaffold` with
`resizeToAvoidBottomInset`) has already resized the frame, `k` is zero there, so nothing moves twice.

| Chrome | `lift` | `hide` | `ignore` |
|--------|--------|--------|----------|
| column | laid out in `height − k`; rail and chips ride above the keyboard | hidden while `k > 0` | full height, covered |
| bar | placed on top of the keyboard | hidden while `k > 0` | stays at the bottom, covered |

In **inset mode** the body follows `DuoKeyboard.body`:

- `passThrough` (default): the body ends at the bar's top edge as without a keyboard, and below the frame
  `viewInsets.bottom = max(0, k − bottom strip)`, the part of the keyboard the bar doesn't already cover. The page's
  `Scaffold` decides, including `resizeToAvoidBottomInset: false`. A frame can't see the page's choice, so it leaves it
  to the page.
- `lift`: the frame consumes the keyboard: `bottomReserve = max(k, bar bottom edge above the frame bottom)`, so
  `max(k, barHeight)` for `ignore`, `k` for `hide`, and `k + barHeight` for `lift`; below the frame
  `viewInsets.bottom = 0`, so a page's own `Scaffold` does not resize a second time.
- `DuoShell.keyboard` and `DuoModalScope.keyboard` override the app's setting per frame.

In **overlay mode** the frame does not consume the keyboard. `viewInsets` pass through, and the page's `Scaffold`
handles them as in 0.0.1.

At small heights (a landscape phone with the keyboard open leaves about 150 px), the column keeps the rail and the
bottom-most action and scrolls the other actions. It never throws an overflow error.

### 6.5 Visibility

The navigation is hidden when any of these says so:

- `DuoShell(navigationVisible: false)` / `DuoModalScope(navigationVisible: false)`;
- the page that owns the frame (`DuoPageScope(visible: false)`);
- the keyboard rule (`hide`).

Each source drives its own `AnimationController`, and the effective visibility is their product. Controllers only
tick while animating. Under `MediaQuery.disableAnimations` they jump. At visibility 0 the chrome is not painted, not
hit-tested, wrapped in `ExcludeSemantics` and `ExcludeFocus`, and `chrome` and `strip` are zero.

## 7. Configuration and builders

0.0.1 kept configuration and visuals in one global `DockNavigationData`. 0.1.0 splits them.

### 7.1 Non-visual configuration

```dart
@immutable
class DuoNavigationData {
  const DuoNavigationData({
    this.layoutPolicy = const DuoLayoutPolicy.shortestSide(600),
    this.side = DuoSide.end,
    this.windowEdgesSource,                       // null: always `side`
    this.bodyMode = DuoBodyMode.inset,
    this.keyboard = const DuoKeyboard(),
    this.hoisting = DuoHoisting.iconActions,
    this.tapGuard = const DuoTapGuard(),
    this.sideColumnWidth = 72,
    this.sideItemExtent = 56,
    this.actionSpacing = 8,
    this.animation = const DuoAnimation(),       // durations and curves for actions, visibility, backdrop
  });
  // == and hashCode over all fields; copyWith can reset nullable fields (sentinel default).
}

class DuoNavigation extends StatefulWidget {
  const DuoNavigation({super.key, this.data = const DuoNavigationData(), required this.builders, required this.child});
  static DuoNavigationData of(BuildContext context);       // FlutterError with a fix hint when missing
  static DuoNavigationData? maybeOf(BuildContext context);
  static DuoLayoutMode modeOf(BuildContext context);
  static DuoSide sideOf(BuildContext context);
}
```

`DuoNavigation` sits above the root `Navigator` (`MaterialApp.builder`), so root-level modals see it. Because the
data has value equality, rebuilding it with equal data notifies nobody.

### 7.2 Builders

```dart
@immutable
class DuoBuilders<T, A, B> {
  const DuoBuilders({
    this.tabItem, this.tabBar, this.rail,         // tabs
    this.action, this.actionTransition,           // actions
    this.sideColumn,                              // column arrangement
    this.page,                                    // DuoPage's scaffold
    this.backdrop,                                // a frame's default backdrop
  });
  final DuoTabItemBuilder<T>? tabItem;
  final DuoTabsBuilder<T>? tabBar;
  final DuoTabsBuilder<T>? rail;
  final DuoActionBuilder<A>? action;
  final DuoActionTransitionBuilder? actionTransition;
  final DuoSideColumnBuilder? sideColumn;
  final DuoPageBuilder<A, B>? page;
  final WidgetBuilder? backdrop; // shows in the strip around the chrome

  /// [other]'s non-null fields win.
  DuoBuilders<T, A, B> merge(DuoBuilders<T, A, B>? other);
}
```

- Builders are provided on `DuoNavigation` (app level) and can be overridden on `DuoShell(builders: ...)` /
  `DuoModalScope(builders: ...)`. The nearest scope wins, field by field. An override on one shell leaves other
  shells unchanged.
- A field that is null all the way up fails with a `FlutterError` naming the field and pointing to
  `DuoMaterialBuilders()` in `package:duo_navigation/material.dart`.
- Every builder has the shape `(BuildContext, Data)`. `Data` is immutable and has value equality. Each typedef's
  dartdoc states the builder contract:

| Builder | Gets | Safe area | Semantics | Keys | Animation |
|---------|------|-----------|-----------|------|-----------|
| `tabItem` | `DuoTabItemData<T>` (tab, index, count, selected, onTap, mode) | n/a | package (section 13) | package (`DuoKeys.tab`) | builder (selection) |
| `tabBar` | `DuoTabsData<T>` + built items | builder includes `padding.bottom` | package (tab-bar container) | package | builder |
| `rail` | `DuoTabsData<T>` + built items | column (vertical) | package | package | builder |
| `action` | `DuoActionData<A>` (action, placement, enabled, onPressed) | n/a | package (button, label, enabled) | package (`DuoKeys.action`) | package for presence, builder for icon morph |
| `sideColumn` | `DuoSideColumnData` (actions widget, rail widget, hasActions) | gets system inset on its edge | package | package | package |
| `page` | `DuoBarData<A, B>` + body | page | page | page | page |

- Builders are called with a context below the shell and `DuoNavigation`, so they can read app scopes.

## 8. Typed payloads

```dart
class DuoTab<T>     { final T? payload; ... }
class DuoAction<A>  { final A? payload; ... }
class DuoPageScope<A, B> { final B? barPayload; ... }   // e.g. a structured title spec
```

- `DuoShell<T, A, B>` and `DuoModalScope<A, B>` bind the types for their frame.
- `DuoBuilders<T, A, B>` is provided through two typed inherited scopes, one for tabs (`T`) and one for chrome
  (`A`, `B`). Pages, which don't know `T`, look up the chrome scope. Lookups are by exact type. When nothing matches,
  a debug walk finds the scope that is there and reports both types:
  `DuoBuilders<..., MyAction, ...> expected, found DuoBuilders<..., Object?, ...> above this DuoPage`.
- The action host stores `DuoAction<Object?>` (generics are covariant). The frame hands the builder a
  `DuoAction<A>` after a checked conversion with the same kind of error, never a bare cast error.
- Apps without payloads write no type arguments. Everything infers to `dynamic` and matches.
- Apps with payloads declare their types once:

```dart
typedef AppDock = DuoBuilders<AppTab, AppAction, AppTitle>;
typedef AppShell = DuoShell<AppTab, AppAction, AppTitle>;
typedef AppPage = DuoPage<AppAction, AppTitle>;
```

- Icons are descriptors, not widgets, so a component that needs `IconData` gets it directly:

```dart
sealed class DuoIcon {
  const factory DuoIcon(IconData data) = _DataIcon;
  const factory DuoIcon.image(ImageProvider image) = _ImageIcon;
  const factory DuoIcon.widget(Widget widget, {Object? identity}) = _WidgetIcon;
  static const DuoIcon back = _PlatformIcon.back;   // resolved by the builder (chevron, arrow)
  static const DuoIcon close = _PlatformIcon.close;
  Object get identity;   // keys the icon morph
}
```

The type parameters arrive with their models: `T` with tabs (#11), `A` with actions (#14, #19) and `B` with the page
layer (#12). Until then `DuoBuilders` has none.

Two risks are validated early. The first is ergonomics: a fixture in `test/fixtures/typed_payloads.dart` models a
component library with typed payloads and is used from the geometry/config PR on. The second is real adapters. If
generics turn out too heavy, a checked accessor (`payloadOf<T>()`) is the fallback, decided before the docs PR.

## 9. Tabs

```dart
@immutable
class DuoTab<T> {
  const DuoTab({required this.id, required this.icon, this.selectedIcon, this.label,
                 this.badge, this.tooltip, this.semanticLabel, this.key, this.payload});
  final Object id;
  final DuoIcon icon;
  final DuoIcon? selectedIcon;
  final String? label;
  final DuoBadge? badge;          // DuoBadge.count(3), DuoBadge.dot(), DuoBadge.text('new')
  ...
}

DuoShell<T, A, B>(
  tabs: tabs,
  currentIndex: i,
  onTabSelected: (i) => ...,
  onTabReselected: (i) => ...,            // pop to root, scroll to top
  canSelectTab: (i) async => ...,         // veto, e.g. unsaved changes
  navigationVisible: true,
  bodyMode: null, hoisting: null, keyboard: null, builders: null, backdrop: null,
  child: DuoTabStack(index: i, children: [...]),
)
```

- Tab items are built one by one (`tabItem`) and wrapped by the package: semantics (section 13), `DuoKeys.tab(id)`
  and badge semantics. The container builders (`tabBar`, `rail`) arrange the built items. Builders can't drop the
  semantics or the keys.
- `DuoTabStack` is the tab container helper. It builds tabs lazily, keeps them alive, and makes inactive tabs inert:
  `Offstage`, `TickerMode(enabled: false)`, `ExcludeFocus`, `HeroMode(enabled: false)`. It does not clip, so bleeds
  work. Any other container works if it provides `TickerMode(enabled: false)` for inactive tabs. A debug message
  reports two pages owning one frame from different tick-enabled subtrees.
- The rail scrolls when the tabs don't fit, keeping the selected tab visible.

## 10. Actions

### 10.1 Model

```dart
@immutable
class DuoAction<A> {
  const DuoAction({required this.id, this.role = DuoActionRole.secondary, this.icon, this.label,
                    this.onPressed, this.enabled = true, this.badge, this.tooltip, this.semanticLabel,
                    this.key, this.order = 0, this.hoist = DuoHoist.auto, this.shared = false,
                    this.guarded = true, this.cooldown, this.payload})
      : assert(icon != null || label != null);
  const DuoAction.back({DuoIcon? icon = DuoIcon.back, String? label, VoidCallback? onPressed, ...});
  const DuoAction.close({DuoIcon? icon = DuoIcon.close, String? label, VoidCallback? onPressed, ...});
}

enum DuoActionRole { back, close, primary, secondary, destructive, overflow }
enum DuoHoist { auto, never }
enum DuoHoisting { iconActions, none }
```

- `role` gives the builder a styling hook and gives the leading slot its meaning. `back` and `close` share one
  identity across pages, so the chip stays in place and morphs between back and close.
- A **text-only leading action** ("Cancel") is valid in every mode. It never moves into the column.
- **Hoisting.** In wide mode an action moves into the column when hoisting is `iconActions` (app, shell or modal scope;
  nearest wins), the action has an icon and `hoist` is `auto`. With `none`, `DuoBarData` is identical in compact and
  wide mode, leading action included, and the column holds only the rail.
- **Column order**, bottom to top: the leading action right above the rail, then the hoisted trailing actions by
  `order`, then by declaration order. The leading chip never moves when trailing actions change.
- Actions that leave animate out in place (`mergeOrder`, kept from 0.0.1). The package owns presence timing, and
  builders own the visuals.
- The icon morph is keyed by `DuoIcon.identity`. For a widget icon, the identity defaults to the widget's key.

### 10.2 Which page owns the frame

Each page layer (`DuoPageScope`) registers with the nearest frame's action host. A page is **active** while:

- its route is current, **or** its route is not current but only popup routes (dialogs, sheets) are above it. The
  rule used: the route's `secondaryAnimation` is dismissed, because page routes don't animate under popup routes.
  If this proves unreliable, an exported `DuoRouteObserver` replaces it.
- and its subtree is ticking (`TickerMode`), so inactive tabs don't compete.

The most recently activated registration owns the column, body mode, visibility and backdrop of the frame. This
needs no router knowledge, as in 0.0.1.

### 10.3 Tap guard

```dart
class DuoTapGuard {
  const DuoTapGuard({this.enabled = true, this.cooldown = const Duration(milliseconds: 350),
                      this.clock, this.onRejected});
  final DuoClock? clock;                                  // null: a monotonic stopwatch
  final void Function(DuoAction<Object?> action, DuoTapRejection reason)? onRejected;
}

enum DuoTapRejection { notActive, transition, cooldown }

abstract interface class DuoClock {
  Duration now();
  static const DuoClock frameTime = _FrameTimeClock();   // SchedulerBinding.currentSystemFrameTimeStamp
}
```

A guarded tap fires only if:

1. its page owns the frame;
2. its route is current and settled (no transition, no back gesture in progress);
3. the same action (same identity as in the column) has not fired within its cooldown (`action.cooldown ??
   tapGuard.cooldown`).

Different actions don't block each other. Rejections call `onRejected` and log in debug mode. `DuoTestHarness` uses
`DuoClock.frameTime`, so `tester.pump(duration)` advances the guard and tests never wait on real time.

## 11. Page layer

The page layer is optional (level 2). A plain `Scaffold` page in a frame is a first-class case and is tested in both
modes.

```dart
class DuoPageScope<A, B> extends StatefulWidget {
  const DuoPageScope({super.key, this.title, this.barPayload, this.leading, this.automaticallyImplyLeading = true,
                       this.trailing = const [], this.bodyMode, this.visible = true, this.backdrop, this.hoisting,
                       required this.child});
  // Registers with the frame and provides DuoBarData<A, B> to child.
}

@immutable
class DuoBarData<A, B> {
  final DuoLayoutMode mode;
  final Widget? title;
  final B? payload;
  final DuoAction<A>? leading;            // null in wide mode only when it is in the column
  final List<DuoAction<A>> trailing;      // what stays in the bar
  final List<DuoAction<A>> hoisted;       // what is in the column (for information)
  final bool actionsAtStart;               // the column is on the start edge, so bar actions follow it
  Widget buildAction(DuoAction<A> action, DuoActionPlacement placement);
  static DuoBarData<A, B> of<A, B>(BuildContext context);
}
```

- `DuoBarLayout` (widgets only) lays out leading, title and trailing. It handles start/end mirroring, right-to-left
  and the centered-title policy, with or without a leading action. The default app bar and custom bars use it.
- `DuoAppBar` (in `material.dart`) reads `DuoBarData.of(context)`, so a page with its own `Scaffold`, keys, bottom
  bar or FAB needs no builder closure:

```dart
DuoPageScope(
  title: const Text('Items'),
  trailing: [DuoAction(id: 'add', icon: const DuoIcon(Icons.add), onPressed: add)],
  child: Scaffold(
    key: const Key('items'),
    appBar: const DuoAppBar(),
    bottomNavigationBar: const ItemsToolbar(),
    body: const ItemsList(),
  ),
)
```

- `DuoPage<A, B>` is the convenience widget: `DuoPageScope` plus the configured `page` builder.
- An implied leading action (route can pop) is `DuoAction.back()`, or `DuoAction.close()` for full-screen dialogs;
  `DuoImpliedLeading` on `DuoModalScope` and `DuoPageScope` overrides it. A modal's first page (on the modal's route,
  or first in a `Navigator` inside it) gets one that dismisses the modal.
  Its icon is a descriptor and its tooltip comes from the builder's localizations, so the core stays widgets-only.
- A `DuoPage` with no frame above it brings its own modal frame (kept from 0.0.1).

## 12. Backdrop and bleed

Content under the chrome is opt-in at three granularities.

**Backdrop.** `DuoShell(backdrop: ...)` and `DuoPageScope(backdrop: ...)` paint one widget across the whole frame,
under body and chrome. The active page's backdrop wins over the shell's and cross-fades when the owner changes. This
covers full-window gradients and pictures with no component knowing about the frame. The cross-fade follows page
activation, not an interactive back swipe.

**Bleed.** `DuoBleed` widens its child toward the strip while keeping its own size, so siblings are unaffected.

- Constraints grow by the strip on the chrome side: both `minWidth` and `maxWidth` when tight, `maxWidth` when loose
  (`maxHeight` for the bar). The child is offset when the strip is on the left.
- It assumes its box touches the body's edge on the chrome side. Use it on full-width (or full-height) content.
- Inside it, `MediaQuery.padding` on the covered edge equals the strip, so `SafeArea` and list padding pad back.
- It is a no-op when the strip is zero (overlay mode, hidden navigation, outside a frame) and inside another bleed.
  The tree shape never changes, so state survives mode switches.
- It is a `RenderShiftedBox`, with intrinsics and dry layout. It adds no layers and no `saveLayer`.
- Pointer events in the strip go to the chrome (it paints above), not to the child: the frame hit-tests its body
  only within the body's bounds. Interactive content belongs in a `DuoInset`.
- `column` and `bar` turn the two directions off for content that doesn't touch that edge.

**Inset.** `DuoInset` is the inverse: inside a bleed, it pads its child back by the strip and removes that padding
from `MediaQuery`. It is a no-op outside a bleed.

**Scroll views** clip at their bounds, so one item can't bleed out of a list. Wrap the scroll view instead:
`DuoBleed(child: ListView(...))` lays the whole viewport out widened, and its own clip then includes the strip.
`DuoInset.wrapAll(children)` insets every child except the ones wrapped in `DuoBleedItem`, so a bleeding header in a
list of inset rows needs no custom render object.

**What clips a bleed:** `ClipRect`, scroll views with their default clip, `Material` with a clip, and `Navigator`
(`clipBehavior` defaults to `Clip.hardEdge`). `Stack` and `IndexedStack` don't. `DuoTabStack` doesn't clip. A
`Navigator` inside the frame needs `clipBehavior: Clip.none` for page-level bleeds. In debug mode, `DuoBleed` warns
once when a clipping ancestor sits between it and the frame's body. The backdrop is the recommended way to run page
backgrounds under the chrome, because it is not affected by these clips.

`DuoBleed.insetOf(context)` returns the strip for painters and custom layouts.

## 13. Accessibility

- **Semantics are attached by the package**, outside the builder's output. Strings the core cannot localize come from
  the builders: `DuoBuilders.tabPosition` ("Tab 2 of 3", as a hint) and `DuoBuilders.actionLabel` (labels for the
  implied back and close actions).
  - tab items: `SemanticsRole.tab`, selected, label (`semanticLabel ?? label ?? tooltip`), tap action, badge text;
  - the tab bar and rail: `SemanticsRole.tabBar` container;
  - actions: button, label, enabled, tap action, badge text.

  Builders can add semantics but not drop the package's. `DuoSemantics.tab(...)` / `DuoSemantics.action(...)`
  helpers keep the tap action for builders that wrap their own items.
- **Traversal order** (`FocusTraversalOrder` and `OrdinalSortKey`), the same in both modes:
  1. the page: its title bar, then its content;
  2. page actions in the column, top to bottom;
  3. the rail or the tab bar.
- **Focus across a mode switch.** The frame records the focused chrome element by id (tab id, action id) before the
  switch, and moves focus to the element with the same id afterwards: rail item ↔ tab bar item, column chip ↔ app
  bar action. Focus in the body is untouched, because the body is never remounted.
- **Reduced motion.** Every package animation honors `MediaQuery.disableAnimations`.
- **Default visuals** have targets of at least 48 dp, follow the text scale and bold text, and work with a hardware
  keyboard and D-pad in wide mode.
- The package tests the defaults with `meetsGuideline(labeledTapTargetGuideline)` and `androidTapTargetGuideline`,
  plus a semantics-tree test with a custom builder that wraps the defaults.

## 14. Testing support

```dart
DuoTestHarness(
  mode: DuoLayoutMode.wide,          // a fixed policy
  side: DuoSide.end,
  windowEdges: FakeWindowEdgesSource(),
  textDirection: TextDirection.rtl,
  tapGuard: const DuoTapGuard(clock: DuoClock.frameTime),   // the default in the harness
  builders: DuoMaterialBuilders(),
  child: ...,
)
```

- `FakeWindowEdgesSource.push(edges)` changes the edges over time (fold, unfold, window moved).
- `DuoKeys.tab(id)`, `.action(id)`, `.column`, `.bar`, `.rail` are used by the default visuals. The key contract for
  custom builders is documented: the package applies these keys around builder output.
- The package's own acceptance tests live in `test/acceptance/`, one file per behavior in section 18.

## 15. Performance rules

- The body does not rebuild when bar or column content changes. Geometry dependents rebuild only for the aspect they
  read.
- Page subtrees are not remounted on a mode switch.
- Nothing ticks or listens while nothing animates.
- Bleed and inset add no compositing layers.
- A benchmark (build, layout and paint of a frame with a fixed tab and action count) runs in CI. Its budget is set
  once the baseline exists.

## 16. Loud failures

| Situation | 0.0.1 | 0.1.0 |
|-----------|-------|-------|
| No `DuoNavigation` above a frame or page | silently used defaults (wide on an 800×600 test surface) | `FlutterError` with the fix; `maybeOf` for optional use |
| No builder for a field | n/a (built-in defaults) | `FlutterError` naming the field and `DuoMaterialBuilders` |
| Builder or page payload type mismatch | cast error inside a builder | `FlutterError` naming expected and found types at lookup |
| Bar shorter than the bottom safe area | drew under the home indicator | debug assertion |
| Two tabs' pages own one frame | wrong chips | debug message pointing to `TickerMode` / `DuoTabStack` |
| Bleed under a clipping ancestor | cut silently | debug warning naming the ancestor |
| Rejected tap | silent | `onRejected` callback and a debug log |

## 17. Migration from 0.0.1

| 0.0.1 | 0.1.0 |
|-------|-------|
| package `nav_dock`, types `Dock*` | package `duo_navigation`, types `Duo*` (`DockShell` → `DuoShell`, ...) |
| `DockNavigationData(tabBarBuilder: ..., railBuilder: ..., actionBuilder: ..., pageBuilder: ..., sideColumnBuilder: ..., actionTransitionBuilder: ...)` | `DuoNavigation(builders: DuoMaterialBuilders().merge(DuoBuilders(...)))` |
| `DockDefaults.*` | `package:duo_navigation/material.dart` |
| `breakpoint: 600` | `layoutPolicy: DuoLayoutPolicy.breakpoint(600)` |
| `windowEdges:` / `detectWindowEdges:` | `windowEdgesSource: WindowPlacementEdgesSource()` (separate package) or `DuoWindowEdgesSource.fixed(...)` |
| body under the chrome, obstruction as padding | `bodyMode: DuoBodyMode.inset` (default); `overlay` for the old behavior |
| column overlapped the system inset | unchanged by default; `columnInset: DuoColumnInset.safeArea` places it after |
| `tapCooldown:` | `tapGuard: DuoTapGuard(cooldown: ...)`; cooldown is per action |
| `DockTab(icon: Icon(...), data: ...)` | `DuoTab(id: ..., icon: DuoIcon(...), payload: ...)` |
| `DockAction(icon: Icon(...), pinToBar: true, data: ...)` | `DuoAction(icon: DuoIcon(...), hoist: DuoHoist.never, payload: ...)` |
| `DockAction.back(icon: ...)` (no label) | `DuoAction.back(label: 'Cancel')` allowed |
| `DockPage.custom(builder: (context, bar) => ...)` | `DuoPageScope(child: Scaffold(appBar: const DuoAppBar(), ...))` |
| `DockBarData.trailingAtStart` | `DuoBarData.actionsAtStart`, handled by `DuoBarLayout` |
| `DockScope.modeOf(context)` | `DuoGeometry.of(context, aspect: mode).mode` or `DuoNavigation.modeOf(context)` |
| inactive tabs via your own `Offstage` + `TickerMode` | `DuoTabStack` (or any container providing `TickerMode`) |

## 18. Acceptance

The redesign is done when each of these is shown by a test:

1. A plain `Scaffold` page lays out correctly in compact and wide mode, column at start and end, LTR and RTL, with no
   page-layer type.
2. `Column([Expanded(...), button])` never has the button under the chrome, with no app code.
3. A rotation or unfold keeps the tab, the route, scroll positions, text-field content and focus.
4. Hidden navigation gives zero obstruction, lets taps through and is absent from semantics, in both modes.
5. A full-width gradient behind a page needs one backdrop widget. A bleeding header in a list with inset rows needs
   one helper.
6. With the keyboard open, rail and bar follow `keyboard`, and the focused field is visible.
7. A test pins mode, edges and clock in one call and never waits on real time.
8. A builder override on one shell leaves other shells unchanged.
9. A semantics test for tabs and actions passes with a custom builder that wraps the default.
10. `duo_navigation` builds for Android, iOS, web and desktop with no native plugin in its dependency graph.
11. A typed payload reaches a builder with no cast.
12. With hoisting `none`, the bar data is the same in compact and wide mode, and a text leading action works in both.
13. `dart doc` is clean and a public-API diff runs in CI.

## 19. To validate during implementation

| Question | Where | Fallback |
|----------|-------|----------|
| Are scoped generics comfortable in a real adapter? | #20 fixture, early adopters | checked `payloadOf<T>()` accessor |
| Does `secondaryAnimation` reliably mark "only popups above"? | #14 | `DuoRouteObserver` |
| Do platforms announce "tab x of n" from the tab roles? | #18, release checklist #39 | explicit position in the semantic label |
| Is per-page body mode smooth during page transitions? | #6, #23 | body mode per frame only |

## 20. Delivery

Work happens on the `next` branch, one PR per step, each green (format, analyze, tests, example builds). `next`
merges into `main` for the 0.1.0 release.

| Step | Scope | Issues |
|------|-------|--------|
| 1 | This document | #4 |
| 2 | Workspace, stricter analysis, import-boundary test, CI and release per package | #38 |
| 3 | Geometry, configuration and the window-placement adapter package | #5, #16, #17, #20 (models), #24 |
| 4 | Frame: slots, inset and overlay, geometry publication | #6 |
| 5 | Testing entry point | #32 |
| 6 | Builders and Material defaults | #8, #9, #34 |
| 7 | Tabs | #11, #25, #26, #27 |
| 8 | Actions and tap guard | #10 (model), #14, #15, #19, #20 (actions) |
| 9 | Page layer | #10, #12, #13, #20 (bar), #23 |
| 10 | Show and hide | #7 |
| 11 | Keyboard | #22 |
| 12 | Backdrop and bleed | #21, #28, #29 |
| 13 | Accessibility | #18, #30, #31 |
| 14 | Example, README, migration guide | #37, #9, #23, #24 |
| 15 | Quality gates: docs, API diff, performance | #35, #36 |
| 16 | Release checklist and 0.1.0 | #39 |
