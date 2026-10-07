import 'package:flutter/widgets.dart';

import '../models/action.dart';
import '../models/bar_data.dart';
import '../models/enums.dart';
import '../models/tabs_data.dart';

/// Builds the compact tab bar or the wide rail from [DockTabsData].
///
/// Contract:
/// * **Constraints.** The bar gets the frame's full width and its height is
///   up to the bar; the frame measures it on every layout and lays the body
///   out above it, so a bar that animates its height moves the body with it.
///   The rail gets the column's width (`sideItemExtent` plus padding is a good
///   fit) and sits at the bottom of the column.
/// * **Safe area.** The bar owns the bottom safe area: include
///   `MediaQuery.paddingOf(context).bottom` in its height (for example with
///   `SafeArea(top: false, ...)`). A debug error reports a bar that is
///   shorter. The rail is already inside the column's safe area.
/// * **Context.** Called below the shell (or modal frame), its
///   [DockBuilders] scope and `DockNavigation`: inherited widgets placed
///   around a `DockShell` are visible.
/// * **Keys.** The package wraps the result in `DockKeys.bar` /
///   `DockKeys.rail`; don't reuse those keys.
/// * **Semantics and animation** of the items belong to the builder.
typedef DockTabsBuilder =
    Widget Function(BuildContext context, DockTabsData data);

/// Builds one action. [placement] says where: the title bar's leading or
/// trailing area, or a chip in the side column.
///
/// Contract:
/// * **Callback.** `action.onPressed` is already guarded (double taps, taps
///   during transitions); call it as is. Null means disabled.
/// * **Constraints.** Chips are centered in the column; size them to
///   `DockNavigationData.sideItemExtent` to line up with the rail.
/// * **Keys.** The package wraps the result in `DockKeys.action(id)`.
/// * **Animation.** The package animates chips in and out
///   ([DockActionTransitionBuilder]); morphing between icons is up to the
///   builder.
/// * **Semantics** (button, label, enabled) belong to the builder.
typedef DockActionBuilder =
    Widget Function(
      BuildContext context,
      DockAction action,
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
typedef DockPageScaffoldBuilder =
    Widget Function(BuildContext context, DockBarData bar, Widget body);

/// Arranges the side column.
///
/// [actions] is the animated stack of action chips: give it the remaining
/// height (for example with `Expanded`); it anchors to the bottom and scrolls
/// when there are more chips than fit. [tabs] is the rail, or null in a modal
/// frame. [hasActions] is true while the page has chips in the column, for
/// example to show a separator only then; it turns false as soon as the
/// chips start animating out.
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

/// Every visual of nav_dock: the tab bar, the rail, actions, the page's
/// scaffold, the side column's arrangement and the chips' transition.
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
class DockBuilders {
  /// Builders for the given fields; null fields fall back to the scope above.
  const DockBuilders({
    this.tabBar,
    this.rail,
    this.action,
    this.page,
    this.sideColumn,
    this.actionTransition,
  });

  /// The compact tab bar.
  final DockTabsBuilder? tabBar;

  /// The rail of tabs in the wide side column.
  final DockTabsBuilder? rail;

  /// Every action, in the title bar and as a chip in the column.
  final DockActionBuilder? action;

  /// The title bar and body of each `DockPage` (not `DockPage.custom`).
  final DockPageScaffoldBuilder? page;

  /// The arrangement of chips and rail in the side column.
  final DockSideColumnBuilder? sideColumn;

  /// How chips appear in and disappear from the column.
  final DockActionTransitionBuilder? actionTransition;

  /// These builders with [other]'s non-null fields on top.
  DockBuilders merge(DockBuilders? other) {
    if (other == null) return this;
    return DockBuilders(
      tabBar: other.tabBar ?? tabBar,
      rail: other.rail ?? rail,
      action: other.action ?? action,
      page: other.page ?? page,
      sideColumn: other.sideColumn ?? sideColumn,
      actionTransition: other.actionTransition ?? actionTransition,
    );
  }

  /// The effective builders at [context]: every [DockBuildersScope] above,
  /// merged. Empty (all null) when there is none.
  static DockBuilders of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_InheritedBuilders>()
          ?.builders ??
      const DockBuilders();

  /// Builds the tab bar; throws a [FlutterError] if no scope sets [tabBar].
  Widget buildTabBar(BuildContext context, DockTabsData data) =>
      _need(tabBar, 'tabBar', context)(context, data);

  /// Builds the rail; throws a [FlutterError] if no scope sets [rail].
  Widget buildRail(BuildContext context, DockTabsData data) =>
      _need(rail, 'rail', context)(context, data);

  /// Builds an action; throws a [FlutterError] if no scope sets [action].
  Widget buildAction(
    BuildContext context,
    DockAction action,
    DockActionPlacement placement,
  ) => _need(this.action, 'action', context)(context, action, placement);

  /// Builds a page; throws a [FlutterError] if no scope sets [page].
  Widget buildPage(BuildContext context, DockBarData bar, Widget body) =>
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

  static B _need<B extends Function>(
    B? builder,
    String name,
    BuildContext context,
  ) {
    if (builder != null) return builder;
    throw FlutterError.fromParts([
      ErrorSummary('No DockBuilders.$name found.'),
      ErrorDescription(
        'nav_dock needs a $name builder to draw this part of the navigation, '
        'and no DockBuilders above sets one.',
      ),
      ErrorHint(
        'Pass builders to DockNavigation, for example the Material defaults:\n'
        "  import 'package:nav_dock/material.dart';\n"
        '  DockNavigation(builders: const DockMaterialBuilders(), child: ...)\n'
        'or set $name on DockShell, DockModalScope or a DockBuildersScope.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is DockBuilders &&
      other.tabBar == tabBar &&
      other.rail == rail &&
      other.action == action &&
      other.page == page &&
      other.sideColumn == sideColumn &&
      other.actionTransition == actionTransition;

  @override
  int get hashCode =>
      Object.hash(tabBar, rail, action, page, sideColumn, actionTransition);
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
  final DockBuilders? builders;

  /// The subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final overrides = builders;
    if (overrides == null) return child;
    return _InheritedBuilders(
      builders: DockBuilders.of(context).merge(overrides),
      child: child,
    );
  }
}

class _InheritedBuilders extends InheritedWidget {
  const _InheritedBuilders({required this.builders, required super.child});

  final DockBuilders builders;

  @override
  bool updateShouldNotify(_InheritedBuilders oldWidget) =>
      builders != oldWidget.builders;
}
