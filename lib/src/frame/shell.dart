import 'dart:async';

import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../geometry/body_mode.dart';
import '../models/tab.dart';
import 'frame.dart';

/// Wraps the tab navigators. Compact: bottom tab bar. Wide: side column with
/// the active page's actions above a rail.
///
/// Routing-agnostic: pass go_router's `StatefulNavigationShell`, a
/// `DockTabStack` of navigators, or any container as [child]. Inactive tabs
/// must be under `TickerMode(enabled: false)` (`DockTabStack` and go_router's
/// indexed stack do this) so their pages don't claim the side column.
///
/// [T] is the tabs' payload type (`DockTab<T>`); tab builders get it typed.
///
/// Push modal pages on the ROOT navigator; they then cover this shell, which
/// hides the tab bar / rail for free.
class DockShell<T> extends StatelessWidget {
  /// Frames [child] with tab bar (compact) or side column + rail (wide).
  const DockShell({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    this.onTabReselected,
    this.canSelectTab,
    this.bodyMode,
    this.builders,
    required this.child,
  });

  /// Top-level destinations, in display order.
  final List<DockTab<T>> tabs;

  /// Index of the selected tab in [tabs].
  final int currentIndex;

  /// Called with the index of a tab the user selects. Switch tabs here.
  ///
  /// Without [onTabReselected], taps on the current tab arrive here too.
  final ValueChanged<int> onTabSelected;

  /// Called with [currentIndex] when the user taps the current tab again,
  /// for example to pop to the tab's root or scroll to the top.
  final ValueChanged<int>? onTabReselected;

  /// Asked before another tab is selected; return false (or a future that
  /// completes with false) to stay, for example on unsaved changes. Not asked
  /// for re-selection.
  final FutureOr<bool> Function(int index)? canSelectTab;

  /// Whether the body is laid out beside the bar and column or under them.
  /// Null: `DockNavigationData.bodyMode`.
  final DockBodyMode? bodyMode;

  /// Builders for this shell only (its bar, rail, column and pages), on top
  /// of the app's; null fields fall back to them.
  final DockBuilders<T>? builders;

  /// The tab navigators, for example a `DockTabStack`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DockFrame<T>(
      isModal: false,
      tabs: tabs,
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      onTabReselected: onTabReselected,
      canSelectTab: canSelectTab,
      bodyMode: bodyMode,
      builders: builders,
      child: child,
    );
  }
}
