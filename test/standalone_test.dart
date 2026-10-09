import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';

const _wideWindow = Size(1000, 700);

Widget _page({VoidCallback? onShare}) => DuoPage<Object?, Object?>(
  title: const Text('Details'),
  trailing: [
    DuoAction<Object?>(
      id: 'share',
      icon: const DuoIcon(Icons.share),
      onPressed: onShare,
    ),
  ],
  body: const Text('body'),
);

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _wideWindow;
    view.devicePixelRatio = 1;
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  testWidgets('a page under a bare MaterialApp gets a compact frame', (
    tester,
  ) async {
    var shares = 0;
    late BuildContext root;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            root = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    Navigator.of(root).push(
      MaterialPageRoute<void>(
        builder: (_) => DuoStandalone(
          builders: const DuoMaterialBuilders(),
          child: _page(onShare: () => shares++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Compact on a wide window: the actions stay in the title bar.
    expect(find.widgetWithText(AppBar, 'Details'), findsOneWidget);
    expect(find.byKey(DuoKeys.column), findsNothing);
    await tester.tap(find.byKey(DuoKeys.action('share')));
    expect(shares, 1);

    await tester.tap(find.byKey(DuoKeys.action(DuoAction.backId)));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  group('without DuoTestHarness, the default tap guard follows the test', () {
    Future<List<int>> pumpPage(WidgetTester tester) async {
      final shares = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: DuoStandalone(
            builders: const DuoMaterialBuilders(),
            child: _page(onShare: () => shares.add(shares.length)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return shares;
    }

    testWidgets('two taps with pumpAndSettle in between both fire', (
      tester,
    ) async {
      final shares = await pumpPage(tester);
      await tester.tap(find.byKey(DuoKeys.action('share')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DuoKeys.action('share')));
      await tester.pumpAndSettle();
      expect(shares, hasLength(2));
    });

    testWidgets('a double tap within the cooldown is still dropped', (
      tester,
    ) async {
      final shares = await pumpPage(tester);
      await tester.tap(find.byKey(DuoKeys.action('share')));
      await tester.pump();
      await tester.tap(find.byKey(DuoKeys.action('share')));
      await tester.pump();
      expect(shares, hasLength(1));
    });
  });

  group('DuoClock.system', () {
    testWidgets('advances with frame time', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final clock = DuoClock.system();
      final start = clock.now();
      // A frame that happens a second later (in the app, a tap's ripple or
      // any animation schedules one).
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(seconds: 1));
      expect(
        clock.now() - start,
        greaterThanOrEqualTo(const Duration(seconds: 1)),
      );
    });

    testWidgets('advances with real time when no frame comes', (tester) async {
      final clock = DuoClock.system();
      final start = clock.now();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      expect(
        clock.now() - start,
        greaterThanOrEqualTo(const Duration(milliseconds: 60)),
      );
    });
  });

  testWidgets('below a DuoNavigation it changes nothing', (tester) async {
    late DuoLayoutMode mode;
    Widget app(DuoBuilders<Object?, Object?, Object?> standaloneBuilders) =>
        MaterialApp(
          builder: (context, child) => DuoNavigation(
            builders: const DuoMaterialBuilders(),
            data: const DuoNavigationData(
              layoutPolicy: DuoLayoutPolicy.fixed(DuoLayoutMode.wide),
            ),
            child: child!,
          ),
          home: DuoStandalone(
            builders: standaloneBuilders,
            child: Builder(
              builder: (context) {
                mode = DuoNavigation.modeOf(context);
                return const _Counter();
              },
            ),
          ),
        );

    await tester.pumpWidget(app(const DuoMaterialBuilders()));
    expect(find.byType(DuoNavigation), findsOneWidget);
    expect(mode, DuoLayoutMode.wide);
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Its own builders are not used, and the child keeps its State.
    await tester.pumpWidget(
      app(
        DuoBuilders<Object?, Object?, Object?>(
          page: (context, bar, body) => throw StateError('not used'),
        ),
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a page below it uses the app\'s builders, not its own', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            DuoNavigation(builders: const DuoMaterialBuilders(), child: child!),
        home: DuoStandalone(
          builders: DuoBuilders<Object?, Object?, Object?>(
            page: (context, bar, body) => const Text('standalone page'),
          ),
          child: _page(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('standalone page'), findsNothing);
    expect(find.text('body'), findsOneWidget);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _count++),
    child: Text('$_count', textDirection: TextDirection.ltr),
  );
}
