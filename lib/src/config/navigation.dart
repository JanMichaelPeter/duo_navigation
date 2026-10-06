import 'package:flutter/widgets.dart';

import 'navigation_data.dart';
import 'window_edges_watcher.dart';

/// Provides [DockNavigationData]. Place it ABOVE the root Navigator
/// (e.g. `MaterialApp.builder`) so modal routes see it too.
///
/// Also watches which display edges the window touches (split screen,
/// windowing) and fills in [DockNavigationData.windowEdges], unless the
/// app set it or turned off [DockNavigationData.detectWindowEdges].
class DockNavigation extends StatefulWidget {
  /// Provides [data] to everything below, usually from `MaterialApp.builder`.
  const DockNavigation({
    super.key,
    this.data = const DockNavigationData(),
    required this.child,
  });

  /// Configuration as set by the app. [of] returns it with detected window
  /// edges filled in.
  final DockNavigationData data;

  /// The app below, usually the root Navigator.
  final Widget child;

  /// The effective data, including detected window edges.
  static DockNavigationData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_DockNavigationScope>()
          ?.data ??
      const DockNavigationData();

  @override
  State<DockNavigation> createState() => _DockNavigationState();
}

class _DockNavigationState extends State<DockNavigation> {
  WindowEdgesWatcher? _watcher;

  bool get _wantsDetection =>
      widget.data.detectWindowEdges && widget.data.windowEdges == null;

  @override
  void initState() {
    super.initState();
    _syncWatcher();
  }

  @override
  void didUpdateWidget(DockNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWatcher();
  }

  void _syncWatcher() {
    if (_wantsDetection && _watcher == null) {
      _watcher = WindowEdgesWatcher()..addListener(_onEdges);
    } else if (!_wantsDetection && _watcher != null) {
      _watcher!.dispose();
      _watcher = null;
    }
  }

  void _onEdges() => setState(() {});

  @override
  void dispose() {
    _watcher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detected = _watcher?.value;
    return _DockNavigationScope(
      data: detected == null
          ? widget.data
          : widget.data.copyWith(windowEdges: detected),
      child: widget.child,
    );
  }
}

class _DockNavigationScope extends InheritedWidget {
  const _DockNavigationScope({required this.data, required super.child});

  final DockNavigationData data;

  @override
  bool updateShouldNotify(_DockNavigationScope oldWidget) =>
      data != oldWidget.data;
}
