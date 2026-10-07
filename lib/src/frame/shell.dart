import 'package:flutter/widgets.dart';

import '../geometry/body_mode.dart';
import '../models/tab.dart';
import 'frame.dart';

/// Wraps the tab navigators. Compact: bottom tab bar. Wide: side column with
/// the active page's actions above a rail.
///
/// Routing-agnostic: pass e.g. go_router's `StatefulNavigationShell` as
/// [child], or your own stack of Navigators. Inactive tabs must be wrapped in
/// `TickerMode(enabled: false)` (go_router's indexedStack does this) so their
/// pages don't claim the side column.
///
/// Push modal pages on the ROOT navigator; they then cover this shell, which
/// hides the tab bar / rail for free.
class DockShell extends StatelessWidget {
  /// Frames [child] with tab bar (compact) or side column + rail (wide).
  const DockShell({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    this.bodyMode,
    required this.child,
  });

  /// Top-level destinations, in display order.
  final List<DockTab> tabs;

  /// Index of the selected tab in [tabs].
  final int currentIndex;

  /// Called with the tapped tab's index. Switch tabs here; re-taps arrive
  /// too (e.g. to pop to the tab's root).
  final ValueChanged<int> onTabSelected;

  /// Whether the body is laid out beside the bar and column or under them.
  /// Null: `DockNavigationData.bodyMode`.
  final DockBodyMode? bodyMode;

  /// The tab navigators, e.g. go_router's `StatefulNavigationShell`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DockFrame(
      isModal: false,
      tabs: tabs,
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      bodyMode: bodyMode,
      child: child,
    );
  }
}
