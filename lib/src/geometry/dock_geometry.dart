import 'package:flutter/widgets.dart';

import 'body_mode.dart';
import 'layout_mode.dart';
import 'side.dart';

/// What a widget can depend on in [DockGeometry.of], so it rebuilds only when
/// that part changes.
enum DockGeometryAspect {
  /// [DockGeometry.mode].
  mode,

  /// [DockGeometry.side] and [DockGeometry.columnOnRight].
  side,

  /// [DockGeometry.chrome], [DockGeometry.strip], [DockGeometry.bodyMode],
  /// [DockGeometry.systemPadding] and [DockGeometry.keyboard].
  chrome,

  /// [DockGeometry.visibility].
  visibility,
}

/// The layout of the nearest shell or modal frame, as its body sees it.
///
/// Read it with [DockGeometry.of] anywhere in a frame's body (pages, their
/// widgets). Pass an [DockGeometryAspect] to rebuild only when that part
/// changes; for example, a widget that only reads [mode] does not rebuild
/// while the bar animates its height.
@immutable
class DockGeometry {
  /// Describes a frame's layout. Frames create it; tests may too.
  const DockGeometry({
    required this.mode,
    required this.side,
    required this.columnOnRight,
    required this.bodyMode,
    required this.systemPadding,
    required this.chrome,
    this.visibility = 1,
    this.keyboard = 0,
  });

  /// Compact (bottom bar) or wide (side column).
  final DockLayoutMode mode;

  /// The edge of the side column relative to the text direction, after the
  /// window-edge resolution. Meaningful in wide mode.
  final DockSide side;

  /// Whether the side column is on the physical right edge.
  final bool columnOnRight;

  /// Whether the body is laid out beside the chrome or under it.
  final DockBodyMode bodyMode;

  /// The `MediaQuery.padding` above the frame: status bar, cutouts, home
  /// indicator.
  final EdgeInsets systemPadding;

  /// The area of the frame the bar or column covers, per edge. In wide mode
  /// its entry is the column width, plus the system inset on its edge with
  /// `DockColumnInset.safeArea`. For a bar lifted above the keyboard,
  /// the bottom entry reaches from the frame's bottom to the bar's top. It
  /// shrinks with [visibility] and is zero while the navigation is hidden.
  final EdgeInsets chrome;

  /// How far the navigation is shown: 1 shown, 0 hidden, in between while it
  /// animates (`DockShell.navigationVisible`, `DockPageScope.visible`).
  final double visibility;

  /// The keyboard height the frame took from the body: the open software
  /// keyboard in [DockBodyMode.inset], zero in [DockBodyMode.overlay] (there
  /// the page's `Scaffold` handles it). Below the frame, `MediaQuery` reports
  /// no keyboard in inset mode.
  final double keyboard;

  /// Whether the navigation is fully hidden.
  bool get isHidden => visibility == 0;

  /// How far the body is inset from the frame's edges: [chrome] in
  /// [DockBodyMode.inset], zero in [DockBodyMode.overlay].
  EdgeInsets get strip =>
      bodyMode == DockBodyMode.inset ? chrome : EdgeInsets.zero;

  /// The geometry of the nearest frame. Throws a [FlutterError] outside any
  /// shell or modal frame; use [maybeOf] where that is expected.
  static DockGeometry of(BuildContext context, {DockGeometryAspect? aspect}) {
    final geometry = maybeOf(context, aspect: aspect);
    if (geometry != null) return geometry;
    throw FlutterError.fromParts([
      ErrorSummary('No DockShell or DockModalScope found.'),
      ErrorDescription(
        'DockGeometry.of reads the layout of the nearest frame, and '
        '${context.widget.runtimeType} is not in the body of one.',
      ),
      ErrorHint(
        'Use DockGeometry.maybeOf where no frame is expected, or '
        'DockNavigation.modeOf / sideOf for the window-wide values.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// The geometry of the nearest frame, or null outside any frame.
  static DockGeometry? maybeOf(
    BuildContext context, {
    DockGeometryAspect? aspect,
  }) => InheritedModel.inheritFrom<DockGeometryScope>(
    context,
    aspect: aspect,
  )?.geometry;

  @override
  bool operator ==(Object other) =>
      other is DockGeometry &&
      other.mode == mode &&
      other.side == side &&
      other.columnOnRight == columnOnRight &&
      other.bodyMode == bodyMode &&
      other.systemPadding == systemPadding &&
      other.chrome == chrome &&
      other.visibility == visibility &&
      other.keyboard == keyboard;

  @override
  int get hashCode => Object.hash(
    mode,
    side,
    columnOnRight,
    bodyMode,
    systemPadding,
    chrome,
    visibility,
    keyboard,
  );

  @override
  String toString() =>
      'DockGeometry(${mode.name}, side: ${side.name}, '
      'columnOnRight: $columnOnRight, bodyMode: ${bodyMode.name}, '
      'systemPadding: $systemPadding, chrome: $chrome, '
      'visibility: $visibility, keyboard: $keyboard)';
}

/// Provides a [DockGeometry] to a frame's body. Frames insert it; it is not
/// exported.
class DockGeometryScope extends InheritedModel<DockGeometryAspect> {
  /// Provides [geometry] to [child].
  const DockGeometryScope({
    super.key,
    required this.geometry,
    required super.child,
  });

  /// The geometry of the frame.
  final DockGeometry geometry;

  @override
  bool updateShouldNotify(DockGeometryScope oldWidget) =>
      geometry != oldWidget.geometry;

  @override
  bool updateShouldNotifyDependent(
    DockGeometryScope oldWidget,
    Set<DockGeometryAspect> dependencies,
  ) {
    final a = geometry, b = oldWidget.geometry;
    return dependencies.any(
      (aspect) => switch (aspect) {
        DockGeometryAspect.mode => a.mode != b.mode,
        DockGeometryAspect.side =>
          a.side != b.side || a.columnOnRight != b.columnOnRight,
        DockGeometryAspect.chrome =>
          a.chrome != b.chrome ||
              a.bodyMode != b.bodyMode ||
              a.systemPadding != b.systemPadding ||
              a.keyboard != b.keyboard,
        DockGeometryAspect.visibility => a.visibility != b.visibility,
      },
    );
  }
}
