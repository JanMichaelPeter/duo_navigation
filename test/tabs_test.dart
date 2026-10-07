import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock/testing.dart';

/// A design system's tab item, carried as a typed payload.
class _Item {
  const _Item(this.name);
  final String name;
}

class _Other {}

List<DockTab<_Item>> _typedTabs() => const [
  DockTab(
    id: 'home',
    icon: DockIcon(Icons.home),
    label: 'Home',
    payload: _Item('home item'),
  ),
  DockTab(
    id: 'me',
    icon: DockIcon(Icons.person),
    label: 'Me',
    badge: DockBadge.count(3),
    key: Key('app-me'),
    payload: _Item('me item'),
  ),
];

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DockLayoutMode mode = DockLayoutMode.compact,
    DockBuilders<Object?>? builders = const DockMaterialBuilders(),
    Size size = const Size(1000, 700),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: DockTestHarness(builders: builders, mode: mode, child: child!),
        ),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A shell around a plain body that tracks the selected index itself.
  Widget shell({
    List<DockTab<Object?>>? tabs,
    void Function(int index)? onSelected,
    void Function(int index)? onReselected,
    FutureOr<bool> Function(int index)? canSelect,
    int initial = 0,
  }) {
    var index = initial;
    return StatefulBuilder(
      builder: (context, setState) => DockShell<Object?>(
        tabs: tabs ?? _typedTabs(),
        currentIndex: index,
        onTabSelected: (i) {
          onSelected?.call(i);
          setState(() => index = i);
        },
        onTabReselected: onReselected,
        canSelectTab: canSelect,
        child: Text('tab $index'),
      ),
    );
  }

  group('typed payloads', () {
    testWidgets('reach the builders without a cast', (tester) async {
      await pump(
        tester,
        DockShell<_Item>(
          tabs: _typedTabs(),
          currentIndex: 0,
          onTabSelected: (_) {},
          builders: DockBuilders<_Item>(
            tabItem: (context, data) => Text(data.tab.payload!.name),
          ),
          child: const SizedBox(),
        ),
      );
      expect(find.text('home item'), findsOneWidget);
      expect(find.text('me item'), findsOneWidget);
      // The bar itself still comes from the app's Material builders.
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Object? builders serve tabs of any payload type', (
      tester,
    ) async {
      await pump(
        tester,
        DockShell<_Item>(
          tabs: _typedTabs(),
          currentIndex: 0,
          onTabSelected: (_) {},
          child: const SizedBox(),
        ),
        mode: DockLayoutMode.wide,
      );
      expect(find.byKey(DockKeys.tab('me')), findsOneWidget);
    });

    testWidgets('builders for another payload type fail with a clear error', (
      tester,
    ) async {
      expect(
        () => const DockMaterialBuilders<Object?>().merge(
          DockBuilders<_Other>(tabItem: (context, data) => const SizedBox()),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('tabItem'),
          ),
        ),
      );

      await pump(
        tester,
        DockShell<_Item>(
          tabs: _typedTabs(),
          currentIndex: 0,
          onTabSelected: (_) {},
          child: const SizedBox(),
        ),
        builders: DockBuilders<_Other>(
          tabItem: (context, data) => const SizedBox(),
          tabBar: (context, data, items) => Row(children: items),
        ),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.toStringDeep(),
          'message',
          contains('does not accept DockTab<_Item>'),
        ),
      );
    });
  });

  group('keys and semantics', () {
    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: keys, selection, label, badge, tap', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, shell(initial: 1), mode: mode);

        expect(find.byKey(DockKeys.tab('home')), findsOneWidget);
        expect(find.byKey(const Key('app-me')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(DockKeys.tab('me')),
            matching: find.byKey(const Key('app-me')),
          ),
          findsOneWidget,
        );
        expect(
          tester.getSemantics(find.byKey(const Key('app-me'))),
          isSemantics(
            label: 'Me',
            value: '3',
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.byKey(DockKeys.tab('home'))),
          isSemantics(
            label: 'Home',
            isSelected: false,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      });
    }

    testWidgets('the Material bar shows the badge', (tester) async {
      await pump(tester, shell());
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('3')),
        findsWidgets,
      );
    });
  });

  group('selection', () {
    testWidgets('selects another tab', (tester) async {
      final selected = <int>[];
      await pump(tester, shell(onSelected: selected.add));
      await tester.tap(find.byKey(DockKeys.tab('me')));
      await tester.pumpAndSettle();
      expect(selected, [1]);
      expect(find.text('tab 1'), findsOneWidget);
    });

    testWidgets('a tap on the current tab re-selects it', (tester) async {
      final selected = <int>[];
      final reselected = <int>[];
      await pump(
        tester,
        shell(onSelected: selected.add, onReselected: reselected.add),
      );
      await tester.tap(find.byKey(DockKeys.tab('home')));
      expect(reselected, [0]);
      expect(selected, isEmpty);
    });

    testWidgets('without onTabReselected, re-taps reach onTabSelected', (
      tester,
    ) async {
      final selected = <int>[];
      await pump(
        tester,
        shell(onSelected: selected.add),
        mode: DockLayoutMode.wide,
      );
      await tester.tap(find.byKey(DockKeys.tab('home')));
      expect(selected, [0]);
    });

    testWidgets('a veto keeps the current tab', (tester) async {
      final asked = <int>[];
      await pump(
        tester,
        shell(
          canSelect: (i) {
            asked.add(i);
            return false;
          },
        ),
      );
      await tester.tap(find.byKey(DockKeys.tab('me')));
      await tester.pumpAndSettle();
      expect(asked, [1]);
      expect(find.text('tab 0'), findsOneWidget);
    });

    testWidgets('an async veto decides later', (tester) async {
      final answer = Completer<bool>();
      await pump(tester, shell(canSelect: (i) => answer.future));
      await tester.tap(find.byKey(DockKeys.tab('me')));
      await tester.pumpAndSettle();
      expect(find.text('tab 0'), findsOneWidget);

      answer.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('tab 1'), findsOneWidget);
    });

    testWidgets('re-selection is not vetoed', (tester) async {
      final reselected = <int>[];
      await pump(
        tester,
        shell(onReselected: reselected.add, canSelect: (_) => false),
      );
      await tester.tap(find.byKey(DockKeys.tab('home')));
      expect(reselected, [0]);
    });
  });

  group('DockTabStack', () {
    Widget stack(int index, List<int> builds) => DockTabStack(
      index: index,
      children: [
        for (var i = 0; i < 2; i++)
          Builder(
            builder: (context) {
              builds.add(i);
              return Material(child: TextField(key: ValueKey('field $i')));
            },
          ),
      ],
    );

    testWidgets('builds tabs when first shown and keeps their state', (
      tester,
    ) async {
      final builds = <int>[];
      await tester.pumpWidget(MaterialApp(home: stack(0, builds)));
      expect(builds, [0]);
      await tester.enterText(find.byKey(const ValueKey('field 0')), 'kept');

      await tester.pumpWidget(MaterialApp(home: stack(1, builds)));
      expect(builds, contains(1));
      expect(find.byKey(const ValueKey('field 0')), findsNothing);
      expect(
        find.byKey(const ValueKey('field 0'), skipOffstage: false),
        findsOneWidget,
      );

      await tester.pumpWidget(MaterialApp(home: stack(0, builds)));
      expect(find.text('kept'), findsOneWidget);
    });

    testWidgets('inactive tabs neither tick nor take focus', (tester) async {
      final nodes = [FocusNode(), FocusNode()];
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: DockTabStack(
            index: 0,
            lazy: false,
            children: [
              for (var i = 0; i < 2; i++)
                Focus(
                  key: ValueKey('tab $i'),
                  focusNode: nodes[i],
                  child: const SizedBox(),
                ),
            ],
          ),
        ),
      );
      BuildContext tab(int i) =>
          tester.element(find.byKey(ValueKey('tab $i'), skipOffstage: false));
      // ignore: deprecated_member_use
      expect(TickerMode.of(tab(0)), isTrue);
      // ignore: deprecated_member_use
      expect(TickerMode.of(tab(1)), isFalse);
      expect(nodes[0].canRequestFocus, isTrue);
      expect(nodes[1].canRequestFocus, isFalse);
    });
  });

  group('the rail', () {
    final many = [
      for (var i = 0; i < 9; i++)
        DockTab<Object?>(id: i, icon: const DockIcon(Icons.star), label: '$i'),
    ];

    testWidgets('scrolls when the tabs do not fit, without overflow', (
      tester,
    ) async {
      await pump(
        tester,
        shell(tabs: many),
        mode: DockLayoutMode.wide,
        size: const Size(800, 300),
      );
      expect(tester.takeException(), isNull);
      final column = tester.getRect(find.byKey(DockKeys.column));
      expect(
        tester.getRect(find.byKey(DockKeys.tab(0))).top,
        greaterThanOrEqualTo(column.top),
      );
    });

    testWidgets('keeps the selected tab visible', (tester) async {
      await pump(
        tester,
        shell(tabs: many, initial: 8),
        mode: DockLayoutMode.wide,
        size: const Size(800, 300),
      );
      final column = tester.getRect(find.byKey(DockKeys.column));
      final last = tester.getRect(find.byKey(DockKeys.tab(8)));
      expect(last.bottom, lessThanOrEqualTo(column.bottom));
      expect(last.top, greaterThanOrEqualTo(column.top));
    });
  });

  testWidgets('the column grows with the text scale, up to a limit', (
    tester,
  ) async {
    double width() => tester.getSize(find.byKey(DockKeys.column)).width;
    await pump(tester, shell(), mode: DockLayoutMode.wide, textScale: 1.25);
    expect(width(), 72 * 1.25);
    await pump(tester, shell(), mode: DockLayoutMode.wide, textScale: 3);
    expect(width(), 72 * 1.5);
  });

  group('models', () {
    test('DockTab has value equality and a resettable copyWith', () {
      const tab = DockTab<int>(
        id: 'a',
        icon: DockIcon(Icons.home),
        label: 'A',
        badge: DockBadge.dot(),
        payload: 1,
      );
      expect(tab, tab.copyWith());
      expect(tab.copyWith(label: 'B'), isNot(tab));
      expect(tab.copyWith(badge: null).badge, isNull);
      expect(tab.copyWith(payload: null).payload, isNull);
      expect(tab.iconFor(selected: true), const DockIcon(Icons.home));
    });

    test('DockIcon identity', () {
      expect(const DockIcon(Icons.home).identity, Icons.home);
      expect(
        const DockIcon.widget(SizedBox(key: ValueKey('k'))).identity,
        const ValueKey('k'),
      );
      expect(const DockIcon.widget(SizedBox(), identity: 'x').identity, 'x');
      expect(const DockIcon(Icons.home), isNot(const DockIcon(Icons.star)));
    });

    test('DockBadge', () {
      expect(const DockBadge.count(3).label, '3');
      expect(const DockBadge.text('new').label, 'new');
      expect(const DockBadge.dot().label, isNull);
      expect(const DockBadge.dot().isDot, isTrue);
    });
  });
}
