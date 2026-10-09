import 'package:duo_navigation/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = [
  DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

Widget _app({
  EdgeInsets padding = EdgeInsets.zero,
  DuoNavigationData data = const DuoNavigationData(),
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: padding, viewPadding: padding),
      child: DuoNavigation(
        builders: const DuoMaterialBuilders(),
        data: data,
        child: child!,
      ),
    ),
    home: DuoShell<Object?, Object?, Object?>(
      tabs: _tabs,
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => DuoPage<Object?, Object?>(
            title: const Text('Home'),
            trailing: [
              DuoAction<Object?>(
                id: 'share',
                icon: const DuoIcon(Icons.share),
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
    DuoNavigationData data = const DuoNavigationData(),
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

  testWidgets('column sits at the window edge, over the side inset', (
    tester,
  ) async {
    await pumpWide(tester, padding: const EdgeInsets.only(right: 90));
    final rail = railRect(tester);
    expect(rail.center.dx, moreOrLessEquals(1000 - 36));
    expect(chipRect(tester).center.dx, moreOrLessEquals(rail.center.dx));
    // The column's builders see no inset on its edge.
    expect(
      MediaQuery.paddingOf(tester.element(find.byIcon(Icons.home))).right,
      0,
    );
  });

  testWidgets('safeArea: column sits after the side inset', (tester) async {
    await pumpWide(
      tester,
      padding: const EdgeInsets.only(right: 90),
      data: const DuoNavigationData(columnInset: DuoColumnInset.safeArea),
    );
    final rail = railRect(tester);
    // The 72 wide column starts after the 90 inset: 838 .. 910.
    expect(rail.center.dx, moreOrLessEquals(1000 - 90 - 36));
    expect(chipRect(tester).center.dx, moreOrLessEquals(rail.center.dx));
  });

  testWidgets('sideItemExtent sizes both rail and chips', (tester) async {
    await pumpWide(tester, data: const DuoNavigationData(sideItemExtent: 64));
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
          DuoWindowEdges(left: l, right: r).resolveRight(preferRight: prefer),
          expected,
        );
      });
    }

    testWidgets('column follows the window to the only touching edge', (
      tester,
    ) async {
      await pumpWide(
        tester,
        data: const DuoNavigationData(
          side: DuoSide.end,
          windowEdgesSource: DuoWindowEdgesSource.fixed(
            DuoWindowEdges(left: true, right: false),
          ),
        ),
      );
      expect(railRect(tester).center.dx, lessThan(100));
    });
  });
}
