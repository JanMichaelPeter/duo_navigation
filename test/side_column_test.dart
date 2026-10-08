import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = [
  DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

Widget _app({
  EdgeInsets padding = EdgeInsets.zero,
  DockNavigationData data = const DockNavigationData(),
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: padding, viewPadding: padding),
      child: DockNavigation(
        builders: const DockMaterialBuilders(),
        data: data,
        child: child!,
      ),
    ),
    home: DockShell<Object?, Object?>(
      tabs: _tabs,
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => DockPage<Object?>(
            title: const Text('Home'),
            trailing: [
              DockAction<Object?>(
                id: 'share',
                icon: const DockIcon(Icons.share),
                onPressed: () {},
              ),
            ],
            body: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  Future<void> pumpWide(
    WidgetTester tester, {
    EdgeInsets? padding,
    DockNavigationData data = const DockNavigationData(),
  }) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(padding: padding ?? EdgeInsets.zero, data: data),
    );
    await tester.pumpAndSettle();
  }

  // at(1): skip the IconButton's own Material, take the chip / pill around it.
  Rect chipRect(WidgetTester tester) => tester.getRect(
    find
        .ancestor(of: find.byIcon(Icons.share), matching: find.byType(Material))
        .at(1),
  );

  Rect railRect(WidgetTester tester) => tester.getRect(
    find
        .ancestor(of: find.byIcon(Icons.home), matching: find.byType(Material))
        .at(1),
  );

  testWidgets('action chips and rail share one centre line and width', (
    tester,
  ) async {
    await pumpWide(tester);
    final chip = chipRect(tester);
    final rail = railRect(tester);
    expect(chip.center.dx, moreOrLessEquals(rail.center.dx));
    expect(chip.width, moreOrLessEquals(rail.width));
  });

  testWidgets('column sits inside the safe area, after the side inset', (
    tester,
  ) async {
    await pumpWide(tester, padding: const EdgeInsets.only(right: 90));
    final rail = railRect(tester);
    // The 72 wide column starts after the 90 inset: 838 .. 910.
    expect(rail.center.dx, moreOrLessEquals(1000 - 90 - 36));
    expect(chipRect(tester).center.dx, moreOrLessEquals(rail.center.dx));
  });

  testWidgets('sideItemExtent sizes both rail and chips', (tester) async {
    await pumpWide(tester, data: const DockNavigationData(sideItemExtent: 64));
    expect(chipRect(tester).width, moreOrLessEquals(64));
    expect(railRect(tester).width, moreOrLessEquals(64));
  });

  group('window edges', () {
    const right = true, left = false;
    for (final (l, r, prefer, expected) in const [
      (true, true, right, right), // both touch: priority wins
      (false, false, right, right), // floating: priority wins
      (false, true, right, right),
      (true, false, right, left), // only left touches: move left
      (true, false, left, left),
      (false, true, left, right), // only right touches: move right
    ]) {
      test('touches left=$l right=$r, prefer right=$prefer', () {
        expect(
          DockWindowEdges(left: l, right: r).resolveRight(preferRight: prefer),
          expected,
        );
      });
    }

    testWidgets('column follows the window to the only touching edge', (
      tester,
    ) async {
      await pumpWide(
        tester,
        data: const DockNavigationData(
          side: DockSide.end,
          windowEdgesSource: DockWindowEdgesSource.fixed(
            DockWindowEdges(left: true, right: false),
          ),
        ),
      );
      expect(railRect(tester).center.dx, lessThan(100));
    });
  });
}
