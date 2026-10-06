import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'tab.dart';

/// Everything a tab bar or rail builder needs.
@immutable
class DockTabsData {
  /// Built by the frame and passed to the tab bar and rail builders.
  const DockTabsData({
    required this.tabs,
    required this.currentIndex,
    required this.onSelected,
    required this.mode,
  });

  /// All tabs, in display order.
  final List<DockTab> tabs;

  /// Index of the selected tab.
  final int currentIndex;

  /// Call with a tab's index when it's tapped.
  final ValueChanged<int> onSelected;

  /// Compact (tab bar) or wide (rail).
  final DockLayoutMode mode;
}
