import 'package:flutter/widgets.dart';

import '../geometry/layout_mode.dart';
import 'tab.dart';

/// Where a tab item is drawn.
enum DuoTabPlacement {
  /// In the compact tab bar.
  bar,

  /// In the rail of the wide side column.
  rail,
}

/// What a tab bar or rail builder gets: all tabs and the selection.
///
/// The items themselves come built (see [DuoTabItemData]); the container
/// arranges them. A bar that builds its children itself from [tabs] (from a
/// list of item descriptions, say) uses [itemData] for each tab's state and
/// tap, and `wrap` (from `package:duo_navigation/duo_navigation.dart`) to give each
/// child the package's keys and semantics.
@immutable
class DuoTabsData<T> {
  /// Built by the frame.
  const DuoTabsData({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    required this.mode,
  });

  /// All tabs, in display order.
  final List<DuoTab<T>> tabs;

  /// Index of the selected tab.
  final int currentIndex;

  /// Selects the tab at an index: the shell's selection, re-selection and
  /// veto rules apply. Containers that report taps themselves (such as
  /// Material's `NavigationBar`) call it; items have their own
  /// [DuoTabItemData.onTap].
  final ValueChanged<int> onSelected;

  /// Compact (tab bar) or wide (rail).
  final DuoLayoutMode mode;

  /// Where the items are drawn.
  DuoTabPlacement get placement => mode == DuoLayoutMode.compact
      ? DuoTabPlacement.bar
      : DuoTabPlacement.rail;

  /// The item data of the tab at [index], as the package's own items get it:
  /// its selection, position and a tap that applies the shell's selection,
  /// re-selection and veto rules.
  DuoTabItemData<T> itemData(int index) {
    RangeError.checkValidIndex(index, tabs, 'index');
    return DuoTabItemData<T>(
      tab: tabs[index],
      index: index,
      count: tabs.length,
      selected: index == currentIndex,
      placement: placement,
      onTap: () => onSelected(index),
    );
  }
}

/// What a tab item builder gets: one tab, its position and selection.
///
/// The package wraps the built item with the tab's semantics (selected, label,
/// badge, tap action) and keys (`DuoKeys.tab(id)`, then [DuoTab.key]).
@immutable
class DuoTabItemData<T> {
  /// Built by the frame for each tab.
  const DuoTabItemData({
    required this.tab,
    required this.index,
    required this.count,
    required this.selected,
    required this.placement,
    required this.onTap,
  });

  /// The tab.
  final DuoTab<T> tab;

  /// The tab's position, from 0.
  final int index;

  /// How many tabs there are.
  final int count;

  /// Whether this tab is the current one.
  final bool selected;

  /// In the tab bar or in the rail.
  final DuoTabPlacement placement;

  /// Selects this tab (or re-selects it), with the shell's rules.
  final VoidCallback onTap;

  @override
  bool operator ==(Object other) =>
      other is DuoTabItemData<T> &&
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
