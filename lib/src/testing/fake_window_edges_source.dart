import 'dart:async';

import '../geometry/window_edges.dart';
import '../geometry/window_edges_source.dart';

/// A [DuoWindowEdgesSource] whose edges a test changes over time, for
/// example to simulate split screen, a window moved to the other half, or a
/// fold and unfold.
///
/// ```dart
/// final edges = FakeWindowEdgesSource();
/// await tester.pumpWidget(app(DuoTestHarness(windowEdgesSource: edges, ...)));
/// edges.push(const DuoWindowEdges(left: true, right: false));
/// await tester.pumpAndSettle();
/// ```
class FakeWindowEdgesSource implements DuoWindowEdgesSource {
  /// Starts with [value] (null: unknown).
  FakeWindowEdgesSource([this._value]);

  final _changes = StreamController<DuoWindowEdges?>.broadcast(sync: true);
  DuoWindowEdges? _value;

  @override
  DuoWindowEdges? get value => _value;

  @override
  Stream<DuoWindowEdges?> get changes => _changes.stream;

  /// Reports [edges] (null: unknown) to every listener.
  void push(DuoWindowEdges? edges) {
    _value = edges;
    _changes.add(edges);
  }

  /// Whether a `DuoNavigation` is listening.
  bool get hasListener => _changes.hasListener;
}
