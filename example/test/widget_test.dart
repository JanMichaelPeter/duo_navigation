import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_placement/window_placement.dart';
import 'package:window_placement/window_placement_platform_interface.dart';

import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock_example/main.dart';
import 'package:nav_dock_example/main_go_router.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
  }

  Finder inAppBar(Finder finder) =>
      find.descendant(of: find.byType(AppBar), matching: finder);

  testWidgets('compact: capsule tab bar, actions in app bar', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(find.text('Map'), findsOneWidget); // tab label
    expect(find.text('3'), findsOneWidget); // Items tab badge
    expect(inAppBar(find.byIcon(Icons.add)), findsOneWidget);

    await tester.tap(find.text('Go deeper'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Level 1'), findsOneWidget);
    expect(inAppBar(find.byType(BackButtonIcon)), findsOneWidget);
  });

  testWidgets('wide: actions move to the column, back chip pops',
      (tester) async {
    await pumpAt(tester, const Size(1024, 768));
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(inAppBar(find.byIcon(Icons.add)), findsNothing);

    await tester.tap(find.text('Go deeper'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Level 1'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Items'), findsOneWidget);
  });

  testWidgets('setup flow: step 1 closes the flow, later steps go back',
      (tester) async {
    await pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run setup flow'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(inAppBar(find.byIcon(Icons.close)), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(inAppBar(find.byType(BackButtonIcon)), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    // Back and close are one action, and the app's tap guard runs on real
    // time: wait out its cooldown as a user would.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.tap(inAppBar(find.byIcon(Icons.close)));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsNothing);
    expect(find.text('Run setup flow'), findsOneWidget);
  });

  testWidgets('tab switch moves the column to the new page', (tester) async {
    await pumpAt(tester, const Size(1024, 768));
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('rail divider only shows when the column has actions',
      (tester) async {
    await pumpAt(tester, const Size(1024, 768));
    double dividerOpacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(
            of: find.byType(Divider), matching: find.byType(AnimatedOpacity)))
        .opacity;

    expect(dividerOpacity(), 1); // Items: "add" chip

    // Profile: only "Edit", a text action that stays in the title bar.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(dividerOpacity(), 0);

    // Settings: a plain Scaffold page, the column holds only the rail.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(dividerOpacity(), 0);
  });

  testWidgets('a plain Scaffold page reads the layout', (tester) async {
    await pumpAt(tester, const Size(1024, 768));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.textContaining('wide, column on the end edge'), findsOneWidget);
  });

  testWidgets('the map bleeds under the chrome', (tester) async {
    await pumpAt(tester, const Size(1024, 768));
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    final map = find.descendant(
      of: find.byType(DockBleed),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getRect(map.first).right, 1024);
    // The column covers the map's right edge.
    expect(tester.getRect(find.byKey(DockKeys.column)).right, 1024);
  });

  testWidgets('the camera page hides the navigation', (tester) async {
    await pumpAt(tester, const Size(1024, 768));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    final camera = tester.element(find.byIcon(Icons.camera_alt_outlined));
    expect(DockGeometry.of(camera).isHidden, isTrue);

    // The close button stays reachable in the bar, at the top right.
    final close = inAppBar(find.byIcon(Icons.close));
    expect(tester.getRect(close).right,
        greaterThan(tester.getRect(find.byType(AppBar)).width - 64));
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(
      DockGeometry.of(tester.element(find.text('Camera'))).isHidden,
      isFalse,
    );
  });

  for (final size in const [Size(390, 844), Size(1024, 768)]) {
    testWidgets('the edit modal has a text Cancel at ${size.width}', (
      tester,
    ) async {
      await pumpAt(tester, size);
      await tester.tap(find.byKey(DockKeys.tab('profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(inAppBar(find.text('Cancel')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsNothing);
    });
  }

  testWidgets('the go_router setup works the same', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GoRouterExampleApp());
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Items'), findsOneWidget);
    await tester.tap(find.byKey(DockKeys.tab('map')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  testWidgets('column follows the window to the only touching edge',
      (tester) async {
    final placements = StreamController<WindowPlacementInfo>.broadcast();
    addTearDown(placements.close);
    final real = WindowPlacementPlatform.instance;
    WindowPlacementPlatform.instance = _FakePlacement(placements.stream);
    addTearDown(() => WindowPlacementPlatform.instance = real);
    await pumpAt(tester, const Size(1024, 768));
    final rail = find.byIcon(Icons.list_alt);

    // Left half of a 2048 wide display: only the left edge touches.
    placements.add(WindowPlacementInfo.fromBounds(
      const Rect.fromLTWH(0, 0, 1024, 768),
      const Rect.fromLTWH(0, 0, 2048, 768),
    ));
    await tester.pumpAndSettle();
    expect(tester.getCenter(rail).dx, lessThan(100));

    // Bar actions follow the column: Profile's "Edit" moves to the left.
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Edit')).dx, lessThan(512));
    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();

    // Fullscreen: both touch, back to the preferred (right) edge.
    placements.add(WindowPlacementInfo.fromBounds(
      const Rect.fromLTWH(0, 0, 1024, 768),
      const Rect.fromLTWH(0, 0, 1024, 768),
    ));
    await tester.pumpAndSettle();
    expect(tester.getCenter(rail).dx, greaterThan(1024 - 100));
  });
}

/// Stands in for the native side of window_placement.
class _FakePlacement extends WindowPlacementPlatform {
  _FakePlacement(this.changes);

  final Stream<WindowPlacementInfo> changes;

  @override
  Future<WindowPlacementInfo> getPlacement() async =>
      WindowPlacementInfo.unknown;

  @override
  Stream<WindowPlacementInfo> get onPlacementChanged => changes;
}
