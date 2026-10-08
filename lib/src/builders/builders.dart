import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/action.dart';
import '../models/bar_data.dart';
import '../models/enums.dart';
import '../models/tabs_data.dart';

/// Builds one tab item, in the tab bar or in the rail
/// ([DockTabItemData.placement]).
///
/// Contract:
/// * **Tap.** Call [DockTabItemData.onTap]; it applies the shell's selection,
///   re-selection and veto rules.
/// * **Semantics.** The package wraps the item with the tab's semantics
///   (selected state, label, badge, tap action) and excludes the item's own,
///   so assistive technology gets the same tab whatever the builder draws.
/// * **Keys.** The package wraps the item in `DockKeys.tab(id)` and then in
///   `DockTab.key`.
/// * **Visuals and animation** (selection, badge) belong to the builder.
typedef DockTabItemBuilder<T> =
    Widget Function(BuildContext context, DockTabItemData<T> data);

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
///   `SafeArea(top: false, ...)`). A debug error reports a bar that is
///   shorter. The rail is already inside the column's safe area.
/// * **Context.** Called below the shell (or modal frame), its
///   [DockBuilders] scope and `DockNavigation`: inherited widgets placed
///   around a `DockShell` are visible.
/// * **Keys and semantics.** The package wraps the result in `DockKeys.bar` /
///   `DockKeys.rail` and each item in its tab semantics; keep [items] as they
///   are. Mark the widget that holds them with `DockTabBarSemantics` (Material's
///   `NavigationBar` marks itself), and add no semantics nodes between it and
///   the items.
typedef DockTabsBuilder<T> =
    Widget Function(
      BuildContext context,
      DockTabsData<T> data,
      List<Widget> items,
    );

/// Builds one action. [placement] says where: the title bar's leading or
/// trailing area, or a chip in the side column.
///
/// Contract:
/// * **Callback.** `action.onPressed` is already guarded (double taps, taps
///   during transitions); call it as is. Null means disabled (also when
///   `action.enabled` is false).
/// * **Icons.** `action.icon` is a `DockIcon`; resolve [DockIcon.back] and
///   [DockIcon.close] in your design system (`DockMaterial.icon` does).
/// * **Constraints.** Chips are centered in the column; size them to
///   `DockNavigationData.sideItemExtent` to line up with the rail.
/// * **Keys.** The package wraps the result in `DockKeys.action(id)`.
/// * **Animation.** The package animates chips in and out
///   ([DockActionTransitionBuilder]); morphing between icons is up to the
///   builder.
/// * **Semantics** (button, label, enabled) belong to the builder.
typedef DockActionBuilder<A> =
    Widget Function(
      BuildContext context,
      DockAction<A> action,
      DockActionPlacement placement,
    );

/// Builds a `DockPage` around its body: a title bar from [DockBarData], then
/// [body].
///
/// Contract:
/// * **Bar.** In wide mode the actions that moved into the column are in
///   `bar.hoisted`, not in `bar.leading` / `bar.trailing`. When
///   `bar.trailingAtStart` is true the column is at the start edge and the
///   bar's actions belong at the start too.
/// * **Actions.** Render them with `bar.buildAction`, which applies the
///   action builder and the keys.
/// * **Safe area, semantics, keys and animation** of the page belong to the
///   builder, as with any `Scaffold`.
typedef DockPageScaffoldBuilder<A> =
    Widget Function(BuildContext context, DockBarData<A> bar, Widget body);

/// Arranges the side column.
///
/// [actions] is the animated stack of action chips: give it the remaining
/// height; it anchors to the bottom and scrolls when there are more chips
/// than fit. [tabs] is the rail, or null in a modal frame. [hasActions] is
/// true while the page has chips in the column, for example to show a
/// separator only then; it turns false as soon as the chips start animating
/// out. `DockSideColumnLayout` gives the rail its height first and the
/// actions the rest.
///
/// Contract:
/// * **Constraints.** Tight: the column's width and the frame's height.
/// * **Safe area.** The package keeps the content clear of the system insets
///   (status bar, home indicator, the cutout on the column's edge).
/// * **Keys.** The package wraps the column in `DockKeys.column`.
typedef DockSideColumnBuilder =
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
typedef DockActionTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Widget child,
    );

/// Every visual of nav_dock: tab items, the tab bar, the rail, actions, the
/// page's scaffold, the side column's arrangement and the chips' transition.
///
/// [T] is the tabs' payload type (`DockTab<T>`) and [A] the actions'
/// (`DockAction<A>`); the builders get them typed. Builders written for
/// `Object?` (such as `DockMaterialBuilders`) work for any payload types.
///
/// Provide them on `DockNavigation(builders: ...)` for the app and override
/// them on `DockShell(builders: ...)`, `DockModalScope(builders: ...)` or any
/// subtree with [DockBuildersScope]. The nearest scope wins, field by field: a
/// field left null falls back to the scope above. A field that is null all
/// the way up fails with a [FlutterError] when it is needed.
///
/// `DockMaterialBuilders()` in `package:nav_dock/material.dart` sets every
/// field to the Material defaults.
@immutable
class DockBuilders<T, A> {
  /// Builders for the given fields; null fields fall back to the scope above.
  const DockBuilders({
    this.tabItem,
    this.tabBar,
    this.rail,
    this.action,
    this.page,
    this.sideColumn,
    this.actionTransition,
  });

  /// One tab item, in the bar or in the rail.
  final DockTabItemBuilder<T>? tabItem;

  /// The compact tab bar, arranging the items.
  final DockTabsBuilder<T>? tabBar;

  /// The rail of tabs in the wide side column, arranging the items.
  final DockTabsBuilder<T>? rail;

  /// Every action, in the title bar and as a chip in the column.
  final DockActionBuilder<A>? action;

  /// The title bar and body of each `DockPage` (not `DockPage.custom`).
  final DockPageScaffoldBuilder<A>? page;

  /// The arrangement of chips and rail in the side column.
  final DockSideColumnBuilder? sideColumn;

  /// How chips appear in and disappear from the column.
  final DockActionTransitionBuilder? actionTransition;

  /// These builders with [other]'s non-null fields on top.
  ///
  /// [other] may be written for other payload types as long as its builders
  /// accept [T] and [A] (for example `Object?` builders); otherwise this
  /// throws an [ArgumentError] naming the fields.
  DockBuilders<T, A> merge(DockBuilders<Object?, Object?>? other) {
    if (other == null) return this;
    final dropped = <String>[];
    final top = other._adapt<T, A>(dropped);
    if (dropped.isNotEmpty) {
      throw ArgumentError.value(
        other,
        'other',
        'The ${dropped.join(', ')} builders of ${other.runtimeType} do not '
            'accept DockTab<$T> and DockAction<$A>',
      );
    }
    return top._over(this);
  }

  // Reads this object's own fields, so the type checks of the function-typed
  // fields always pass.
  DockBuilders<T, A> _over(DockBuilders<T, A> below) => DockBuilders<T, A>(
    tabItem: tabItem ?? below.tabItem,
    tabBar: tabBar ?? below.tabBar,
    rail: rail ?? below.rail,
    action: action ?? below.action,
    page: page ?? below.page,
    sideColumn: sideColumn ?? below.sideColumn,
    actionTransition: actionTransition ?? below.actionTransition,
  );

  /// These builders for tabs of type [S] and actions of type [B], field by
  /// field. Builders that don't accept them are left out and their names
  /// added to [dropped].
  ///
  /// Always builds a new object: with covariant generics a
  /// `DockBuilders<Sub, Sub>` passes an `is DockBuilders<Object?, Object?>`
  /// check while its builders accept only `Sub`, so only the fields
  /// themselves can tell.
  DockBuilders<S, B> _adapt<S, B>(List<String> dropped) {
    F? fit<F>(Object? builder, String name) {
      if (builder == null) return null;
      if (builder is F) return builder as F;
      dropped.add(name);
      return null;
    }

    return DockBuilders<S, B>(
      tabItem: fit<DockTabItemBuilder<S>>(tabItem, 'tabItem'),
      tabBar: fit<DockTabsBuilder<S>>(tabBar, 'tabBar'),
      rail: fit<DockTabsBuilder<S>>(rail, 'rail'),
      action: fit<DockActionBuilder<B>>(action, 'action'),
      page: fit<DockPageScaffoldBuilder<B>>(page, 'page'),
      sideColumn: sideColumn,
      actionTransition: actionTransition,
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
  ];

  /// The effective builders at [context] for tabs of type [T] and actions of
  /// type [A]: every [DockBuildersScope] above, merged, nearest on top. Empty
  /// (all null) when there is none.
  static DockBuilders<T, A> of<T, A>(BuildContext context) {
    final layers =
        context
            .dependOnInheritedWidgetOfExactType<_InheritedBuilders>()
            ?.layers ??
        const [];
    var result = DockBuilders<T, A>();
    final dropped = <String, Type>{};
    for (final layer in layers) {
      final names = <String>[];
      result = layer._adapt<T, A>(names)._over(result);
      for (final name in names) {
        dropped[name] = layer.runtimeType;
      }
    }
    return dropped.isEmpty ? result : _WithDropped<T, A>(result, dropped);
  }

  /// Fields that a scope above sets for another payload type; for the error.
  Map<String, Type> get _dropped => const {};

  /// Builds a tab item; throws a [FlutterError] if no scope sets [tabItem].
  Widget buildTabItem(BuildContext context, DockTabItemData<T> data) =>
      _need(tabItem, 'tabItem', context)(context, data);

  /// Builds the tab bar; throws a [FlutterError] if no scope sets [tabBar].
  Widget buildTabBar(
    BuildContext context,
    DockTabsData<T> data,
    List<Widget> items,
  ) => _need(tabBar, 'tabBar', context)(context, data, items);

  /// Builds the rail; throws a [FlutterError] if no scope sets [rail].
  Widget buildRail(
    BuildContext context,
    DockTabsData<T> data,
    List<Widget> items,
  ) => _need(rail, 'rail', context)(context, data, items);

  /// Builds an action; throws a [FlutterError] if no scope sets [action].
  Widget buildAction(
    BuildContext context,
    DockAction<A> action,
    DockActionPlacement placement,
  ) => _need(this.action, 'action', context)(context, action, placement);

  /// Builds a page; throws a [FlutterError] if no scope sets [page].
  Widget buildPage(BuildContext context, DockBarData<A> bar, Widget body) =>
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

  B _need<B extends Function>(B? builder, String name, BuildContext context) {
    if (builder != null) return builder;
    final other = _dropped[name];
    throw FlutterError.fromParts([
      ErrorSummary('No DockBuilders.$name found.'),
      if (other != null)
        ErrorDescription(
          'A scope above sets $name in a $other, but its builder does not '
          'accept the payload types here: DockTab<$T>, DockAction<$A>.',
        )
      else
        ErrorDescription(
          'nav_dock needs a $name builder to draw this part of the '
          'navigation, and no DockBuilders above sets one.',
        ),
      ErrorHint(
        'Pass builders to DockNavigation, for example the Material defaults:\n'
        "  import 'package:nav_dock/material.dart';\n"
        '  DockNavigation(builders: const DockMaterialBuilders(), child: ...)\n'
        'or set $name on DockShell, DockModalScope or a DockBuildersScope. '
        'Builders written for Object? payloads work for every payload type.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is DockBuilders<Object?, Object?> &&
      listEquals(other._fields, _fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// Effective builders that also remember which fields a scope set for
/// another payload type, for the error message.
class _WithDropped<T, A> extends DockBuilders<T, A> {
  _WithDropped(DockBuilders<T, A> builders, this._droppedFields)
    : super(
        tabItem: builders.tabItem,
        tabBar: builders.tabBar,
        rail: builders.rail,
        action: builders.action,
        page: builders.page,
        sideColumn: builders.sideColumn,
        actionTransition: builders.actionTransition,
      );

  final Map<String, Type> _droppedFields;

  @override
  Map<String, Type> get _dropped => _droppedFields;
}

/// Overrides [builders] for [child]: its non-null fields win over the scopes
/// above, field by field.
///
/// `DockNavigation`, `DockShell` and `DockModalScope` insert one for their
/// `builders`; use it directly for any other subtree.
class DockBuildersScope extends StatelessWidget {
  /// Applies [builders] on top of the scopes above to [child].
  const DockBuildersScope({
    super.key,
    required this.builders,
    required this.child,
  });

  /// The overrides. Null fields fall back to the scope above.
  final DockBuilders<Object?, Object?>? builders;

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
  final List<DockBuilders<Object?, Object?>> layers;

  @override
  bool updateShouldNotify(_InheritedBuilders oldWidget) =>
      !listEquals(layers, oldWidget.layers);
}
