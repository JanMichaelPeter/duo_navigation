import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = [
  DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

/// A shell with one page that has a 'share' action counting its taps.
Widget _app(Widget Function(Widget child) harness, List<int> taps) {
  return MaterialApp(
    builder: (context, child) => harness(child!),
    home: DuoShell<Object?, Object?, Object?>(
      tabs: _tabs,
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => DuoPage<Object?, Object?>(
            title: const Text('Home'),
            trailing: [
              DuoAction<Object?>(
                id: 'share',
                icon: const DuoIcon(Icons.share),
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

  final share = find.byKey(DuoKeys.action('share'));
  double columnX(WidgetTester tester) =>
      tester.getCenter(find.byKey(DuoKeys.column)).dx;

  group('DuoTestHarness pins', () {
    testWidgets('the mode, whatever the surface', (tester) async {
      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          mode: DuoLayoutMode.compact,
          child: child,
        ),
      );
      expect(find.byKey(DuoKeys.bar), findsOneWidget);
      expect(find.byKey(DuoKeys.column), findsNothing);

      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          mode: DuoLayoutMode.wide,
          child: child,
        ),
        size: const Size(400, 800),
      );
      expect(find.byKey(DuoKeys.column), findsOneWidget);
      expect(find.byKey(DuoKeys.rail), findsOneWidget);
      expect(find.byKey(DuoKeys.bar), findsNothing);
    });

    testWidgets('the side and the text direction', (tester) async {
      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          side: DuoSide.start,
          child: child,
        ),
      );
      expect(columnX(tester), lessThan(100));

      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          textDirection: TextDirection.rtl,
          child: child,
        ),
      );
      expect(columnX(tester), lessThan(100));
    });

    testWidgets('fixed window edges', (tester) async {
      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          windowEdges: const DuoWindowEdges(left: true, right: false),
          child: child,
        ),
      );
      expect(columnX(tester), lessThan(100));
    });

    testWidgets('window edges that change over time', (tester) async {
      final edges = FakeWindowEdgesSource();
      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          windowEdgesSource: edges,
          child: child,
        ),
      );
      expect(edges.hasListener, isTrue);
      expect(columnX(tester), greaterThan(900));

      edges.push(const DuoWindowEdges(left: true, right: false));
      await tester.pump();
      expect(columnX(tester), lessThan(100));

      edges.push(null);
      await tester.pump();
      expect(columnX(tester), greaterThan(900));
    });

    testWidgets('on top of a given configuration', (tester) async {
      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          data: const DuoNavigationData(sideColumnWidth: 100),
          mode: DuoLayoutMode.wide,
          child: child,
        ),
      );
      expect(tester.getSize(find.byKey(DuoKeys.column)).width, 100);
    });
  });

  group('tap guard time', () {
    testWidgets('follows the frames in the harness', (tester) async {
      final taps = await pump(
        tester,
        (child) =>
            DuoTestHarness(builders: const DuoMaterialBuilders(), child: child),
      );
      await tester.tap(share);
      await tester.tap(share); // same frame: within the cooldown
      expect(taps, hasLength(1));

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(share);
      expect(taps, hasLength(2));
    });

    testWidgets('can be a fake clock', (tester) async {
      final clock = FakeDuoClock();
      final taps = await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          tapGuard: DuoTapGuard(clock: clock),
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
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          tapGuard: DuoTapGuard.disabled,
          child: child,
        ),
      );
      await tester.tap(share);
      await tester.tap(share);
      expect(taps, hasLength(2));
    });
  });

  group('DuoKeys', () {
    testWidgets('find an action in the bar and in the column', (tester) async {
      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          mode: DuoLayoutMode.compact,
          child: child,
        ),
      );
      expect(
        find.descendant(of: find.byType(AppBar), matching: share),
        findsOneWidget,
      );

      await pump(
        tester,
        (child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          mode: DuoLayoutMode.wide,
          child: child,
        ),
      );
      expect(
        find.descendant(of: find.byKey(DuoKeys.column), matching: share),
        findsOneWidget,
      );
    });

    test('are equal for equal ids and print readably', () {
      expect(DuoKeys.action('a'), DuoKeys.action('a'));
      expect(DuoKeys.action('a'), isNot(DuoKeys.action('b')));
      expect(DuoKeys.action(1), isNot(DuoKeys.action('1')));
      expect(DuoKeys.action('a').toString(), contains("DuoKeys.action(a)"));
    });
  });
}
