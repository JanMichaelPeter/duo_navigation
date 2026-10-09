import 'package:flutter/widgets.dart';

import 'layout_mode.dart';

/// Decides between [DuoLayoutMode.compact] and [DuoLayoutMode.wide].
///
/// The default, [DuoLayoutPolicy.shortestSide], looks at the window, so
/// every frame in one window agrees on the mode. Implement this class for
/// other rules (for example hinge aware ones).
@immutable
abstract class DuoLayoutPolicy {
  /// Lets subclasses be const.
  const DuoLayoutPolicy();

  /// Wide when the window's shorter side is at least [size] logical pixels.
  /// The default, with 600.
  ///
  /// Phones stay compact in both orientations: in landscape the column would
  /// sit next to the camera cutout or the system buttons, on a short screen.
  /// Tablets and unfolded foldables get the column, and in split screen a
  /// window whose shorter side is under [size] is compact.
  const factory DuoLayoutPolicy.shortestSide(double size) = _ShortestSidePolicy;

  /// Wide from a window [width] of this many logical pixels, so phones get
  /// the column in landscape too.
  ///
  /// 600 is the Material compact/medium boundary; a lower value such as 466
  /// also gives foldables in their narrow unfolded posture the wide layout.
  const factory DuoLayoutPolicy.breakpoint(double width) = _BreakpointPolicy;

  /// Always [mode], whatever the size. For tests and single-layout products.
  const factory DuoLayoutPolicy.fixed(DuoLayoutMode mode) = _FixedPolicy;

  /// The mode for a frame of size [frame] in a window of size [window].
  DuoLayoutMode resolve({required Size window, required Size frame});
}

class _ShortestSidePolicy extends DuoLayoutPolicy {
  const _ShortestSidePolicy(this.size);

  final double size;

  @override
  DuoLayoutMode resolve({required Size window, required Size frame}) =>
      window.shortestSide >= size ? DuoLayoutMode.wide : DuoLayoutMode.compact;

  @override
  bool operator ==(Object other) =>
      other is _ShortestSidePolicy && other.size == size;

  @override
  int get hashCode => size.hashCode;

  @override
  String toString() => 'DuoLayoutPolicy.shortestSide($size)';
}

class _BreakpointPolicy extends DuoLayoutPolicy {
  const _BreakpointPolicy(this.width);

  final double width;

  @override
  DuoLayoutMode resolve({required Size window, required Size frame}) =>
      window.width >= width ? DuoLayoutMode.wide : DuoLayoutMode.compact;

  @override
  bool operator ==(Object other) =>
      other is _BreakpointPolicy && other.width == width;

  @override
  int get hashCode => width.hashCode;

  @override
  String toString() => 'DuoLayoutPolicy.breakpoint($width)';
}

class _FixedPolicy extends DuoLayoutPolicy {
  const _FixedPolicy(this.mode);

  final DuoLayoutMode mode;

  @override
  DuoLayoutMode resolve({required Size window, required Size frame}) => mode;

  @override
  bool operator ==(Object other) => other is _FixedPolicy && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'DuoLayoutPolicy.fixed(${mode.name})';
}
