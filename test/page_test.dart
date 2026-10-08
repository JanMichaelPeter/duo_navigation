import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock/testing.dart';

/// A design system's title spec, carried as the bar payload.
class _Title {
  const _Title(this.text);
  final String text;
}

const _tabs = <DockTab<Object?>>[
  DockTab(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

Finder _action(Object id) => find.byKey(DockKeys.action(id));
Finder _inColumn(Finder finder) =>
    find.descendant(of: find.byKey(DockKeys.column), matching: finder);
Finder _inBar(Finder finder) =>
    find.descendant(of: find.byType(AppBar), matching: finder);

DockAction<Object?> _share() => DockAction<Object?>(
  id: 'share',
  icon: const DockIcon(Icons.share),
  onPressed: () {},
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DockLayoutMode mode = DockLayoutMode.wide,
    DockNavigationData data = const DockNavigationData(),
    TextDirection? textDirection,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          data: data,
          mode: mode,
          textDirection: textDirection,
          child: child!,
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A shell whose single tab navigator pushes [page] on top of a root page,
  /// so the page has an implied back action.
  Widget shellWithPushed(Widget page, {DockHoisting? hoisting}) =>
      DockShell<Object?, Object?, Object?>(
        tabs: _tabs,
        currentIndex: 0,
        onTabSelected: (_) {},
        hoisting: hoisting,
        child: Navigator(
          onGenerateInitialRoutes: (navigator, _) => [
            MaterialPageRoute<void>(builder: (_) => const SizedBox.expand()),
            MaterialPageRoute<void>(builder: (_) => page),
          ],
        ),
      );

  group('DockPageScope', () {
    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: a custom Scaffold with DockAppBar', (
        tester,
      ) async {
        await pump(
          tester,
          shellWithPushed(
            DockPageScope<Object?, Object?>(
              title: const Text('Details'),
              trailing: [_share()],
              child: Scaffold(
                key: const Key('details'),
                appBar: const DockAppBar(),
                bottomNavigationBar: const SizedBox(
                  height: 40,
                  child: Text('toolbar'),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
          mode: mode,
        );
        expect(find.byKey(const Key('details')), findsOneWidget);
        expect(find.text('toolbar'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(_inBar(find.text('Details')), findsOneWidget);
        if (mode == DockLayoutMode.compact) {
          expect(_inBar(_action('share')), findsOneWidget);
          expect(_inBar(_action(DockAction.backId)), findsOneWidget);
        } else {
          expect(_inColumn(_action('share')), findsOneWidget);
          expect(_inColumn(_action(DockAction.backId)), findsOneWidget);
          expect(_inBar(_action('share')), findsNothing);
        }
      });
    }

    testWidgets('DockBarData.of fails loudly outside a page', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(DockBarData.maybeOf<Object?, Object?>(context), isNull);
      expect(
        () => DockBarData.of<Object?, Object?>(context),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.message,
            'message',
            contains('No DockPageScope found.'),
          ),
        ),
      );
    });

    testWidgets('DockBarData.of names the types when they do not match', (
      tester,
    ) async {
      late BuildContext inside;
      await pump(
        tester,
        DockPageScope<Object?, _Title>(
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(DockBarData.of<Object?, _Title>(inside), isNotNull);
      expect(DockBarData.of<Object?, Object?>(inside), isNotNull);
      expect(
        () => DockBarData.of<Object?, String>(inside),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toStringDeep(),
            'message',
            contains('DockBarData<Object?, String>'),
          ),
        ),
      );
    });

    testWidgets('a page scope without a frame brings its own', (tester) async {
      final key = GlobalKey();
      await pump(
        tester,
        DockPageScope<Object?, Object?>(
          key: key,
          trailing: [_share()],
          child: const Scaffold(appBar: DockAppBar()),
        ),
      );
      expect(_inColumn(_action('share')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a typed bar payload reaches the page builder', (tester) async {
    await pump(
      tester,
      DockShell<Object?, Object?, _Title>(
        tabs: _tabs,
        currentIndex: 0,
        onTabSelected: (_) {},
        builders: DockBuilders<Object?, Object?, _Title>(
          page: (context, bar, body) => Text(bar.payload!.text),
        ),
        child: const DockPage<Object?, _Title>(
          barPayload: _Title('structured title'),
          body: SizedBox(),
        ),
      ),
      mode: DockLayoutMode.compact,
    );
    expect(find.text('structured title'), findsOneWidget);
  });

  group('DockBarLayout', () {
    const leading = Key('leading'), title = Key('title'), a = Key('a');

    Future<void> layout(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      bool actionsAtStart = false,
      bool centerTitle = false,
      bool withLeading = true,
    }) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: direction,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 56,
              child: DockBarLayout(
                leading: withLeading
                    ? const SizedBox(key: leading, width: 40, height: 40)
                    : null,
                title: const SizedBox(key: title, width: 100, height: 20),
                trailing: const [SizedBox(key: a, width: 40, height: 40)],
                centerTitle: centerTitle,
                actionsAtStart: actionsAtStart,
                spacing: 16,
                edgePadding: 4,
              ),
            ),
          ),
        ),
      );
    }

    Rect rect(WidgetTester tester, Key key) {
      final origin = tester.getTopLeft(find.byType(DockBarLayout));
      return tester.getRect(find.byKey(key)).shift(-origin);
    }

    testWidgets('leading, title, actions at the end', (tester) async {
      await layout(tester);
      expect(rect(tester, leading).left, 4);
      expect(rect(tester, title).left, 4 + 40 + 16);
      expect(rect(tester, a).right, 400 - 4);
      expect(rect(tester, title).center.dy, 28);
    });

    testWidgets('actions at the start follow the leading action', (
      tester,
    ) async {
      await layout(tester, actionsAtStart: true);
      expect(rect(tester, leading).left, 4);
      expect(rect(tester, a).left, 44);
      expect(rect(tester, title).left, 44 + 40 + 16);
    });

    testWidgets('mirrors in right-to-left', (tester) async {
      await layout(tester, direction: TextDirection.rtl);
      expect(rect(tester, leading).right, 400 - 4);
      expect(rect(tester, title).right, 400 - 4 - 40 - 16);
      expect(rect(tester, a).left, 4);

      await layout(tester, direction: TextDirection.rtl, actionsAtStart: true);
      expect(rect(tester, a).right, 400 - 44);
    });

    testWidgets('a centered title is centered on the bar', (tester) async {
      await layout(tester, centerTitle: true);
      expect(rect(tester, title).center.dx, 200);
      await layout(tester, centerTitle: true, withLeading: false);
      expect(rect(tester, title).center.dx, 200);
    });

    testWidgets('without a leading action the start is free', (tester) async {
      await layout(tester, withLeading: false, actionsAtStart: true);
      expect(rect(tester, a).left, 4);
      expect(rect(tester, title).left, 4 + 40 + 16);
    });
  });

  group('implied leading', () {
    late BuildContext root;
    final roles = <String, DockActionRole?>{};

    /// A page that records the role of its leading action under [name].
    Widget page(String name, {DockImpliedLeading? impliedLeading}) =>
        DockPage<Object?, Object?>.custom(
          impliedLeading: impliedLeading,
          builder: (context, bar) {
            roles[name] = bar.leading?.role;
            return Scaffold(appBar: const DockAppBar(), body: Text(name));
          },
        );

    Future<void> start(WidgetTester tester) async {
      roles.clear();
      await pump(
        tester,
        Builder(
          builder: (context) {
            root = context;
            return const SizedBox.expand();
          },
        ),
        mode: DockLayoutMode.compact,
      );
    }

    Future<void> push(WidgetTester tester, Route<void> route) async {
      Navigator.of(root).push(route);
      await tester.pumpAndSettle();
    }

    Future<void> tapLeading(WidgetTester tester) async {
      await tester.tap(_action(DockAction.backId).last);
      await tester.pumpAndSettle();
    }

    testWidgets('back for a page, close for a full-screen dialog', (
      tester,
    ) async {
      await start(tester);
      await push(tester, MaterialPageRoute(builder: (_) => page('page')));
      await push(
        tester,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => page('dialog'),
        ),
      );
      expect(roles['page'], DockActionRole.back);
      expect(roles['dialog'], DockActionRole.close);
    });

    testWidgets('a modal scope can ask for close on any route', (tester) async {
      await start(tester);
      await push(
        tester,
        MaterialPageRoute(
          builder: (_) => DockModalScope<Object?, Object?>(
            impliedLeading: DockImpliedLeading.close,
            child: page('modal'),
          ),
        ),
      );
      expect(roles['modal'], DockActionRole.close);
      await tapLeading(tester);
      expect(find.text('modal'), findsNothing);
    });

    testWidgets('the first page of a navigator inside a modal dismisses it, '
        'later pages go back', (tester) async {
      await start(tester);
      late BuildContext inner;
      await push(
        tester,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DockModalScope<Object?, Object?>(
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) {
                  inner = context;
                  return page('step 1');
                },
              ),
            ),
          ),
        ),
      );
      expect(roles['step 1'], DockActionRole.close);

      Navigator.of(
        inner,
      ).push(MaterialPageRoute<void>(builder: (_) => page('step 2')));
      await tester.pumpAndSettle();
      expect(roles['step 2'], DockActionRole.back);
      await tapLeading(tester);
      expect(find.text('step 2'), findsNothing);
      expect(find.text('step 1'), findsOneWidget);

      await tapLeading(tester);
      expect(find.text('step 1'), findsNothing);
    });

    testWidgets('a page can choose its own', (tester) async {
      await start(tester);
      await push(
        tester,
        MaterialPageRoute(
          builder: (_) =>
              page('sheet', impliedLeading: DockImpliedLeading.close),
        ),
      );
      expect(roles['sheet'], DockActionRole.close);
    });
  });

  group('hoisting off', () {
    /// Records the bar data a page gets.
    Widget recordingPage(List<DockBarData<Object?, Object?>> bars) =>
        DockPage<Object?, Object?>.custom(
          leading: const DockAction<Object?>.back(icon: null, label: 'Cancel'),
          trailing: [_share()],
          builder: (context, bar) {
            bars.add(bar);
            return Scaffold(appBar: const DockAppBar());
          },
        );

    testWidgets('keeps every action in the bar and the data equal in both '
        'modes', (tester) async {
      final bars = <DockBarData<Object?, Object?>>[];
      for (final mode in DockLayoutMode.values) {
        await pump(
          tester,
          shellWithPushed(recordingPage(bars)),
          mode: mode,
          data: const DockNavigationData(
            hoisting: DockHoisting.none,
            side: DockSide.start,
          ),
        );
        expect(_inBar(_action('share')), findsOneWidget);
        expect(_inBar(find.text('Cancel')), findsOneWidget);
        expect(_inColumn(_action('share')), findsNothing);
      }
      final compact = bars.firstWhere((b) => !b.isWide);
      final wide = bars.lastWhere((b) => b.isWide);
      expect(wide.leading?.label, compact.leading?.label);
      expect(wide.trailing.map((a) => a.id), compact.trailing.map((a) => a.id));
      expect(wide.hoisted, isEmpty);
      expect(wide.trailingAtStart, isFalse);
      // The column holds only the rail.
      expect(find.byKey(DockKeys.rail), findsOneWidget);
    });

    testWidgets('can be set per shell', (tester) async {
      await pump(
        tester,
        shellWithPushed(
          DockPage<Object?, Object?>(
            trailing: [_share()],
            body: const SizedBox(),
          ),
          hoisting: DockHoisting.none,
        ),
      );
      expect(_inBar(_action('share')), findsOneWidget);
      expect(_inBar(_action(DockAction.backId)), findsOneWidget);
      expect(_inColumn(_action(DockAction.backId)), findsNothing);
    });

    testWidgets('can be set per page', (tester) async {
      await pump(
        tester,
        shellWithPushed(
          DockPage<Object?, Object?>(
            hoisting: DockHoisting.none,
            trailing: [_share()],
            body: const SizedBox(),
          ),
        ),
      );
      expect(_inBar(_action('share')), findsOneWidget);
      expect(_inColumn(_action('share')), findsNothing);
    });
  });

  group('plain Scaffold pages, no page layer', () {
    Widget plain(String title, {VoidCallback? onOpen}) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: TextButton(onPressed: onOpen, child: Text('open from $title')),
      ),
    );

    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: tabs, switching and a nested navigator', (
        tester,
      ) async {
        final navigators = [
          GlobalKey<NavigatorState>(),
          GlobalKey<NavigatorState>(),
        ];
        var index = 0;
        await pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) =>
                DockShell<Object?, Object?, Object?>(
                  tabs: _tabs,
                  currentIndex: index,
                  onTabSelected: (i) => setState(() => index = i),
                  child: DockTabStack(
                    index: index,
                    children: [
                      for (var i = 0; i < 2; i++)
                        Navigator(
                          key: navigators[i],
                          onGenerateRoute: (_) => MaterialPageRoute<void>(
                            builder: (context) => plain(
                              'tab $i',
                              onOpen: () => navigators[i].currentState!.push(
                                MaterialPageRoute<void>(
                                  builder: (_) => plain('detail $i'),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
          mode: mode,
        );
        expect(find.text('tab 0'), findsOneWidget);

        await tester.tap(find.text('open from tab 0'));
        await tester.pumpAndSettle();
        expect(find.text('detail 0'), findsOneWidget);
        // The plain AppBar has its own back button; the column has no chips.
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.byKey(DockKeys.action(DockAction.backId)), findsNothing);

        await tester.tap(find.byKey(DockKeys.tab('me')));
        await tester.pumpAndSettle();
        expect(find.text('tab 1'), findsOneWidget);

        await tester.tap(find.byKey(DockKeys.tab('home')));
        await tester.pumpAndSettle();
        expect(find.text('detail 0'), findsOneWidget);

        final chrome = mode == DockLayoutMode.wide
            ? find.byKey(DockKeys.column)
            : find.byKey(DockKeys.bar);
        expect(chrome, findsOneWidget);
        // The body sits beside the chrome: the AppBar ends where it starts.
        final appBar = tester.getRect(find.byType(AppBar).last);
        final chromeRect = tester.getRect(chrome);
        if (mode == DockLayoutMode.wide) {
          expect(appBar.right, lessThanOrEqualTo(chromeRect.left));
        } else {
          expect(appBar.bottom, lessThanOrEqualTo(chromeRect.top));
        }
      });

      testWidgets('${mode.name}: a plain page in a modal frame', (
        tester,
      ) async {
        await pump(
          tester,
          DockModalScope<Object?, Object?>(child: plain('modal')),
          mode: mode,
        );
        expect(find.text('modal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
