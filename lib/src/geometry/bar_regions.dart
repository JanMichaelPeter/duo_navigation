import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bar_region_source.dart';

/// Caches a [DuoBarRegionSource]'s answers for the current window. Not
/// exported; `DuoNavigation` owns one and reads it through [BarRegionsScope].
///
/// Lookups are synchronous: a miss asks the source and returns null (the
/// safe area applies) until the answer arrives, then notifies. A change of
/// the window's size or padding drops every answer, since rotation, folding
/// and split screen move the regions.
class BarRegionCache extends ChangeNotifier {
  DuoBarRegionSource? _source;
  Object? _window;
  int _generation = 0;
  final Map<(DuoScreenEdge, double), Rect?> _regions = {};
  final Set<(DuoScreenEdge, double)> _pending = {};

  /// Sets the source and the window the answers are for. Called during build;
  /// does not notify (dependents rebuild with the window anyway).
  void update(DuoBarRegionSource? source, Size size, EdgeInsets viewPadding) {
    final window = (size, viewPadding);
    if (source == _source && window == _window) return;
    _source = source;
    _window = window;
    _generation++;
    _regions.clear();
    _pending.clear();
  }

  /// The region for a bar [extent] thick along [edge], in window coordinates,
  /// or null while unknown.
  Rect? lookup(DuoScreenEdge edge, double extent) {
    final key = (edge, extent);
    if (_regions.containsKey(key)) return _regions[key];
    final source = _source;
    if (source == null || !_pending.add(key)) return null;
    final generation = _generation;
    source
        .barRegion(edge, extent)
        .then<Rect?>((region) => region, onError: (Object _) => null)
        .then((region) {
          if (generation != _generation) return; // The window changed.
          _pending.remove(key);
          _regions[key] = region;
          if (region != null) notifyListeners();
        });
    return null;
  }
}

/// Provides the [BarRegionCache] below `DuoNavigation`. Not exported.
class BarRegionsScope extends InheritedNotifier<BarRegionCache> {
  /// Provides [cache] to [child].
  const BarRegionsScope({
    super.key,
    required BarRegionCache cache,
    required super.child,
  }) : super(notifier: cache);

  /// The region for a bar [extent] thick along [edge] in window coordinates,
  /// or null without a source, while unknown, or without a scope. Rebuilds
  /// [context] when it arrives.
  static Rect? of(BuildContext context, DuoScreenEdge edge, double extent) =>
      context
          .dependOnInheritedWidgetOfExactType<BarRegionsScope>()
          ?.notifier
          ?.lookup(edge, extent);
}

/// Where a side column of [width] sits beside the status icons on its edge.
@immutable
class ColumnPlacement {
  /// A placement with [top] and [offset].
  const ColumnPlacement({required this.top, required this.offset});

  /// Where the column's content starts: below the icons. Null: the safe
  /// area's top.
  final double? top;

  /// The gap between the window edge and the column, so the column is
  /// centred on the icons.
  final double offset;
}

/// Where a side column of [width] on the right or left edge of a window of
/// [size] with [padding] goes, given the bar [region] for that edge; null to
/// keep the column at the edge with the safe area.
///
/// Only when the status icons share the column's edge: that edge has a
/// system inset, and the bar region hugs the edge (closer to it than the
/// inset, so it is not the safe-area fallback for a column too wide to fit
/// beside the icons). The column's content then starts below the icons, and
/// the column is centred on the region's centre line, which is the icons'.
ColumnPlacement? columnPlacementFromRegion({
  required Rect? region,
  required bool onRight,
  required double width,
  required Size size,
  required EdgeInsets padding,
}) {
  if (region == null) return null;
  final inset = onRight ? padding.right : padding.left;
  final margin = onRight ? size.width - region.right : region.left;
  if (inset <= 0 || margin >= inset) return null;
  final centre = onRight ? size.width - region.center.dx : region.center.dx;
  return ColumnPlacement(
    top: region.top > padding.top ? region.top : null,
    offset: math.max(0.0, centre - width / 2),
  );
}

/// The padding for a title bar in a body at [origin] (in window coordinates)
/// of [bodyWidth], given the top bar [region] in window coordinates, a window
/// of [size] and the body's [padding].
///
/// The bar goes as high as the region allows (into the top safe-area band
/// beside the status icons, or at the top edge where there is no band). If
/// the icons cut into the top edge from one side (the region's margin on
/// that side is the larger one), the bar ends before them on that side.
EdgeInsets titleBarPaddingFromRegion({
  required Rect region,
  required Offset origin,
  required double bodyWidth,
  required Size size,
  required EdgeInsets padding,
}) {
  final leftMargin = region.left;
  final rightMargin = size.width - region.right;
  var left = padding.left;
  var right = padding.right;
  if (rightMargin > leftMargin + precisionErrorTolerance) {
    right = math.max(right, origin.dx + bodyWidth - region.right);
  } else if (leftMargin > rightMargin + precisionErrorTolerance) {
    left = math.max(left, region.left - origin.dx);
  }
  return EdgeInsets.fromLTRB(
    left,
    math.max(0.0, math.min(padding.top, region.top - origin.dy)),
    right,
    padding.bottom,
  );
}
