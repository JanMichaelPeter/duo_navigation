import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_dock/material.dart';
import 'package:nav_dock/testing.dart';

/// Performance gates, as counts rather than timings, so they are stable on
/// any machine: how many widgets rebuild for a change, and whether anything
/// works while nothing changes.
///
/// The budgets are the counts measured when the gates were added, with some
/// room; a change that needs more must say why and raise them.

/// Counts the builds of a widget that depends on nothing.
class _BodyProbe extends StatelessWidget {
  const _BodyProbe(this.builds);

  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(builds.length);
    return const SizedBox.expand();
  }
}

List<DockTab<Object?>> _tabs({int badge = 1}) => [
  for (var i = 0; i < 5; i++)
    DockTab(
      id: i,
      icon: const DockIcon(Icons.star),
      label: 'Tab $i',
      badge: i == 0 ? DockBadge.count(badge) : null,
    ),
];

/// A shell with 5 tabs and a page with 4 actions. [body] is the same widget
/// instance on every rebuild of the shell, as in an app.
class _Scene extends StatefulWidget {
  const _Scene({
    required this.body,
    required this.visible,
    required this.badge,
  });

  final Widget body;
  final ValueNotifier<bool> visible;
  final ValueNotifier<int> badge;

  @override
  State<_Scene> createState() => _SceneState();
}

class _SceneState extends State<_Scene> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.visible, widget.badge]),
      builder: (context, _) => DockShell<Object?, Object?, Object?>(
        tabs: _tabs(badge: widget.badge.value),
        currentIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        navigationVisible: widget.visible.value,
        child: widget.body,
      ),
    );
  }
}

void main() {
  late List<int> bodyBuilds;
  late ValueNotifier<bool> visible;
  late ValueNotifier<int> badge;
  late Widget body;

  setUp(() {
    bodyBuilds = [];
    visible = ValueNotifier(true);
    badge = ValueNotifier(1);
    body = Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => DockPage<Object?, Object?>(
          title: const Text('Page'),
          trailing: [
            for (var i = 0; i < 4; i++)
              DockAction<Object?>(
                id: 'a$i',
                icon: const DockIcon(Icons.share),
                tooltip: 'Action $i',
                onPressed: () {},
              ),
          ],
          body: _BodyProbe(bodyBuilds),
        ),
      ),
    );
  });
  tearDown(() {
    visible.dispose();
    badge.dispose();
  });

  Future<void> pump(WidgetTester tester, DockLayoutMode mode) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DockTestHarness(
          builders: const DockMaterialBuilders(),
          mode: mode,
          child: child!,
        ),
        home: _Scene(body: body, visible: visible, badge: badge),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The number of widgets rebuilt while [action] runs.
  Future<int> rebuilds(Future<void> Function() action) async {
    var count = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) => count++;
    try {
      await action();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    return count;
  }

  for (final mode in DockLayoutMode.values) {
    group(mode.name, () {
      testWidgets('chrome changes do not rebuild the body', (tester) async {
        await pump(tester, mode);
        final before = bodyBuilds.length;

        badge.value = 7; // the tab bar or rail changes
        await tester.pumpAndSettle();
        visible.value = false; // hide, then show, animated
        await tester.pumpAndSettle();
        visible.value = true;
        await tester.pumpAndSettle();

        expect(bodyBuilds.length, before);
      });

      testWidgets('nothing works while nothing changes', (tester) async {
        await pump(tester, mode);
        expect(tester.binding.hasScheduledFrame, isFalse);
        final idle = await rebuilds(() async {
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
        });
        expect(idle, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
      });

      testWidgets('rebuild budgets', (tester) async {
        await pump(tester, mode);
        final tabSwitch = await rebuilds(() async {
          await tester.tap(find.byKey(DockKeys.tab(1)));
          await tester.pumpAndSettle();
        });
        await tester.tap(find.byKey(DockKeys.tab(0)));
        await tester.pumpAndSettle();

        visible.value = false;
        await tester.pump();
        final tick = await rebuilds(
          () => tester.pump(const Duration(milliseconds: 16)),
        );
        await tester.pumpAndSettle();

        // Measured when the gates were added (Flutter 3.38 / 3.47): a tab
        // switch with its selection animation rebuilt 295-300 widgets in
        // compact mode and 545-554 in wide mode; one tick of the hide
        // animation 14 and 22.
        final budget = mode == DockLayoutMode.compact
            ? (tabSwitch: 400, tick: 20)
            : (tabSwitch: 750, tick: 30);
        expect(tabSwitch, lessThanOrEqualTo(budget.tabSwitch));
        expect(tick, lessThanOrEqualTo(budget.tick));
      });
    });
  }
}
