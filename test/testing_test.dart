import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock/testing.dart';

const _tabs = [
  DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

/// A shell with one page that has a 'share' action counting its taps.
Widget _app(Widget Function(Widget child) harness, List<int> taps) {
  return MaterialApp(
    builder: (context, child) => harness(child!),
    home: DockShell<Object?, Object?>(
      tabs: _tabs,
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => DockPage<Object?>(
            title: const Text('Home'),
            trailing: [
              DockAction<Object?>(
                id: 'share',
                icon: const DockIcon(Icons.share),
                onPressed: () => taps.add(taps.length),
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
  Future<List<int>> pump(
    WidgetTester tester,
    Widget Function(Widget child) harness, {
    Size size = const Size(1000, 700),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final taps = <int>[];
    await tester.pumpWidget(_app(harness, taps));
    await tester.pumpAndSettle();
    return taps;
  }

  final share = find.byKey(DockKeys.action('share'));
  double columnX(WidgetTester tester) =>
      tester.getCenter(find.byKey(DockKeys.column)).dx;

  group('DockTestHarness pins', () {
    testWidgets('the mode, whatever the surface', (tester) async {
      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          mode: DockLayoutMode.compact,
          child: child,
        ),
      );
      expect(find.byKey(DockKeys.bar), findsOneWidget);
      expect(find.byKey(DockKeys.column), findsNothing);

      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          mode: DockLayoutMode.wide,
          child: child,
        ),
        size: const Size(400, 800),
      );
      expect(find.byKey(DockKeys.column), findsOneWidget);
      expect(find.byKey(DockKeys.rail), findsOneWidget);
      expect(find.byKey(DockKeys.bar), findsNothing);
    });

    testWidgets('the side and the text direction', (tester) async {
      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          side: DockSide.start,
          child: child,
        ),
      );
      expect(columnX(tester), lessThan(100));

      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          textDirection: TextDirection.rtl,
          child: child,
        ),
      );
      expect(columnX(tester), lessThan(100));
    });

    testWidgets('fixed window edges', (tester) async {
      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          windowEdges: const DockWindowEdges(left: true, right: false),
          child: child,
        ),
      );
      expect(columnX(tester), lessThan(100));
    });

    testWidgets('window edges that change over time', (tester) async {
      final edges = FakeWindowEdgesSource();
      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          windowEdgesSource: edges,
          child: child,
        ),
      );
      expect(edges.hasListener, isTrue);
      expect(columnX(tester), greaterThan(900));

      edges.push(const DockWindowEdges(left: true, right: false));
      await tester.pump();
      expect(columnX(tester), lessThan(100));

      edges.push(null);
      await tester.pump();
      expect(columnX(tester), greaterThan(900));
    });

    testWidgets('on top of a given configuration', (tester) async {
      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          data: const DockNavigationData(sideColumnWidth: 100),
          mode: DockLayoutMode.wide,
          child: child,
        ),
      );
      expect(tester.getSize(find.byKey(DockKeys.column)).width, 100);
    });
  });

  group('tap guard time', () {
    testWidgets('follows the frames in the harness', (tester) async {
      final taps = await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          child: child,
        ),
      );
      await tester.tap(share);
      await tester.tap(share); // same frame: within the cooldown
      expect(taps, hasLength(1));

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(share);
      expect(taps, hasLength(2));
    });

    testWidgets('can be a fake clock', (tester) async {
      final clock = FakeDockClock();
      final taps = await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          tapGuard: DockTapGuard(clock: clock),
          child: child,
        ),
      );
      await tester.tap(share);
      await tester.pump(const Duration(seconds: 1)); // frames don't count
      await tester.tap(share);
      expect(taps, hasLength(1));

      clock.advance(const Duration(milliseconds: 350));
      await tester.tap(share);
      expect(taps, hasLength(2));
    });

    testWidgets('a disabled guard lets every tap through', (tester) async {
      final taps = await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          tapGuard: DockTapGuard.disabled,
          child: child,
        ),
      );
      await tester.tap(share);
      await tester.tap(share);
      expect(taps, hasLength(2));
    });
  });

  group('DockKeys', () {
    testWidgets('find an action in the bar and in the column', (tester) async {
      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          mode: DockLayoutMode.compact,
          child: child,
        ),
      );
      expect(
        find.descendant(of: find.byType(AppBar), matching: share),
        findsOneWidget,
      );

      await pump(
        tester,
        (child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          mode: DockLayoutMode.wide,
          child: child,
        ),
      );
      expect(
        find.descendant(of: find.byKey(DockKeys.column), matching: share),
        findsOneWidget,
      );
    });

    test('are equal for equal ids and print readably', () {
      expect(DockKeys.action('a'), DockKeys.action('a'));
      expect(DockKeys.action('a'), isNot(DockKeys.action('b')));
      expect(DockKeys.action(1), isNot(DockKeys.action('1')));
      expect(DockKeys.action('a').toString(), contains("DockKeys.action(a)"));
    });
  });
}
