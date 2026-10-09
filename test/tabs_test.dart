import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

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
    DockBuilders<Object?, Object?, Object?>? builders =
        const DockMaterialBuilders(),
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
      builder: (context, setState) => DockShell<Object?, Object?, Object?>(
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
        DockShell<_Item, Object?, Object?>(
          tabs: _typedTabs(),
          currentIndex: 0,
          onTabSelected: (_) {},
          builders: DockBuilders<_Item, Object?, Object?>(
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
        DockShell<_Item, Object?, Object?>(
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
        () => const DockMaterialBuilders<Object?, Object?, Object?>().merge(
          DockBuilders<_Other, Object?, Object?>(
            tabItem: (context, data) => const SizedBox(),
          ),
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
        DockShell<_Item, Object?, Object?>(
          tabs: _typedTabs(),
          currentIndex: 0,
          onTabSelected: (_) {},
          child: const SizedBox(),
        ),
        builders: DockBuilders<_Other, Object?, Object?>(
          tabItem: (context, data) => const SizedBox(),
          tabBar: (context, data, items) => Row(children: items),
        ),
      );
      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (e) => e.toStringDeep(),
          'message',
          contains('DockTab<_Item>'),
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
          // containsSemantics: deprecated after 3.40, but 3.38 lacks isSemantics.
          // ignore: deprecated_member_use
          containsSemantics(
            label: 'Me',
            value: '3',
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.byKey(DockKeys.tab('home'))),
          // containsSemantics: deprecated after 3.40, but 3.38 lacks isSemantics.
          // ignore: deprecated_member_use
          containsSemantics(
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

  group('a bar built from data', () {
    // Builds its own children from the tabs' payloads, as a design system's
    // bar that takes a list of item descriptions does. No tabItem builder.
    final builders = DockBuilders<Object?, Object?, Object?>(
      tabBar: (context, data, items) => DockTabBarSemantics(
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var i = 0; i < data.tabs.length; i++)
                  Expanded(
                    child: data.wrap(
                      i,
                      GestureDetector(
                        onTap: data.itemData(i).onTap,
                        child: Text((data.tabs[i].payload! as _Item).name),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('gets the same keys and semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, shell(initial: 1), builders: builders);
      expect(
        find.descendant(
          of: find.byKey(DockKeys.tab('me')),
          matching: find.byKey(const Key('app-me')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('app-me')),
          matching: find.text('me item'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.byKey(const Key('app-me'))),
        // containsSemantics: deprecated after 3.40, but 3.38 lacks isSemantics.
        // ignore: deprecated_member_use
        containsSemantics(
          label: 'Me',
          value: '3',
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(DockKeys.tab('home'))),
        // containsSemantics: deprecated after 3.40, but 3.38 lacks isSemantics.
        // ignore: deprecated_member_use
        containsSemantics(
          label: 'Home',
          isSelected: false,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('taps, re-taps and vetoes follow the shell\'s rules', (
      tester,
    ) async {
      final selected = <int>[];
      final reselected = <int>[];
      var allow = false;
      await pump(
        tester,
        shell(
          onSelected: selected.add,
          onReselected: reselected.add,
          canSelect: (_) => allow,
        ),
        builders: builders,
      );
      await tester.tap(find.text('me item'));
      await tester.pumpAndSettle();
      expect(selected, isEmpty); // vetoed
      await tester.tap(find.text('home item'));
      expect(reselected, [0]);

      allow = true;
      await tester.tap(find.text('me item'));
      await tester.pumpAndSettle();
      expect(selected, [1]);
      expect(find.text('tab 1'), findsOneWidget);
    });

    test('itemData describes one tab', () {
      final data = DockTabsData<_Item>(
        tabs: _typedTabs(),
        currentIndex: 1,
        onSelected: (_) {},
        mode: DockLayoutMode.wide,
      );
      final item = data.itemData(1);
      expect(item.tab.id, 'me');
      expect(item.index, 1);
      expect(item.count, 2);
      expect(item.selected, isTrue);
      expect(item.placement, DockTabPlacement.rail);
      expect(() => data.itemData(2), throwsRangeError);
    });
  });

  group('a bar that builds its own item widgets', () {
    DockBuilders<Object?, Object?, Object?> builders({
      required bool withSemantics,
    }) {
      Widget bar(BuildContext context, DockTabsData<Object?> tabs, Axis axis) =>
          DockTabBarSemantics(
            child: _DsTabBar(
              axis: axis,
              items: [
                for (var i = 0; i < tabs.tabs.length; i++)
                  _DsItem(
                    (tabs.tabs[i].payload! as _Item).name,
                    tabs.itemData(i).onTap,
                    withSemantics
                        ? tabs.itemData(i).semanticsOf(context)
                        : null,
                  ),
              ],
            ),
          );
      return DockBuilders(
        tabBar: (context, tabs, items) =>
            SafeArea(child: bar(context, tabs, Axis.horizontal)),
        rail: (context, tabs, items) => bar(context, tabs, Axis.vertical),
      );
    }

    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: items with semanticsOf are tabs', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          shell(initial: 1),
          mode: mode,
          builders: const DockMaterialBuilders<Object?, Object?, Object?>()
              .merge(builders(withSemantics: true)),
        );
        expect(tester.takeException(), isNull);
        SemanticsNode item(String text) => tester.getSemantics(
          find
              .ancestor(of: find.text(text), matching: find.byType(Semantics))
              .first,
        );
        for (final (text, label, selected, hint) in const [
          ('me item', 'Me', true, 'Tab 2 of 2'),
          ('home item', 'Home', false, 'Tab 1 of 2'),
        ]) {
          final node = item(text);
          expect(node.getSemanticsData().role, SemanticsRole.tab);
          expect(node.getSemanticsData().hint, hint);
          expect(
            node,
            // containsSemantics: deprecated after 3.40, but 3.35 lacks isSemantics.
            // ignore: deprecated_member_use
            containsSemantics(
              label: label,
              isSelected: selected,
              hasSelectedState: true,
              hasTapAction: true,
            ),
          );
        }
        expect(item('me item').getSemanticsData().value, '3');
        handle.dispose();
      });
    }

    testWidgets('without them, DockTabBarSemantics reports its children', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        shell(),
        builders: const DockMaterialBuilders<Object?, Object?, Object?>().merge(
          builders(withSemantics: false),
        ),
      );
      expect(
        tester.takeException().toString(),
        contains('Children of TabBar must have the tab role'),
      );
      handle.dispose();
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

    for (final maintain in [false, true]) {
      testWidgets('maintainTickers: $maintain', (tester) async {
        final values = <double>[];
        await tester.pumpWidget(
          MaterialApp(
            home: DockTabStack(
              index: 0,
              lazy: false,
              maintainTickers: maintain,
              children: [const SizedBox(), _Spinner(values)],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        final moved = values.toSet().length > 1;
        expect(moved, maintain);
      });
    }

    testWidgets('with maintainTickers, only the shown tab\'s page claims the '
        'column', (tester) async {
      Widget page(String id) => DockPage<Object?, Object?>(
        trailing: [
          DockAction<Object?>(
            id: id,
            icon: const DockIcon(Icons.share),
            onPressed: () {},
          ),
        ],
        body: const SizedBox.expand(),
      );
      Finder inColumn(Object id) => find.descendant(
        of: find.byKey(DockKeys.column),
        matching: find.byKey(DockKeys.action(id)),
      );
      var index = 0;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => DockShell<Object?, Object?, Object?>(
            tabs: _typedTabs(),
            currentIndex: index,
            onTabSelected: (i) => setState(() => index = i),
            child: DockTabStack(
              index: index,
              lazy: false,
              maintainTickers: true,
              children: [page('first'), page('second')],
            ),
          ),
        ),
        mode: DockLayoutMode.wide,
      );
      expect(inColumn('first'), findsOneWidget);
      expect(inColumn('second'), findsNothing);

      await tester.tap(find.byKey(DockKeys.tab('me')));
      await tester.pumpAndSettle();
      expect(inColumn('first'), findsNothing);
      expect(inColumn('second'), findsOneWidget);
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

/// Records the value of an endless animation on every build.
class _Spinner extends StatefulWidget {
  const _Spinner(this.values);

  final List<double> values;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      widget.values.add(_controller.value);
      return const SizedBox();
    },
  );
}

/// A design system's item description: what its tab bar builds a tab from.
class _DsItem {
  const _DsItem(this.label, this.onTap, this.semantics);

  final String label;
  final VoidCallback onTap;

  /// The design system's per-item semantics hook.
  final SemanticsProperties? semantics;
}

/// A design system's tab bar: it takes item descriptions and builds the item
/// widgets itself, so nothing can be wrapped around them.
class _DsTabBar extends StatelessWidget {
  const _DsTabBar({required this.axis, required this.items});

  final Axis axis;
  final List<_DsItem> items;

  @override
  Widget build(BuildContext context) => Flex(
    direction: axis,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final item in items)
        Semantics.fromProperties(
          container: true,
          properties: item.semantics ?? const SemanticsProperties(),
          child: GestureDetector(
            onTap: item.onTap,
            child: SizedBox(
              width: 72,
              height: 56,
              child: ExcludeSemantics(child: Text(item.label)),
            ),
          ),
        ),
    ],
  );
}
