import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(TargetPlatform platform, DockSide side) {
  return MaterialApp(
    theme: ThemeData(platform: platform),
    builder: (context, child) => DockNavigation(
      builders: const DockMaterialBuilders(),
      data: DockNavigationData(side: side),
      child: child!,
    ),
    home: DockShell<Object?, Object?, Object?>(
      tabs: const [
        DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
        DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
      ],
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => DockPage<Object?, Object?>(
            title: const Text('Title'),
            trailing: [
              DockAction<Object?>(id: 'edit', label: 'Edit', onPressed: () {}),
              DockAction<Object?>(id: 'done', label: 'Done', onPressed: () {}),
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
    Future<void> pumpWide(WidgetTester tester, DockSide side) async {
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
      await pumpWide(tester, DockSide.start);
      expect(x(tester, 'Edit'), lessThan(x(tester, 'Done'))); // reading order
      expect(x(tester, 'Done'), lessThan(x(tester, 'Title')));
      expect(x(tester, 'Done'), lessThan(500));
    });

    testWidgets('${platform.name}: column at end, bar actions at end', (
      tester,
    ) async {
      await pumpWide(tester, DockSide.end);
      expect(x(tester, 'Edit'), lessThan(x(tester, 'Done')));
      expect(x(tester, 'Edit'), greaterThan(x(tester, 'Title')));
      expect(x(tester, 'Edit'), greaterThan(500));
    });
  }
}
