import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_placement/window_placement.dart';
import 'package:window_placement/window_placement_platform_interface.dart';

/// Left half of a 2000 wide display: only the left edge touches.
final _leftHalf = WindowPlacementInfo.fromBounds(
  const Rect.fromLTWH(0, 0, 1000, 700),
  const Rect.fromLTWH(0, 0, 2000, 700),
);

class _FakePlacement extends WindowPlacementPlatform {
  @override
  Future<WindowPlacementInfo> getPlacement() async => _leftHalf;

  @override
  Stream<WindowPlacementInfo> get onPlacementChanged => Stream.value(_leftHalf);
}

Widget _app(DockNavigationData data) {
  return MaterialApp(
    builder: (context, child) => DockNavigation(data: data, child: child!),
    home: DockShell(
      tabs: const [
        DockTab(icon: Icon(Icons.home), label: 'Home'),
        DockTab(icon: Icon(Icons.person), label: 'Me'),
      ],
      currentIndex: 0,
      onTabSelected: (_) {},
      child: const SizedBox.expand(),
    ),
  );
}

void main() {
  Future<double> railX(WidgetTester tester, DockNavigationData data) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final real = WindowPlacementPlatform.instance;
    WindowPlacementPlatform.instance = _FakePlacement();
    addTearDown(() => WindowPlacementPlatform.instance = real);
    await tester.pumpWidget(_app(data));
    await tester.pumpAndSettle();
    return tester.getCenter(find.byIcon(Icons.home)).dx;
  }

  testWidgets('detected left half moves the column left', (tester) async {
    expect(await railX(tester, const DockNavigationData()), lessThan(100));
  });

  testWidgets('explicit windowEdges overrides detection', (tester) async {
    const fullscreen = DockWindowEdges(left: true, right: true);
    expect(
      await railX(tester, const DockNavigationData(windowEdges: fullscreen)),
      greaterThan(900),
    );
  });

  testWidgets('detectWindowEdges: false always uses side', (tester) async {
    expect(
      await railX(tester, const DockNavigationData(detectWindowEdges: false)),
      greaterThan(900),
    );
  });

  testWidgets('no plugin (web, desktop, tests): falls back to side quietly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const DockNavigationData()));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byIcon(Icons.home)).dx, greaterThan(900));
    expect(tester.takeException(), isNull);
  });
}
