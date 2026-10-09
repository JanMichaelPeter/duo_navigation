import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = [
  DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
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
  group('DuoNavigation.of', () {
    testWidgets('fails loudly without a DuoNavigation', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(DuoNavigation.maybeOf(context), isNull);
      expect(
        () => DuoNavigation.of(context),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toStringDeep(),
            'message',
            allOf(
              contains('No DuoNavigation found.'),
              contains('MaterialApp('),
            ),
          ),
        ),
      );
    });

    testWidgets('a DuoPage without DuoNavigation fails instead of '
        'guessing a layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DuoPage<Object?, Object?>(body: SizedBox())),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('No DuoNavigation found.'),
        ),
      );
    });

    testWidgets('equal data does not notify dependents', (tester) async {
      final builds = <int>[];
      // The same instance every time, so only a notification rebuilds it.
      final probe = _Probe(DuoNavigation.of, builds);
      Widget app(DuoNavigationData data) => DuoNavigation(
        builders: const DuoMaterialBuilders(),
        data: data,
        child: probe,
      );

      await tester.pumpWidget(app(const DuoNavigationData()));
      // Equal but not identical (not const).
      await tester.pumpWidget(app(DuoNavigationData(sideColumnWidth: 72)));
      expect(builds, hasLength(1));

      await tester.pumpWidget(app(DuoNavigationData(sideColumnWidth: 80)));
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
          child: DuoNavigation(
            builders: const DuoMaterialBuilders(),
            data: DuoNavigationData(windowEdgesSource: source),
            child: Column(
              children: [
                _Probe(DuoNavigation.of, configBuilds),
                _Probe(DuoNavigation.sideOf, sideBuilds),
              ],
            ),
          ),
        ),
      );

      source.push(const DuoWindowEdges(left: true, right: false));
      await tester.pumpAndSettle();
      expect(configBuilds, hasLength(1));
      expect(sideBuilds, hasLength(2));
    });
  });

  group('DuoNavigationData', () {
    test('has value equality', () {
      expect(
        const DuoNavigationData(),
        DuoNavigationData(layoutPolicy: DuoLayoutPolicy.shortestSide(600)),
      );
      expect(
        const DuoNavigationData().hashCode,
        DuoNavigationData(sideColumnWidth: 72).hashCode,
      );
      expect(
        const DuoNavigationData(),
        isNot(const DuoNavigationData(side: DuoSide.start)),
      );
      expect(
        const DuoNavigationData(),
        isNot(const DuoNavigationData(actionAnimationCurve: Curves.linear)),
      );
    });

    test('copyWith can remove the window-edge source', () {
      const source = DuoWindowEdgesSource.fixed(
        DuoWindowEdges(left: true, right: false),
      );
      const data = DuoNavigationData(windowEdgesSource: source);
      expect(data.copyWith().windowEdgesSource, source);
      expect(data.copyWith(side: DuoSide.start).windowEdgesSource, source);
      expect(data.copyWith(windowEdgesSource: null).windowEdgesSource, isNull);
    });
  });

  group('layout policy', () {
    test('shortestSide (the default) keeps phones compact in landscape', () {
      const policy = DuoLayoutPolicy.shortestSide(600);
      expect(const DuoNavigationData().layoutPolicy, policy);
      DuoLayoutMode at(double width, double height) => policy.resolve(
        window: Size(width, height),
        frame: Size(width, height),
      );
      expect(at(390, 844), DuoLayoutMode.compact); // phone, portrait
      expect(at(844, 390), DuoLayoutMode.compact); // phone, landscape
      expect(at(1024, 768), DuoLayoutMode.wide); // tablet
      expect(at(673, 841), DuoLayoutMode.wide); // foldable, unfolded
      expect(at(600, 960), DuoLayoutMode.wide); // the boundary
      expect(at(400, 1000), DuoLayoutMode.compact); // narrow split window
    });

    test('breakpoint uses the window width', () {
      const policy = DuoLayoutPolicy.breakpoint(600);
      expect(
        policy.resolve(window: const Size(600, 400), frame: const Size(10, 10)),
        DuoLayoutMode.wide,
      );
      expect(
        policy.resolve(
          window: const Size(599, 900),
          frame: const Size(900, 900),
        ),
        DuoLayoutMode.compact,
      );
    });

    test('fixed ignores the size', () {
      const policy = DuoLayoutPolicy.fixed(DuoLayoutMode.compact);
      expect(
        policy.resolve(
          window: const Size(2000, 1000),
          frame: const Size(2000, 1000),
        ),
        DuoLayoutMode.compact,
      );
    });

    test('has value equality', () {
      expect(
        const DuoLayoutPolicy.breakpoint(466),
        // ignore: prefer_const_constructors
        DuoLayoutPolicy.breakpoint(466),
      );
      expect(
        const DuoLayoutPolicy.breakpoint(466),
        isNot(const DuoLayoutPolicy.breakpoint(600)),
      );
      expect(
        const DuoLayoutPolicy.fixed(DuoLayoutMode.wide),
        // ignore: prefer_const_constructors
        DuoLayoutPolicy.fixed(DuoLayoutMode.wide),
      );
    });

    testWidgets('a fixed compact policy gives the bottom bar on a wide '
        'surface', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DuoNavigation(
            builders: const DuoMaterialBuilders(),
            data: const DuoNavigationData(
              layoutPolicy: DuoLayoutPolicy.fixed(DuoLayoutMode.compact),
            ),
            child: child!,
          ),
          home: DuoShell<Object?, Object?, Object?>(
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
      DuoNavigationData data, {
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
            child: DuoNavigation(
              builders: const DuoMaterialBuilders(),
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
      var context = await pump(tester, const DuoNavigationData());
      expect(DuoNavigation.modeOf(context), DuoLayoutMode.wide);
      context = await pump(
        tester,
        const DuoNavigationData(),
        size: const Size(400, 800),
      );
      expect(DuoNavigation.modeOf(context), DuoLayoutMode.compact);
    });

    testWidgets('sideOf resolves window edges and direction', (tester) async {
      const leftOnly = DuoWindowEdgesSource.fixed(
        DuoWindowEdges(left: true, right: false),
      );
      var context = await pump(tester, const DuoNavigationData());
      expect(DuoNavigation.sideOf(context), DuoSide.end);
      expect(DuoNavigation.sideOnRight(context), isTrue);

      context = await pump(
        tester,
        const DuoNavigationData(windowEdgesSource: leftOnly),
      );
      expect(DuoNavigation.sideOf(context), DuoSide.start);
      expect(DuoNavigation.sideOnRight(context), isFalse);

      // RTL: end is the left edge, which the window touches.
      context = await pump(
        tester,
        const DuoNavigationData(windowEdgesSource: leftOnly),
        direction: TextDirection.rtl,
      );
      expect(DuoNavigation.sideOf(context), DuoSide.end);
      expect(DuoNavigation.sideOnRight(context), isFalse);
    });
  });

  group('DuoWindowEdgesSource.fixed', () {
    test('reports its value and never changes', () async {
      const edges = DuoWindowEdges(left: false, right: true);
      const source = DuoWindowEdgesSource.fixed(edges);
      expect(source.value, edges);
      expect(await source.changes.isEmpty, isTrue);
      // ignore: prefer_const_constructors
      expect(source, DuoWindowEdgesSource.fixed(edges));
    });
  });

  group('DuoAction.copyWith', () {
    void handler() {}

    test('keeps fields that are not passed', () {
      final action = DuoAction<Object?>(
        id: 'a',
        icon: const DuoIcon(Icons.share),
        label: 'Share',
        tooltip: 'Share it',
        onPressed: handler,
        payload: 1,
      );
      final copy = action.copyWith(hoist: DuoHoist.never);
      expect(copy.icon, action.icon);
      expect(copy.label, 'Share');
      expect(copy.tooltip, 'Share it');
      expect(copy.onPressed, handler);
      expect(copy.payload, 1);
      expect(copy.hoist, DuoHoist.never);
    });

    test('clears nullable fields passed as null', () {
      final action = DuoAction<Object?>(
        id: 'a',
        icon: const DuoIcon(Icons.share),
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
