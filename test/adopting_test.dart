import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

/// The recipes of doc/adopting.md, as they are written there.

const _tabs = <DockTab<Object?>>[
  DockTab(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab(id: 'me', icon: DockIcon(Icons.person), label: 'Me'),
];

class _TitleSpec {
  const _TitleSpec(this.text);
  final String text;
}

/// The guide's design-system title bar.
class _NavBar extends StatelessWidget implements PreferredSizeWidget {
  const _NavBar();

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final bar = DockBarData.of<Object?, Object?>(context);
    final title = bar.payload;
    assert(title == null || title is _TitleSpec, 'Needs a _TitleSpec.');
    final leading = bar.leading;
    return SafeArea(
      bottom: false,
      child: DockBarLayout(
        leading: leading == null
            ? null
            : bar.buildAction(leading, DockActionPlacement.barLeading),
        title: title is _TitleSpec ? Text('spec ${title.text}') : bar.title,
        trailing: [
          for (final a in bar.trailing)
            bar.buildAction(a, DockActionPlacement.barTrailing),
        ],
        actionsAtStart: bar.trailingAtStart,
        leadingAtEnd: bar.leadingAtEnd,
      ),
    );
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    DockLayoutMode mode = DockLayoutMode.wide,
    DockBuilders<Object?, Object?, Object?>? builders,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(
      top: padding.top,
      bottom: padding.bottom,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DockTestHarness(
          builders: const DockMaterialBuilders<Object?, Object?, Object?>()
              .merge(builders),
          mode: mode,
          child: child!,
        ),
        home: DockShell<Object?, Object?, Object?>(
          tabs: _tabs,
          currentIndex: 0,
          onTabSelected: (_) {},
          child: DockTabStack(
            index: 0,
            children: [
              DockTabNavigator(
                onGenerateRoute: (_) =>
                    MaterialPageRoute<void>(builder: (_) => page),
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rect(WidgetTester tester, String key) =>
      tester.getRect(find.byKey(Key(key)));

  testWidgets('a bleed in a DockTabNavigator reaches under the column', (
    tester,
  ) async {
    await pump(
      tester,
      const DockBleed(
        child: ColoredBox(key: Key('map'), color: Colors.green),
      ),
    );
    expect(rect(tester, 'map').right, 1000);
  });

  testWidgets('a header background bleeds, its actions stay beside the '
      'column', (tester) async {
    var taps = 0;
    await pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DockBleed(
                    bar: false,
                    child: ColoredBox(
                      key: Key('background'),
                      color: Colors.blue,
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    key: const Key('settings'),
                    icon: const Icon(Icons.settings),
                    onPressed: () => taps++,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
    expect(rect(tester, 'background').right, 1000);
    expect(rect(tester, 'settings').right, lessThanOrEqualTo(1000 - 72));
    await tester.tap(find.byKey(const Key('settings')));
    expect(taps, 1);
  });

  testWidgets('wrapAll: DockBleedItem rows bleed, wrapped ones do not', (
    tester,
  ) async {
    await pump(
      tester,
      DockBleed(
        child: ListView(
          children: DockInset.wrapAll([
            const DockBleedItem(child: SizedBox(key: Key('hero'), height: 50)),
            const SizedBox(key: Key('row'), height: 50),
            // Not the list entry itself: wrapAll can't see it.
            const Padding(
              padding: EdgeInsets.zero,
              child: DockBleedItem(
                child: SizedBox(key: Key('hidden'), height: 50),
              ),
            ),
          ]),
        ),
      ),
    );
    expect(rect(tester, 'hero').right, 1000);
    expect(rect(tester, 'row').right, 1000 - 72);
    expect(rect(tester, 'hidden').right, 1000 - 72);
  });

  testWidgets('tab items that pad the inset themselves reach the screen edge', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      const SizedBox.expand(),
      mode: DockLayoutMode.compact,
      padding: const EdgeInsets.only(bottom: 34),
      builders: DockBuilders<Object?, Object?, Object?>(
        tabBar: (context, tabs, items) => Material(
          child: DockTabBarSemantics(
            child: Row(
              children: [for (final item in items) Expanded(child: item)],
            ),
          ),
        ),
        tabItem: (context, item) => InkWell(
          onTap: () {
            taps++;
            item.onTap();
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(height: 56, child: Text(item.tab.label!)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull); // the bar covers the safe area
    expect(tester.getRect(find.byKey(DockKeys.bar)).height, 56 + 34);
    await tester.tapAt(const Offset(100, 700 - 2)); // the last pixels
    expect(taps, 1);
  });

  testWidgets('a design system title bar reads the bar data of any page', (
    tester,
  ) async {
    await pump(
      tester,
      DockPageScope<Object?, _TitleSpec>(
        barPayload: const _TitleSpec('Details'),
        trailing: [
          DockAction<Object?>(id: 'edit', label: 'Edit', onPressed: () {}),
        ],
        child: const Scaffold(appBar: _NavBar(), body: SizedBox.expand()),
      ),
      mode: DockLayoutMode.compact,
      padding: const EdgeInsets.only(top: 40),
    );
    expect(find.text('spec Details'), findsOneWidget);
    expect(find.byKey(DockKeys.action('edit')), findsOneWidget);
    // Below the status bar.
    expect(tester.getRect(find.text('spec Details')).top, greaterThan(40));
  });
}
