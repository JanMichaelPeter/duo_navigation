import 'package:flutter/widgets.dart';

import '../geometry/layout_mode.dart';
import 'tab.dart';

/// Where a tab item is drawn.
enum DockTabPlacement {
  /// In the compact tab bar.
  bar,

  /// In the rail of the wide side column.
  rail,
}

/// What a tab bar or rail builder gets: all tabs and the selection.
///
/// The items themselves come built (see [DockTabItemData]); the container
/// arranges them.
@immutable
class DockTabsData<T> {
  /// Built by the frame.
  const DockTabsData({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    required this.mode,
  });

  /// All tabs, in display order.
  final List<DockTab<T>> tabs;

  /// Index of the selected tab.
  final int currentIndex;

  /// Selects the tab at an index: the shell's selection, re-selection and
  /// veto rules apply. Containers that report taps themselves (such as
  /// Material's `NavigationBar`) call it; items have their own
  /// [DockTabItemData.onTap].
  final ValueChanged<int> onSelected;

  /// Compact (tab bar) or wide (rail).
  final DockLayoutMode mode;

  /// Where the items are drawn.
  DockTabPlacement get placement => mode == DockLayoutMode.compact
      ? DockTabPlacement.bar
      : DockTabPlacement.rail;
}

/// What a tab item builder gets: one tab, its position and selection.
///
/// The package wraps the built item with the tab's semantics (selected, label,
/// badge, tap action) and keys (`DockKeys.tab(id)`, then [DockTab.key]).
@immutable
class DockTabItemData<T> {
  /// Built by the frame for each tab.
  const DockTabItemData({
    required this.tab,
    required this.index,
    required this.count,
    required this.selected,
    required this.placement,
    required this.onTap,
  });

  /// The tab.
  final DockTab<T> tab;

  /// The tab's position, from 0.
  final int index;

  /// How many tabs there are.
  final int count;

  /// Whether this tab is the current one.
  final bool selected;

  /// In the tab bar or in the rail.
  final DockTabPlacement placement;

  /// Selects this tab (or re-selects it), with the shell's rules.
  final VoidCallback onTap;

  @override
  bool operator ==(Object other) =>
      other is DockTabItemData<T> &&
      other.tab == tab &&
      other.index == index &&
      other.count == count &&
      other.selected == selected &&
      other.placement == placement &&
      other.onTap == onTap;

  @override
  int get hashCode =>
      Object.hash(tab, index, count, selected, placement, onTap);
}
