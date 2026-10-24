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

  /// Wide while the window is inside every bound given, compact outside.
  ///
  /// A min bound is reached at its value, a max bound only below it: a window
  /// exactly [maxHeight] tall is compact. Bounds left `null` don't apply.
  /// [minAspectRatio] and [maxAspectRatio] compare width / height, so 1
  /// separates portrait from landscape.
  ///
  /// Wide in landscape only, from foldable widths up:
  ///
  /// ```dart
  /// const DuoLayoutPolicy.band(minWidth: 466, minAspectRatio: 1)
  /// ```
  ///
  /// The unfolded iPhone Duo then gets the bottom tab bar in portrait
  /// (669 × 951) and the side column in landscape (951 × 669); so does an
  /// iPad. `band(minWidth: 466, maxHeight: 900)` draws the same line by
  /// height instead.
  const factory DuoLayoutPolicy.band({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    double? minAspectRatio,
    double? maxAspectRatio,
  }) = _BandPolicy;

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

class _BandPolicy extends DuoLayoutPolicy {
  const _BandPolicy({
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.minAspectRatio,
    this.maxAspectRatio,
  }) : assert(minWidth == null || maxWidth == null || minWidth < maxWidth),
       assert(minHeight == null || maxHeight == null || minHeight < maxHeight),
       assert(
         minAspectRatio == null ||
             maxAspectRatio == null ||
             minAspectRatio < maxAspectRatio,
       );

  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final double? minAspectRatio;
  final double? maxAspectRatio;

  @override
  DuoLayoutMode resolve({required Size window, required Size frame}) =>
      _within(window.width, minWidth, maxWidth) &&
          _within(window.height, minHeight, maxHeight) &&
          _within(window.aspectRatio, minAspectRatio, maxAspectRatio)
      ? DuoLayoutMode.wide
      : DuoLayoutMode.compact;

  static bool _within(double value, double? min, double? max) =>
      (min == null || value >= min) && (max == null || value < max);

  @override
  bool operator ==(Object other) =>
      other is _BandPolicy &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.minHeight == minHeight &&
      other.maxHeight == maxHeight &&
      other.minAspectRatio == minAspectRatio &&
      other.maxAspectRatio == maxAspectRatio;

  @override
  int get hashCode => Object.hash(
    minWidth,
    maxWidth,
    minHeight,
    maxHeight,
    minAspectRatio,
    maxAspectRatio,
  );

  @override
  String toString() {
    final bounds = {
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'minAspectRatio': minAspectRatio,
      'maxAspectRatio': maxAspectRatio,
    }.entries.where((e) => e.value != null);
    return 'DuoLayoutPolicy.band('
        '${bounds.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }
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
