import 'package:duo_navigation/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(TargetPlatform platform, DuoSide side) {
  return MaterialApp(
    theme: ThemeData(platform: platform),
    builder: (context, child) => DuoNavigation(
      builders: const DuoMaterialBuilders(),
      data: DuoNavigationData(side: side),
      child: child!,
    ),
    home: DuoShell<Object?, Object?, Object?>(
      tabs: const [
        DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
        DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
      ],
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => DuoPage<Object?, Object?>(
            title: const Text('Title'),
            trailing: [
              DuoAction<Object?>(id: 'edit', label: 'Edit', onPressed: () {}),
              DuoAction<Object?>(id: 'done', label: 'Done', onPressed: () {}),
            ],
            body: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    Future<void> pumpWide(WidgetTester tester, DuoSide side) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(platform, side));
      await tester.pumpAndSettle();
    }

    double x(WidgetTester tester, String text) =>
        tester.getCenter(find.text(text)).dx;

    testWidgets('${platform.name}: column at start, bar actions at start', (
      tester,
    ) async {
      await pumpWide(tester, DuoSide.start);
      expect(x(tester, 'Edit'), lessThan(x(tester, 'Done'))); // reading order
      expect(x(tester, 'Done'), lessThan(x(tester, 'Title')));
      expect(x(tester, 'Done'), lessThan(500));
    });

    testWidgets('${platform.name}: column at end, bar actions at end', (
      tester,
    ) async {
      await pumpWide(tester, DuoSide.end);
      expect(x(tester, 'Edit'), lessThan(x(tester, 'Done')));
      expect(x(tester, 'Edit'), greaterThan(x(tester, 'Title')));
      expect(x(tester, 'Edit'), greaterThan(500));
    });
  }
}
