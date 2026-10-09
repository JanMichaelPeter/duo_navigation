import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = <DuoTab<Object?>>[
  DuoTab(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

const _field = Key('field');

void main() {
  late ValueNotifier<double> keyboard;
  setUp(() => keyboard = ValueNotifier(0));
  tearDown(() => keyboard.dispose());

  /// A shell whose page has a 'save' action and a text field, with the
  /// keyboard height from [keyboard] reported above the app.
  Future<void> pump(
    WidgetTester tester, {
    DuoLayoutMode mode = DuoLayoutMode.wide,
    DuoKeyboard behavior = const DuoKeyboard(),
    Size size = const Size(800, 600),
    bool resizingScaffold = false,
    DuoBodyMode bodyMode = DuoBodyMode.inset,
    int actions = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget shell = DuoShell<Object?, Object?, Object?>(
      tabs: _tabs,
      currentIndex: 0,
      onTabSelected: (_) {},
      bodyMode: bodyMode,
      child: Navigator(
        onGenerateInitialRoutes: (_, _) => [
          MaterialPageRoute<void>(builder: (_) => const SizedBox()),
          MaterialPageRoute<void>(
            builder: (_) => DuoPage<Object?, Object?>(
              title: const Text('Profile'),
              trailing: [
                for (var i = 0; i < actions; i++)
                  DuoAction<Object?>(
                    id: i == 0 ? 'save' : 'a$i',
                    icon: const DuoIcon(Icons.check),
                    onPressed: () {},
                  ),
              ],
              body: const Align(
                alignment: Alignment.bottomCenter,
                child: TextField(key: _field),
              ),
            ),
          ),
        ],
      ),
    );
    if (resizingScaffold) {
      shell = Scaffold(resizeToAvoidBottomInset: true, body: shell);
    }
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ValueListenableBuilder(
          valueListenable: keyboard,
          builder: (context, height, _) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: EdgeInsets.only(bottom: height)),
            child: DuoTestHarness(
              builders: const DuoMaterialBuilders(),
              mode: mode,
              data: DuoNavigationData(keyboard: behavior),
              child: child!,
            ),
          ),
        ),
        home: shell,
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));
  Rect rail(WidgetTester tester) => rect(tester, DuoKeys.rail);
  Rect chip(WidgetTester tester) => rect(tester, DuoKeys.action('save'));

  group('the column', () {
    testWidgets('lifts above the keyboard, and is unchanged without one', (
      tester,
    ) async {
      await pump(tester);
      final railBefore = rail(tester);
      final chipBefore = chip(tester);

      keyboard.value = 250;
      await tester.pumpAndSettle();
      expect(rail(tester).bottom, lessThanOrEqualTo(600 - 250));
      expect(chip(tester).bottom, lessThanOrEqualTo(rail(tester).top));

      keyboard.value = 0;
      await tester.pumpAndSettle();
      expect(rail(tester), railBefore);
      expect(chip(tester), chipBefore);
    });

    testWidgets('moves once when an ancestor Scaffold already made room', (
      tester,
    ) async {
      await pump(tester);
      keyboard.value = 250;
      await tester.pumpAndSettle();
      final lifted = rail(tester);

      keyboard.value = 0;
      await pump(tester, resizingScaffold: true);
      keyboard.value = 250;
      await tester.pumpAndSettle();
      expect(rail(tester), lifted);
    });

    testWidgets('ignore: stays where it is, under the keyboard', (
      tester,
    ) async {
      await pump(
        tester,
        behavior: const DuoKeyboard(column: DuoKeyboardBehavior.ignore),
      );
      final before = rail(tester);
      keyboard.value = 250;
      await tester.pumpAndSettle();
      expect(rail(tester), before);
      expect(rail(tester).bottom, greaterThan(600 - 250));
    });

    testWidgets('hide: hides while the keyboard is open', (tester) async {
      await pump(
        tester,
        behavior: const DuoKeyboard(column: DuoKeyboardBehavior.hide),
      );
      keyboard.value = 250;
      await tester.pumpAndSettle();
      final geometry = DuoGeometry.of(tester.element(find.byKey(_field)));
      expect(geometry.isHidden, isTrue);
      keyboard.value = 0;
      await tester.pumpAndSettle();
      expect(
        DuoGeometry.of(tester.element(find.byKey(_field))).isHidden,
        isFalse,
      );
    });

    testWidgets('a small space above the keyboard does not overflow', (
      tester,
    ) async {
      await pump(tester, size: const Size(800, 400), actions: 6);
      keyboard.value = 250; // 150 left above it
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final column = rect(tester, DuoKeys.column);
      expect(column.height, 150);
      // The rail keeps its place at the bottom of the column.
      expect(rail(tester).bottom, lessThanOrEqualTo(column.bottom));
      expect(rail(tester).top, greaterThanOrEqualTo(column.top));
    });

    testWidgets('follows the keyboard as it animates, keeping the body '
        'State', (tester) async {
      await pump(tester);
      await tester.enterText(find.byKey(_field), 'kept');
      final state = tester.state(find.byKey(_field));
      final bottoms = <double>[];
      for (final height in [50.0, 125.0, 200.0, 250.0]) {
        keyboard.value = height;
        await tester.pump();
        bottoms.add(rail(tester).bottom);
      }
      for (var i = 1; i < bottoms.length; i++) {
        expect(bottoms[i], lessThan(bottoms[i - 1]));
      }
      expect(tester.state(find.byKey(_field)), same(state));
      expect(find.text('kept'), findsOneWidget);
    });
  });

  group('the bar', () {
    const phone = Size(400, 800);
    Rect bar(WidgetTester tester) => rect(tester, DuoKeys.bar);

    testWidgets('ignore (default): covered, the body ends at the keyboard', (
      tester,
    ) async {
      await pump(tester, mode: DuoLayoutMode.compact, size: phone);
      final before = bar(tester);
      keyboard.value = 300;
      await tester.pumpAndSettle();
      expect(bar(tester), before);
      expect(rect(tester, _field).bottom, lessThanOrEqualTo(800 - 300));
    });

    testWidgets('lift: sits on the keyboard, the body ends above it', (
      tester,
    ) async {
      await pump(
        tester,
        mode: DuoLayoutMode.compact,
        size: phone,
        behavior: const DuoKeyboard(bar: DuoKeyboardBehavior.lift),
      );
      keyboard.value = 300;
      await tester.pumpAndSettle();
      expect(bar(tester).bottom, 800 - 300);
      expect(rect(tester, _field).bottom, lessThanOrEqualTo(bar(tester).top));
    });

    testWidgets('hide: hidden while the keyboard is open', (tester) async {
      await pump(
        tester,
        mode: DuoLayoutMode.compact,
        size: phone,
        behavior: const DuoKeyboard(bar: DuoKeyboardBehavior.hide),
      );
      keyboard.value = 300;
      await tester.pumpAndSettle();
      expect(
        DuoGeometry.of(tester.element(find.byKey(_field))).isHidden,
        isTrue,
      );
      expect(rect(tester, _field).bottom, 800 - 300);
    });
  });

  group('the body', () {
    const body = Key('body');

    /// A shell whose page is a Scaffold with [resize] as its
    /// resizeToAvoidBottomInset, and a 300 px keyboard.
    Future<Rect> pageBody(
      WidgetTester tester, {
      required Size size,
      required bool resize,
      DuoKeyboard? app,
      DuoKeyboard? shell,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DuoTestHarness(
            builders: const DuoMaterialBuilders<Object?, Object?, Object?>(),
            data: DuoNavigationData(keyboard: app ?? const DuoKeyboard()),
            child: child!,
          ),
          home: DuoShell<Object?, Object?, Object?>(
            tabs: _tabs,
            currentIndex: 0,
            onTabSelected: (_) {},
            keyboard: shell,
            child: Scaffold(
              resizeToAvoidBottomInset: resize,
              body: const SizedBox.expand(key: body),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byKey(body));
    }

    const lift = DuoKeyboard(body: DuoBodyKeyboardBehavior.lift);

    for (final size in const [Size(400, 800), Size(800, 600)]) {
      final compact = size.width < 600;
      final name = compact ? 'compact' : 'wide';

      testWidgets('$name, passThrough (default): a page that opts out keeps '
          'its height', (tester) async {
        final rect = await pageBody(tester, size: size, resize: false);
        final bottom = compact
            ? tester.getRect(find.byKey(DuoKeys.bar)).top
            : size.height;
        expect(rect.bottom, bottom);
      });

      testWidgets('$name, passThrough (default): a resizing page ends at the '
          'keyboard, without counting the bar twice', (tester) async {
        final rect = await pageBody(tester, size: size, resize: true);
        expect(rect.bottom, size.height - 300);
      });

      testWidgets('$name, lift: the frame lifts every page', (tester) async {
        final rect = await pageBody(
          tester,
          size: size,
          resize: false,
          app: lift,
        );
        expect(rect.bottom, size.height - 300);
      });
    }

    testWidgets('a shell can override the app\'s behavior', (tester) async {
      final rect = await pageBody(
        tester,
        size: const Size(800, 600),
        resize: false,
        shell: lift,
      );
      expect(rect.bottom, 600 - 300);
    });
  });

  testWidgets('a page Scaffold in the inset body does not shrink twice', (
    tester,
  ) async {
    await pump(tester, mode: DuoLayoutMode.compact, size: const Size(400, 800));
    keyboard.value = 300;
    await tester.pumpAndSettle();
    // The field sits at the bottom of the page Scaffold's body, which ends
    // where the frame's body ends: right above the keyboard.
    expect(rect(tester, _field).bottom, 800 - 300);
  });

  testWidgets('overlay mode leaves the keyboard to the page', (tester) async {
    await pump(
      tester,
      mode: DuoLayoutMode.compact,
      size: const Size(400, 800),
      bodyMode: DuoBodyMode.overlay,
    );
    keyboard.value = 300;
    await tester.pumpAndSettle();
    final geometry = DuoGeometry.of(tester.element(find.byKey(_field)));
    expect(geometry.keyboard, 0);
    // The page's Scaffold sees the keyboard and makes room itself.
    expect(
      MediaQuery.viewInsetsOf(tester.element(find.byType(Scaffold))).bottom,
      300,
    );
    expect(rect(tester, _field).bottom, 800 - 300);
  });
}
