import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../geometry/body_mode.dart';
import '../geometry/dock_geometry.dart';
import 'render_frame.dart';

/// Publishes the frame's [DockGeometry] and an adjusted `MediaQuery` to the
/// frame's body.
///
/// The geometry arrives with the body's constraints ([DockFrameConstraints]),
/// because the bar's height is only known during layout. [child] is the same
/// widget on every layout, so only widgets that depend on the geometry or on
/// `MediaQuery` rebuild when the chrome changes.
class DockBodyScope extends StatelessWidget {
  /// Publishes the geometry to [child].
  const DockBodyScope({super.key, required this.child});

  /// The page subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints is! DockFrameConstraints) return child;
        final geometry = constraints.geometry;
        return DockGeometryScope(
          geometry: geometry,
          child: MediaQuery(
            data: bodyMediaQuery(MediaQuery.of(context), geometry),
            child: child,
          ),
        );
      },
    );
  }

  /// The `MediaQuery` the body of a frame with [geometry] sees, given the
  /// frame's own [outer] one.
  ///
  /// * [DockBodyMode.inset]: the body starts after the chrome, so padding and
  ///   view padding are reduced by it per edge (zero on the covered edges).
  ///   The keyboard is reduced by what the frame already took at the bottom:
  ///   the bar's strip, and the whole keyboard when the frame lifts the body
  ///   (`DockBodyKeyboardBehavior.lift`).
  /// * [DockBodyMode.overlay]: the body covers the frame and the chrome is
  ///   published as padding (the larger of the system padding and the chrome
  ///   per edge). A bar hidden by the keyboard no longer counts as padding.
  static MediaQueryData bodyMediaQuery(
    MediaQueryData outer,
    DockGeometry geometry,
  ) {
    final chrome = geometry.chrome;
    final keyboard = outer.viewInsets.bottom;
    switch (geometry.bodyMode) {
      case DockBodyMode.inset:
        // The body ends above the chrome, and above the keyboard if the frame
        // lifted it (geometry.keyboard). The page sees the rest of the
        // keyboard, so nothing below counts what the frame took again.
        final taken = chrome.copyWith(
          bottom: math.max(chrome.bottom, geometry.keyboard),
        );
        return outer.copyWith(
          padding: _reduce(outer.padding, taken),
          viewPadding: _reduce(outer.viewPadding, chrome),
          viewInsets: outer.viewInsets.copyWith(
            bottom: math.max(0.0, keyboard - taken.bottom),
          ),
        );
      case DockBodyMode.overlay:
        final visibleChrome = chrome.copyWith(
          bottom: math.max(0.0, chrome.bottom - keyboard),
        );
        return outer.copyWith(
          padding: _max(outer.padding, visibleChrome),
          viewPadding: _max(outer.viewPadding, chrome),
        );
    }
  }

  static EdgeInsets _reduce(EdgeInsets a, EdgeInsets b) => EdgeInsets.fromLTRB(
    math.max(0.0, a.left - b.left),
    math.max(0.0, a.top - b.top),
    math.max(0.0, a.right - b.right),
    math.max(0.0, a.bottom - b.bottom),
  );

  static EdgeInsets _max(EdgeInsets a, EdgeInsets b) => EdgeInsets.fromLTRB(
    math.max(a.left, b.left),
    math.max(a.top, b.top),
    math.max(a.right, b.right),
    math.max(a.bottom, b.bottom),
  );
}
