import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock_window_placement/nav_dock_window_placement.dart';
import 'package:window_placement/window_placement.dart';
import 'package:window_placement/window_placement_platform_interface.dart';

/// Left half of a 2000 wide display: only the left edge touches.
final _leftHalf = WindowPlacementInfo.fromBounds(
  const Rect.fromLTWH(0, 0, 1000, 700),
  const Rect.fromLTWH(0, 0, 2000, 700),
);

final _fullscreen = WindowPlacementInfo.fromBounds(
  const Rect.fromLTWH(0, 0, 1000, 700),
  const Rect.fromLTWH(0, 0, 1000, 700),
);

/// Stands in for the native side of window_placement.
class _FakePlacement extends WindowPlacementPlatform {
  _FakePlacement(this.initial);

  final WindowPlacementInfo initial;
  final changes = StreamController<WindowPlacementInfo>.broadcast();

  @override
  Future<WindowPlacementInfo> getPlacement() async => initial;

  @override
  Stream<WindowPlacementInfo> get onPlacementChanged => changes.stream;
}

/// The plugin without a native side (web, desktop, plain widget tests).
class _MissingPlacement extends WindowPlacementPlatform {
  @override
  Future<WindowPlacementInfo> getPlacement() =>
      Future.error(MissingPluginException());

  @override
  Stream<WindowPlacementInfo> get onPlacementChanged =>
      Stream.error(MissingPluginException());
}

void main() {
  late WindowPlacementPlatform real;
  setUp(() => real = WindowPlacementPlatform.instance);
  tearDown(() {
    WindowPlacementPlatform.instance = real;
    debugDefaultTargetPlatformOverride = null;
  });

  Future<WindowPlacementEdgesSource> start(
    WindowPlacementPlatform platform,
  ) async {
    WindowPlacementPlatform.instance = platform;
    final source = WindowPlacementEdgesSource();
    addTearDown(source.dispose);
    await pumpEventQueue();
    return source;
  }

  test('reports the detected edges and their changes', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final platform = _FakePlacement(_leftHalf);
    final source = await start(platform);
    expect(source.value, const DockWindowEdges(left: true, right: false));

    final reported = <DockWindowEdges?>[];
    source.changes.listen(reported.add);
    platform.changes.add(_fullscreen);
    platform.changes.add(_fullscreen); // unchanged: not reported again
    await pumpEventQueue();
    expect(reported, [const DockWindowEdges(left: true, right: true)]);
    expect(source.value, const DockWindowEdges(left: true, right: true));
  });

  test('unknown placement reports null', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final source = await start(_FakePlacement(WindowPlacementInfo.unknown));
    expect(source.value, isNull);
  });

  test('stays unknown without a native side, and quietly', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final source = await start(_MissingPlacement());
    expect(source.value, isNull);
  });

  test('does not query the plugin on unsupported platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final source = await start(_FakePlacement(_leftHalf));
    expect(source.value, isNull);
  });

  test('dispose closes the change stream', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final source = await start(_FakePlacement(_leftHalf));
    final done = expectLater(source.changes, emitsDone);
    source.dispose();
    await done;
  });

  testWidgets('moves the column to the edge the window touches', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    WindowPlacementPlatform.instance = _FakePlacement(_leftHalf);
    final source = WindowPlacementEdgesSource();
    addTearDown(source.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DockNavigation(
          builders: const DockMaterialBuilders(),
          data: DockNavigationData(windowEdgesSource: source),
          child: child!,
        ),
        home: DockShell(
          tabs: const [
            DockTab<Object?>(
              id: 'home',
              icon: DockIcon(Icons.home),
              label: 'Home',
            ),
            DockTab<Object?>(
              id: 'me',
              icon: DockIcon(Icons.person),
              label: 'Me',
            ),
          ],
          currentIndex: 0,
          onTabSelected: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.byIcon(Icons.home)).dx, lessThan(100));
    debugDefaultTargetPlatformOverride = null;
  });
}
