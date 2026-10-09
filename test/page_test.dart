import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

/// A design system's title spec, carried as the bar payload.
class _Title {
  const _Title(this.text);
  final String text;
}

const _tabs = <DuoTab<Object?>>[
  DuoTab(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

Finder _action(Object id) => find.byKey(DuoKeys.action(id));
Finder _inColumn(Finder finder) =>
    find.descendant(of: find.byKey(DuoKeys.column), matching: finder);
Finder _inBar(Finder finder) =>
    find.descendant(of: find.byType(AppBar), matching: finder);

DuoAction<Object?> _share() => DuoAction<Object?>(
  id: 'share',
  icon: const DuoIcon(Icons.share),
  onPressed: () {},
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DuoLayoutMode mode = DuoLayoutMode.wide,
    DuoNavigationData data = const DuoNavigationData(),
    TextDirection? textDirection,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
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
  Widget shellWithPushed(Widget page, {DuoHoisting? hoisting}) =>
      DuoShell<Object?, Object?, Object?>(
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

  group('DuoPageScope', () {
    for (final mode in DuoLayoutMode.values) {
      testWidgets('${mode.name}: a custom Scaffold with DuoAppBar', (
        tester,
      ) async {
        await pump(
          tester,
          shellWithPushed(
            DuoPageScope<Object?, Object?>(
              title: const Text('Details'),
              trailing: [_share()],
              child: Scaffold(
                key: const Key('details'),
                appBar: const DuoAppBar(),
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
        if (mode == DuoLayoutMode.compact) {
          expect(_inBar(_action('share')), findsOneWidget);
          expect(_inBar(_action(DuoAction.backId)), findsOneWidget);
        } else {
          expect(_inColumn(_action('share')), findsOneWidget);
          expect(_inColumn(_action(DuoAction.backId)), findsOneWidget);
          expect(_inBar(_action('share')), findsNothing);
        }
      });
    }

    testWidgets('DuoBarData.of fails loudly outside a page', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(DuoBarData.maybeOf<Object?, Object?>(context), isNull);
      expect(
        () => DuoBarData.of<Object?, Object?>(context),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.message,
            'message',
            contains('No DuoPageScope found.'),
          ),
        ),
      );
    });

    testWidgets('DuoBarData.of names the types when they do not match', (
      tester,
    ) async {
      late BuildContext inside;
      await pump(
        tester,
        DuoPageScope<Object?, _Title>(
          child: Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(DuoBarData.of<Object?, _Title>(inside), isNotNull);
      expect(DuoBarData.of<Object?, Object?>(inside), isNotNull);
      expect(
        () => DuoBarData.of<Object?, String>(inside),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toStringDeep(),
            'message',
            contains('DuoBarData<Object?, String>'),
          ),
        ),
      );
    });

    testWidgets('a page scope without a frame brings its own', (tester) async {
      final key = GlobalKey();
      await pump(
        tester,
        DuoPageScope<Object?, Object?>(
          key: key,
          trailing: [_share()],
          child: const Scaffold(appBar: DuoAppBar()),
        ),
      );
      expect(_inColumn(_action('share')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a typed bar payload reaches the page builder', (tester) async {
    await pump(
      tester,
      DuoShell<Object?, Object?, _Title>(
        tabs: _tabs,
        currentIndex: 0,
        onTabSelected: (_) {},
        builders: DuoBuilders<Object?, Object?, _Title>(
          page: (context, bar, body) => Text(bar.payload!.text),
        ),
        child: const DuoPage<Object?, _Title>(
          barPayload: _Title('structured title'),
          body: SizedBox(),
        ),
      ),
      mode: DuoLayoutMode.compact,
    );
    expect(find.text('structured title'), findsOneWidget);
  });

  group('DuoBarLayout', () {
    const leading = Key('leading'), title = Key('title'), a = Key('a');

    Future<void> layout(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      bool actionsAtStart = false,
      bool leadingAtEnd = false,
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
              child: DuoBarLayout(
                leading: withLeading
                    ? const SizedBox(key: leading, width: 40, height: 40)
                    : null,
                title: const SizedBox(key: title, width: 100, height: 20),
                trailing: const [SizedBox(key: a, width: 40, height: 40)],
                centerTitle: centerTitle,
                actionsAtStart: actionsAtStart,
                leadingAtEnd: leadingAtEnd,
                spacing: 16,
                edgePadding: 4,
              ),
            ),
          ),
        ),
      );
    }

    Rect rect(WidgetTester tester, Key key) {
      final origin = tester.getTopLeft(find.byType(DuoBarLayout));
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

    testWidgets('a leading action at the end follows the actions', (
      tester,
    ) async {
      await layout(tester, leadingAtEnd: true);
      expect(rect(tester, leading).right, 400 - 4);
      expect(rect(tester, a).right, 400 - 4 - 40);
      expect(rect(tester, title).left, 4);

      await layout(tester, leadingAtEnd: true, direction: TextDirection.rtl);
      expect(rect(tester, leading).left, 4);
      expect(rect(tester, a).left, 44);
      expect(rect(tester, title).right, 400 - 4);
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

  testWidgets('DuoAppBar passes AppBar\'s parameters through', (tester) async {
    const style = SystemUiOverlayStyle.light;
    const shape = RoundedRectangleBorder();
    const space = SizedBox(key: Key('space'));
    await pump(
      tester,
      DuoPage<Object?, Object?>.custom(
        title: const Text('Title'),
        trailing: [_share()],
        builder: (context, bar) => const Scaffold(
          appBar: DuoAppBar(
            foregroundColor: Color(0xFF123456),
            elevation: 3,
            scrolledUnderElevation: 5,
            shape: shape,
            systemOverlayStyle: style,
            titleTextStyle: TextStyle(fontSize: 31),
            flexibleSpace: space,
          ),
        ),
      ),
      mode: DuoLayoutMode.compact,
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.foregroundColor, const Color(0xFF123456));
    expect(appBar.elevation, 3);
    expect(appBar.scrolledUnderElevation, 5);
    expect(appBar.shape, shape);
    expect(appBar.systemOverlayStyle, style);
    expect(appBar.titleTextStyle?.fontSize, 31);
    expect(find.byKey(const Key('space')), findsOneWidget);
    // The foreground color reaches the action icons too.
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.share))).color,
      const Color(0xFF123456),
    );
  });

  group('leading at the end', () {
    Widget sheet() => DuoPage<Object?, Object?>(
      title: const Text('Sheet'),
      leading: DuoAction<Object?>.close(onPressed: () {}),
      leadingAtEnd: true,
      trailing: [_share()],
      body: const SizedBox.expand(),
    );

    testWidgets('compact: the close action sits at the end of the bar', (
      tester,
    ) async {
      await pump(tester, shellWithPushed(sheet()), mode: DuoLayoutMode.compact);
      final bar = tester.getRect(find.byType(AppBar));
      final close = tester.getRect(_inBar(_action(DuoAction.backId)));
      final share = tester.getRect(_inBar(_action('share')));
      expect(close.right, greaterThan(share.right));
      expect(close.right, closeTo(bar.right, 8));
      expect(tester.getRect(find.text('Sheet')).left, lessThan(share.left));
    });

    testWidgets('wide: it is still the lowest chip in the column', (
      tester,
    ) async {
      await pump(tester, shellWithPushed(sheet()));
      final close = tester.getRect(_inColumn(_action(DuoAction.backId)));
      final share = tester.getRect(_inColumn(_action('share')));
      expect(close.top, greaterThan(share.top));
    });
  });

  group('implied leading', () {
    late BuildContext root;
    final roles = <String, DuoActionRole?>{};
    final atEnd = <String, bool>{};

    /// A page that records the role and the place of its leading action
    /// under [name].
    Widget page(
      String name, {
      DuoImpliedLeading? impliedLeading,
      bool? leadingAtEnd,
      DuoAction<Object?>? leading,
    }) => DuoPage<Object?, Object?>.custom(
      impliedLeading: impliedLeading,
      leadingAtEnd: leadingAtEnd,
      leading: leading,
      builder: (context, bar) {
        roles[name] = bar.leading?.role;
        atEnd[name] = bar.leadingAtEnd;
        return Scaffold(appBar: const DuoAppBar(), body: Text(name));
      },
    );

    Future<void> start(
      WidgetTester tester, {
      DuoNavigationData data = const DuoNavigationData(),
    }) async {
      roles.clear();
      atEnd.clear();
      await pump(
        tester,
        Builder(
          builder: (context) {
            root = context;
            return const SizedBox.expand();
          },
        ),
        mode: DuoLayoutMode.compact,
        data: data,
      );
    }

    Future<void> push(WidgetTester tester, Route<void> route) async {
      Navigator.of(root).push(route);
      await tester.pumpAndSettle();
    }

    Future<void> tapLeading(WidgetTester tester) async {
      await tester.tap(_action(DuoAction.backId).last);
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
      expect(roles['page'], DuoActionRole.back);
      expect(roles['dialog'], DuoActionRole.close);
    });

    testWidgets('a modal scope can ask for close on any route', (tester) async {
      await start(tester);
      await push(
        tester,
        MaterialPageRoute(
          builder: (_) => DuoModalScope<Object?, Object?>(
            impliedLeading: DuoImpliedLeading.close,
            child: page('modal'),
          ),
        ),
      );
      expect(roles['modal'], DuoActionRole.close);
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
          builder: (_) => DuoModalScope<Object?, Object?>(
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
      expect(roles['step 1'], DuoActionRole.close);

      Navigator.of(
        inner,
      ).push(MaterialPageRoute<void>(builder: (_) => page('step 2')));
      await tester.pumpAndSettle();
      expect(roles['step 2'], DuoActionRole.back);
      await tapLeading(tester);
      expect(find.text('step 2'), findsNothing);
      expect(find.text('step 1'), findsOneWidget);

      await tapLeading(tester);
      expect(find.text('step 1'), findsNothing);
    });

    group('app-wide modal defaults', () {
      const xTopRight = DuoNavigationData(
        modalLeading: DuoModalLeading(
          implied: DuoImpliedLeading.close,
          atEnd: true,
        ),
      );

      testWidgets('apply to a modal\'s first page, not to pages inside it', (
        tester,
      ) async {
        await start(tester, data: xTopRight);
        late BuildContext inner;
        await push(
          tester,
          MaterialPageRoute(
            builder: (_) => DuoModalScope<Object?, Object?>(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) {
                    inner = context;
                    return page('first');
                  },
                ),
              ),
            ),
          ),
        );
        expect(roles['first'], DuoActionRole.close);
        expect(atEnd['first'], isTrue);

        Navigator.of(
          inner,
        ).push(MaterialPageRoute<void>(builder: (_) => page('second')));
        await tester.pumpAndSettle();
        expect(roles['second'], DuoActionRole.back);
        expect(atEnd['second'], isFalse);
      });

      testWidgets('apply to a full-screen dialog on the root navigator, also '
          'to a declared leading action', (tester) async {
        await start(tester, data: xTopRight);
        await push(
          tester,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => page('root'),
          ),
        );
        expect(roles['root'], DuoActionRole.close);
        expect(atEnd['root'], isTrue);

        await push(
          tester,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => page(
              'confirmation',
              leading: DuoAction<Object?>.close(onPressed: () {}),
            ),
          ),
        );
        expect(atEnd['confirmation'], isTrue);
      });

      testWidgets('not to a plain page pushed on the root navigator, such as a '
          'follow-up of a modal', (tester) async {
        await start(tester, data: xTopRight);
        await push(
          tester,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => page('checkout'),
          ),
        );
        await push(tester, MaterialPageRoute(builder: (_) => page('address')));
        expect(roles['checkout'], DuoActionRole.close);
        expect(roles['address'], DuoActionRole.back);
        expect(atEnd['address'], isFalse);
      });

      testWidgets('apply to a modal route that is not a page', (tester) async {
        await start(tester, data: xTopRight);
        await push(
          tester,
          DialogRoute<void>(context: root, builder: (_) => page('dialog')),
        );
        expect(roles['dialog'], DuoActionRole.close);
        expect(atEnd['dialog'], isTrue);
      });

      testWidgets('the modal scope and the page win', (tester) async {
        await start(tester, data: xTopRight);
        await push(
          tester,
          MaterialPageRoute(
            builder: (_) => DuoModalScope<Object?, Object?>(
              impliedLeading: DuoImpliedLeading.back,
              leadingAtEnd: false,
              child: page('scope'),
            ),
          ),
        );
        expect(roles['scope'], DuoActionRole.back);
        expect(atEnd['scope'], isFalse);

        await push(
          tester,
          MaterialPageRoute(
            builder: (_) => page(
              'page',
              impliedLeading: DuoImpliedLeading.back,
              leadingAtEnd: false,
            ),
          ),
        );
        expect(roles['page'], DuoActionRole.back);
        expect(atEnd['page'], isFalse);
      });

      testWidgets('pages in a shell are not modal', (tester) async {
        await pump(
          tester,
          shellWithPushed(page('tab page')),
          mode: DuoLayoutMode.compact,
          data: xTopRight,
        );
        expect(roles['tab page'], DuoActionRole.back);
        expect(atEnd['tab page'], isFalse);
      });
    });

    testWidgets('a page can choose its own', (tester) async {
      await start(tester);
      await push(
        tester,
        MaterialPageRoute(
          builder: (_) =>
              page('sheet', impliedLeading: DuoImpliedLeading.close),
        ),
      );
      expect(roles['sheet'], DuoActionRole.close);
    });
  });

  group('hoisting off', () {
    /// Records the bar data a page gets.
    Widget recordingPage(List<DuoBarData<Object?, Object?>> bars) =>
        DuoPage<Object?, Object?>.custom(
          leading: const DuoAction<Object?>.back(icon: null, label: 'Cancel'),
          trailing: [_share()],
          builder: (context, bar) {
            bars.add(bar);
            return Scaffold(appBar: const DuoAppBar());
          },
        );

    testWidgets('keeps every action in the bar and the data equal in both '
        'modes', (tester) async {
      final bars = <DuoBarData<Object?, Object?>>[];
      for (final mode in DuoLayoutMode.values) {
        await pump(
          tester,
          shellWithPushed(recordingPage(bars)),
          mode: mode,
          data: const DuoNavigationData(
            hoisting: DuoHoisting.none,
            side: DuoSide.start,
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
      expect(find.byKey(DuoKeys.rail), findsOneWidget);
    });

    testWidgets('can be set per shell', (tester) async {
      await pump(
        tester,
        shellWithPushed(
          DuoPage<Object?, Object?>(
            trailing: [_share()],
            body: const SizedBox(),
          ),
          hoisting: DuoHoisting.none,
        ),
      );
      expect(_inBar(_action('share')), findsOneWidget);
      expect(_inBar(_action(DuoAction.backId)), findsOneWidget);
      expect(_inColumn(_action(DuoAction.backId)), findsNothing);
    });

    testWidgets('can be set per page', (tester) async {
      await pump(
        tester,
        shellWithPushed(
          DuoPage<Object?, Object?>(
            hoisting: DuoHoisting.none,
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

    for (final mode in DuoLayoutMode.values) {
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
            builder: (context, setState) => DuoShell<Object?, Object?, Object?>(
              tabs: _tabs,
              currentIndex: index,
              onTabSelected: (i) => setState(() => index = i),
              child: DuoTabStack(
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
        expect(find.byKey(DuoKeys.action(DuoAction.backId)), findsNothing);

        await tester.tap(find.byKey(DuoKeys.tab('me')));
        await tester.pumpAndSettle();
        expect(find.text('tab 1'), findsOneWidget);

        await tester.tap(find.byKey(DuoKeys.tab('home')));
        await tester.pumpAndSettle();
        expect(find.text('detail 0'), findsOneWidget);

        final chrome = mode == DuoLayoutMode.wide
            ? find.byKey(DuoKeys.column)
            : find.byKey(DuoKeys.bar);
        expect(chrome, findsOneWidget);
        // The body sits beside the chrome: the AppBar ends where it starts.
        final appBar = tester.getRect(find.byType(AppBar).last);
        final chromeRect = tester.getRect(chrome);
        if (mode == DuoLayoutMode.wide) {
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
          DuoModalScope<Object?, Object?>(child: plain('modal')),
          mode: mode,
        );
        expect(find.text('modal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
