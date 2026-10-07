// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../actions/action_host.dart';
import '../config/navigation.dart';
import '../models/tab.dart';
import '../models/tabs_data.dart';
import 'frame_layout.dart';
import 'obstructed_body.dart';
import 'side_column.dart';
import '../geometry/side.dart';
import '../geometry/layout_mode.dart';

/// Exposes the current layout mode and action host to pages.
class DockScope extends InheritedWidget {
  const DockScope._({
    required this.mode,
    required this.host,
    required this.isModal,
    required this.side,
    required super.child,
  });

  /// Compact or wide, decided by the layout policy.
  final DockLayoutMode mode;

  /// Edge the side column is on (after window-edge resolution), relative to
  /// [Directionality]. Only meaningful in wide mode.
  final DockSide side;

  /// Collects the actions of the pages in this frame.
  final DockActionHost host;

  /// True for an [DockModalScope] (no tabs), false inside an DockShell.
  final bool isModal;

  /// The nearest scope, or null outside any shell or modal frame.
  static DockScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DockScope>();

  /// Current mode; outside any scope it is [DockNavigation.modeOf].
  static DockLayoutMode modeOf(BuildContext context) =>
      maybeOf(context)?.mode ?? DockNavigation.modeOf(context);

  @override
  bool updateShouldNotify(DockScope oldWidget) =>
      mode != oldWidget.mode ||
      host != oldWidget.host ||
      isModal != oldWidget.isModal ||
      side != oldWidget.side;
}

/// Shared implementation of the shell and modal frames. Not exported.
class DockFrame extends StatefulWidget {
  const DockFrame({
    super.key,
    required this.isModal,
    required this.child,
    this.tabs,
    this.currentIndex = 0,
    this.onTabSelected,
  });

  final bool isModal;
  final Widget child;
  final List<DockTab>? tabs;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  State<DockFrame> createState() => _DockFrameState();
}

class _DockFrameState extends State<DockFrame> {
  final DockActionHost _host = DockActionHost();

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = DockNavigation.of(context);
    _host.tapCooldown = config.tapCooldown;
    final padding = MediaQuery.paddingOf(context);
    final window = MediaQuery.sizeOf(context);
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final sideOnRight = DockNavigation.sideOnRight(context);
    final systemInset = sideOnRight ? padding.right : padding.left;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = config.layoutPolicy.resolve(
          window: window,
          frame: constraints.biggest,
        );
        final wide = mode == DockLayoutMode.wide;
        final tabs = widget.tabs == null
            ? null
            : DockTabsData(
                tabs: widget.tabs!,
                currentIndex: widget.currentIndex,
                onSelected: widget.onTabSelected ?? (_) {},
                mode: mode,
              );

        return DockScope._(
          mode: mode,
          host: _host,
          isModal: widget.isModal,
          side: sideOnRight == ltr ? DockSide.end : DockSide.start,
          child: CustomMultiChildLayout(
            delegate: FrameLayout(
              wide: wide,
              // The column sits inside the system inset on its edge (notch,
              // reserved side strip) rather than beside it.
              sideExtent: math.max(config.sideColumnWidth, systemInset),
              sideOnRight: sideOnRight,
            ),
            children: [
              // Body is always the first child of the same type, so switching
              // modes (rotation, split view) keeps its State.
              LayoutId(
                id: FrameSlot.body,
                child: ObstructedBody(child: widget.child),
              ),
              if (!wide && tabs != null)
                LayoutId(
                  id: FrameSlot.bar,
                  child: config.tabBarBuilder(context, tabs),
                ),
              if (wide)
                LayoutId(
                  id: FrameSlot.side,
                  child: SideColumn(
                    host: _host,
                    tabs: tabs,
                    sideOnRight: sideOnRight,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
