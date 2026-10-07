import 'package:flutter/widgets.dart';

import 'layout_mode.dart';

/// Decides between [DockLayoutMode.compact] and [DockLayoutMode.wide].
///
/// The default, [DockLayoutPolicy.breakpoint], looks at the window width, so
/// every frame in one window agrees on the mode. Implement this class for
/// other rules (for example height or hinge aware ones).
@immutable
abstract class DockLayoutPolicy {
  /// Lets subclasses be const.
  const DockLayoutPolicy();

  /// Wide from a window [width] of this many logical pixels.
  ///
  /// 600 is the Material compact/medium boundary; a lower value such as 466
  /// also gives foldables in their narrow unfolded posture the wide layout.
  const factory DockLayoutPolicy.breakpoint(double width) = _BreakpointPolicy;

  /// Always [mode], whatever the size. For tests and single-layout products.
  const factory DockLayoutPolicy.fixed(DockLayoutMode mode) = _FixedPolicy;

  /// The mode for a frame of size [frame] in a window of size [window].
  DockLayoutMode resolve({required Size window, required Size frame});
}

class _BreakpointPolicy extends DockLayoutPolicy {
  const _BreakpointPolicy(this.width);

  final double width;

  @override
  DockLayoutMode resolve({required Size window, required Size frame}) =>
      window.width >= width ? DockLayoutMode.wide : DockLayoutMode.compact;

  @override
  bool operator ==(Object other) =>
      other is _BreakpointPolicy && other.width == width;

  @override
  int get hashCode => width.hashCode;

  @override
  String toString() => 'DockLayoutPolicy.breakpoint($width)';
}

class _FixedPolicy extends DockLayoutPolicy {
  const _FixedPolicy(this.mode);

  final DockLayoutMode mode;

  @override
  DockLayoutMode resolve({required Size window, required Size frame}) => mode;

  @override
  bool operator ==(Object other) => other is _FixedPolicy && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'DockLayoutPolicy.fixed(${mode.name})';
}
