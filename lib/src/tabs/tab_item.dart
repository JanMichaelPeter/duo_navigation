import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../a11y/focus.dart';
import '../a11y/semantics.dart';
import '../builders/builders.dart';
import '../keys.dart';
import '../models/tabs_data.dart';

/// Wraps a built tab item with what the package owns: the tab's keys and its
/// semantics.
///
/// The item's own semantics are excluded and replaced by one node with the
/// tab role, the selected state, the label (`semanticLabel`, `label` or
/// `tooltip`), the badge as value, the position as hint
/// (`DuoBuilders.tabPosition`) and the tap action, so assistive technology
/// gets the same tab whatever the builder draws ([DuoSemantics.tab]).
class DuoTabItem<T> extends StatelessWidget {
  /// Wraps [child], the built item for [data].
  const DuoTabItem({super.key, required this.data, required this.child});

  /// The tab and its position.
  final DuoTabItemData<T> data;

  /// The item as the builder drew it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tab = data.tab;
    final appKey = tab.key;
    return KeyedSubtree(
      key: DuoKeys.tab(tab.id),
      child: _RevealWhenSelected(
        selected: data.selected,
        child: DuoFocusMarker(
          id: ('tab', tab.id),
          child: Semantics.fromProperties(
            container: true,
            properties: data.semanticsOf(context),
            child: ExcludeSemantics(
              child: appKey == null
                  ? child
                  : KeyedSubtree(key: appKey, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tab semantics of one item, for tab bars that build their item widgets
/// themselves.
extension DuoTabItemSemantics<T> on DuoTabItemData<T> {
  /// The semantics the package gives this tab, as a value: the tab role, the
  /// selected state, the label (`semanticLabel`, `label` or `tooltip`), the
  /// badge as value, the position as hint (`DuoBuilders.tabPosition`, read
  /// at [context]) and the tap action.
  ///
  /// For a tab bar whose item widgets are built by the bar itself, so that
  /// neither the package's items nor `DuoTabsData.wrap` can be placed: pass
  /// them to the bar's per-item semantics hook, and mark the bar with
  /// [DuoTabBarSemantics].
  ///
  /// ```dart
  /// tabBar: (context, tabs, items) => DuoTabBarSemantics(
  ///   child: MyTabBar(items: [
  ///     for (var i = 0; i < tabs.tabs.length; i++)
  ///       MyTabBarItem(
  ///         spec: tabs.tabs[i].payload! as MyTabSpec,
  ///         onTap: tabs.itemData(i).onTap,
  ///         additionalSemantics: tabs.itemData(i).semanticsOf(context),
  ///       ),
  ///   ]),
  /// )
  /// ```
  SemanticsProperties semanticsOf(BuildContext context) =>
      DuoSemantics.tabProperties(
        selected: selected,
        label: tab.semanticLabel ?? tab.label ?? tab.tooltip,
        value: tab.badge?.label,
        hint: DuoBuilders.of<Object?, Object?, Object?>(
          context,
        ).tabPosition?.call(context, index, count),
        onTap: onTap,
      );
}

/// Applies the package's per-item wrapping to children a tab bar builds
/// itself.
extension DuoTabsDataWrap<T> on DuoTabsData<T> {
  /// Wraps [child], the widget a bar built for the tab at [index], like the
  /// package wraps its own items: `DuoKeys.tab(id)` and `DuoTab.key`, and
  /// the tab's semantics (selected state, label, badge, position, tap), which
  /// replace the child's own. Use it for bars that build their children from
  /// [tabs] instead of placing the built `items`; mark the bar with
  /// [DuoTabBarSemantics].
  ///
  /// ```dart
  /// tabBar: (context, data, items) => DuoTabBarSemantics(
  ///   child: MyTabBar(children: [
  ///     for (var i = 0; i < data.tabs.length; i++)
  ///       data.wrap(i, MyTabButton(spec: data.tabs[i].payload, onTap: data.itemData(i).onTap)),
  ///   ]),
  /// )
  /// ```
  Widget wrap(int index, Widget child) =>
      DuoTabItem<T>(data: itemData(index), child: child);
}

/// Marks a tab bar or rail as a tab bar for assistive technology.
///
/// Use it in custom `tabBar` and `rail` builders, around the widget that
/// holds the items. Every semantics node directly below it must be a tab:
/// Flutter checks this and reports "Children of TabBar must have the tab
/// role" otherwise. The package's `items`, children wrapped with
/// `DuoTabsData.wrap`, and items that carry
/// `DuoTabsData.itemData(i).semanticsOf(context)` are tabs; nothing between
/// them and this widget may add nodes of its own. A bar whose items can carry
/// none of these keeps its own semantics and goes without this widget.
/// Material's `NavigationBar` marks itself and needs none.
class DuoTabBarSemantics extends StatelessWidget {
  /// Marks [child] as a tab bar.
  const DuoTabBarSemantics({super.key, required this.child});

  /// The bar or rail.
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    role: SemanticsRole.tabBar,
    explicitChildNodes: true,
    child: child,
  );
}

/// Scrolls the selected tab into view, for example in a rail that is taller
/// than the column. Does nothing where nothing scrolls.
class _RevealWhenSelected extends StatefulWidget {
  const _RevealWhenSelected({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  State<_RevealWhenSelected> createState() => _RevealWhenSelectedState();
}

class _RevealWhenSelectedState extends State<_RevealWhenSelected> {
  @override
  void initState() {
    super.initState();
    if (widget.selected) _reveal();
  }

  @override
  void didUpdateWidget(_RevealWhenSelected oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || Scrollable.maybeOf(context) == null) return;
      Scrollable.ensureVisible(context, duration: Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
