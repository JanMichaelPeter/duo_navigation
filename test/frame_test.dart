import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';

const _tabs = [
  DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

const _plain = Key('plain');
const _safe = Key('safe');

/// A body with one plain box and one box in a horizontal SafeArea, stacked.
const Widget _probeBody = Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(
      child: ColoredBox(key: _plain, color: Color(0xFF00FF00)),
    ),
    Expanded(
      child: SafeArea(
        top: false,
        bottom: false,
        child: ColoredBox(key: _safe, color: Color(0xFF0000FF)),
      ),
    ),
  ],
);

enum _Frame { shell, modal }

Widget _app({
  DockNavigationData data = const DockNavigationData(),
  DockBuilders<Object?>? builders,
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
  TextDirection direction = TextDirection.ltr,
  _Frame frame = _Frame.shell,
  DockBodyMode? bodyMode,
  Widget body = _probeBody,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
      ),
      child: Directionality(
        textDirection: direction,
        child: DockNavigation(
          builders: const DockMaterialBuilders<Object?>().merge(builders),
          data: data,
          child: child!,
        ),
      ),
    ),
    home: switch (frame) {
      _Frame.shell => DockShell(
        tabs: _tabs,
        currentIndex: 0,
        onTabSelected: (_) {},
        bodyMode: bodyMode,
        child: body,
      ),
      _Frame.modal => DockModalScope(bodyMode: bodyMode, child: body),
    },
  );
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget app, {
    Size size = const Size(1000, 700),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  Rect rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  MediaQueryData bodyMediaQuery(WidgetTester tester) =>
      MediaQuery.of(tester.element(find.byKey(_plain)));

  DockGeometry geometry(WidgetTester tester) =>
      DockGeometry.of(tester.element(find.byKey(_plain)));

  group('inset (default), wide', () {
    for (final frame in _Frame.values) {
      testWidgets('${frame.name}: column at the end', (tester) async {
        await pump(tester, _app(frame: frame));
        expect(rectOf(tester, _plain).left, 0);
        expect(rectOf(tester, _plain).right, 1000 - 72);
        expect(rectOf(tester, _safe).right, 1000 - 72);
        expect(bodyMediaQuery(tester).padding, EdgeInsets.zero);
      });

      testWidgets('${frame.name}: column at the start', (tester) async {
        await pump(
          tester,
          _app(
            frame: frame,
            data: const DockNavigationData(side: DockSide.start),
          ),
        );
        expect(rectOf(tester, _plain).left, 72);
        expect(rectOf(tester, _plain).right, 1000);
      });

      testWidgets('${frame.name}: right to left', (tester) async {
        await pump(tester, _app(frame: frame, direction: TextDirection.rtl));
        expect(rectOf(tester, _plain).left, 72);
        expect(rectOf(tester, _plain).right, 1000);
        expect(geometry(tester).side, DockSide.end);
        expect(geometry(tester).columnOnRight, isFalse);
      });

      testWidgets('${frame.name}: window-edge flip', (tester) async {
        await pump(
          tester,
          _app(
            frame: frame,
            data: const DockNavigationData(
              windowEdgesSource: DockWindowEdgesSource.fixed(
                DockWindowEdges(left: true, right: false),
              ),
            ),
          ),
        );
        expect(rectOf(tester, _plain).left, 72);
        expect(geometry(tester).side, DockSide.start);
      });
    }

    testWidgets('a DockPage without a frame brings its own', (tester) async {
      await pump(
        tester,
        MaterialApp(
          builder: (context, child) => DockNavigation(
            builders: const DockMaterialBuilders(),
            child: child!,
          ),
          home: const DockPage(body: _probeBody),
        ),
      );
      expect(rectOf(tester, _plain).right, 1000 - 72);
    });

    testWidgets('the column sits after the system inset on its edge', (
      tester,
    ) async {
      await pump(tester, _app(padding: const EdgeInsets.only(right: 100)));
      expect(rectOf(tester, _plain).right, 1000 - 100 - 72);
      expect(geometry(tester).chrome, const EdgeInsets.only(right: 172));
      expect(geometry(tester).strip, const EdgeInsets.only(right: 172));
      expect(bodyMediaQuery(tester).padding.right, 0);
      expect(bodyMediaQuery(tester).viewPadding.right, 0);
    });

    testWidgets('the inset on the opposite edge is kept', (tester) async {
      await pump(tester, _app(padding: const EdgeInsets.only(left: 30)));
      expect(rectOf(tester, _plain).left, 0);
      expect(rectOf(tester, _safe).left, 30);
      expect(bodyMediaQuery(tester).padding, const EdgeInsets.only(left: 30));
    });

    testWidgets('top and bottom system padding are kept', (tester) async {
      const padding = EdgeInsets.only(top: 24, bottom: 20);
      await pump(tester, _app(padding: padding));
      expect(bodyMediaQuery(tester).padding, padding);
    });
  });

  group('inset (default), compact', () {
    const phone = Size(400, 800);

    testWidgets('the body ends above the bar', (tester) async {
      await pump(tester, _app(), size: phone);
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(bar.bottom, 800);
      expect(rectOf(tester, _plain).left, 0);
      expect(rectOf(tester, _plain).right, 400);
      expect(tester.getRect(find.byKey(_safe)).bottom, bar.top);
      expect(geometry(tester).chrome, EdgeInsets.only(bottom: bar.height));
    });

    testWidgets('the bar owns the bottom safe area', (tester) async {
      await pump(
        tester,
        _app(padding: const EdgeInsets.only(bottom: 34)),
        size: phone,
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(tester.getRect(find.byKey(_safe)).bottom, bar.top);
      expect(bodyMediaQuery(tester).padding.bottom, 0);
    });

    testWidgets('the body follows a bar that animates its height', (
      tester,
    ) async {
      final tall = ValueNotifier(false);
      addTearDown(tall.dispose);
      await pump(
        tester,
        _app(
          builders: DockBuilders<Object?>(
            tabBar: (context, tabs, items) => ValueListenableBuilder(
              valueListenable: tall,
              builder: (context, isTall, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isTall ? 120 : 60,
              ),
            ),
          ),
        ),
        size: phone,
      );
      expect(rectOf(tester, _safe).bottom, 800 - 60);

      tall.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = rectOf(tester, _safe).bottom;
      expect(mid, lessThan(800 - 60));
      expect(mid, greaterThan(800 - 120));

      await tester.pumpAndSettle();
      expect(rectOf(tester, _safe).bottom, 800 - 120);
    });

    testWidgets('the keyboard is reported where it overlaps the body', (
      tester,
    ) async {
      await pump(
        tester,
        _app(viewInsets: const EdgeInsets.only(bottom: 300)),
        size: phone,
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      expect(bodyMediaQuery(tester).viewInsets.bottom, 300 - bar.height);
    });

    testWidgets('a short bar under a home indicator is reported', (
      tester,
    ) async {
      await pump(
        tester,
        _app(
          padding: const EdgeInsets.only(bottom: 34),
          builders: DockBuilders<Object?>(
            tabBar: (context, tabs, items) => const SizedBox(height: 20),
          ),
        ),
        size: phone,
      );
      expect(
        tester.takeException().toString(),
        contains('shorter than the bottom safe area'),
      );
    });
  });

  testWidgets('a plain Scaffold page keeps its bottom button clear of the '
      'chrome in both modes', (tester) async {
    const button = Key('button');
    final app = _app(
      body: Scaffold(
        body: Column(
          children: [
            const Expanded(child: Placeholder()),
            FilledButton(
              key: button,
              onPressed: () {},
              child: const Text('Go'),
            ),
          ],
        ),
      ),
    );

    await pump(tester, app, size: const Size(400, 800));
    final bar = tester.getRect(find.byType(NavigationBar));
    expect(rectOf(tester, button).bottom, lessThanOrEqualTo(bar.top));

    await pump(tester, app);
    expect(rectOf(tester, button).right, lessThanOrEqualTo(1000 - 72));
  });

  group('overlay', () {
    testWidgets('reproduces 0.0.1: the body covers the frame', (tester) async {
      await pump(
        tester,
        _app(bodyMode: DockBodyMode.overlay),
        size: const Size(800, 600),
      );
      expect(rectOf(tester, _plain).left, 0);
      expect(rectOf(tester, _plain).right, 800);
      expect(rectOf(tester, _safe).right, 728);
      expect(bodyMediaQuery(tester).padding.right, 72);
      expect(geometry(tester).strip, EdgeInsets.zero);
      expect(geometry(tester).chrome, const EdgeInsets.only(right: 72));
    });

    testWidgets('can be the app default', (tester) async {
      await pump(
        tester,
        _app(data: const DockNavigationData(bodyMode: DockBodyMode.overlay)),
      );
      expect(rectOf(tester, _plain).right, 1000);
    });

    testWidgets('a bar covered by the keyboard is not padding', (tester) async {
      await pump(
        tester,
        _app(
          bodyMode: DockBodyMode.overlay,
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
        size: const Size(400, 800),
      );
      expect(bodyMediaQuery(tester).padding.bottom, 0);
      expect(bodyMediaQuery(tester).viewInsets.bottom, 300);
    });
  });

  testWidgets('a mode switch keeps the body State', (tester) async {
    final app = _app(body: const Material(child: TextField()));
    await pump(tester, app, size: const Size(400, 800));
    await tester.enterText(find.byType(TextField), 'kept');
    final state = tester.state(find.byType(TextField));

    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.state(find.byType(TextField)), same(state));
    expect(find.text('kept'), findsOneWidget);
  });

  testWidgets('geometry aspects limit rebuilds', (tester) async {
    final modeBuilds = <DockLayoutMode>[];
    final chromeBuilds = <EdgeInsets>[];
    final tall = ValueNotifier(false);
    addTearDown(tall.dispose);
    await pump(
      tester,
      _app(
        builders: DockBuilders<Object?>(
          tabBar: (context, tabs, items) => ValueListenableBuilder(
            valueListenable: tall,
            builder: (context, isTall, _) =>
                SizedBox(height: isTall ? 120 : 60),
          ),
        ),
        body: Column(
          children: [
            Builder(
              builder: (context) {
                modeBuilds.add(
                  DockGeometry.of(
                    context,
                    aspect: DockGeometryAspect.mode,
                  ).mode,
                );
                return const SizedBox();
              },
            ),
            Builder(
              builder: (context) {
                chromeBuilds.add(
                  DockGeometry.of(
                    context,
                    aspect: DockGeometryAspect.chrome,
                  ).chrome,
                );
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
      size: const Size(400, 800),
    );
    expect(modeBuilds, hasLength(1));
    expect(chromeBuilds, hasLength(1));

    tall.value = true;
    await tester.pump();
    expect(modeBuilds, hasLength(1));
    expect(chromeBuilds.last, const EdgeInsets.only(bottom: 120));
  });

  testWidgets('DockGeometry.of fails loudly outside a frame', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(DockGeometry.maybeOf(context), isNull);
    expect(() => DockGeometry.of(context), throwsFlutterError);
  });

  testWidgets('taps reach the column over the body and the body elsewhere', (
    tester,
  ) async {
    var bodyTaps = 0;
    await pump(
      tester,
      _app(
        bodyMode: DockBodyMode.overlay,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => bodyTaps++,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.tapAt(const Offset(500, 350));
    expect(bodyTaps, 1);
    await tester.tap(find.byIcon(Icons.person));
    expect(bodyTaps, 1);
  });
}
