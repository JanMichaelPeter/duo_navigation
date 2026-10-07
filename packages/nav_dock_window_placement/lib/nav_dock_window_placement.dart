/// Window-edge source for nav_dock backed by the window_placement plugin.
///
/// ```dart
/// final edges = WindowPlacementEdgesSource();
///
/// DockNavigation(
///   data: DockNavigationData(windowEdgesSource: edges),
///   child: ...,
/// )
/// ```
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nav_dock/geometry.dart';
import 'package:window_placement/window_placement.dart';

/// Reports which display edges the app window touches, from the
/// window_placement plugin, so nav_dock's side column follows the window to
/// the screen edge in split screen and windowing.
///
/// Detection runs on iOS, iPadOS and Android. Elsewhere, and wherever the
/// plugin has no native side (widget tests), [value] stays null and nav_dock
/// uses its preferred side. Failures are silent: a one-off query probes the
/// native side first, and the live stream is only opened if that worked.
///
/// Create one for the app and [dispose] it when the app goes away.
class WindowPlacementEdgesSource implements DockWindowEdgesSource {
  /// Starts detecting right away.
  WindowPlacementEdgesSource() {
    if (_supported) _start();
  }

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  final _detector = WindowPlacementDetector();
  final StreamController<DockWindowEdges?> _changes =
      StreamController<DockWindowEdges?>.broadcast();
  StreamSubscription<WindowPlacementInfo>? _subscription;
  DockWindowEdges? _value;
  bool _disposed = false;

  @override
  DockWindowEdges? get value => _value;

  @override
  Stream<DockWindowEdges?> get changes => _changes.stream;

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
        : DockWindowEdges(
            left: info.touchesLeftEdge,
            right: info.touchesRightEdge,
          ),
  );

  void _set(DockWindowEdges? edges) {
    if (_disposed || edges == _value) return;
    _value = edges;
    _changes.add(edges);
  }

  /// Stops listening to the plugin and closes [changes].
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _changes.close();
  }
}
