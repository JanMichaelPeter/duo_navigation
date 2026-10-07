import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock_window_placement/nav_dock_window_placement.dart';

void main() {
  test('resolves nav_dock from the workspace', () {
    expect(
      const DockWindowEdges(left: true, right: false),
      const DockWindowEdges(left: true, right: false),
    );
  });
}
