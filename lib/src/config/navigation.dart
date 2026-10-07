import 'dart:async';

import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../geometry/layout_mode.dart';
import '../geometry/side.dart';
import '../geometry/window_edges.dart';
import '../geometry/window_edges_source.dart';
import 'navigation_data.dart';

/// Provides [DockNavigationData] to the app. Place it above the root
/// `Navigator` (usually in `MaterialApp.builder`), so pages pushed on the root
/// navigator see it too.
///
/// It also listens to [DockNavigationData.windowEdgesSource], once for the
/// whole app, and moves the side column to the edge the window touches.
class DockNavigation extends StatefulWidget {
  /// Provides [data] and [builders] to [child].
  const DockNavigation({
    super.key,
    this.data = const DockNavigationData(),
    this.builders,
    required this.child,
  });

  /// The configuration.
  final DockNavigationData data;

  /// The app's visuals, for example `const DockMaterialBuilders()` from
  /// `package:nav_dock/material.dart`. Shells, modal frames and
  /// [DockBuildersScope]s can override them field by field.
  ///
  /// Optional: an app that only reads the layout (`DockNavigation.modeOf`,
  /// `DockGeometry`) needs none. A frame that needs a builder no scope sets
  /// fails with a [FlutterError] naming it.
  final DockBuilders<Object?>? builders;

  /// The app below, usually the root `Navigator`.
  final Widget child;

  /// The configuration of the nearest [DockNavigation].
  ///
  /// Throws a [FlutterError] if there is none: nav_dock does not guess a
  /// layout. Use [maybeOf] where a missing [DockNavigation] is expected.
  static DockNavigationData of(BuildContext context) {
    final data = maybeOf(context);
    if (data != null) return data;
    throw FlutterError.fromParts([
      ErrorSummary('No DockNavigation found.'),
      ErrorDescription(
        '${context.widget.runtimeType} needs a DockNavigation above it to '
        'know how navigation is laid out.',
      ),
      ErrorHint(
        'Wrap the app in a DockNavigation above the root Navigator, for '
        'example:\n'
        '  MaterialApp(\n'
        '    builder: (context, child) => DockNavigation(child: child!),\n'
        '  )\n'
        'In tests, wrap the widget under test the same way.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// The configuration of the nearest [DockNavigation], or null if there is
  /// none.
  static DockNavigationData? maybeOf(BuildContext context) =>
      InheritedModel.inheritFrom<_DockNavigationScope>(
        context,
        aspect: _Aspect.data,
      )?.data;

  /// The window edges last reported by
  /// [DockNavigationData.windowEdgesSource], or null while unknown or without
  /// a source.
  static DockWindowEdges? windowEdgesOf(BuildContext context) =>
      _scopeOf(context, _Aspect.edges).edges;

  /// The layout mode for the window, from [DockNavigationData.layoutPolicy].
  ///
  /// Use it outside any shell or modal frame. Inside one, the frame's own mode
  /// is authoritative.
  static DockLayoutMode modeOf(BuildContext context) {
    final window = MediaQuery.sizeOf(context);
    return of(context).layoutPolicy.resolve(window: window, frame: window);
  }

  /// The edge the side column is on: [DockNavigationData.side], moved to the
  /// other edge when the window touches only that one.
  static DockSide sideOf(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return sideOnRight(context) == ltr ? DockSide.end : DockSide.start;
  }

  /// Whether the side column is on the physical right edge (see [sideOf]).
  static bool sideOnRight(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final preferRight = (of(context).side == DockSide.end) == ltr;
    return windowEdgesOf(context)?.resolveRight(preferRight: preferRight) ??
        preferRight;
  }

  static _DockNavigationScope _scopeOf(BuildContext context, _Aspect aspect) {
    of(context); // Fails with the explanation above when there is none.
    return InheritedModel.inheritFrom<_DockNavigationScope>(
      context,
      aspect: aspect,
    )!;
  }

  @override
  State<DockNavigation> createState() => _DockNavigationState();
}

class _DockNavigationState extends State<DockNavigation> {
  StreamSubscription<DockWindowEdges?>? _subscription;
  DockWindowEdges? _edges;

  @override
  void initState() {
    super.initState();
    _listen(widget.data.windowEdgesSource);
  }

  @override
  void didUpdateWidget(DockNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final source = widget.data.windowEdgesSource;
    if (source != oldWidget.data.windowEdgesSource) _listen(source);
  }

  void _listen(DockWindowEdgesSource? source) {
    _subscription?.cancel();
    _subscription = source?.changes.listen((edges) {
      if (edges != _edges) setState(() => _edges = edges);
    });
    _edges = source?.value;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DockNavigationScope(
      data: widget.data,
      edges: _edges,
      child: DockBuildersScope(builders: widget.builders, child: widget.child),
    );
  }
}

enum _Aspect { data, edges }

class _DockNavigationScope extends InheritedModel<_Aspect> {
  const _DockNavigationScope({
    required this.data,
    required this.edges,
    required super.child,
  });

  final DockNavigationData data;
  final DockWindowEdges? edges;

  @override
  bool updateShouldNotify(_DockNavigationScope oldWidget) =>
      data != oldWidget.data || edges != oldWidget.edges;

  @override
  bool updateShouldNotifyDependent(
    _DockNavigationScope oldWidget,
    Set<_Aspect> dependencies,
  ) =>
      (dependencies.contains(_Aspect.data) && data != oldWidget.data) ||
      (dependencies.contains(_Aspect.edges) && edges != oldWidget.edges);
}
