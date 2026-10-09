import 'package:flutter/widgets.dart';

import '../actions/tap_guard.dart';
import '../geometry/body_mode.dart';
import 'column_inset.dart';
import 'keyboard.dart';
import '../models/action.dart';
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
/// It has value equality, so rebuilding `DuoNavigation` with equal data
/// notifies no dependents.
///
/// The visuals are not part of it: see `DuoBuilders`.
@immutable
class DuoNavigationData {
  /// Every argument is optional; the defaults are Material 3.
  const DuoNavigationData({
    this.layoutPolicy = const DuoLayoutPolicy.shortestSide(600),
    this.side = DuoSide.end,
    this.windowEdgesSource,
    this.bodyMode = DuoBodyMode.inset,
    this.hoisting = DuoHoisting.iconActions,
    this.modalLeading = const DuoModalLeading(),
    this.keyboard = const DuoKeyboard(),
    this.sideColumnWidth = 72,
    this.columnInset = DuoColumnInset.overlap,
    this.columnTextScaleLimit = 1.5,
    this.sideItemExtent = 56,
    this.actionSpacing = 8,
    this.actionAnimationDuration = const Duration(milliseconds: 250),
    this.actionAnimationCurve = Curves.easeOutCubic,
    this.visibilityDuration = const Duration(milliseconds: 250),
    this.visibilityCurve = Curves.easeInOutCubic,
    this.tapGuard = const DuoTapGuard(),
  });

  /// Decides between the compact and the wide layout. Default:
  /// `DuoLayoutPolicy.shortestSide(600)`, wide when the window's shorter
  /// side is at least 600, so phones stay compact in landscape.
  final DuoLayoutPolicy layoutPolicy;

  /// Preferred edge for the side column. Used unless [windowEdgesSource]
  /// reports that the window touches only the other edge of the display.
  final DuoSide side;

  /// Where the window's display edges come from (split screen, windowing).
  ///
  /// If the window touches only the edge opposite [side] (for example the left
  /// half of a split screen with `side: end`), the column moves to that edge so
  /// it sits at the screen border instead of in the middle of the display. In
  /// every other case (fullscreen, floating, unknown) [side] is used. Null: no
  /// detection, always [side].
  final DuoWindowEdgesSource? windowEdgesSource;

  /// How frames lay out their body: beside the bar and column
  /// ([DuoBodyMode.inset], the default) or under them
  /// ([DuoBodyMode.overlay]). `DuoShell` and `DuoModalScope` can override
  /// it.
  final DuoBodyMode bodyMode;

  /// Whether icon actions move into the side column in wide mode. `DuoShell`,
  /// `DuoModalScope` and `DuoPageScope` can override it.
  final DuoHoisting hoisting;

  /// The leading action of every modal's first page, for example
  /// `DuoModalLeading(implied: DuoImpliedLeading.close, atEnd: true)` for
  /// an "X" at the top right of every modal. It applies to modal starts only
  /// (see [DuoModalLeading]); `DuoModalScope` and the page override it.
  final DuoModalLeading modalLeading;

  /// What the column and the bar do while the software keyboard is open.
  /// Default: the column lifts above it, the bar is covered.
  final DuoKeyboard keyboard;

  /// Width of the side column. With [DuoColumnInset.safeArea] it also
  /// covers the system inset on its edge.
  final double sideColumnWidth;

  /// Whether the column sits over the system inset on its edge
  /// ([DuoColumnInset.overlap], the default: at the window edge) or after it
  /// ([DuoColumnInset.safeArea]: clear of cutouts and system buttons).
  final DuoColumnInset columnInset;

  /// How far the column grows with the text scale: its width is
  /// [sideColumnWidth] times the text scale, at most this factor.
  final double columnTextScaleLimit;

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

  /// Duration of hiding and showing the navigation. Zero under
  /// `MediaQuery.disableAnimations`.
  final Duration visibilityDuration;

  /// Curve of hiding and showing the navigation.
  final Curve visibilityCurve;

  /// Guards action taps against double taps and taps during route
  /// transitions. [DuoTapGuard.disabled] lets every tap through.
  final DuoTapGuard tapGuard;

  /// A copy with the given fields replaced. Pass null for [windowEdgesSource]
  /// to remove it.
  DuoNavigationData copyWith({
    DuoLayoutPolicy? layoutPolicy,
    DuoSide? side,
    Object? windowEdgesSource = _unset,
    DuoBodyMode? bodyMode,
    DuoHoisting? hoisting,
    DuoModalLeading? modalLeading,
    DuoKeyboard? keyboard,
    double? sideColumnWidth,
    DuoColumnInset? columnInset,
    double? columnTextScaleLimit,
    double? sideItemExtent,
    double? actionSpacing,
    Duration? actionAnimationDuration,
    Curve? actionAnimationCurve,
    Duration? visibilityDuration,
    Curve? visibilityCurve,
    DuoTapGuard? tapGuard,
  }) {
    return DuoNavigationData(
      layoutPolicy: layoutPolicy ?? this.layoutPolicy,
      side: side ?? this.side,
      windowEdgesSource: identical(windowEdgesSource, _unset)
          ? this.windowEdgesSource
          : windowEdgesSource as DuoWindowEdgesSource?,
      bodyMode: bodyMode ?? this.bodyMode,
      hoisting: hoisting ?? this.hoisting,
      modalLeading: modalLeading ?? this.modalLeading,
      keyboard: keyboard ?? this.keyboard,
      sideColumnWidth: sideColumnWidth ?? this.sideColumnWidth,
      columnInset: columnInset ?? this.columnInset,
      columnTextScaleLimit: columnTextScaleLimit ?? this.columnTextScaleLimit,
      sideItemExtent: sideItemExtent ?? this.sideItemExtent,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      actionAnimationDuration:
          actionAnimationDuration ?? this.actionAnimationDuration,
      actionAnimationCurve: actionAnimationCurve ?? this.actionAnimationCurve,
      visibilityDuration: visibilityDuration ?? this.visibilityDuration,
      visibilityCurve: visibilityCurve ?? this.visibilityCurve,
      tapGuard: tapGuard ?? this.tapGuard,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DuoNavigationData &&
      other.layoutPolicy == layoutPolicy &&
      other.side == side &&
      other.windowEdgesSource == windowEdgesSource &&
      other.bodyMode == bodyMode &&
      other.hoisting == hoisting &&
      other.modalLeading == modalLeading &&
      other.keyboard == keyboard &&
      other.sideColumnWidth == sideColumnWidth &&
      other.columnInset == columnInset &&
      other.columnTextScaleLimit == columnTextScaleLimit &&
      other.sideItemExtent == sideItemExtent &&
      other.actionSpacing == actionSpacing &&
      other.actionAnimationDuration == actionAnimationDuration &&
      other.actionAnimationCurve == actionAnimationCurve &&
      other.visibilityDuration == visibilityDuration &&
      other.visibilityCurve == visibilityCurve &&
      other.tapGuard == tapGuard;

  @override
  int get hashCode => Object.hash(
    layoutPolicy,
    side,
    windowEdgesSource,
    bodyMode,
    hoisting,
    modalLeading,
    keyboard,
    sideColumnWidth,
    columnInset,
    columnTextScaleLimit,
    sideItemExtent,
    actionSpacing,
    actionAnimationDuration,
    actionAnimationCurve,
    visibilityDuration,
    visibilityCurve,
    tapGuard,
  );
}
