// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:window_placement/window_placement.dart';

import '../models/window_edges.dart';

/// Live [DockWindowEdges] from the window_placement plugin; null while
/// unknown.
///
/// Fails silently wherever the plugin isn't available (web, desktop, widget
/// tests): a one-off query probes the native side first, and the live stream
/// is only opened if that worked. Its event channel would otherwise report a
/// MissingPluginException through FlutterError.
class WindowEdgesWatcher extends ValueNotifier<DockWindowEdges?> {
  WindowEdgesWatcher() : super(null) {
    if (_supported) _start();
  }

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  final _detector = WindowPlacementDetector();
  StreamSubscription<WindowPlacementInfo>? _subscription;
  bool _disposed = false;

  Future<void> _start() async {
    try {
      _apply(await _detector.getPlacement());
    } catch (_) {
      return; // No native side: stay unknown.
    }
    if (_disposed) return;
    _subscription = _detector.onPlacementChanged.listen(
      _apply,
      onError: (Object _) => value = null,
    );
  }

  void _apply(WindowPlacementInfo info) {
    if (_disposed) return;
    value = info.placement == WindowPlacement.unknown
        ? null
        : DockWindowEdges(
            left: info.touchesLeftEdge,
            right: info.touchesRightEdge,
          );
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
