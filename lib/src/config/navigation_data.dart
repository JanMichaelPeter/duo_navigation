import 'package:flutter/widgets.dart';

import '../defaults.dart';
import '../models/enums.dart';
import '../models/window_edges.dart';
import 'builders.dart';

/// All knobs. Every visual is a builder; the package only owns placement,
/// visibility, insets, identity and animation timing.
@immutable
class DockNavigationData {
  /// Every argument is optional; the defaults are Material 3.
  const DockNavigationData({
    this.breakpoint = 600,
    this.sideColumnWidth = 72,
    this.side = DockSide.end,
    this.windowEdges,
    this.detectWindowEdges = true,
    this.tabBarBuilder = DockDefaults.tabBar,
    this.railBuilder = DockDefaults.rail,
    this.actionBuilder = DockDefaults.action,
    this.pageBuilder = DockDefaults.page,
    this.sideColumnBuilder = DockDefaults.sideColumn,
    this.actionTransitionBuilder = DockDefaults.actionTransition,
    this.sideItemExtent = 56,
    this.actionSpacing = 8,
    this.actionAnimationDuration = const Duration(milliseconds: 250),
    this.actionAnimationCurve = Curves.easeOutCubic,
    this.tapCooldown = const Duration(milliseconds: 350),
  });

  /// Available width (logical px) from which the wide layout is used.
  /// 600 = Material compact/medium boundary; ~466 is the passport view of the iPhone duo.
  final double breakpoint;

  /// Minimum width of the side column. It overlaps the system inset on its
  /// edge (notch, reserved side strip) and grows to cover it if wider.
  final double sideColumnWidth;

  /// Preferred edge for the side column. Always used unless [windowEdges]
  /// says the window touches only the other edge of the display.
  final DockSide side;

  /// Which display edges the app window touches. Normally leave this null:
  /// [DockNavigation] detects it on iOS and Android (window_placement).
  /// Set it to override detection (tests, custom sources).
  ///
  /// If the window touches only the edge opposite [side] (e.g. the left half
  /// of a split screen with `side: end`), the column moves to that edge so it
  /// sits at the screen border instead of in the middle of the display. In
  /// every other case (fullscreen, floating, unknown) [side] is used.
  final DockWindowEdges? windowEdges;

  /// Detect [windowEdges] automatically when it is null. Off: always [side].
  final bool detectWindowEdges;

  /// Bottom tab bar in compact mode.
  final DockTabsBuilder tabBarBuilder;

  /// Tab rail at the bottom of the side column in wide mode.
  final DockTabsBuilder railBuilder;

  /// Every action, in the title bar and as side-column chip.
  final DockActionBuilder actionBuilder;

  /// Title bar + body of each [DockPage] (not `DockPage.custom`).
  final DockPageScaffoldBuilder pageBuilder;

  /// Arrangement of action chips and rail inside the side column.
  final DockSideColumnBuilder sideColumnBuilder;

  /// How side-column chips appear and disappear.
  final DockActionTransitionBuilder actionTransitionBuilder;

  /// Vertical gap between action chips in the side column.
  final double actionSpacing;

  /// Outer width of the rail pill and the action chips in the side column.
  /// The default builders both read it, so they line up as one column; read
  /// it in your own rail / chip builders to stay aligned with the defaults.
  final double sideItemExtent;

  /// Duration of chip in/out animations.
  final Duration actionAnimationDuration;

  /// Curve of chip in/out animations (flipped when animating out).
  final Curve actionAnimationCurve;

  /// After an action fires, further action taps from the same frame (shell or
  /// modal) are ignored for this long. Catches double taps on async handlers.
  /// Taps are additionally ignored while a route transition is running.
  final Duration tapCooldown;

  /// A copy with the given fields replaced.
  DockNavigationData copyWith({
    double? breakpoint,
    double? sideColumnWidth,
    DockSide? side,
    DockWindowEdges? windowEdges,
    bool? detectWindowEdges,
    DockTabsBuilder? tabBarBuilder,
    DockTabsBuilder? railBuilder,
    DockActionBuilder? actionBuilder,
    DockPageScaffoldBuilder? pageBuilder,
    DockSideColumnBuilder? sideColumnBuilder,
    DockActionTransitionBuilder? actionTransitionBuilder,
    double? sideItemExtent,
    double? actionSpacing,
    Duration? actionAnimationDuration,
    Curve? actionAnimationCurve,
    Duration? tapCooldown,
  }) {
    return DockNavigationData(
      breakpoint: breakpoint ?? this.breakpoint,
      sideColumnWidth: sideColumnWidth ?? this.sideColumnWidth,
      side: side ?? this.side,
      windowEdges: windowEdges ?? this.windowEdges,
      detectWindowEdges: detectWindowEdges ?? this.detectWindowEdges,
      tabBarBuilder: tabBarBuilder ?? this.tabBarBuilder,
      railBuilder: railBuilder ?? this.railBuilder,
      actionBuilder: actionBuilder ?? this.actionBuilder,
      pageBuilder: pageBuilder ?? this.pageBuilder,
      sideColumnBuilder: sideColumnBuilder ?? this.sideColumnBuilder,
      actionTransitionBuilder:
          actionTransitionBuilder ?? this.actionTransitionBuilder,
      sideItemExtent: sideItemExtent ?? this.sideItemExtent,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      actionAnimationDuration:
          actionAnimationDuration ?? this.actionAnimationDuration,
      actionAnimationCurve: actionAnimationCurve ?? this.actionAnimationCurve,
      tapCooldown: tapCooldown ?? this.tapCooldown,
    );
  }
}
