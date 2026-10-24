/// Window-edge and bar-region source for duo_navigation backed by the
/// window_placement plugin.
///
/// ```dart
/// final placement = WindowPlacementEdgesSource();
///
/// DuoNavigation(
///   data: DuoNavigationData(
///     windowEdgesSource: placement,
///     barRegionSource: placement,
///   ),
///   child: ...,
/// )
/// ```
library;

import 'dart:async';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:duo_navigation/geometry.dart';
import 'package:window_placement/window_placement.dart';

/// Reports which display edges the app window touches, from the
/// window_placement plugin, so duo_navigation's side column follows the window to
/// the screen edge in split screen and windowing.
///
/// Detection runs on iOS, iPadOS and Android. Elsewhere, and wherever the
/// plugin has no native side (widget tests), [value] stays null and duo_navigation
/// uses its preferred side. Failures are silent: a one-off query probes the
/// native side first, and the live stream is only opened if that worked.
///
/// It is also a [DuoBarRegionSource]: on iOS 27.1 and later it reports where
/// bars fit beside the status icons, so the side column's actions start below
/// them and the title bar sits beside them (iPhone Duo). Elsewhere it has no
/// answer and duo_navigation uses the safe area.
///
/// Create one for the app and [dispose] it when the app goes away.
class WindowPlacementEdgesSource
    implements DuoWindowEdgesSource, DuoBarRegionSource {
  /// Starts detecting right away.
  WindowPlacementEdgesSource() {
    if (_supported) _start();
  }

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  final _detector = WindowPlacementDetector();
  final StreamController<DuoWindowEdges?> _changes =
      StreamController<DuoWindowEdges?>.broadcast();
  StreamSubscription<WindowPlacementInfo>? _subscription;
  DuoWindowEdges? _value;
  bool _disposed = false;

  @override
  DuoWindowEdges? get value => _value;

  @override
  Stream<DuoWindowEdges?> get changes => _changes.stream;

  Future<void> _start() async {
    try {
      _apply(await _detector.getPlacement());
    } catch (_) {
      return; // No native side: stay unknown.
    }
    if (_disposed) return;
    _subscription = _detector.onPlacementChanged.listen(
      _apply,
      onError: (Object _) => _set(null),
    );
  }

  void _apply(WindowPlacementInfo info) => _set(
    info.placement == WindowPlacement.unknown
        ? null
        : DuoWindowEdges(
            left: info.touchesLeftEdge,
            right: info.touchesRightEdge,
          ),
  );

  void _set(DuoWindowEdges? edges) {
    if (_disposed || edges == _value) return;
    _value = edges;
    _changes.add(edges);
  }

  @override
  Future<Rect?> barRegion(DuoScreenEdge edge, double extent) async {
    if (!_supported || _disposed) return null;
    try {
      return await _detector.getBarRegion(switch (edge) {
        DuoScreenEdge.left => WindowEdge.left,
        DuoScreenEdge.top => WindowEdge.top,
        DuoScreenEdge.right => WindowEdge.right,
        DuoScreenEdge.bottom => WindowEdge.bottom,
      }, extent);
    } catch (_) {
      return null; // No native side, or an older plugin: use the safe area.
    }
  }

  /// Stops listening to the plugin and closes [changes].
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _changes.close();
  }
}
