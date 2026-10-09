import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = <DuoTab<Object?>>[
  DuoTab(id: 'a', icon: DuoIcon(Icons.home), label: 'A'),
  DuoTab(id: 'b', icon: DuoIcon(Icons.person), label: 'B'),
];

void main() {
  late List<GlobalKey<NavigatorState>> navigators;
  late int systemPops;
  late List<bool> canHandlePop;

  setUp(() {
    navigators = [GlobalKey(), GlobalKey()];
    systemPops = 0;
    canHandlePop = [];
  });

  Future<void> pump(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') systemPops++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DuoTestHarness(
          builders: const DuoMaterialBuilders(),
          mode: DuoLayoutMode.compact,
          child: child!,
        ),
        home: NotificationListener<NavigationNotification>(
          onNotification: (notification) {
            canHandlePop.add(notification.canHandlePop);
            return false;
          },
          child: StatefulBuilder(
            builder: (context, setState) => DuoShell<Object?, Object?, Object?>(
              tabs: _tabs,
              currentIndex: index,
              onTabSelected: (i) => setState(() => index = i),
              child: DuoTabStack(
                index: index,
                lazy: false,
                children: [
                  for (var i = 0; i < 2; i++)
                    DuoTabNavigator(
                      navigatorKey: navigators[i],
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => Text('root $i'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> push(WidgetTester tester, int tab) async {
    navigators[tab].currentState!.push(
      MaterialPageRoute<void>(builder: (_) => Text('detail $tab')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('system back pops the shown tab first, then leaves the app', (
    tester,
  ) async {
    await pump(tester);
    await push(tester, 0);
    expect(find.text('detail 0'), findsOneWidget);

    await systemBack(tester);
    expect(find.text('detail 0'), findsNothing);
    expect(find.text('root 0'), findsOneWidget);
    expect(systemPops, 0);

    await systemBack(tester);
    expect(find.text('root 0'), findsOneWidget);
    expect(systemPops, 1);
  });

  testWidgets('a page in a hidden tab does not keep the app from closing', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(DuoKeys.tab('b')));
    await tester.pumpAndSettle();
    await push(tester, 1);
    await tester.tap(find.byKey(DuoKeys.tab('a')));
    await tester.pumpAndSettle();

    await systemBack(tester);
    expect(systemPops, 1);
    expect(find.text('detail 1', skipOffstage: false), findsOneWidget);
  });

  testWidgets('tells the app whether back can pop, for the shown tab only', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(DuoKeys.tab('b')));
    await tester.pumpAndSettle();
    await push(tester, 1);
    expect(canHandlePop.last, isTrue);

    // Back on tab a, which has nothing to pop.
    await tester.tap(find.byKey(DuoKeys.tab('a')));
    await tester.pumpAndSettle();
    expect(canHandlePop.last, isFalse);

    // Changes in the hidden tab are not announced.
    canHandlePop.clear();
    await push(tester, 1);
    expect(canHandlePop, isEmpty);

    // Showing it again announces its pages.
    await tester.tap(find.byKey(DuoKeys.tab('b')));
    await tester.pumpAndSettle();
    expect(canHandlePop.last, isTrue);
  });

  test('a navigator key passed as key is reported', () {
    expect(
      () => DuoTabNavigator(key: GlobalKey<NavigatorState>()),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('navigatorKey'),
        ),
      ),
    );
    // Other keys are fine.
    expect(() => DuoTabNavigator(key: GlobalKey()), returnsNormally);
    expect(() => const DuoTabNavigator(key: ValueKey('tab')), returnsNormally);
  });

  testWidgets('does not clip', (tester) async {
    await pump(tester);
    final navigator = tester.widget<Navigator>(
      find.descendant(
        of: find.byType(DuoTabNavigator).first,
        matching: find.byType(Navigator),
      ),
    );
    expect(navigator.clipBehavior, Clip.none);
  });
}
