import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/testing.dart';

const _tabs = <DockTab<Object?>>[
  DockTab(id: 'home', icon: DockIcon(Icons.home), label: 'Home'),
  DockTab(
    id: 'me',
    icon: DockIcon(Icons.person),
    label: 'Me',
    badge: DockBadge.count(2),
  ),
];

Finder _action(Object id) => find.byKey(DockKeys.action(id));
Finder _tab(Object id) => find.byKey(DockKeys.tab(id));

/// Whether the focused widget is inside [finder].
bool _focusIn(WidgetTester tester, Finder finder) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final target = tester.element(finder);
  var inside = false;
  focused.visitAncestorElements((element) {
    if (element == target) inside = true;
    return !inside;
  });
  return inside || focused == target;
}

/// The labels of the semantics tree in traversal order.
List<String> _labelsInOrder(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  var root = tester.getSemantics(find.byType(MaterialApp));
  while (root.parent != null) {
    root = root.parent!;
  }
  visit(root);
  return labels;
}

void main() {
  /// A shell with a pushed page (implied back), a 'share' action, a disabled
  /// 'edit' action with a badge, and a button in the body.
  Future<void> pump(
    WidgetTester tester, {
    DockLayoutMode? mode = DockLayoutMode.wide,
    DockBuilders<Object?, Object?, Object?> builders =
        const DockMaterialBuilders(),
    TextDirection? direction,
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: DockTestHarness(
            builders: builders,
            mode: mode,
            textDirection: direction,
            child: child!,
          ),
        ),
        home: DockShell<Object?, Object?, Object?>(
          tabs: _tabs,
          currentIndex: 0,
          onTabSelected: (_) {},
          child: Navigator(
            onGenerateInitialRoutes: (_, _) => [
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
              MaterialPageRoute<void>(
                builder: (_) => DockPage<Object?, Object?>(
                  title: const Text('Details'),
                  trailing: [
                    DockAction<Object?>(
                      id: 'share',
                      icon: const DockIcon(Icons.share),
                      tooltip: 'Share',
                      onPressed: () {},
                    ),
                    DockAction<Object?>(
                      id: 'edit',
                      icon: const DockIcon(Icons.edit),
                      tooltip: 'Edit',
                      enabled: false,
                      badge: const DockBadge.count(5),
                      onPressed: () {},
                    ),
                  ],
                  body: Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Body button'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('semantics', () {
    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: actions are labeled buttons', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, mode: mode);
        expect(
          tester.getSemantics(_action('share')),
          // ignore: deprecated_member_use
          containsSemantics(
            label: 'Share',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(_action('edit')),
          // ignore: deprecated_member_use
          containsSemantics(
            label: 'Edit',
            value: '5',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        // The implied back action gets a localized label.
        expect(
          tester.getSemantics(_action(DockAction.backId)),
          // ignore: deprecated_member_use
          containsSemantics(label: 'Back', isButton: true, hasTapAction: true),
        );
        handle.dispose();
      });

      testWidgets('${mode.name}: tabs read their position', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, mode: mode);
        expect(
          tester.getSemantics(_tab('me')),
          // ignore: deprecated_member_use
          containsSemantics(label: 'Me', value: '2', hint: 'Tab 2 of 2'),
        );
        handle.dispose();
      });
    }

    testWidgets('custom builders that wrap the defaults keep the semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        builders: const DockMaterialBuilders<Object?, Object?, Object?>().merge(
          DockBuilders<Object?, Object?, Object?>(
            tabItem: (context, data) => Padding(
              padding: const EdgeInsets.all(2),
              child: DockMaterial.tabItem(context, data),
            ),
            action: (context, action, placement) => Padding(
              padding: const EdgeInsets.all(2),
              child: DockMaterial.action(context, action, placement),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(_tab('home')),
        // ignore: deprecated_member_use
        containsSemantics(label: 'Home', isSelected: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(_action('share')),
        // ignore: deprecated_member_use
        containsSemantics(label: 'Share', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('a builder that drops its tap action still gets one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        builders: const DockMaterialBuilders<Object?, Object?, Object?>().merge(
          DockBuilders<Object?, Object?, Object?>(
            // The classic mistake: excluding semantics loses the tap action.
            action: (context, action, placement) => Semantics(
              excludeSemantics: true,
              label: 'broken',
              child: Material(
                type: MaterialType.transparency,
                child: InkResponse(
                  onTap: action.onPressed,
                  child: const SizedBox.square(dimension: 48),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(_action('share')),
        // ignore: deprecated_member_use
        containsSemantics(label: 'Share', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    for (final mode in DockLayoutMode.values) {
      testWidgets('${mode.name}: meets the tap target guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, mode: mode);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('order', () {
    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}: the page comes first, then the column '
          'actions, then the rail', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, direction: direction);
        final labels = _labelsInOrder(tester);
        int at(String label) => labels.indexWhere((l) => l.contains(label));
        expect(at('Body button'), lessThan(at('Share')));
        expect(at('Share'), lessThan(at('Back')));
        expect(at('Back'), lessThan(at('Home')));

        // Keyboard traversal follows the same order.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final stops = <String>[];
        for (var i = 0; i < 8; i++) {
          if (_focusIn(tester, find.text('Body button'))) stops.add('body');
          if (_focusIn(tester, _action('share'))) stops.add('share');
          if (_focusIn(tester, _tab('home'))) stops.add('home');
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(stops.indexOf('body'), lessThan(stops.indexOf('share')));
        expect(stops.indexOf('share'), lessThan(stops.indexOf('home')));
        handle.dispose();
      });
    }
  });

  group('focus across a mode switch', () {
    Future<void> focusInside(WidgetTester tester, Finder finder) async {
      final button = find.descendant(
        of: finder,
        matching: find.byWidgetPredicate(
          (w) => w is IconButton || w is TextButton,
        ),
      );
      final icon = find
          .descendant(of: button.first, matching: find.byType(Icon))
          .first;
      Focus.maybeOf(
        tester.element(icon),
        createDependency: false,
      )!.requestFocus();
      await tester.pump();
      expect(_focusIn(tester, finder), isTrue);
    }

    testWidgets('moves from a rail tab to the same tab in the bar', (
      tester,
    ) async {
      await pump(tester, mode: null);
      await focusInside(tester, _tab('me'));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      expect(find.byKey(DockKeys.bar), findsOneWidget);
      expect(_focusIn(tester, _tab('me')), isTrue);
    });

    testWidgets('moves from a column chip to the same action in the bar', (
      tester,
    ) async {
      await pump(tester, mode: null);
      await focusInside(tester, _action('share'));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      expect(_focusIn(tester, _action('share')), isTrue);
      expect(
        find.descendant(of: find.byType(AppBar), matching: _action('share')),
        findsOneWidget,
      );
    });
  });

  testWidgets('reduced motion swaps icons without animating', (tester) async {
    final icon = ValueNotifier(Icons.star_border);
    addTearDown(icon.dispose);
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: DockTestHarness(
            builders: const DockMaterialBuilders(),
            mode: DockLayoutMode.compact,
            child: child!,
          ),
        ),
        home: ValueListenableBuilder(
          valueListenable: icon,
          builder: (context, data, _) => DockPage<Object?, Object?>(
            trailing: [
              DockAction<Object?>(
                id: 'fav',
                icon: DockIcon(data),
                tooltip: 'Favorite',
                onPressed: () {},
              ),
            ],
            body: const SizedBox(),
          ),
        ),
      ),
    );
    icon.value = Icons.star;
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
