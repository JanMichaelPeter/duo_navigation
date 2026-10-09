import 'package:flutter/widgets.dart';

import '../actions/clock.dart';
import '../actions/tap_guard.dart';
import '../builders/builders.dart';
import '../config/navigation.dart';
import '../config/navigation_data.dart';
import '../geometry/layout_mode.dart';
import '../geometry/layout_policy.dart';
import '../geometry/side.dart';
import '../geometry/window_edges.dart';
import '../geometry/window_edges_source.dart';

/// A [DuoNavigation] for tests that pins everything a test usually wants
/// fixed, in one widget: the layout mode, the column's side, the window edges,
/// the text direction and the tap guard's clock.
///
/// Use it where the app uses [DuoNavigation], above the root navigator:
///
/// ```dart
/// await tester.pumpWidget(MaterialApp(
///   builder: (context, child) => DuoTestHarness(
///     builders: const DuoMaterialBuilders(),
///     mode: DuoLayoutMode.wide,
///     textDirection: TextDirection.rtl,
///     child: child!,
///   ),
///   home: const MyShell(),
/// ));
/// ```
///
/// By default the tap guard reads [DuoClock.frameTime], so
/// `tester.pump(duration)` lets its cooldown pass and a test never waits on
/// real time. Pass `tapGuard: DuoTapGuard.disabled` to let every tap through.
class DuoTestHarness extends StatelessWidget {
  /// Pins the given values on top of [data]; null leaves [data]'s value.
  const DuoTestHarness({
    super.key,
    this.data = const DuoNavigationData(),
    this.builders,
    this.mode,
    this.side,
    this.windowEdges,
    this.windowEdgesSource,
    this.textDirection,
    this.tapGuard = const DuoTapGuard(clock: DuoClock.frameTime),
    required this.child,
  }) : assert(
         windowEdges == null || windowEdgesSource == null,
         'Pass windowEdges or windowEdgesSource, not both.',
       );

  /// The configuration the pinned values are applied to.
  final DuoNavigationData data;

  /// The visuals, as on [DuoNavigation.builders]; usually
  /// `const DuoMaterialBuilders()` or the app's own.
  final DuoBuilders<Object?, Object?, Object?>? builders;

  /// The layout mode, whatever the window size. Null: [data]'s policy.
  final DuoLayoutMode? mode;

  /// The preferred edge of the column. Null: [data]'s side.
  final DuoSide? side;

  /// Fixed window edges. Null: [windowEdgesSource], else [data]'s source.
  final DuoWindowEdges? windowEdges;

  /// A source that changes over time, usually a `FakeWindowEdgesSource`.
  final DuoWindowEdgesSource? windowEdgesSource;

  /// The text direction below the harness. Null: the inherited one.
  final TextDirection? textDirection;

  /// The tap guard. Default: on, with a clock that follows the frames.
  final DuoTapGuard tapGuard;

  /// The app below, usually the root navigator.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mode = this.mode;
    final edges = windowEdges;
    Widget result = DuoNavigation(
      data: data.copyWith(
        layoutPolicy: mode == null ? null : DuoLayoutPolicy.fixed(mode),
        side: side,
        windowEdgesSource: edges != null
            ? DuoWindowEdgesSource.fixed(edges)
            : windowEdgesSource ?? data.windowEdgesSource,
        tapGuard: tapGuard,
      ),
      builders: builders,
      child: child,
    );
    final direction = textDirection;
    if (direction != null) {
      result = Directionality(textDirection: direction, child: result);
    }
    return result;
  }
}
