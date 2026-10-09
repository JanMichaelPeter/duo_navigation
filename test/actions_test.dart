import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

/// A design system's action spec, carried as a typed payload.
class _Spec {
  const _Spec(this.name);
  final String name;
}

class _Other {}

const _tabs = <DuoTab<Object?>>[
  DuoTab(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

Finder _action(Object id) => find.byKey(DuoKeys.action(id));
Finder _inColumn(Finder finder) =>
    find.descendant(of: find.byKey(DuoKeys.column), matching: finder);
Finder _inBar(Finder finder) =>
    find.descendant(of: find.byType(AppBar), matching: finder);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DuoLayoutMode mode = DuoLayoutMode.wide,
    DuoTapGuard tapGuard = const DuoTapGuard(clock: DuoClock.frameTime),
    DuoBuilders<Object?, Object?, Object?>? builders =
        const DuoMaterialBuilders(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DuoTestHarness(
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
  Widget shell(Widget page) => DuoShell<Object?, Object?, Object?>(
    tabs: _tabs,
    currentIndex: 0,
    onTabSelected: (_) {},
    child: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
    ),
  );

  DuoAction<Object?> icon(
    Object id, {
    VoidCallback? onPressed,
    int order = 0,
    bool guarded = true,
    bool enabled = true,
    Duration? cooldown,
    DuoHoist hoist = DuoHoist.auto,
  }) => DuoAction<Object?>(
    id: id,
    icon: const DuoIcon(Icons.star),
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
              return DuoPage<Object?, Object?>(
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
              return DuoPage<Object?, Object?>(
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
      final rejected = <DuoTapRejection>[];
      var taps = 0;
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DuoTestHarness(
            builders: const DuoMaterialBuilders(),
            mode: DuoLayoutMode.wide,
            tapGuard: DuoTapGuard(
              clock: DuoClock.frameTime,
              onRejected: (action, reason) => rejected.add(reason),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return DuoPage<Object?, Object?>(
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
      expect(rejected, [DuoTapRejection.notActive]);
    });

    testWidgets('a pushed page still takes over the column', (tester) async {
      late BuildContext pageContext;
      await pump(
        tester,
        shell(
          Builder(
            builder: (context) {
              pageContext = context;
              return DuoPage<Object?, Object?>(
                trailing: [icon('share')],
                body: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      Navigator.of(pageContext).push(
        MaterialPageRoute<void>(
          builder: (_) => DuoPage<Object?, Object?>(
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
      List<DuoAction<Object?>> Function(void Function(Object id) tap) actions, {
      List<DuoTapRejection>? rejected,
    }) async {
      final taps = <Object>[];
      await pump(
        tester,
        shell(
          DuoPage<Object?, Object?>(
            trailing: actions(taps.add),
            body: const SizedBox.expand(),
          ),
        ),
        tapGuard: DuoTapGuard(
          clock: DuoClock.frameTime,
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
      final rejected = <DuoTapRejection>[];
      final taps = await pumpPage(
        tester,
        (tap) => [icon('a', onPressed: () => tap('a'))],
        rejected: rejected,
      );
      await tester.tap(_action('a'));
      await tester.tap(_action('a'));
      expect(taps, ['a']);
      expect(rejected, [DuoTapRejection.cooldown]);

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
    for (final mode in DuoLayoutMode.values) {
      testWidgets('${mode.name}: a text-only leading action stays in the bar', (
        tester,
      ) async {
        await pump(
          tester,
          shell(
            DuoPage<Object?, Object?>(
              leading: DuoAction<Object?>.back(icon: null, label: 'Cancel'),
              trailing: [icon('share')],
              body: const SizedBox.expand(),
            ),
          ),
          mode: mode,
        );
        expect(_inBar(find.text('Cancel')), findsOneWidget);
        if (mode == DuoLayoutMode.wide) {
          expect(_inColumn(_action(DuoAction.backId)), findsNothing);
          expect(_inColumn(_action('share')), findsOneWidget);
        }
      });
    }

    testWidgets('hoist: never keeps an icon action in the bar', (tester) async {
      await pump(
        tester,
        shell(
          DuoPage<Object?, Object?>(
            trailing: [
              icon('pinned', hoist: DuoHoist.never),
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
          builder: (_) => DuoPage<Object?, Object?>(
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
      expect(y('d'), lessThan(y(DuoAction.backId)));
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
        mode: DuoLayoutMode.compact,
      );
      Navigator.of(pageContext).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const DuoPage<Object?, Object?>(body: SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
    });
  });

  group('typed payloads', () {
    Widget typedShell(List<DuoAction<Object?>> actions) =>
        DuoShell<Object?, _Spec, Object?>(
          tabs: _tabs,
          currentIndex: 0,
          onTabSelected: (_) {},
          builders: DuoBuilders<Object?, _Spec, Object?>(
            action: (context, action, placement) =>
                Text('${action.payload!.name} ${placement.name}'),
          ),
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => DuoPage<Object?, Object?>(
                trailing: actions,
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );

    for (final mode in DuoLayoutMode.values) {
      testWidgets('${mode.name}: reach the action builder without a cast', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => DuoTestHarness(
              builders: const DuoMaterialBuilders(),
              mode: mode,
              child: child!,
            ),
            home: DuoShell<Object?, _Spec, Object?>(
              tabs: _tabs,
              currentIndex: 0,
              onTabSelected: (_) {},
              builders: DuoBuilders<Object?, _Spec, Object?>(
                action: (context, action, placement) =>
                    Text('${action.payload!.name} ${placement.name}'),
              ),
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => DuoPage<_Spec, Object?>(
                    trailing: [
                      DuoAction<_Spec>(
                        id: 'share',
                        icon: const DuoIcon(Icons.share),
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
            mode == DuoLayoutMode.wide ? 'spec sideColumn' : 'spec barTrailing',
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
          DuoAction<_Other>(
            id: 'share',
            icon: const DuoIcon(Icons.share),
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
            builder: (context, id, _) => DuoPage<Object?, Object?>(
              trailing: [
                DuoAction<Object?>(
                  id: 'fav',
                  icon: DuoIcon.widget(Text('icon $id'), identity: id),
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

    group('DuoIconMorph', () {
      Widget morph(String id, {bool reduceMotion = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DuoIconMorph(
            icon: DuoIcon.widget(const SizedBox(), identity: id),
            // A design system's own rendering.
            builder: (context, icon) => Text('drawn ${icon.identity}'),
          ),
        ),
      );

      testWidgets('uses the builder and cross-fades a new identity', (
        tester,
      ) async {
        await tester.pumpWidget(morph('a'));
        expect(find.text('drawn a'), findsOneWidget);

        await tester.pumpWidget(morph('a')); // same identity: no animation
        expect(tester.binding.hasScheduledFrame, isFalse);

        await tester.pumpWidget(morph('b'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('drawn a'), findsOneWidget);
        expect(find.text('drawn b'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('drawn a'), findsNothing);
      });

      testWidgets('swaps at once with reduced motion', (tester) async {
        await tester.pumpWidget(morph('a', reduceMotion: true));
        await tester.pumpWidget(morph('b', reduceMotion: true));
        await tester.pump();
        expect(find.text('drawn a'), findsNothing);
        expect(find.text('drawn b'), findsOneWidget);
      });
    });

    test('platform icons have no widget of their own', () {
      expect(() => DuoIcon.back.toWidget(), throwsFlutterError);
      expect(DuoIcon.back.identity, isNot(DuoIcon.close.identity));
    });
  });

  group('DuoAction', () {
    test('back and close share an identity but not a role', () {
      const back = DuoAction<Object?>.back();
      const close = DuoAction<Object?>.close();
      expect(back.id, close.id);
      expect(back.shared && close.shared, isTrue);
      expect(back.role, DuoActionRole.back);
      expect(close.role, DuoActionRole.close);
      expect(back.icon, DuoIcon.back);
    });

    test('a text-only back action does not move to the column', () {
      expect(
        const DuoAction<Object?>.back(icon: null, label: 'Cancel').canHoist,
        isFalse,
      );
    });

    test('has value equality and a resettable copyWith', () {
      const action = DuoAction<int>(
        id: 'a',
        icon: DuoIcon(Icons.star),
        badge: DuoBadge.count(2),
        payload: 1,
      );
      expect(action, action.copyWith());
      expect(action.copyWith(order: 2), isNot(action));
      expect(action.copyWith(badge: null).badge, isNull);
      expect(action.copyWith(enabled: false).effectiveOnPressed, isNull);
    });
  });
}
