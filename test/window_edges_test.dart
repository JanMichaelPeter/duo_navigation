import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/testing.dart';

const _leftOnly = DockWindowEdges(left: true, right: false);
const _fullscreen = DockWindowEdges(left: true, right: true);

Widget _app(DockNavigationData data) {
  return MaterialApp(
    builder: (context, child) => DockNavigation(
      builders: const DockMaterialBuilders(),
      data: data,
      child: child!,
    ),
    home: DockShell<Object?, Object?, Object?>(
      tabs: const [
        DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
        DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
      ],
      currentIndex: 0,
      onTabSelected: (_) {},
      child: const SizedBox.expand(),
    ),
  );
}

void main() {
  Future<void> pumpWide(WidgetTester tester, DockNavigationData data) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(data));
    await tester.pumpAndSettle();
  }

  double railX(WidgetTester tester) =>
      tester.getCenter(find.byIcon(Icons.home)).dx;

  testWidgets('no source: always the preferred side', (tester) async {
    await pumpWide(tester, const DockNavigationData());
    expect(railX(tester), greaterThan(900));
  });

  testWidgets('a fixed source moves the column to the touching edge', (
    tester,
  ) async {
    await pumpWide(
      tester,
      const DockNavigationData(
        windowEdgesSource: DockWindowEdgesSource.fixed(_leftOnly),
      ),
    );
    expect(railX(tester), lessThan(100));
  });

  testWidgets('the column follows the source over time', (tester) async {
    final source = FakeWindowEdgesSource();
    await pumpWide(tester, DockNavigationData(windowEdgesSource: source));
    expect(railX(tester), greaterThan(900));

    source.push(_leftOnly); // split screen, left half
    await tester.pumpAndSettle();
    expect(railX(tester), lessThan(100));

    source.push(_fullscreen);
    await tester.pumpAndSettle();
    expect(railX(tester), greaterThan(900));

    source.push(null); // unknown again
    await tester.pumpAndSettle();
    expect(railX(tester), greaterThan(900));
  });

  testWidgets('replacing the source starts from its value', (tester) async {
    final first = FakeWindowEdgesSource(_leftOnly);
    await pumpWide(tester, DockNavigationData(windowEdgesSource: first));
    expect(railX(tester), lessThan(100));

    final second = FakeWindowEdgesSource(_fullscreen);
    await tester.pumpWidget(
      _app(DockNavigationData(windowEdgesSource: second)),
    );
    await tester.pumpAndSettle();
    expect(railX(tester), greaterThan(900));

    first.push(_leftOnly); // the old source no longer counts
    await tester.pumpAndSettle();
    expect(railX(tester), greaterThan(900));
    expect(first.hasListener, isFalse);
  });

  testWidgets('removing the source goes back to the preferred side', (
    tester,
  ) async {
    await pumpWide(
      tester,
      const DockNavigationData(
        windowEdgesSource: DockWindowEdgesSource.fixed(_leftOnly),
      ),
    );
    await tester.pumpWidget(_app(const DockNavigationData()));
    await tester.pumpAndSettle();
    expect(railX(tester), greaterThan(900));
  });
}
