import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../actions/action_host.dart';
import '../config/navigation.dart';
import '../models/enums.dart';
import '../models/tab.dart';
import '../models/tabs_data.dart';
import 'frame_layout.dart';
import 'obstructed_body.dart';
import 'side_column.dart';

/// Exposes the current layout mode and action host to pages.
class DockScope extends InheritedWidget {
  const DockScope._({
    required this.mode,
    required this.host,
    required this.isModal,
    required this.side,
    required super.child,
  });

  /// Compact or wide, decided by the frame's width and the breakpoint.
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

  /// Current mode; outside any scope it falls back to the screen width.
  static DockLayoutMode modeOf(BuildContext context) {
    final scope = maybeOf(context);
    if (scope != null) return scope.mode;
    final config = DockNavigation.of(context);
    return MediaQuery.sizeOf(context).width >= config.breakpoint
        ? DockLayoutMode.wide
        : DockLayoutMode.compact;
  }

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
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final preferRight = (config.side == DockSide.end) == ltr;
    final sideOnRight =
        config.windowEdges?.resolveRight(preferRight: preferRight) ??
        preferRight;
    final systemInset = sideOnRight ? padding.right : padding.left;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= config.breakpoint;
        final mode = wide ? DockLayoutMode.wide : DockLayoutMode.compact;
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
