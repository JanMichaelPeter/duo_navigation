import 'dart:async';

import '../geometry/window_edges.dart';
import '../geometry/window_edges_source.dart';

/// A [DockWindowEdgesSource] whose edges a test changes over time, for
/// example to simulate split screen, a window moved to the other half, or a
/// fold and unfold.
///
/// ```dart
/// final edges = FakeWindowEdgesSource();
/// await tester.pumpWidget(app(DockTestHarness(windowEdgesSource: edges, ...)));
/// edges.push(const DockWindowEdges(left: true, right: false));
/// await tester.pumpAndSettle();
/// ```
class FakeWindowEdgesSource implements DockWindowEdgesSource {
  /// Starts with [value] (null: unknown).
  FakeWindowEdgesSource([this._value]);

  final _changes = StreamController<DockWindowEdges?>.broadcast(sync: true);
  DockWindowEdges? _value;

  @override
  DockWindowEdges? get value => _value;

  @override
  Stream<DockWindowEdges?> get changes => _changes.stream;

  /// Reports [edges] (null: unknown) to every listener.
  void push(DockWindowEdges? edges) {
    _value = edges;
    _changes.add(edges);
  }

  /// Whether a `DockNavigation` is listening.
  bool get hasListener => _changes.hasListener;
}
