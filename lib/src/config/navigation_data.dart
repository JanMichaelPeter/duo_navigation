import 'package:flutter/widgets.dart';

import '../actions/tap_guard.dart';
import '../geometry/body_mode.dart';
import '../geometry/layout_policy.dart';
import '../geometry/side.dart';
import '../geometry/window_edges_source.dart';

/// Marks a `copyWith` argument that was not passed, so a nullable field can be
/// reset to null.
const Object _unset = Object();

/// How navigation is laid out: when it switches to the wide layout, which edge
/// the column prefers, where window edges come from, and the column's sizes and
/// timings.
///
/// It has value equality, so rebuilding `DockNavigation` with equal data
/// notifies no dependents.
///
/// The visuals are not part of it: see `DockBuilders`.
@immutable
class DockNavigationData {
  /// Every argument is optional; the defaults are Material 3.
  const DockNavigationData({
    this.layoutPolicy = const DockLayoutPolicy.breakpoint(600),
    this.side = DockSide.end,
    this.windowEdgesSource,
    this.bodyMode = DockBodyMode.inset,
    this.sideColumnWidth = 72,
    this.sideItemExtent = 56,
    this.actionSpacing = 8,
    this.actionAnimationDuration = const Duration(milliseconds: 250),
    this.actionAnimationCurve = Curves.easeOutCubic,
    this.tapGuard = const DockTapGuard(),
  });

  /// Decides between the compact and the wide layout. Default: wide from a
  /// window width of 600.
  final DockLayoutPolicy layoutPolicy;

  /// Preferred edge for the side column. Used unless [windowEdgesSource]
  /// reports that the window touches only the other edge of the display.
  final DockSide side;

  /// Where the window's display edges come from (split screen, windowing).
  ///
  /// If the window touches only the edge opposite [side] (for example the left
  /// half of a split screen with `side: end`), the column moves to that edge so
  /// it sits at the screen border instead of in the middle of the display. In
  /// every other case (fullscreen, floating, unknown) [side] is used. Null: no
  /// detection, always [side].
  final DockWindowEdgesSource? windowEdgesSource;

  /// How frames lay out their body: beside the bar and column
  /// ([DockBodyMode.inset], the default) or under them
  /// ([DockBodyMode.overlay]). `DockShell` and `DockModalScope` can override
  /// it.
  final DockBodyMode bodyMode;

  /// Width of the side column. On its edge, the column sits after the system
  /// inset (cutout, gesture strip), so it covers that inset plus this width.
  final double sideColumnWidth;

  /// Outer width of the rail pill and the action chips in the side column.
  /// The default builders both read it, so they line up as one column; read
  /// it in your own rail and chip builders to stay aligned with the defaults.
  final double sideItemExtent;

  /// Vertical gap between action chips in the side column.
  final double actionSpacing;

  /// Duration of chip in/out animations.
  final Duration actionAnimationDuration;

  /// Curve of chip in/out animations (flipped when animating out).
  final Curve actionAnimationCurve;

  /// Guards action taps against double taps and taps during route
  /// transitions. [DockTapGuard.disabled] lets every tap through.
  final DockTapGuard tapGuard;

  /// A copy with the given fields replaced. Pass null for [windowEdgesSource]
  /// to remove it.
  DockNavigationData copyWith({
    DockLayoutPolicy? layoutPolicy,
    DockSide? side,
    Object? windowEdgesSource = _unset,
    DockBodyMode? bodyMode,
    double? sideColumnWidth,
    double? sideItemExtent,
    double? actionSpacing,
    Duration? actionAnimationDuration,
    Curve? actionAnimationCurve,
    DockTapGuard? tapGuard,
  }) {
    return DockNavigationData(
      layoutPolicy: layoutPolicy ?? this.layoutPolicy,
      side: side ?? this.side,
      windowEdgesSource: identical(windowEdgesSource, _unset)
          ? this.windowEdgesSource
          : windowEdgesSource as DockWindowEdgesSource?,
      bodyMode: bodyMode ?? this.bodyMode,
      sideColumnWidth: sideColumnWidth ?? this.sideColumnWidth,
      sideItemExtent: sideItemExtent ?? this.sideItemExtent,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      actionAnimationDuration:
          actionAnimationDuration ?? this.actionAnimationDuration,
      actionAnimationCurve: actionAnimationCurve ?? this.actionAnimationCurve,
      tapGuard: tapGuard ?? this.tapGuard,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DockNavigationData &&
      other.layoutPolicy == layoutPolicy &&
      other.side == side &&
      other.windowEdgesSource == windowEdgesSource &&
      other.bodyMode == bodyMode &&
      other.sideColumnWidth == sideColumnWidth &&
      other.sideItemExtent == sideItemExtent &&
      other.actionSpacing == actionSpacing &&
      other.actionAnimationDuration == actionAnimationDuration &&
      other.actionAnimationCurve == actionAnimationCurve &&
      other.tapGuard == tapGuard;

  @override
  int get hashCode => Object.hash(
    layoutPolicy,
    side,
    windowEdgesSource,
    bodyMode,
    sideColumnWidth,
    sideItemExtent,
    actionSpacing,
    actionAnimationDuration,
    actionAnimationCurve,
    tapGuard,
  );
}
