import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = <DockTab<Object?>>[
  DockTab(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

const _body = Key('body');

void main() {
  late ValueNotifier<bool> visible;
  setUp(() => visible = ValueNotifier(true));
  tearDown(() => visible.dispose());

  Future<void> pump(
    WidgetTester tester, {
    DockLayoutMode mode = DockLayoutMode.wide,
    Widget? page,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: DockTestHarness(
            builders: const DockMaterialBuilders(),
            mode: mode,
            child: child!,
          ),
        ),
        home: ValueListenableBuilder(
          valueListenable: visible,
          builder: (context, shown, _) => DockShell<Object?, Object?, Object?>(
            tabs: _tabs,
            currentIndex: 0,
            onTabSelected: (_) {},
            navigationVisible: shown,
            child: page ?? const Material(key: _body, child: TextField()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect body(WidgetTester tester) => tester.getRect(find.byKey(_body));
  DockGeometry geometry(WidgetTester tester) =>
      DockGeometry.of(tester.element(find.byKey(_body)));

  for (final mode in DockLayoutMode.values) {
    testWidgets('${mode.name}: hidden gives the body the whole frame', (
      tester,
    ) async {
      await pump(tester, mode: mode);
      expect(body(tester).size, isNot(const Size(1000, 700)));

      visible.value = false;
      await tester.pumpAndSettle();
      expect(body(tester), const Offset(0, 0) & const Size(1000, 700));
      expect(geometry(tester).isHidden, isTrue);
      expect(geometry(tester).chrome, EdgeInsets.zero);
      expect(geometry(tester).strip, EdgeInsets.zero);
    });

    testWidgets('${mode.name}: hidden chrome takes no taps, focus or '
        'semantics', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pump(
        tester,
        mode: mode,
        page: GestureDetector(
          key: _body,
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
      );
      final home = tester.getCenter(find.byKey(DockKeys.tab('home')));
      expect(find.semantics.byLabel('Home'), findsOneWidget);

      visible.value = false;
      await tester.pumpAndSettle();
      await tester.tapAt(home);
      expect(taps, 1);
      expect(find.semantics.byLabel('Home'), findsNothing);
      final focusable = tester
          .widgetList<ExcludeFocus>(
            find.ancestor(
              of: find.byKey(DockKeys.tab('home')),
              matching: find.byType(ExcludeFocus),
            ),
          )
          .any((w) => w.excluding);
      expect(focusable, isTrue);
      handle.dispose();
    });
  }

  testWidgets('hiding animates, showing restores and keeps the body State', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'kept');
    final state = tester.state(find.byType(TextField));
    final width = body(tester).width;

    visible.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    final mid = geometry(tester);
    expect(mid.visibility, inExclusiveRange(0.0, 1.0));
    expect(body(tester).width, inExclusiveRange(width, 1000.0));
    await tester.pumpAndSettle();

    visible.value = true;
    await tester.pumpAndSettle();
    expect(body(tester).width, width);
    expect(geometry(tester).visibility, 1);
    expect(tester.state(find.byType(TextField)), same(state));
    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets('reduced motion jumps', (tester) async {
    await pump(tester, disableAnimations: true);
    visible.value = false;
    await tester.pump();
    await tester.pump();
    expect(geometry(tester).isHidden, isTrue);
  });

  testWidgets('a page can ask to hide the navigation', (tester) async {
    late BuildContext root;
    await pump(
      tester,
      page: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (context) {
            root = context;
            return const DockPage<Object?, Object?>(
              body: SizedBox.expand(key: _body),
            );
          },
        ),
      ),
    );
    expect(geometry(tester).isHidden, isFalse);

    Navigator.of(root).push(
      MaterialPageRoute<void>(
        builder: (_) => const DockPage<Object?, Object?>(
          visible: false,
          body: SizedBox.expand(key: Key('camera')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      DockGeometry.of(tester.element(find.byKey(const Key('camera')))).isHidden,
      isTrue,
    );

    Navigator.of(root).pop();
    await tester.pumpAndSettle();
    expect(geometry(tester).isHidden, isFalse);
  });

  testWidgets('nothing ticks while nothing animates', (tester) async {
    await pump(tester);
    expect(tester.binding.hasScheduledFrame, isFalse);
    visible.value = false;
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
