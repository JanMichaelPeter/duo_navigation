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
/// (`DockBuilders.tabPosition`) and the tap action, so assistive technology
/// gets the same tab whatever the builder draws ([DockSemantics.tab]).
class DockTabItem<T> extends StatelessWidget {
  /// Wraps [child], the built item for [data].
  const DockTabItem({super.key, required this.data, required this.child});

  /// The tab and its position.
  final DockTabItemData<T> data;

  /// The item as the builder drew it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tab = data.tab;
    final appKey = tab.key;
    return KeyedSubtree(
      key: DockKeys.tab(tab.id),
      child: _RevealWhenSelected(
        selected: data.selected,
        child: DockFocusMarker(
          id: ('tab', tab.id),
          child: DockSemantics.tab(
            selected: data.selected,
            label: tab.semanticLabel ?? tab.label ?? tab.tooltip,
            value: tab.badge?.label,
            hint: DockBuilders.of<Object?, Object?, Object?>(
              context,
            ).tabPosition?.call(context, data.index, data.count),
            onTap: data.onTap,
            child: appKey == null
                ? child
                : KeyedSubtree(key: appKey, child: child),
          ),
        ),
      ),
    );
  }
}

/// Applies the package's per-item wrapping to children a tab bar builds
/// itself.
extension DockTabsDataWrap<T> on DockTabsData<T> {
  /// Wraps [child], the widget a bar built for the tab at [index], like the
  /// package wraps its own items: `DockKeys.tab(id)` and `DockTab.key`, and
  /// the tab's semantics (selected state, label, badge, position, tap), which
  /// replace the child's own. Use it for bars that build their children from
  /// [tabs] instead of placing the built `items`; mark the bar with
  /// [DockTabBarSemantics].
  ///
  /// ```dart
  /// tabBar: (context, data, items) => DockTabBarSemantics(
  ///   child: MyTabBar(children: [
  ///     for (var i = 0; i < data.tabs.length; i++)
  ///       data.wrap(i, MyTabButton(spec: data.tabs[i].payload, onTap: data.itemData(i).onTap)),
  ///   ]),
  /// )
  /// ```
  Widget wrap(int index, Widget child) =>
      DockTabItem<T>(data: itemData(index), child: child);
}

/// Marks a tab bar or rail as a tab bar for assistive technology.
///
/// Use it in custom `tabBar` and `rail` builders, around the widget that
/// holds the items. Nothing between it and the items may add semantics nodes
/// of its own (the items carry the tab role). Material's `NavigationBar`
/// marks itself and needs none.
class DockTabBarSemantics extends StatelessWidget {
  /// Marks [child] as a tab bar.
  const DockTabBarSemantics({super.key, required this.child});

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
