## 0.1.0

A redesign of nav_dock, under a new name. Upgrading: see the
[migration guide](https://github.com/JanMichaelPeter/duo_navigation/blob/main/doc/migration_0.1.md);
adding it to an existing app: see
[adopting duo_navigation](https://github.com/JanMichaelPeter/duo_navigation/blob/main/doc/adopting.md);
the design is in the
[architecture document](https://github.com/JanMichaelPeter/duo_navigation/blob/main/doc/design/architecture.md).

* Renamed from nav_dock to duo_navigation. Depend on `duo_navigation` and
  import `package:duo_navigation/...`; nav_dock 0.0.1 stays on pub.dev and
  gets no further releases.
* **BREAKING** The types are renamed from the `Dock` prefix to `Duo`, after
  the package: `DockNavigation` → `DuoNavigation`, `DockShell` → `DuoShell`,
  `DockPage` → `DuoPage`, `DockAction` → `DuoAction`, and so on. The entries
  below use the new names, except for 0.0.1 APIs that were removed.
* Requires Dart 3.9 / Flutter 3.35 (0.0.1 required Dart 3.10 / Flutter 3.38).
* **BREAKING** `DockNavigationData.breakpoint` is replaced by `layoutPolicy`:
  `DuoLayoutPolicy.shortestSide(600)` (default: wide when the window's
  shorter side is at least 600, so phones keep the bottom bar in landscape),
  `DuoLayoutPolicy.breakpoint(width)` (the window width, as in 0.0.1 but of
  the window) or `DuoLayoutPolicy.fixed(mode)`.
* **BREAKING** `duo_navigation` no longer depends on window_placement and has no
  native code. `windowEdges` and `detectWindowEdges` are replaced by
  `windowEdgesSource`: pass `WindowPlacementEdgesSource()` from the new
  `duo_navigation_window_placement` package, `DuoWindowEdgesSource.fixed(...)`, or
  your own source. Without a source the preferred `side` is used.
* **BREAKING** `DuoNavigation.of` throws a `FlutterError` when there is no
  `DuoNavigation` above, instead of silently using defaults. Use
  `DuoNavigation.maybeOf` where none is expected, and the new
  `DuoStandalone` around content that may be shown without one: it provides
  a compact `DuoNavigation` there and does nothing below an existing one.
* **BREAKING** The body is laid out beside the tab bar and side column
  (`DuoBodyMode.inset`, the new default) instead of under them. Plain
  `Scaffold` pages no longer need `SafeArea` to stay clear of the chrome.
  `DuoBodyMode.overlay` on `DuoNavigationData`, `DuoShell` or
  `DuoModalScope` restores the 0.0.1 layout.
* New `DuoNavigationData.columnInset`: the side column sits at the window
  edge over the system inset on its edge (`DuoColumnInset.overlap`, the
  default, as in 0.0.1) or after it, clear of cutouts and system buttons
  (`DuoColumnInset.safeArea`). The README explains the trade-off on phones
  in landscape.
* New `DuoGeometry.of(context)`: the frame's mode, side and chrome per edge,
  with aspects so widgets rebuild only for what they read.
* A debug error reports a tab bar that is shorter than the bottom safe area.
  The tab bar's `MediaQuery` has no top padding, so a bar wrapped in
  `SafeArea` doesn't grow by the status bar height.
* **BREAKING** `DockNavigationData.tapCooldown` is replaced by
  `tapGuard: DuoTapGuard(enabled:, cooldown:, clock:)`. The guard's time
  comes from a `DuoClock`; `DuoTapGuard.disabled` lets every tap through.
  The default, `DuoClock.system()`, is real time on a device and follows
  `tester.pump(duration)` / `pumpAndSettle` in widget tests, so a page under
  a plain `DuoNavigation` or a `DuoStandalone` can be tapped twice in a test
  without `DuoTestHarness`.
* New `package:duo_navigation/testing.dart`: `DuoTestHarness` pins layout mode,
  side, window edges, text direction and the tap guard's clock in one widget;
  `FakeWindowEdgesSource` and `FakeDuoClock`. It does not depend on
  `flutter_test`.
* New `DuoKeys` (`bar`, `column`, `rail`, `action(id)`), applied by the
  package around the builders' output.
* **BREAKING** The visuals moved out of `DockNavigationData` into
  `DuoBuilders` (`tabBar`, `rail`, `action`, `page`, `sideColumn`,
  `actionTransition`, and the new `backdrop`), passed as `DuoNavigation(builders: ...)`.
  `DuoShell(builders:)`, `DuoModalScope(builders:)` and `DuoBuildersScope`
  override them per frame or subtree, field by field. A builder that no scope
  sets fails with an error naming it.
* **BREAKING** The Material defaults moved to `package:duo_navigation/material.dart`:
  `DuoMaterialBuilders()` sets every builder, and `DockDefaults` is now
  `DuoMaterial`. The core library depends on `package:flutter/widgets.dart`
  only.
* Each builder typedef documents its contract: constraints, safe area, keys,
  semantics and animation.
* **BREAKING** Tabs: `DuoTab<T>` has a required `id`, icons as `DuoIcon`
  descriptors (font, image or widget), `badge` (`DuoBadge`), `semanticLabel`,
  `key` and a typed `payload` (replacing `data`). `DuoShell<T>` and
  `DuoBuilders<T>` carry the payload type to the tab builders without casts;
  `Object?` builders such as `DuoMaterialBuilders` work for any type.
* **BREAKING** Tab builders are split: `tabItem` draws one tab and
  `tabBar` / `rail` arrange the built items. The package wraps each item with
  its semantics (selected, label, badge, tap action) and keys
  (`DuoKeys.tab(id)`, then `DuoTab.key`); `DuoTabBarSemantics` marks custom
  containers.
* `DuoShell.onTabReselected` (taps on the current tab) and
  `DuoShell.canSelectTab` (a sync or async veto).
* New `DuoTabStack`: keeps tabs alive and the inactive ones inert (offstage,
  no tickers, no focus, no hero flights), built when first shown.
  `maintainTickers` keeps inactive tabs ticking; their pages still don't claim
  the column (`DuoTabStack.isActiveOf`).
* New `DuoTabNavigator`: a tab's `Navigator` that handles Android's system
  back (the shown tab's pages first, and a hidden tab's pages don't keep the
  app from closing) and doesn't clip. Its navigator's key is `navigatorKey`;
  a `GlobalKey<NavigatorState>` passed as `key` is reported in debug mode.
* Tab bars that build their children from data: `DuoTabsData.itemData(i)`
  gives a tab's state and tap, and `DuoTabsData.wrap(i, child)` adds the
  package's keys and semantics. For bars that build their item widgets
  themselves, `itemData(i).semanticsOf(context)` and
  `DuoSemantics.tabProperties` give the tab semantics as
  `SemanticsProperties`.
* The rail scrolls when the tabs don't fit and keeps the selected tab visible;
  `DuoSideColumnLayout` gives the rail its height before the actions. The
  column grows with the text scale up to `columnTextScaleLimit` (1.5).
* **BREAKING** Actions: `DuoAction<A>` takes a `DuoIcon` instead of a
  widget, `hoist: DuoHoist.never` replaces `pinToBar`, and a typed `payload`
  replaces `data`. New: `role` (`back`, `close`, `primary`, `secondary`,
  `destructive`, `overflow`), `enabled`, `badge`, `semanticLabel`, `key`,
  `order`, `guarded` and `cooldown`. `DuoShell<T, A>`, `DuoModalScope<A>`,
  `DuoPage<A>` and `DuoBuilders<T, A>` carry the action payload type.
* **BREAKING** `DuoAction.back` takes a `label` and can be text-only
  ("Cancel"); a text-only leading action stays in the bar in every mode. New
  `DuoAction.close`, with the same identity as back, so the two morph.
  `DuoIcon.back` and `DuoIcon.close` are resolved by the builders
  (`DuoMaterial.icon`). New `DuoIconMorph(icon:, builder:)` cross-fades an
  icon when it changes, with any icon rendering; `DuoMaterial.morphingIcon`
  uses it.
* New `DuoImpliedLeading` (`impliedLeading` on `DuoModalScope`,
  `DuoPageScope` and `DuoPage`): close or back instead of the default
  (close only for full-screen dialogs). A modal's first page, also the first
  page of a `Navigator` inside a `DuoModalScope`, gets an implied action that
  dismisses the modal.
* New `leadingAtEnd` on `DuoPageScope`, `DuoPage` and `DuoModalScope`
  (`DuoBarData.leadingAtEnd`): the leading action sits at the end of the
  title bar, such as a close button at the top right; in wide mode it is
  still the lowest chip.
* New `DuoNavigationData.modalLeading` (`DuoModalLeading(implied:, atEnd:)`):
  app-wide defaults for the leading action of every modal start: the first
  page of a `DuoModalScope`, and a page presented as a full-screen dialog or
  in a modal route that isn't a page. A plain page pushed on the root
  navigator keeps back. A `DuoModalScope`'s or a page's own setting wins.
* **BREAKING** The tap guard's cooldown applies per action, so different
  actions no longer block each other. `DuoTapGuard.onRejected` reports each
  dropped tap with a reason; rejections are logged in debug mode.
* A page keeps its actions in the column while dialogs, sheets or menus are
  open above it.
* The icon morph is keyed by `DuoIcon.identity`, so custom icon widgets with
  an identity or a key cross-fade too. `DuoMaterial.morphingIcon` takes a
  `DuoIcon`.
* The core library no longer imports Material anywhere.
* New `DuoPageScope`: the page layer as a piece. It registers a page's
  title and actions and provides `DuoBarData.of(context)`, so pages keep
  their own `Scaffold`, keys, bottom bar or floating action button.
  `DuoPage` is the scope plus the `page` builder.
* New `DuoAppBar` (`package:duo_navigation/material.dart`) reads the page's bar
  data; the Material page uses it. It passes `AppBar`'s `backgroundColor`,
  `foregroundColor`, `elevation`, `scrolledUnderElevation`, `shape`,
  `systemOverlayStyle`, `titleTextStyle`, `flexibleSpace` and `bottom`
  through.
* `package:duo_navigation/material.dart` exports `package:duo_navigation/duo_navigation.dart`,
  so a Material app needs one import (drop the second one, the analyzer
  reports it as unnecessary).
* New `DuoBarLayout`: leading, title and actions with start/end mirroring,
  right-to-left and a centered title, with or without a leading action, and
  the leading action at the end (`leadingAtEnd`).
* **BREAKING** Bar payloads: `DuoPageScope.barPayload` / `DuoPage.barPayload`
  reach builders as `DuoBarData<A, B>.payload`, typed through
  `DuoBuilders<T, A, B>`, `DuoShell<T, A, B>` and `DuoModalScope<A, B>`.
* New `DuoHoisting.none` (on `DuoNavigationData`, `DuoShell`,
  `DuoModalScope` and pages): nothing moves into the column, and the bar data
  is the same in both modes.
* Hide and show the navigation: `DuoShell.navigationVisible`,
  `DuoModalScope.navigationVisible`, and per page `DuoPageScope.visible` /
  `DuoPage.visible`. The bar and column animate away
  (`visibilityDuration`, `visibilityCurve`; instant under reduced motion), the
  body gets the whole frame, and hidden chrome takes no taps, focus or
  semantics. `DuoGeometry.visibility` and `DuoGeometryAspect.visibility`
  follow the animation.
* The software keyboard: `DuoNavigationData.keyboard` with a
  `DuoKeyboardBehavior` (`lift`, `hide`, `ignore`) for the column (default
  `lift`: rail and chips stay above the keyboard) and the bar (default
  `ignore`). For the body, `DuoBodyKeyboardBehavior`: `passThrough` (default)
  keeps its height and reports the part of the keyboard the bar doesn't cover,
  so the page's `Scaffold` and its `resizeToAvoidBottomInset` decide; `lift`
  lays the body out above the keyboard and reports none
  (`DuoGeometry.keyboard` tells how much it took). `DuoShell.keyboard` and
  `DuoModalScope.keyboard` override it per frame. An ancestor that already
  made room is respected.
* Backdrops: `DuoShell.backdrop`, `DuoModalScope.backdrop` and per page
  `DuoPageScope.backdrop` / `DuoPage.backdrop` paint one widget across the
  whole frame, under body and chrome; a page's replaces the frame's while it
  is shown and cross-fades. Without one, a frame paints
  `DuoBuilders.backdrop` (the Material defaults: the theme's scaffold
  background), so the strip around a floating bar or round chips is not the
  bare window.
* New `DuoBleed`, `DuoInset`, `DuoBleedItem` and `DuoInset.wrapAll`
  (also in `geometry.dart`): single components run under the column and the
  bar while the body stays beside them; `DuoBleed.insetOf(context)` returns
  the strip. A debug message names an ancestor that clips a bleed, and what
  to change; clips set to `Clip.none` are not reported.
* Accessibility: actions get package-owned semantics like tabs (button,
  label, enabled, badge, tap); tabs announce their position. New
  `DuoSemantics.tab` / `DuoSemantics.action` and the localizable
  `DuoBuilders.tabPosition` / `DuoBuilders.actionLabel` (Material uses
  `MaterialLocalizations`). Focus and semantics order is page, then column
  actions and rail, or the tab bar, in both modes. A layout switch keeps
  focus on the same tab or action. Reduced motion turns off the chips' and
  the icon morph's animations too.
* **BREAKING** `DockActionHost`, `DockActionRegistration` and `DockScope` are
  no longer exported: `DuoPageScope` covers custom pages, and
  `DuoGeometry.of` / `DuoNavigation.modeOf` give the layout.
* Docs: the README is reorganized around the adoption levels and documents
  the libraries and the stable API; new
  [migration guide](https://github.com/JanMichaelPeter/duo_navigation/blob/main/doc/migration_0.1.md).
  The example covers every level, including a go_router setup
  (`example/lib/main_go_router.dart`), typed tab payloads, a backdrop, a
  bleeding map, a plain `Scaffold` page and an immersive page.
* CI: `dart doc` must report no warnings, every PR gets a public-API diff
  against the last release in its summary, publishing checks the version
  against the API changes, and performance gates count rebuilds (chrome
  changes don't rebuild the body, nothing rebuilds while idle, budgets for a
  tab switch and an animation tick).
* New `package:duo_navigation/geometry.dart`: layout mode, side and window edges
  without the page, action or builder types.
* `DuoNavigation.modeOf`, `sideOf`, `sideOnRight` and `windowEdgesOf` work
  without a frame. Window-edge changes rebuild only widgets that read them.
* `DuoNavigationData` has value equality, so rebuilding `DuoNavigation` with
  equal data no longer rebuilds every dependent.
* `DuoNavigationData.copyWith` and `DuoAction.copyWith` can reset nullable
  fields to null.

## 0.0.1

Initial release, published as `nav_dock`.

* `DockShell` and `DockPage`: bottom tab bar and app bar on compact
  screens; a thumb-reachable side column (action chips above a pill rail) on
  wide screens. Modals get the column without the rail (`DockModalScope`).
* Side column and tab bar are reported as extra safe-area padding, so
  `SafeArea` content stops beside them and full-bleed content runs under them.
* Action identity and animation: back/close is shared across pages and morphs;
  other actions animate out and in per page. Tap guard against double taps and
  taps during route transitions.
* Side column follows the window to the screen edge in split screen and
  windowing (via `window_placement`); title-bar actions follow the column.
* Every visual is a builder in `DockNavigationData`, with Material 3
  defaults in `DockDefaults`.
* iOS, iPadOS and Android.
