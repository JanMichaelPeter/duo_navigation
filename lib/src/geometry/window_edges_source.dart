import 'package:flutter/foundation.dart';

import 'window_edges.dart';

/// Reports which display edges the app window touches, so the side column can
/// follow the window to the screen edge in split screen and windowing.
///
/// Set one on `DockNavigationData.windowEdgesSource`. `DockNavigation` reads
/// [value] when it starts listening and then follows [changes]. The app owns
/// the source: create it once and dispose it when the app goes away.
///
/// The package `nav_dock_window_placement` provides a source backed by the
/// native window_placement plugin. Tests can use
/// [DockWindowEdgesSource.fixed] or a fake.
abstract interface class DockWindowEdgesSource {
  /// A source that always reports [edges] and never changes.
  const factory DockWindowEdgesSource.fixed(DockWindowEdges? edges) =
      _FixedEdgesSource;

  /// The current edges, or null while unknown (then the preferred side is
  /// used).
  DockWindowEdges? get value;

  /// Every later change of [value]. Must allow more than one listener over
  /// time (a broadcast stream), because `DockNavigation` listens again when
  /// its configuration changes.
  Stream<DockWindowEdges?> get changes;
}

@immutable
class _FixedEdgesSource implements DockWindowEdgesSource {
  const _FixedEdgesSource(this.value);

  @override
  final DockWindowEdges? value;

  @override
  Stream<DockWindowEdges?> get changes => const Stream.empty();

  @override
  bool operator ==(Object other) =>
      other is _FixedEdgesSource && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
