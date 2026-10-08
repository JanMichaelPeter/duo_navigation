import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/testing.dart';

const _tabs = <DockTab<Object?>>[
  DockTab(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

const _bled = Key('bled');
const _sibling = Key('sibling');
const _safe = Key('safe');
const _inset = Key('inset');

enum _Frame { shell, modal }

/// A body with a bleeding box, a plain sibling, a SafeArea box and a
/// DockInset box inside the bleed.
Widget _probe({bool column = true, bool bar = true}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(
      child: DockBleed(
        column: column,
        bar: bar,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(key: _bled, color: Color(0xFF00FF00)),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: SizedBox.expand(key: _safe),
              ),
            ),
            Expanded(
              child: DockInset(child: SizedBox.expand(key: _inset)),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(key: _sibling, height: 50),
  ],
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget body, {
    DockLayoutMode mode = DockLayoutMode.wide,
    _Frame frame = _Frame.shell,
    DockNavigationData data = const DockNavigationData(),
    TextDirection? direction,
    EdgeInsets padding = EdgeInsets.zero,
    bool visible = true,
    Widget? backdrop,
    Size size = const Size(1000, 700),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: padding, viewPadding: padding),
          child: DockTestHarness(
            builders: const DockMaterialBuilders(),
            data: data,
            mode: mode,
            textDirection: direction,
            child: child!,
          ),
        ),
        home: switch (frame) {
          _Frame.shell => DockShell<Object?, Object?, Object?>(
            tabs: _tabs,
            currentIndex: 0,
            onTabSelected: (_) {},
            navigationVisible: visible,
            backdrop: backdrop,
            child: body,
          ),
          _Frame.modal => DockModalScope<Object?, Object?>(
            navigationVisible: visible,
            backdrop: backdrop,
            child: body,
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  group('DockBleed', () {
    for (final frame in _Frame.values) {
      testWidgets('${frame.name}: runs under the column at the end', (
        tester,
      ) async {
        await pump(tester, _probe(), frame: frame);
        expect(rect(tester, _bled).left, 0);
        expect(rect(tester, _bled).right, 1000);
        expect(rect(tester, _sibling).right, 1000 - 72);
        expect(rect(tester, _safe).right, 1000 - 72);
        expect(rect(tester, _inset).right, 1000 - 72);
      });

      testWidgets('${frame.name}: runs under the column at the start', (
        tester,
      ) async {
        await pump(
          tester,
          _probe(),
          frame: frame,
          direction: TextDirection.rtl,
        );
        expect(rect(tester, _bled).left, 0);
        expect(rect(tester, _bled).right, 1000);
        expect(rect(tester, _sibling).left, 72);
        expect(rect(tester, _inset).left, 72);
      });
    }

    testWidgets('reaches the screen edge past a wide system inset', (
      tester,
    ) async {
      await pump(tester, _probe(), padding: const EdgeInsets.only(right: 100));
      expect(rect(tester, _bled).right, 1000);
      expect(rect(tester, _sibling).right, 1000 - 72);
      // SafeArea clears the column and the rest of the inset; DockInset puts
      // its child back beside the column, where the body was.
      expect(rect(tester, _safe).right, 1000 - 100);
      expect(rect(tester, _inset).right, 1000 - 72);
    });

    testWidgets('safeArea: reaches the screen edge past the column', (
      tester,
    ) async {
      await pump(
        tester,
        _probe(),
        padding: const EdgeInsets.only(right: 100),
        data: const DockNavigationData(columnInset: DockColumnInset.safeArea),
      );
      expect(rect(tester, _bled).right, 1000);
      expect(rect(tester, _sibling).right, 1000 - 172);
      expect(rect(tester, _inset).right, 1000 - 172);
    });

    testWidgets('runs under the compact bar', (tester) async {
      await pump(
        tester,
        const DockBleed(child: SizedBox.expand(key: _bled)),
        mode: DockLayoutMode.compact,
        size: const Size(400, 800),
      );
      expect(rect(tester, _bled).bottom, 800);
      expect(rect(tester, DockKeys.bar).top, lessThan(800));
    });

    testWidgets('edges can be turned off', (tester) async {
      await pump(tester, _probe(column: false));
      expect(rect(tester, _bled).right, 1000 - 72);
    });

    group('is a no-op', () {
      Future<void> expectNoBleed(WidgetTester tester) async {
        expect(rect(tester, _bled).right, rect(tester, _sibling).right);
      }

      testWidgets('in overlay mode', (tester) async {
        await pump(
          tester,
          _probe(),
          data: const DockNavigationData(bodyMode: DockBodyMode.overlay),
        );
        await expectNoBleed(tester);
      });

      testWidgets('while the navigation is hidden', (tester) async {
        await pump(tester, _probe(), visible: false);
        await expectNoBleed(tester);
        expect(rect(tester, _bled).right, 1000);
      });

      testWidgets('inside another bleed', (tester) async {
        await pump(
          tester,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DockBleed(
                  child: Center(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: DockBleed(child: SizedBox.expand(key: _bled)),
                    ),
                  ),
                ),
              ),
              const SizedBox(key: _sibling, height: 10),
            ],
          ),
        );
        expect(rect(tester, _bled).width, 100);
      });

      testWidgets('outside a frame', (tester) async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(),
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: DockBleed(child: SizedBox.expand(key: _bled)),
                ),
              ),
            ),
          ),
        );
        expect(rect(tester, _bled).width, 100);
      });
    });

    testWidgets('keeps the child State across a mode switch', (tester) async {
      await pump(
        tester,
        const DockBleed(child: Material(child: TextField())),
        size: const Size(1000, 700),
      );
      await tester.enterText(find.byType(TextField), 'kept');
      final state = tester.state(find.byType(TextField));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(TextField)), same(state));
      expect(find.text('kept'), findsOneWidget);
    });

    testWidgets('insetOf reports the strip, and zero inside a bleed', (
      tester,
    ) async {
      late EdgeInsets outside, inside;
      await pump(
        tester,
        Builder(
          builder: (context) {
            outside = DockBleed.insetOf(context);
            return DockBleed(
              child: Builder(
                builder: (context) {
                  inside = DockBleed.insetOf(context);
                  return const SizedBox.expand();
                },
              ),
            );
          },
        ),
      );
      expect(outside, const EdgeInsets.only(right: 72));
      expect(inside, EdgeInsets.zero);
    });

    testWidgets('taps in the strip do not reach the bleed', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Column(
          children: [
            Expanded(
              child: DockBleed(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
        // A modal frame: the column has no rail that would take the tap.
        frame: _Frame.modal,
      );
      await tester.tapAt(const Offset(1000 - 20, 100));
      expect(taps, 0);
      await tester.tapAt(const Offset(500, 100));
      expect(taps, 1);
    });

    testWidgets('adds no layer', (tester) async {
      await pump(tester, _probe());
      // The first render object of a DockBleed is the bleed's own box.
      final bleed = tester.renderObject(find.byType(DockBleed).first);
      expect(bleed.isRepaintBoundary, isFalse);
      expect(bleed.debugLayer, isNull);
    });

    testWidgets('names a clipping ancestor in debug mode', (tester) async {
      final messages = <String>[];
      final previous = debugPrint;
      debugPrint = (message, {wrapWidth}) => messages.add(message ?? '');
      try {
        await pump(
          tester,
          const ClipRect(child: DockBleed(child: SizedBox.expand())),
        );
      } finally {
        // flutter_test checks that debugPrint is restored when the body ends.
        debugPrint = previous;
      }
      expect(
        messages.where((m) => m.contains('DockBleed is clipped')),
        hasLength(1),
      );
      expect(messages.first, contains('RenderClipRect'));
    });

    testWidgets('a list bleeds as a whole, with inset rows and a bleeding '
        'header', (tester) async {
      await pump(
        tester,
        DockBleed(
          child: ListView(
            children: DockInset.wrapAll([
              const DockBleedItem(child: SizedBox(key: _bled, height: 100)),
              const SizedBox(key: _inset, height: 40),
            ]),
          ),
        ),
      );
      expect(rect(tester, _bled).right, 1000);
      expect(rect(tester, _inset).right, 1000 - 72);
      expect(rect(tester, _inset).left, 0);
    });
  });

  group('backdrop', () {
    const backdrop = Key('backdrop');

    testWidgets('covers the whole frame under body and chrome', (tester) async {
      var bodyTaps = 0;
      await pump(
        tester,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => bodyTaps++,
          child: const SizedBox.expand(),
        ),
        backdrop: const ColoredBox(key: backdrop, color: Color(0xFF123456)),
      );
      expect(
        rect(tester, backdrop),
        const Offset(0, 0) & const Size(1000, 700),
      );
      await tester.tapAt(const Offset(400, 300));
      expect(bodyTaps, 1);
    });

    for (final frame in _Frame.values) {
      testWidgets('${frame.name}: the builders\' backdrop fills the strip '
          'when none is set', (tester) async {
        final material = find.byWidgetPredicate(
          (w) =>
              w is ColoredBox && w.color == ThemeData().scaffoldBackgroundColor,
        );
        await pump(tester, const SizedBox.expand(), frame: frame);
        expect(
          tester.getRect(material.first),
          Offset.zero & const Size(1000, 700),
        );

        await pump(
          tester,
          const SizedBox.expand(),
          frame: frame,
          backdrop: const SizedBox.expand(key: backdrop),
        );
        expect(find.byKey(backdrop), findsOneWidget);
        expect(material, findsNothing);
      });
    }

    testWidgets('a page backdrop replaces the frame\'s while it is shown', (
      tester,
    ) async {
      late BuildContext root;
      await pump(
        tester,
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) {
              root = context;
              return const DockPage<Object?, Object?>(body: SizedBox.expand());
            },
          ),
        ),
        backdrop: const SizedBox.expand(key: backdrop),
      );
      expect(find.byKey(backdrop), findsOneWidget);

      Navigator.of(root).push(
        MaterialPageRoute<void>(
          builder: (_) => const DockPage<Object?, Object?>(
            backdrop: SizedBox.expand(key: Key('page backdrop')),
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Cross-fading: both are there for a moment.
      expect(find.byKey(const Key('page backdrop')), findsOneWidget);
      expect(find.byKey(backdrop), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page backdrop')), findsOneWidget);
      expect(find.byKey(backdrop), findsNothing);
      expect(
        rect(tester, const Key('page backdrop')),
        const Offset(0, 0) & const Size(1000, 700),
      );

      Navigator.of(root).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(backdrop), findsOneWidget);
      expect(find.byKey(const Key('page backdrop')), findsNothing);
    });
  });
}
