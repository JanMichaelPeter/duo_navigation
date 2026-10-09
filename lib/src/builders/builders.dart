import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/action.dart';
import '../models/bar_data.dart';
import '../models/enums.dart';
import '../models/tabs_data.dart';

/// Builds one tab item, in the tab bar or in the rail
/// ([DuoTabItemData.placement]).
///
/// Contract:
/// * **Tap.** Call [DuoTabItemData.onTap]; it applies the shell's selection,
///   re-selection and veto rules.
/// * **Semantics.** The package wraps the item with the tab's semantics
///   (selected state, label, badge, tap action) and excludes the item's own,
///   so assistive technology gets the same tab whatever the builder draws.
/// * **Keys.** The package wraps the item in `DuoKeys.tab(id)` and then in
///   `DuoTab.key`.
/// * **Visuals and animation** (selection, badge) belong to the builder.
typedef DuoTabItemBuilder<T> =
    Widget Function(BuildContext context, DuoTabItemData<T> data);

/// Arranges the built tab [items] into the compact tab bar or the wide rail.
///
/// Contract:
/// * **Constraints.** The bar gets the frame's full width and its height is
///   up to the bar; the frame measures it on every layout and lays the body
///   out above it, so a bar that animates its height moves the body with it.
///   The rail gets the column's width and as much height as the column has;
///   when the tabs don't fit, the package scrolls the rail and keeps the
///   selected tab visible.
/// * **Safe area.** The bar owns the bottom safe area: include
///   `MediaQuery.paddingOf(context).bottom` in its height (for example with
///   `SafeArea`). A debug error reports a bar that is shorter. The bar's
///   `MediaQuery` has no top padding (the status bar is above the page), so
///   a `SafeArea` around the bar adds only the bottom and side insets. The
///   rail is already inside the column's safe area.
/// * **Context.** Called below the shell (or modal frame), its
///   [DuoBuilders] scope and `DuoNavigation`: inherited widgets placed
///   around a `DuoShell` are visible.
/// * **Keys and semantics.** The package wraps the result in `DuoKeys.bar` /
///   `DuoKeys.rail` and each item in its tab semantics; keep [items] as they
///   are. Mark the widget that holds them with `DuoTabBarSemantics` (Material's
///   `NavigationBar` marks itself), and add no semantics nodes between it and
///   the items.
/// * **Bars built from data.** A bar that builds its own children from
///   `data.tabs` (and their payloads) instead of placing [items] wraps each
///   child with `data.wrap(index, child)`, which applies the same keys and
///   semantics, and calls `data.itemData(index).onTap` (or
///   [DuoTabsData.onSelected]) for taps, so selection, re-selection and
///   vetoes follow the shell's rules. The `tabItem` builder is then not
///   needed for the bar.
typedef DuoTabsBuilder<T> =
    Widget Function(
      BuildContext context,
      DuoTabsData<T> data,
      List<Widget> items,
    );

/// Builds one action. [placement] says where: the title bar's leading or
/// trailing area, or a chip in the side column.
///
/// Contract:
/// * **Callback.** `action.onPressed` is already guarded (double taps, taps
///   during transitions); call it as is. Null means disabled (also when
///   `action.enabled` is false).
/// * **Icons.** `action.icon` is a `DuoIcon`; resolve [DuoIcon.back] and
///   [DuoIcon.close] in your design system (`DuoMaterial.icon` does).
/// * **Constraints.** Chips are centered in the column; size them to
///   `DuoNavigationData.sideItemExtent` to line up with the rail.
/// * **Keys.** The package wraps the result in `DuoKeys.action(id)`.
/// * **Animation.** The package animates chips in and out
///   ([DuoActionTransitionBuilder]); morphing between icons is up to the
///   builder.
/// * **Semantics** (button, label, enabled) belong to the builder.
typedef DuoActionBuilder<A> =
    Widget Function(
      BuildContext context,
      DuoAction<A> action,
      DuoActionPlacement placement,
    );

/// Builds a `DuoPage` around its body: a title bar from [DuoBarData], then
/// [body].
///
/// Contract:
/// * **Bar.** In wide mode the actions that moved into the column are in
///   `bar.hoisted`, not in `bar.leading` / `bar.trailing`. When
///   `bar.trailingAtStart` is true the column is at the start edge and the
///   bar's actions belong at the start too. When `bar.leadingAtEnd` is
///   true the leading action belongs at the end edge. `DuoBarLayout` does
///   both.
/// * **Actions.** Render them with `bar.buildAction`, which applies the
///   action builder and the keys.
/// * **Context.** Called below the page's `DuoPageScope`, so widgets in the
///   page (such as `DuoAppBar`) can read `DuoBarData.of(context)` too.
/// * **Safe area, semantics, keys and animation** of the page belong to the
///   builder, as with any `Scaffold`.
typedef DuoPageScaffoldBuilder<A, B> =
    Widget Function(BuildContext context, DuoBarData<A, B> bar, Widget body);

/// Arranges the side column.
///
/// [actions] is the animated stack of action chips: give it the remaining
/// height; it anchors to the bottom and scrolls when there are more chips
/// than fit. [tabs] is the rail, or null in a modal frame. [hasActions] is
/// true while the page has chips in the column, for example to show a
/// separator only then; it turns false as soon as the chips start animating
/// out. `DuoSideColumnLayout` gives the rail its height first and the
/// actions the rest.
///
/// Contract:
/// * **Constraints.** Tight: the column's width and the frame's height.
/// * **Safe area.** The package keeps the content clear of the status bar
///   and the home indicator. On the column's own edge it depends on
///   `DuoNavigationData.columnInset`: with `overlap` (the default) the
///   column is over the system inset and its `MediaQuery.padding` there is
///   zero; with `safeArea` the content stays clear of it.
/// * **Keys.** The package wraps the column in `DuoKeys.column`.
typedef DuoSideColumnBuilder =
    Widget Function(
      BuildContext context,
      Widget actions,
      Widget? tabs,
      bool hasActions,
    );

/// Animates a side-column chip in ([animation] 0 → 1) and out (1 → 0).
///
/// The package owns the timing (`actionAnimationDuration`,
/// `actionAnimationCurve`) and ignores pointers on chips that are leaving;
/// the builder owns how the transition looks.
typedef DuoActionTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Widget child,
    );

/// Paints a frame's default backdrop: the background under the body, the
/// tab bar and the side column.
///
/// Contract:
/// * **Constraints.** Tight to the whole frame, system insets included.
/// * **Why.** In `DuoBodyMode.inset` the body stops at the chrome, so the
///   strip behind a bar or column that doesn't fill it edge to edge (a
///   floating capsule, round chips) shows this backdrop. Without one it shows
///   whatever is behind the frame, often the bare (black) window.
/// * **Replaced** by `DuoShell.backdrop`, `DuoModalScope.backdrop` and a
///   page's own backdrop while they are set.
typedef DuoBackdropBuilder = Widget Function(BuildContext context);

/// The position of a tab for assistive technology, such as "Tab 2 of 3".
/// [index] counts from 0.
typedef DuoTabPositionLabel =
    String Function(BuildContext context, int index, int count);

/// A label for assistive technology for an action that has no
/// `semanticLabel`, `tooltip` or `label` of its own (such as the implied back
/// and close actions), or null.
typedef DuoActionLabel =
    String? Function(BuildContext context, DuoAction<Object?> action);

/// Every visual of duo_navigation: tab items, the tab bar, the rail, actions, the
/// page's scaffold, the side column's arrangement, the chips' transition and
/// the frame's default backdrop.
///
/// [T] is the tabs' payload type (`DuoTab<T>`), [A] the actions'
/// (`DuoAction<A>`) and [B] the title bar's (`DuoBarData<A, B>.payload`);
/// the builders get them typed. Builders written for `Object?` (such as
/// `DuoMaterialBuilders`) work for any payload types.
///
/// Provide them on `DuoNavigation(builders: ...)` for the app and override
/// them on `DuoShell(builders: ...)`, `DuoModalScope(builders: ...)` or any
/// subtree with [DuoBuildersScope]. The nearest scope wins, field by field: a
/// field left null falls back to the scope above. A field that is null all
/// the way up fails with a [FlutterError] when it is needed.
///
/// `DuoMaterialBuilders()` in `package:duo_navigation/material.dart` sets every
/// field to the Material defaults.
@immutable
class DuoBuilders<T, A, B> {
  /// Builders for the given fields; null fields fall back to the scope above.
  const DuoBuilders({
    this.tabItem,
    this.tabBar,
    this.rail,
    this.action,
    this.page,
    this.sideColumn,
    this.actionTransition,
    this.backdrop,
    this.tabPosition,
    this.actionLabel,
  });

  /// One tab item, in the bar or in the rail.
  final DuoTabItemBuilder<T>? tabItem;

  /// The compact tab bar, arranging the items.
  final DuoTabsBuilder<T>? tabBar;

  /// The rail of tabs in the wide side column, arranging the items.
  final DuoTabsBuilder<T>? rail;

  /// Every action, in the title bar and as a chip in the column.
  final DuoActionBuilder<A>? action;

  /// The title bar and body of each `DuoPage` (not `DuoPage.custom`).
  final DuoPageScaffoldBuilder<A, B>? page;

  /// The arrangement of chips and rail in the side column.
  final DuoSideColumnBuilder? sideColumn;

  /// How chips appear in and disappear from the column.
  final DuoActionTransitionBuilder? actionTransition;

  /// The background of every frame without a backdrop of its own. Null: none,
  /// the frame paints nothing behind its chrome.
  final DuoBackdropBuilder? backdrop;

  /// The localized position of a tab, read after its label. Null: none.
  final DuoTabPositionLabel? tabPosition;

  /// Localized labels for actions without one of their own. Null: none.
  final DuoActionLabel? actionLabel;

  /// These builders with [other]'s non-null fields on top.
  ///
  /// [other] may be written for other payload types as long as its builders
  /// accept [T] and [A] (for example `Object?` builders); otherwise this
  /// throws an [ArgumentError] naming the fields.
  DuoBuilders<T, A, B> merge(DuoBuilders<Object?, Object?, Object?>? other) {
    if (other == null) return this;
    final dropped = <String>[];
    final top = other._adapt<T, A, B>(dropped);
    if (dropped.isNotEmpty) {
      throw ArgumentError.value(
        other,
        'other',
        'The ${dropped.join(', ')} builders of ${other.runtimeType} do not '
            'accept DuoTab<$T>, DuoAction<$A> and DuoBarData<$A, $B>',
      );
    }
    return top._over(this);
  }

  // Reads this object's own fields, so the type checks of the function-typed
  // fields always pass.
  DuoBuilders<T, A, B> _over(DuoBuilders<T, A, B> below) =>
      DuoBuilders<T, A, B>(
        tabItem: tabItem ?? below.tabItem,
        tabBar: tabBar ?? below.tabBar,
        rail: rail ?? below.rail,
        action: action ?? below.action,
        page: page ?? below.page,
        sideColumn: sideColumn ?? below.sideColumn,
        actionTransition: actionTransition ?? below.actionTransition,
        backdrop: backdrop ?? below.backdrop,
        tabPosition: tabPosition ?? below.tabPosition,
        actionLabel: actionLabel ?? below.actionLabel,
      );

  /// These builders for tabs of type [S], actions of type [P] and bar
  /// payloads of type [Q], field by field. Builders that don't accept them are
  /// left out and their names added to [dropped].
  ///
  /// Always builds a new object: with covariant generics a
  /// `DuoBuilders<Sub, Sub, Sub>` passes an
  /// `is DuoBuilders<Object?, Object?, Object?>` check while its builders
  /// accept only `Sub`, so only the fields themselves can tell.
  DuoBuilders<S, P, Q> _adapt<S, P, Q>(List<String> dropped) {
    F? fit<F>(Object? builder, String name) {
      if (builder == null) return null;
      if (builder is F) return builder as F;
      dropped.add(name);
      return null;
    }

    return DuoBuilders<S, P, Q>(
      tabItem: fit<DuoTabItemBuilder<S>>(tabItem, 'tabItem'),
      tabBar: fit<DuoTabsBuilder<S>>(tabBar, 'tabBar'),
      rail: fit<DuoTabsBuilder<S>>(rail, 'rail'),
      action: fit<DuoActionBuilder<P>>(action, 'action'),
      page: fit<DuoPageScaffoldBuilder<P, Q>>(page, 'page'),
      sideColumn: sideColumn,
      actionTransition: actionTransition,
      backdrop: backdrop,
      tabPosition: tabPosition,
      actionLabel: actionLabel,
    );
  }

  List<Object?> get _fields => [
    tabItem,
    tabBar,
    rail,
    action,
    page,
    sideColumn,
    actionTransition,
    backdrop,
    tabPosition,
    actionLabel,
  ];

  /// The effective builders at [context] for tabs of type [T], actions of
  /// type [A] and bar payloads of type [B]: every [DuoBuildersScope] above,
  /// merged, nearest on top. Empty (all null) when there is none.
  static DuoBuilders<T, A, B> of<T, A, B>(BuildContext context) {
    final layers =
        context
            .dependOnInheritedWidgetOfExactType<_InheritedBuilders>()
            ?.layers ??
        const [];
    var result = DuoBuilders<T, A, B>();
    final dropped = <String, Type>{};
    for (final layer in layers) {
      final names = <String>[];
      result = layer._adapt<T, A, B>(names)._over(result);
      for (final name in names) {
        dropped[name] = layer.runtimeType;
      }
    }
    return dropped.isEmpty ? result : _WithDropped<T, A, B>(result, dropped);
  }

  /// Fields that a scope above sets for another payload type; for the error.
  Map<String, Type> get _dropped => const {};

  /// Builds a tab item; throws a [FlutterError] if no scope sets [tabItem].
  Widget buildTabItem(BuildContext context, DuoTabItemData<T> data) =>
      _need(tabItem, 'tabItem', context)(context, data);

  /// Builds the tab bar; throws a [FlutterError] if no scope sets [tabBar].
  Widget buildTabBar(
    BuildContext context,
    DuoTabsData<T> data,
    List<Widget> items,
  ) => _need(tabBar, 'tabBar', context)(context, data, items);

  /// Builds the rail; throws a [FlutterError] if no scope sets [rail].
  Widget buildRail(
    BuildContext context,
    DuoTabsData<T> data,
    List<Widget> items,
  ) => _need(rail, 'rail', context)(context, data, items);

  /// Builds an action; throws a [FlutterError] if no scope sets [action].
  Widget buildAction(
    BuildContext context,
    DuoAction<A> action,
    DuoActionPlacement placement,
  ) => _need(this.action, 'action', context)(context, action, placement);

  /// Builds a page; throws a [FlutterError] if no scope sets [page].
  Widget buildPage(BuildContext context, DuoBarData<A, B> bar, Widget body) =>
      _need(page, 'page', context)(context, bar, body);

  /// Arranges the column; throws a [FlutterError] if no scope sets
  /// [sideColumn].
  Widget buildSideColumn(
    BuildContext context,
    Widget actions,
    Widget? tabs,
    bool hasActions,
  ) => _need(sideColumn, 'sideColumn', context)(
    context,
    actions,
    tabs,
    hasActions,
  );

  /// Animates a chip; throws a [FlutterError] if no scope sets
  /// [actionTransition].
  Widget buildActionTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) => _need(actionTransition, 'actionTransition', context)(
    context,
    animation,
    child,
  );

  F _need<F extends Function>(F? builder, String name, BuildContext context) {
    if (builder != null) return builder;
    final other = _dropped[name];
    throw FlutterError.fromParts([
      ErrorSummary('No DuoBuilders.$name found.'),
      if (other != null)
        ErrorDescription(
          'A scope above sets $name in a $other, but its builder does not '
          'accept the payload types here: DuoTab<$T>, DuoAction<$A>, '
          'DuoBarData<$A, $B>.',
        )
      else
        ErrorDescription(
          'duo_navigation needs a $name builder to draw this part of the '
          'navigation, and no DuoBuilders above sets one.',
        ),
      ErrorHint(
        'Pass builders to DuoNavigation, for example the Material defaults:\n'
        "  import 'package:duo_navigation/material.dart';\n"
        '  DuoNavigation(builders: const DuoMaterialBuilders(), child: ...)\n'
        'or set $name on DuoShell, DuoModalScope or a DuoBuildersScope. '
        'Builders written for Object? payloads work for every payload type.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is DuoBuilders<Object?, Object?, Object?> &&
      listEquals(other._fields, _fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// Effective builders that also remember which fields a scope set for
/// another payload type, for the error message.
class _WithDropped<T, A, B> extends DuoBuilders<T, A, B> {
  _WithDropped(DuoBuilders<T, A, B> builders, this._droppedFields)
    : super(
        tabItem: builders.tabItem,
        tabBar: builders.tabBar,
        rail: builders.rail,
        action: builders.action,
        page: builders.page,
        sideColumn: builders.sideColumn,
        actionTransition: builders.actionTransition,
        backdrop: builders.backdrop,
        tabPosition: builders.tabPosition,
        actionLabel: builders.actionLabel,
      );

  final Map<String, Type> _droppedFields;

  @override
  Map<String, Type> get _dropped => _droppedFields;
}

/// Overrides [builders] for [child]: its non-null fields win over the scopes
/// above, field by field.
///
/// `DuoNavigation`, `DuoShell` and `DuoModalScope` insert one for their
/// `builders`; use it directly for any other subtree.
class DuoBuildersScope extends StatelessWidget {
  /// Applies [builders] on top of the scopes above to [child].
  const DuoBuildersScope({
    super.key,
    required this.builders,
    required this.child,
  });

  /// The overrides. Null fields fall back to the scope above.
  final DuoBuilders<Object?, Object?, Object?>? builders;

  /// The subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final overrides = builders;
    if (overrides == null) return child;
    final above = context
        .dependOnInheritedWidgetOfExactType<_InheritedBuilders>();
    return _InheritedBuilders(
      layers: [...?above?.layers, overrides],
      child: child,
    );
  }
}

class _InheritedBuilders extends InheritedWidget {
  const _InheritedBuilders({required this.layers, required super.child});

  /// The scopes' builders, outermost first.
  final List<DuoBuilders<Object?, Object?, Object?>> layers;

  @override
  bool updateShouldNotify(_InheritedBuilders oldWidget) =>
      !listEquals(layers, oldWidget.layers);
}
