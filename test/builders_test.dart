import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock/testing.dart';

const _tabs = [
  DockTab<Object?>(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab<Object?>(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

Widget _shell({
  DockBuilders<Object?>? builders,
  Widget child = const SizedBox(),
}) => DockShell(
  tabs: _tabs,
  currentIndex: 0,
  onTabSelected: (_) {},
  builders: builders,
  child: child,
);

/// A page with one 'share' icon action.
Widget _page() => Navigator(
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => DockPage(
      title: const Text('Page'),
      trailing: [
        DockAction(
          id: 'share',
          icon: const Icon(Icons.share),
          onPressed: () {},
        ),
      ],
      body: const SizedBox.expand(),
    ),
  ),
);

/// Something placed around a shell that its builders can read.
class _Marker extends InheritedWidget {
  const _Marker({required this.label, required super.child});

  final String label;

  @override
  bool updateShouldNotify(_Marker oldWidget) => label != oldWidget.label;
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DockBuilders<Object?>? builders = const DockMaterialBuilders(),
    DockLayoutMode mode = DockLayoutMode.compact,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            DockTestHarness(builders: builders, mode: mode, child: child!),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a missing builder fails loudly with the fix', (tester) async {
    await pump(tester, _shell(), builders: null);
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (e) => e.toStringDeep(),
        'message',
        allOf(
          contains('No DockBuilders.tabBar found.'),
          contains('DockMaterialBuilders'),
        ),
      ),
    );
  });

  testWidgets('reading the layout needs no builders', (tester) async {
    late DockLayoutMode mode;
    await pump(
      tester,
      Builder(
        builder: (context) {
          mode = DockNavigation.modeOf(context);
          return const SizedBox();
        },
      ),
      builders: null,
    );
    expect(mode, DockLayoutMode.compact);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an override on one shell leaves other shells unchanged', (
    tester,
  ) async {
    await pump(
      tester,
      Row(
        children: [
          Expanded(
            child: _shell(
              builders: DockBuilders(
                tabBar: (context, tabs, items) => const Text('custom bar'),
              ),
            ),
          ),
          Expanded(child: _shell()),
        ],
      ),
    );
    expect(find.text('custom bar'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('fields a shell does not set fall back to the app', (
    tester,
  ) async {
    await pump(
      tester,
      _shell(
        builders: DockBuilders(
          action: (context, action, placement) => Text('chip ${action.id}'),
        ),
        child: _page(),
      ),
      mode: DockLayoutMode.wide,
    );
    expect(find.text('chip share'), findsOneWidget);
    // The rail still comes from the app's Material builders.
    expect(
      find.descendant(
        of: find.byKey(DockKeys.rail),
        matching: find.byType(IconButton),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('builders are called below the shell', (tester) async {
    await pump(
      tester,
      _Marker(
        label: 'from around the shell',
        child: _shell(
          builders: DockBuilders(
            tabBar: (context, tabs, items) => Text(
              context.dependOnInheritedWidgetOfExactType<_Marker>()!.label,
            ),
          ),
        ),
      ),
    );
    expect(find.text('from around the shell'), findsOneWidget);
  });

  testWidgets('a DockBuildersScope overrides a subtree', (tester) async {
    await pump(
      tester,
      _shell(
        child: DockBuildersScope(
          builders: DockBuilders(
            page: (context, bar, body) => const Text('custom page'),
          ),
          child: _page(),
        ),
      ),
    );
    expect(find.text('custom page'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  group('DockBuilders', () {
    Widget bar(
      BuildContext context,
      DockTabsData<Object?> data,
      List<Widget> items,
    ) => const SizedBox();

    test('merge: the other side wins where it is set', () {
      const material = DockMaterialBuilders<Object?>();
      final merged = material.merge(DockBuilders(tabBar: bar));
      expect(merged.tabBar, bar);
      expect(merged.rail, material.rail);
      expect(merged.page, material.page);
      expect(material.merge(null), same(material));
      expect(material.merge(const DockBuilders<Object?>()), material);
    });

    test('has value equality', () {
      expect(DockBuilders(tabBar: bar), DockBuilders(tabBar: bar));
      expect(DockBuilders(tabBar: bar), isNot(const DockBuilders<Object?>()));
      expect(
        const DockMaterialBuilders<Object?>(),
        const DockBuilders<Object?>(
          tabItem: DockMaterial.tabItem,
          tabBar: DockMaterial.tabBar,
          rail: DockMaterial.rail,
          action: DockMaterial.action,
          page: DockMaterial.page,
          sideColumn: DockMaterial.sideColumn,
          actionTransition: DockMaterial.actionTransition,
        ),
      );
    });
  });
}
