import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/testing.dart';

const _tabs = [
  DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

/// Counts builds of a widget that depends on [read].
class _Probe extends StatelessWidget {
  const _Probe(this.read, this.builds);

  final void Function(BuildContext context) read;
  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    read(context);
    builds.add(builds.length);
    return const SizedBox();
  }
}

void main() {
  group('DockNavigation.of', () {
    testWidgets('fails loudly without a DockNavigation', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(DockNavigation.maybeOf(context), isNull);
      expect(
        () => DockNavigation.of(context),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toStringDeep(),
            'message',
            allOf(
              contains('No DockNavigation found.'),
              contains('MaterialApp('),
            ),
          ),
        ),
      );
    });

    testWidgets('a DockPage without DockNavigation fails instead of '
        'guessing a layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DockPage<Object?, Object?>(body: SizedBox())),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('No DockNavigation found.'),
        ),
      );
    });

    testWidgets('equal data does not notify dependents', (tester) async {
      final builds = <int>[];
      // The same instance every time, so only a notification rebuilds it.
      final probe = _Probe(DockNavigation.of, builds);
      Widget app(DockNavigationData data) => DockNavigation(
        builders: const DockMaterialBuilders(),
        data: data,
        child: probe,
      );

      await tester.pumpWidget(app(const DockNavigationData()));
      // Equal but not identical (not const).
      await tester.pumpWidget(app(DockNavigationData(sideColumnWidth: 72)));
      expect(builds, hasLength(1));

      await tester.pumpWidget(app(DockNavigationData(sideColumnWidth: 80)));
      expect(builds, hasLength(2));
    });
  });

  group('window-edge changes', () {
    testWidgets('rebuild side readers only', (tester) async {
      final source = FakeWindowEdgesSource();
      final configBuilds = <int>[];
      final sideBuilds = <int>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DockNavigation(
            builders: const DockMaterialBuilders(),
            data: DockNavigationData(windowEdgesSource: source),
            child: Column(
              children: [
                _Probe(DockNavigation.of, configBuilds),
                _Probe(DockNavigation.sideOf, sideBuilds),
              ],
            ),
          ),
        ),
      );

      source.push(const DockWindowEdges(left: true, right: false));
      await tester.pumpAndSettle();
      expect(configBuilds, hasLength(1));
      expect(sideBuilds, hasLength(2));
    });
  });

  group('DockNavigationData', () {
    test('has value equality', () {
      expect(
        const DockNavigationData(),
        DockNavigationData(layoutPolicy: DockLayoutPolicy.breakpoint(600)),
      );
      expect(
        const DockNavigationData().hashCode,
        DockNavigationData(sideColumnWidth: 72).hashCode,
      );
      expect(
        const DockNavigationData(),
        isNot(const DockNavigationData(side: DockSide.start)),
      );
      expect(
        const DockNavigationData(),
        isNot(const DockNavigationData(actionAnimationCurve: Curves.linear)),
      );
    });

    test('copyWith can remove the window-edge source', () {
      const source = DockWindowEdgesSource.fixed(
        DockWindowEdges(left: true, right: false),
      );
      const data = DockNavigationData(windowEdgesSource: source);
      expect(data.copyWith().windowEdgesSource, source);
      expect(data.copyWith(side: DockSide.start).windowEdgesSource, source);
      expect(data.copyWith(windowEdgesSource: null).windowEdgesSource, isNull);
    });
  });

  group('layout policy', () {
    test('breakpoint uses the window width', () {
      const policy = DockLayoutPolicy.breakpoint(600);
      expect(
        policy.resolve(window: const Size(600, 400), frame: const Size(10, 10)),
        DockLayoutMode.wide,
      );
      expect(
        policy.resolve(
          window: const Size(599, 900),
          frame: const Size(900, 900),
        ),
        DockLayoutMode.compact,
      );
    });

    test('fixed ignores the size', () {
      const policy = DockLayoutPolicy.fixed(DockLayoutMode.compact);
      expect(
        policy.resolve(
          window: const Size(2000, 1000),
          frame: const Size(2000, 1000),
        ),
        DockLayoutMode.compact,
      );
    });

    test('has value equality', () {
      expect(
        const DockLayoutPolicy.breakpoint(466),
        // ignore: prefer_const_constructors
        DockLayoutPolicy.breakpoint(466),
      );
      expect(
        const DockLayoutPolicy.breakpoint(466),
        isNot(const DockLayoutPolicy.breakpoint(600)),
      );
      expect(
        const DockLayoutPolicy.fixed(DockLayoutMode.wide),
        // ignore: prefer_const_constructors
        DockLayoutPolicy.fixed(DockLayoutMode.wide),
      );
    });

    testWidgets('a fixed compact policy gives the bottom bar on a wide '
        'surface', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DockNavigation(
            builders: const DockMaterialBuilders(),
            data: const DockNavigationData(
              layoutPolicy: DockLayoutPolicy.fixed(DockLayoutMode.compact),
            ),
            child: child!,
          ),
          home: DockShell<Object?, Object?, Object?>(
            tabs: _tabs,
            currentIndex: 0,
            onTabSelected: (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('without a frame', () {
    Future<BuildContext> pump(
      WidgetTester tester,
      DockNavigationData data, {
      TextDirection direction = TextDirection.ltr,
      Size size = const Size(1000, 700),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext context;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Directionality(
            textDirection: direction,
            child: DockNavigation(
              builders: const DockMaterialBuilders(),
              data: data,
              child: Builder(
                builder: (c) {
                  context = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      return context;
    }

    testWidgets('modeOf follows the policy and the window', (tester) async {
      var context = await pump(tester, const DockNavigationData());
      expect(DockNavigation.modeOf(context), DockLayoutMode.wide);
      context = await pump(
        tester,
        const DockNavigationData(),
        size: const Size(400, 800),
      );
      expect(DockNavigation.modeOf(context), DockLayoutMode.compact);
    });

    testWidgets('sideOf resolves window edges and direction', (tester) async {
      const leftOnly = DockWindowEdgesSource.fixed(
        DockWindowEdges(left: true, right: false),
      );
      var context = await pump(tester, const DockNavigationData());
      expect(DockNavigation.sideOf(context), DockSide.end);
      expect(DockNavigation.sideOnRight(context), isTrue);

      context = await pump(
        tester,
        const DockNavigationData(windowEdgesSource: leftOnly),
      );
      expect(DockNavigation.sideOf(context), DockSide.start);
      expect(DockNavigation.sideOnRight(context), isFalse);

      // RTL: end is the left edge, which the window touches.
      context = await pump(
        tester,
        const DockNavigationData(windowEdgesSource: leftOnly),
        direction: TextDirection.rtl,
      );
      expect(DockNavigation.sideOf(context), DockSide.end);
      expect(DockNavigation.sideOnRight(context), isFalse);
    });
  });

  group('DockWindowEdgesSource.fixed', () {
    test('reports its value and never changes', () async {
      const edges = DockWindowEdges(left: false, right: true);
      const source = DockWindowEdgesSource.fixed(edges);
      expect(source.value, edges);
      expect(await source.changes.isEmpty, isTrue);
      // ignore: prefer_const_constructors
      expect(source, DockWindowEdgesSource.fixed(edges));
    });
  });

  group('DockAction.copyWith', () {
    void handler() {}

    test('keeps fields that are not passed', () {
      final action = DockAction<Object?>(
        id: 'a',
        icon: const DockIcon(Icons.share),
        label: 'Share',
        tooltip: 'Share it',
        onPressed: handler,
        payload: 1,
      );
      final copy = action.copyWith(hoist: DockHoist.never);
      expect(copy.icon, action.icon);
      expect(copy.label, 'Share');
      expect(copy.tooltip, 'Share it');
      expect(copy.onPressed, handler);
      expect(copy.payload, 1);
      expect(copy.hoist, DockHoist.never);
    });

    test('clears nullable fields passed as null', () {
      final action = DockAction<Object?>(
        id: 'a',
        icon: const DockIcon(Icons.share),
        label: 'Share',
        tooltip: 'Share it',
        onPressed: handler,
        payload: 1,
      );
      final copy = action.copyWith(
        icon: null,
        tooltip: null,
        onPressed: null,
        payload: null,
      );
      expect(copy.icon, isNull);
      expect(copy.label, 'Share');
      expect(copy.tooltip, isNull);
      expect(copy.onPressed, isNull);
      expect(copy.payload, isNull);
    });
  });
}
