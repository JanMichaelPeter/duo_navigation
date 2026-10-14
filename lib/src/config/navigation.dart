import 'dart:async';

import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../frame/frame.dart' show DuoScope;
import '../geometry/bar_region_source.dart';
import '../geometry/bar_regions.dart';
import '../geometry/dock_geometry.dart';
import '../geometry/layout_mode.dart';
import '../geometry/side.dart';
import '../geometry/window_edges.dart';
import '../geometry/window_edges_source.dart';
import 'navigation_data.dart';

/// Provides [DuoNavigationData] to the app. Place it above the root
/// `Navigator` (usually in `MaterialApp.builder`), so pages pushed on the root
/// navigator see it too.
///
/// It also listens to [DuoNavigationData.windowEdgesSource], once for the
/// whole app, and moves the side column to the edge the window touches; and
/// it asks [DuoNavigationData.barRegionSource] where bars fit beside the
/// status icons ([barRegionOf]).
class DuoNavigation extends StatefulWidget {
  /// Provides [data] and [builders] to [child].
  const DuoNavigation({
    super.key,
    this.data = const DuoNavigationData(),
    this.builders,
    required this.child,
  });

  /// The configuration.
  final DuoNavigationData data;

  /// The app's visuals, for example `const DuoMaterialBuilders()` from
  /// `package:duo_navigation/material.dart`. Shells, modal frames and
  /// [DuoBuildersScope]s can override them field by field.
  ///
  /// Optional: an app that only reads the layout (`DuoNavigation.modeOf`,
  /// `DuoGeometry`) needs none. A frame that needs a builder no scope sets
  /// fails with a [FlutterError] naming it.
  final DuoBuilders<Object?, Object?, Object?>? builders;

  /// The app below, usually the root `Navigator`.
  final Widget child;

  /// The configuration of the nearest [DuoNavigation].
  ///
  /// Throws a [FlutterError] if there is none: duo_navigation does not guess a
  /// layout. Use [maybeOf] where a missing [DuoNavigation] is expected.
  static DuoNavigationData of(BuildContext context) {
    final data = maybeOf(context);
    if (data != null) return data;
    throw FlutterError.fromParts([
      ErrorSummary('No DuoNavigation found.'),
      ErrorDescription(
        '${context.widget.runtimeType} needs a DuoNavigation above it to '
        'know how navigation is laid out.',
      ),
      ErrorHint(
        'Wrap the app in a DuoNavigation above the root Navigator, for '
        'example:\n'
        '  MaterialApp(\n'
        '    builder: (context, child) => DuoNavigation(child: child!),\n'
        '  )\n'
        'In tests, wrap the widget under test the same way.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// The configuration of the nearest [DuoNavigation], or null if there is
  /// none.
  static DuoNavigationData? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<_DuoNavigationScope>(
        context,
        aspect: _Aspect.data,
      )?.data;

  /// The window edges last reported by
  /// [DuoNavigationData.windowEdgesSource], or null while unknown or without
  /// a source.
  static DuoWindowEdges? windowEdgesOf(BuildContext context) =>
      _scopeOf(context, _Aspect.edges).edges;

  /// The layout mode for the window, from [DuoNavigationData.layoutPolicy].
  ///
  /// Use it outside any shell or modal frame. Inside one, the frame's own mode
  /// is authoritative.
  static DuoLayoutMode modeOf(BuildContext context) {
    final window = MediaQuery.sizeOf(context);
    return of(context).layoutPolicy.resolve(window: window, frame: window);
  }

  /// The edge the side column is on: [DuoNavigationData.side], moved to the
  /// other edge when the window touches only that one.
  static DuoSide sideOf(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return sideOnRight(context) == ltr ? DuoSide.end : DuoSide.start;
  }

  /// Whether the side column is on the physical right edge (see [sideOf]).
  static bool sideOnRight(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final preferRight = (of(context).side == DuoSide.end) == ltr;
    return windowEdgesOf(context)?.resolveRight(preferRight: preferRight) ??
        preferRight;
  }

  /// Where the system lets a bar [extent] thick sit along [edge], in window
  /// coordinates, from [DuoNavigationData.barRegionSource]; see
  /// [DuoBarRegionSource]. Null without a source, where it can't tell, and
  /// until its first answer for the current window arrives ([context] then
  /// rebuilds).
  static Rect? barRegionOf(
    BuildContext context,
    DuoScreenEdge edge,
    double extent,
  ) => BarRegionsScope.of(context, edge, extent);

  /// The padding for a page's title bar [extent] high at the top of the
  /// nearest frame's body, so the bar sits on the window's top edge beside
  /// the status icons rather than below them.
  ///
  /// Like `MediaQuery.paddingOf`, with two changes from
  /// [DuoNavigationData.barRegionSource]: the top is as small as the top bar
  /// region allows (in the top safe-area band beside the icons, for example
  /// an unfolded iPhone Duo in portrait), and the side where the icons cut
  /// into the top edge is padded so the title and the bar's actions end
  /// before them. The Material `DuoAppBar` and `DuoTitleBarPadding` apply
  /// it; custom title bars can too.
  ///
  /// Null where it doesn't apply: no source or no answer yet, outside a
  /// frame, or a frame that doesn't fill the window (a sheet). Use
  /// `MediaQuery.paddingOf` then.
  static EdgeInsets? titleBarPaddingOf(BuildContext context, double extent) {
    final region = barRegionOf(context, DuoScreenEdge.top, extent);
    if (region == null) return null;
    final scope = DuoScope.maybeOf(context);
    final geometry = DuoGeometry.maybeOf(
      context,
      aspect: DuoGeometryAspect.chrome,
    );
    if (scope == null || !scope.fillsWindow || geometry == null) return null;
    final size = MediaQuery.sizeOf(context);
    final strip = geometry.strip;
    return titleBarPaddingFromRegion(
      region: region,
      origin: Offset(strip.left, strip.top),
      bodyWidth: size.width - strip.horizontal,
      size: size,
      padding: MediaQuery.paddingOf(context),
    );
  }

  static _DuoNavigationScope _scopeOf(BuildContext context, _Aspect aspect) {
    of(context); // Fails with the explanation above when there is none.
    return InheritedModel.inheritFrom<_DuoNavigationScope>(
      context,
      aspect: aspect,
    )!;
  }

  @override
  State<DuoNavigation> createState() => _DuoNavigationState();
}

class _DuoNavigationState extends State<DuoNavigation> {
  StreamSubscription<DuoWindowEdges?>? _subscription;
  DuoWindowEdges? _edges;
  final BarRegionCache _regions = BarRegionCache();

  @override
  void initState() {
    super.initState();
    _listen(widget.data.windowEdgesSource);
  }

  @override
  void didUpdateWidget(DuoNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final source = widget.data.windowEdgesSource;
    if (source != oldWidget.data.windowEdgesSource) _listen(source);
  }

  void _listen(DuoWindowEdgesSource? source) {
    _subscription?.cancel();
    _subscription = source?.changes.listen((edges) {
      if (edges != _edges) setState(() => _edges = edges);
    });
    _edges = source?.value;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _regions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _regions.update(
      widget.data.barRegionSource,
      MediaQuery.maybeSizeOf(context) ?? Size.zero,
      MediaQuery.maybeViewPaddingOf(context) ?? EdgeInsets.zero,
    );
    return _DuoNavigationScope(
      data: widget.data,
      edges: _edges,
      child: BarRegionsScope(
        cache: _regions,
        child: DuoBuildersScope(builders: widget.builders, child: widget.child),
      ),
    );
  }
}

enum _Aspect { data, edges }

class _DuoNavigationScope extends InheritedModel<_Aspect> {
  const _DuoNavigationScope({
    required this.data,
    required this.edges,
    required super.child,
  });

  final DuoNavigationData data;
  final DuoWindowEdges? edges;

  @override
  bool updateShouldNotify(_DuoNavigationScope oldWidget) =>
      data != oldWidget.data || edges != oldWidget.edges;

  @override
  bool updateShouldNotifyDependent(
    _DuoNavigationScope oldWidget,
    Set<_Aspect> dependencies,
  ) =>
      (dependencies.contains(_Aspect.data) && data != oldWidget.data) ||
      (dependencies.contains(_Aspect.edges) && edges != oldWidget.edges);
}
