import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';

const _wideWindow = Size(1000, 700);

Widget _page({VoidCallback? onShare}) => DockPage<Object?, Object?>(
  title: const Text('Details'),
  trailing: [
    DockAction<Object?>(
      id: 'share',
      icon: const DockIcon(Icons.share),
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
        builder: (_) => DockStandalone(
          builders: const DockMaterialBuilders(),
          child: _page(onShare: () => shares++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Compact on a wide window: the actions stay in the title bar.
    expect(find.widgetWithText(AppBar, 'Details'), findsOneWidget);
    expect(find.byKey(DockKeys.column), findsNothing);
    await tester.tap(find.byKey(DockKeys.action('share')));
    expect(shares, 1);

    await tester.tap(find.byKey(DockKeys.action(DockAction.backId)));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('below a DockNavigation it changes nothing', (tester) async {
    late DockLayoutMode mode;
    Widget app(DockBuilders<Object?, Object?, Object?> standaloneBuilders) =>
        MaterialApp(
          builder: (context, child) => DockNavigation(
            builders: const DockMaterialBuilders(),
            data: const DockNavigationData(
              layoutPolicy: DockLayoutPolicy.fixed(DockLayoutMode.wide),
            ),
            child: child!,
          ),
          home: DockStandalone(
            builders: standaloneBuilders,
            child: Builder(
              builder: (context) {
                mode = DockNavigation.modeOf(context);
                return const _Counter();
              },
            ),
          ),
        );

    await tester.pumpWidget(app(const DockMaterialBuilders()));
    expect(find.byType(DockNavigation), findsOneWidget);
    expect(mode, DockLayoutMode.wide);
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Its own builders are not used, and the child keeps its State.
    await tester.pumpWidget(
      app(
        DockBuilders<Object?, Object?, Object?>(
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
        builder: (context, child) => DockNavigation(
          builders: const DockMaterialBuilders(),
          child: child!,
        ),
        home: DockStandalone(
          builders: DockBuilders<Object?, Object?, Object?>(
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
