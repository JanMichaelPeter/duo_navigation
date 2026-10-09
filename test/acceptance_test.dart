import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

/// Acceptance checks of the 0.1.0 redesign that no other test covers as a
/// whole: plain Scaffold pages across every layout, state across a mode
/// switch, and the focused field above the keyboard.

const _tabs = <DuoTab<Object?>>[
  DuoTab(id: 'a', icon: DuoIcon(Icons.home), label: 'A'),
  DuoTab(id: 'b', icon: DuoIcon(Icons.person), label: 'B'),
];

const _phone = Size(400, 800);
const _tablet = Size(1000, 700);

/// A plain Scaffold page with no duo_navigation type: a list and a button below it.
class _PlainPage extends StatelessWidget {
  const _PlainPage(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            key: PageStorageKey<String>('list $name'),
            children: [
              for (var i = 0; i < 40; i++) ListTile(title: Text('$name $i')),
            ],
          ),
        ),
        ElevatedButton(
          key: Key('button $name'),
          onPressed: () {},
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// A shell with a navigator per tab, sized by the test's window; the layout
/// follows the window (no pinned mode), as on a device.
class _App extends StatefulWidget {
  const _App({this.side = DuoSide.end, this.direction = TextDirection.ltr});

  final DuoSide side;
  final TextDirection direction;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  int index = 0;
  final navigators = [GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>()];

  @override
  Widget build(BuildContext context) => MaterialApp(
    builder: (context, child) => DuoTestHarness(
      builders: const DuoMaterialBuilders<Object?, Object?, Object?>(),
      side: widget.side,
      textDirection: widget.direction,
      child: child!,
    ),
    home: DuoShell<Object?, Object?, Object?>(
      tabs: _tabs,
      currentIndex: index,
      onTabSelected: (i) => setState(() => index = i),
      child: DuoTabStack(
        index: index,
        children: [
          for (var i = 0; i < 2; i++)
            DuoTabNavigator(
              navigatorKey: navigators[i],
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => _PlainPage('tab $i')),
            ),
        ],
      ),
    ),
  );
}

void main() {
  Future<void> setWindow(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
  }

  group('a plain Scaffold page lays out clear of the chrome', () {
    for (final size in [_phone, _tablet]) {
      for (final side in DuoSide.values) {
        for (final direction in TextDirection.values) {
          final name =
              '${size == _phone ? 'compact' : 'wide'}, ${side.name}, '
              '${direction.name}';
          testWidgets(name, (tester) async {
            addTearDown(tester.view.reset);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(_App(side: side, direction: direction));
            await tester.pumpAndSettle();

            final button = tester.getRect(
              find.byKey(const Key('button tab 0')),
            );
            final appBar = tester.getRect(find.byType(AppBar));
            final Rect chrome = size == _phone
                ? tester.getRect(find.byKey(DuoKeys.bar))
                : tester.getRect(find.byKey(DuoKeys.column));
            expect(button.overlaps(chrome), isFalse);
            expect(appBar.overlaps(chrome), isFalse);
            // The button sits right at the free area's bottom edge.
            final bottom = size == _phone ? chrome.top : size.height;
            expect(button.bottom, bottom);
          });
        }
      }
    }
  });

  testWidgets('a mode switch keeps the tab, the route, the scroll position, '
      'text and focus', (tester) async {
    addTearDown(tester.view.reset);
    await setWindow(tester, _phone);
    await tester.pumpWidget(const _App());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DuoKeys.tab('b')));
    await tester.pumpAndSettle();
    final app = tester.state<_AppState>(find.byType(_App));
    app.navigators[1].currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('details')),
          // The field sits above the list: a focused field in a list
          // scrolls itself back into view, which would hide the scroll.
          body: Column(
            children: [
              const TextField(key: Key('field')),
              Expanded(
                child: ListView(
                  key: const PageStorageKey<String>('details list'),
                  children: [
                    for (var i = 0; i < 40; i++)
                      ListTile(title: Text('row $i')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field')), 'kept');
    await tester.drag(find.text('row 3'), const Offset(0, -200));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const PageStorageKey<String>('details list')),
        matching: find.byType(Scrollable),
      ),
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0));
    final field = find.byKey(const Key('field'));
    final focus = tester
        .widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        )
        .focusNode;
    expect(focus.hasFocus, isTrue);

    await setWindow(tester, _tablet); // unfold
    expect(find.byKey(DuoKeys.column), findsOneWidget);
    expect(app.index, 1);
    expect(find.text('details'), findsOneWidget);
    expect(scrollable.mounted, isTrue);
    expect(scrollable.position.pixels, offset);
    expect(find.text('kept'), findsOneWidget);
    expect(focus.hasFocus, isTrue);

    await setWindow(tester, _phone); // fold again
    expect(find.byKey(DuoKeys.bar), findsOneWidget);
    expect(find.text('details'), findsOneWidget);
    expect(scrollable.position.pixels, offset);
    expect(focus.hasFocus, isTrue);
  });

  for (final size in [_phone, _tablet]) {
    testWidgets('${size == _phone ? 'compact' : 'wide'}: the focused field '
        'stays visible above the keyboard', (tester) async {
      addTearDown(tester.view.reset);
      await setWindow(tester, size);
      await tester.pumpWidget(const _App());
      await tester.pumpAndSettle();
      final app = tester.state<_AppState>(find.byType(_App));
      app.navigators[0].currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('form')),
            body: ListView(
              key: const Key('form list'),
              children: [
                const SizedBox(height: 1200),
                const TextField(key: Key('low field')),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('low field')),
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('form list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const Key('low field')));
      await tester.pumpAndSettle();

      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byKey(const Key('low field')));
      expect(field.bottom, lessThanOrEqualTo(size.height - keyboard));
      expect(field.top, greaterThanOrEqualTo(0));
    });
  }
}
