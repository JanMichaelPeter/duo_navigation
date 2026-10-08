import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock/testing.dart';

/// A design system's action spec, carried as a typed payload.
class _Spec {
  const _Spec(this.name);
  final String name;
}

class _Other {}

const _tabs = <DockTab<Object?>>[
  DockTab(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

Finder _action(Object id) => find.byKey(DockKeys.action(id));
Finder _inColumn(Finder finder) =>
    find.descendant(of: find.byKey(DockKeys.column), matching: finder);
Finder _inBar(Finder finder) =>
    find.descendant(of: find.byType(AppBar), matching: finder);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DockLayoutMode mode = DockLayoutMode.wide,
    DockTapGuard tapGuard = const DockTapGuard(clock: DockClock.frameTime),
    DockBuilders<Object?, Object?, Object?>? builders =
        const DockMaterialBuilders(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DockTestHarness(
          builders: builders,
          mode: mode,
          tapGuard: tapGuard,
          child: child!,
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A shell with one nested navigator whose root page is [page].
  Widget shell(Widget page) => DockShell<Object?, Object?, Object?>(
    tabs: _tabs,
    currentIndex: 0,
    onTabSelected: (_) {},
    child: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
    ),
  );

  DockAction<Object?> icon(
    Object id, {
    VoidCallback? onPressed,
    int order = 0,
    bool guarded = true,
    bool enabled = true,
    Duration? cooldown,
    DockHoist hoist = DockHoist.auto,
  }) => DockAction<Object?>(
    id: id,
    icon: const DockIcon(Icons.star),
    tooltip: '$id',
    onPressed: onPressed ?? () {},
    order: order,
    guarded: guarded,
    enabled: enabled,
    cooldown: cooldown,
    hoist: hoist,
  );

  group('popups', () {
    testWidgets('a dialog keeps the page\'s chips in the column', (
      tester,
    ) async {
      late BuildContext pageContext;
      await pump(
        tester,
        shell(
          Builder(
            builder: (context) {
              pageContext = context;
              return DockPage<Object?, Object?>(
                trailing: [icon('share'), icon('edit')],
                body: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      expect(_inColumn(_action('share')), findsOneWidget);

      showDialog<void>(
        context: pageContext,
        builder: (_) => const AlertDialog(content: Text('Sure?')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sure?'), findsOneWidget);
      expect(_inColumn(_action('share')), findsOneWidget);
      expect(_inColumn(_action('edit')), findsOneWidget);

      Navigator.of(pageContext, rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(_inColumn(_action('share')), findsOneWidget);
    });

    testWidgets('a sheet on the page\'s own navigator keeps them too', (
      tester,
    ) async {
      late BuildContext pageContext;
      await pump(
        tester,
        shell(
          Builder(
            builder: (context) {
              pageContext = context;
              return DockPage<Object?, Object?>(
                trailing: [icon('share')],
                body: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      showModalBottomSheet<void>(
        context: pageContext,
        builder: (_) => const SizedBox(height: 200, child: Text('Sheet')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sheet'), findsOneWidget);
      expect(_inColumn(_action('share')), findsOneWidget);
    });

    testWidgets('taps under a dialog are rejected as not active', (
      tester,
    ) async {
      final rejected = <DockTapRejection>[];
      var taps = 0;
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DockTestHarness(
            builders: const DockMaterialBuilders(),
            mode: DockLayoutMode.wide,
            tapGuard: DockTapGuard(
              clock: DockClock.frameTime,
              onRejected: (action, reason) => rejected.add(reason),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return DockPage<Object?, Object?>(
                trailing: [icon('share', onPressed: () => taps++)],
                body: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      showDialog<void>(
        context: pageContext,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(content: Text('Sure?')),
      );
      await tester.pumpAndSettle();
      // The chip stays, but its page is not current.
      final chip = tester.widget<IconButton>(
        find.descendant(
          of: _action('share'),
          matching: find.byType(IconButton),
        ),
      );
      chip.onPressed!();
      expect(taps, 0);
      expect(rejected, [DockTapRejection.notActive]);
    });

    testWidgets('a pushed page still takes over the column', (tester) async {
      late BuildContext pageContext;
      await pump(
        tester,
        shell(
          Builder(
            builder: (context) {
              pageContext = context;
              return DockPage<Object?, Object?>(
                trailing: [icon('share')],
                body: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      Navigator.of(pageContext).push(
        MaterialPageRoute<void>(
          builder: (_) => DockPage<Object?, Object?>(
            trailing: [icon('edit')],
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_inColumn(_action('edit')), findsOneWidget);
      expect(_inColumn(_action('share')), findsNothing);
    });
  });

  group('tap guard', () {
    Future<List<Object>> pumpPage(
      WidgetTester tester,
      List<DockAction<Object?>> Function(void Function(Object id) tap)
      actions, {
      List<DockTapRejection>? rejected,
    }) async {
      final taps = <Object>[];
      await pump(
        tester,
        shell(
          DockPage<Object?, Object?>(
            trailing: actions(taps.add),
            body: const SizedBox.expand(),
          ),
        ),
        tapGuard: DockTapGuard(
          clock: DockClock.frameTime,
          onRejected: rejected == null
              ? null
              : (action, reason) => rejected.add(reason),
        ),
      );
      return taps;
    }

    testWidgets('different actions do not block each other', (tester) async {
      final taps = await pumpPage(
        tester,
        (tap) => [
          icon('a', onPressed: () => tap('a')),
          icon('b', onPressed: () => tap('b')),
        ],
      );
      await tester.tap(_action('a'));
      await tester.tap(_action('b'));
      expect(taps, ['a', 'b']);
    });

    testWidgets('a repeated tap within the cooldown is rejected', (
      tester,
    ) async {
      final rejected = <DockTapRejection>[];
      final taps = await pumpPage(
        tester,
        (tap) => [icon('a', onPressed: () => tap('a'))],
        rejected: rejected,
      );
      await tester.tap(_action('a'));
      await tester.tap(_action('a'));
      expect(taps, ['a']);
      expect(rejected, [DockTapRejection.cooldown]);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(_action('a'));
      expect(taps, ['a', 'a']);
    });

    testWidgets('an action can set its own cooldown', (tester) async {
      final taps = await pumpPage(
        tester,
        (tap) => [
          icon(
            'a',
            cooldown: const Duration(seconds: 1),
            onPressed: () => tap('a'),
          ),
        ],
      );
      await tester.tap(_action('a'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(_action('a'));
      expect(taps, hasLength(1));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(_action('a'));
      expect(taps, hasLength(2));
    });

    testWidgets('guarded: false lets every tap through', (tester) async {
      final taps = await pumpPage(
        tester,
        (tap) => [icon('a', guarded: false, onPressed: () => tap('a'))],
      );
      await tester.tap(_action('a'));
      await tester.tap(_action('a'));
      expect(taps, ['a', 'a']);
    });

    testWidgets('a disabled action reaches builders without a callback', (
      tester,
    ) async {
      final taps = await pumpPage(
        tester,
        (tap) => [icon('a', enabled: false, onPressed: () => tap('a'))],
      );
      final button = tester.widget<IconButton>(
        find.descendant(of: _action('a'), matching: find.byType(IconButton)),
      );
      expect(button.onPressed, isNull);
      await tester.tap(_action('a'), warnIfMissed: false);
      expect(taps, isEmpty);
    });
  });

  group('placement', () {
    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: a text-only leading action stays in the bar', (
        tester,
      ) async {
        await pump(
          tester,
          shell(
            DockPage<Object?, Object?>(
              leading: DockAction<Object?>.back(icon: null, label: 'Cancel'),
              trailing: [icon('share')],
              body: const SizedBox.expand(),
            ),
          ),
          mode: mode,
        );
        expect(_inBar(find.text('Cancel')), findsOneWidget);
        if (mode == DockLayoutMode.wide) {
          expect(_inColumn(_action(DockAction.backId)), findsNothing);
          expect(_inColumn(_action('share')), findsOneWidget);
        }
      });
    }

    testWidgets('hoist: never keeps an icon action in the bar', (tester) async {
      await pump(
        tester,
        shell(
          DockPage<Object?, Object?>(
            trailing: [
              icon('pinned', hoist: DockHoist.never),
              icon('free'),
            ],
            body: const SizedBox.expand(),
          ),
        ),
      );
      expect(_inBar(_action('pinned')), findsOneWidget);
      expect(_inColumn(_action('free')), findsOneWidget);
    });

    testWidgets('order sorts the column, the leading action stays lowest', (
      tester,
    ) async {
      late BuildContext pageContext;
      await pump(
        tester,
        shell(
          Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      Navigator.of(pageContext).push(
        MaterialPageRoute<void>(
          builder: (_) => DockPage<Object?, Object?>(
            trailing: [
              icon('a'),
              icon('b', order: 1),
              icon('c'),
              icon('d', order: -1),
            ],
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double y(Object id) => tester.getCenter(_inColumn(_action(id))).dy;
      // Top to bottom: b (1), a and c (0, declaration order), d (-1), back.
      expect(y('b'), lessThan(y('a')));
      expect(y('a'), lessThan(y('c')));
      expect(y('c'), lessThan(y('d')));
      expect(y('d'), lessThan(y(DockAction.backId)));
    });

    testWidgets('the implied back action gets the Material tooltip', (
      tester,
    ) async {
      late BuildContext pageContext;
      await pump(
        tester,
        shell(
          Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
        mode: DockLayoutMode.compact,
      );
      Navigator.of(pageContext).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const DockPage<Object?, Object?>(body: SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
    });
  });

  group('typed payloads', () {
    Widget typedShell(List<DockAction<Object?>> actions) =>
        DockShell<Object?, _Spec, Object?>(
          tabs: _tabs,
          currentIndex: 0,
          onTabSelected: (_) {},
          builders: DockBuilders<Object?, _Spec, Object?>(
            action: (context, action, placement) =>
                Text('${action.payload!.name} ${placement.name}'),
          ),
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => DockPage<Object?, Object?>(
                trailing: actions,
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );

    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: reach the action builder without a cast', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => DockTestHarness(
              builders: const DockMaterialBuilders(),
              mode: mode,
              child: child!,
            ),
            home: DockShell<Object?, _Spec, Object?>(
              tabs: _tabs,
              currentIndex: 0,
              onTabSelected: (_) {},
              builders: DockBuilders<Object?, _Spec, Object?>(
                action: (context, action, placement) =>
                    Text('${action.payload!.name} ${placement.name}'),
              ),
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => DockPage<_Spec, Object?>(
                    trailing: [
                      DockAction<_Spec>(
                        id: 'share',
                        icon: const DockIcon(Icons.share),
                        payload: const _Spec('spec'),
                        onPressed: () {},
                      ),
                    ],
                    body: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            mode == DockLayoutMode.wide
                ? 'spec sideColumn'
                : 'spec barTrailing',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('page actions of another type fail with a clear error', (
      tester,
    ) async {
      await pump(
        tester,
        typedShell([
          DockAction<_Other>(
            id: 'share',
            icon: const DockIcon(Icons.share),
            onPressed: () {},
          ),
        ]),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.toStringDeep(),
          'message',
          contains('does not match this frame'),
        ),
      );
    });
  });

  group('icons', () {
    testWidgets('a changed identity cross-fades, the same one does not', (
      tester,
    ) async {
      final which = ValueNotifier('a');
      addTearDown(which.dispose);
      await pump(
        tester,
        shell(
          ValueListenableBuilder(
            valueListenable: which,
            builder: (context, id, _) => DockPage<Object?, Object?>(
              trailing: [
                DockAction<Object?>(
                  id: 'fav',
                  icon: DockIcon.widget(Text('icon $id'), identity: id),
                  onPressed: () {},
                ),
              ],
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      which.value = 'b';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('icon a'), findsOneWidget);
      expect(find.text('icon b'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('icon a'), findsNothing);
    });

    test('platform icons have no widget of their own', () {
      expect(() => DockIcon.back.toWidget(), throwsFlutterError);
      expect(DockIcon.back.identity, isNot(DockIcon.close.identity));
    });
  });

  group('DockAction', () {
    test('back and close share an identity but not a role', () {
      const back = DockAction<Object?>.back();
      const close = DockAction<Object?>.close();
      expect(back.id, close.id);
      expect(back.shared && close.shared, isTrue);
      expect(back.role, DockActionRole.back);
      expect(close.role, DockActionRole.close);
      expect(back.icon, DockIcon.back);
    });

    test('a text-only back action does not move to the column', () {
      expect(
        const DockAction<Object?>.back(icon: null, label: 'Cancel').canHoist,
        isFalse,
      );
    });

    test('has value equality and a resettable copyWith', () {
      const action = DockAction<int>(
        id: 'a',
        icon: DockIcon(Icons.star),
        badge: DockBadge.count(2),
        payload: 1,
      );
      expect(action, action.copyWith());
      expect(action.copyWith(order: 2), isNot(action));
      expect(action.copyWith(badge: null).badge, isNull);
      expect(action.copyWith(enabled: false).effectiveOnPressed, isNull);
    });
  });
}
