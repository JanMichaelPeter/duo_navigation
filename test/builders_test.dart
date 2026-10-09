import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = [
  DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

Widget _shell({
  DuoBuilders<Object?, Object?, Object?>? builders,
  Widget child = const SizedBox(),
}) => DuoShell<Object?, Object?, Object?>(
  tabs: _tabs,
  currentIndex: 0,
  onTabSelected: (_) {},
  builders: builders,
  child: child,
);

/// A page with one 'share' icon action.
Widget _page() => Navigator(
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => DuoPage<Object?, Object?>(
      title: const Text('Page'),
      trailing: [
        DuoAction<Object?>(
          id: 'share',
          icon: const DuoIcon(Icons.share),
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
    DuoBuilders<Object?, Object?, Object?>? builders =
        const DuoMaterialBuilders(),
    DuoLayoutMode mode = DuoLayoutMode.compact,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            DuoTestHarness(builders: builders, mode: mode, child: child!),
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
          contains('No DuoBuilders.tabBar found.'),
          contains('DuoMaterialBuilders'),
        ),
      ),
    );
  });

  testWidgets('reading the layout needs no builders', (tester) async {
    late DuoLayoutMode mode;
    await pump(
      tester,
      Builder(
        builder: (context) {
          mode = DuoNavigation.modeOf(context);
          return const SizedBox();
        },
      ),
      builders: null,
    );
    expect(mode, DuoLayoutMode.compact);
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
              builders: DuoBuilders<Object?, Object?, Object?>(
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
        builders: DuoBuilders<Object?, Object?, Object?>(
          action: (context, action, placement) => Text('chip ${action.id}'),
        ),
        child: _page(),
      ),
      mode: DuoLayoutMode.wide,
    );
    expect(find.text('chip share'), findsOneWidget);
    // The rail still comes from the app's Material builders.
    expect(
      find.descendant(
        of: find.byKey(DuoKeys.rail),
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
          builders: DuoBuilders<Object?, Object?, Object?>(
            tabBar: (context, tabs, items) => Text(
              context.dependOnInheritedWidgetOfExactType<_Marker>()!.label,
            ),
          ),
        ),
      ),
    );
    expect(find.text('from around the shell'), findsOneWidget);
  });

  testWidgets('a DuoBuildersScope overrides a subtree', (tester) async {
    await pump(
      tester,
      _shell(
        child: DuoBuildersScope(
          builders: DuoBuilders<Object?, Object?, Object?>(
            page: (context, bar, body) => const Text('custom page'),
          ),
          child: _page(),
        ),
      ),
    );
    expect(find.text('custom page'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  group('DuoBuilders', () {
    Widget bar(
      BuildContext context,
      DuoTabsData<Object?> data,
      List<Widget> items,
    ) => const SizedBox();

    test('merge: the other side wins where it is set', () {
      const material = DuoMaterialBuilders<Object?, Object?, Object?>();
      final merged = material.merge(
        DuoBuilders<Object?, Object?, Object?>(tabBar: bar),
      );
      expect(merged.tabBar, bar);
      expect(merged.rail, material.rail);
      expect(merged.page, material.page);
      expect(material.merge(null), same(material));
      expect(
        material.merge(const DuoBuilders<Object?, Object?, Object?>()),
        material,
      );
    });

    test('has value equality', () {
      expect(
        DuoBuilders<Object?, Object?, Object?>(tabBar: bar),
        DuoBuilders<Object?, Object?, Object?>(tabBar: bar),
      );
      expect(
        DuoBuilders<Object?, Object?, Object?>(tabBar: bar),
        isNot(const DuoBuilders<Object?, Object?, Object?>()),
      );
      expect(
        const DuoMaterialBuilders<Object?, Object?, Object?>(),
        const DuoBuilders<Object?, Object?, Object?>(
          tabItem: DuoMaterial.tabItem,
          tabBar: DuoMaterial.tabBar,
          rail: DuoMaterial.rail,
          action: DuoMaterial.action,
          page: DuoMaterial.page,
          sideColumn: DuoMaterial.sideColumn,
          actionTransition: DuoMaterial.actionTransition,
          backdrop: DuoMaterial.backdrop,
          tabPosition: DuoMaterial.tabPosition,
          actionLabel: DuoMaterial.actionLabel,
        ),
      );
    });
  });
}
