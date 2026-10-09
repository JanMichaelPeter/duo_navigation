import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _leftOnly = DuoWindowEdges(left: true, right: false);
const _fullscreen = DuoWindowEdges(left: true, right: true);

Widget _app(DuoNavigationData data) {
  return MaterialApp(
    builder: (context, child) => DuoNavigation(
      builders: const DuoMaterialBuilders(),
      data: data,
      child: child!,
    ),
    home: DuoShell<Object?, Object?, Object?>(
      tabs: const [
        DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
        DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
      ],
      currentIndex: 0,
      onTabSelected: (_) {},
      child: const SizedBox.expand(),
    ),
  );
}

void main() {
  Future<void> pumpWide(WidgetTester tester, DuoNavigationData data) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(data));
    await tester.pumpAndSettle();
  }

  double railX(WidgetTester tester) =>
      tester.getCenter(find.byIcon(Icons.home)).dx;

  testWidgets('no source: always the preferred side', (tester) async {
    await pumpWide(tester, const DuoNavigationData());
    expect(railX(tester), greaterThan(900));
  });

  testWidgets('a fixed source moves the column to the touching edge', (
    tester,
  ) async {
    await pumpWide(
      tester,
      const DuoNavigationData(
        windowEdgesSource: DuoWindowEdgesSource.fixed(_leftOnly),
      ),
    );
    expect(railX(tester), lessThan(100));
  });

  testWidgets('the column follows the source over time', (tester) async {
    final source = FakeWindowEdgesSource();
    await pumpWide(tester, DuoNavigationData(windowEdgesSource: source));
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
    await pumpWide(tester, DuoNavigationData(windowEdgesSource: first));
    expect(railX(tester), lessThan(100));

    final second = FakeWindowEdgesSource(_fullscreen);
    await tester.pumpWidget(_app(DuoNavigationData(windowEdgesSource: second)));
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
      const DuoNavigationData(
        windowEdgesSource: DuoWindowEdgesSource.fixed(_leftOnly),
      ),
    );
    await tester.pumpWidget(_app(const DuoNavigationData()));
    await tester.pumpAndSettle();
    expect(railX(tester), greaterThan(900));
  });
}
