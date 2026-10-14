import 'package:duo_navigation/material.dart';
import 'package:duo_navigation/src/geometry/bar_regions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The numbers are what iOS 27.1 reports on the iPhone Duo simulator.

/// Answers like iOS: a bar is centred on a line 48 from its edge, within the
/// edge's free stretch.
class _FakeRegions implements DuoBarRegionSource {
  _FakeRegions(this.regions);

  final Map<DuoScreenEdge, Rect Function(double extent)> regions;
  int calls = 0;

  @override
  Future<Rect?> barRegion(DuoScreenEdge edge, double extent) async {
    calls++;
    return regions[edge]?.call(extent);
  }
}

const _tabs = [
  DuoTab<Object?>(id: 'home', icon: DuoIcon(Icons.home), label: 'Home'),
  DuoTab<Object?>(id: 'me', icon: DuoIcon(Icons.person), label: 'Me'),
];

Widget _app({
  required EdgeInsets padding,
  required DuoBarRegionSource source,
  Widget? page,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: padding, viewPadding: padding),
      child: DuoNavigation(
        builders: const DuoMaterialBuilders(),
        data: DuoNavigationData(
          // 466 also gives the folded iPhone Duo the column.
          layoutPolicy: const DuoLayoutPolicy.breakpoint(466),
          barRegionSource: source,
        ),
        child: child!,
      ),
    ),
    home: DuoShell<Object?, Object?, Object?>(
      tabs: _tabs,
      currentIndex: 0,
      onTabSelected: (_) {},
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) =>
              page ??
              DuoPage<Object?, Object?>(
                title: const Text('Title'),
                body: const SizedBox.expand(),
              ),
        ),
      ),
    ),
  );
}

void main() {
  group('columnPlacementFromRegion', () {
    const folded = Size(466, 678);
    const icons = EdgeInsets.only(right: 84, bottom: 34);

    test('starts below the status icons and centres on them', () {
      final placement = columnPlacementFromRegion(
        region: const Rect.fromLTWH(386, 170, 64, 474),
        onRight: true,
        width: 72,
        size: folded,
        padding: icons,
      )!;
      expect(placement.top, 170);
      // The icons' centre line is 48 from the edge: 12 + 72 / 2.
      expect(placement.offset, 12);
    });

    test('on the left edge, the offset counts from the left', () {
      final placement = columnPlacementFromRegion(
        region: const Rect.fromLTWH(16, 120, 64, 515),
        onRight: false,
        width: 80,
        size: const Size(951, 669),
        padding: const EdgeInsets.only(left: 84, bottom: 34),
      )!;
      expect(placement.top, 120);
      expect(placement.offset, 8);
    });

    test('keeps the safe area on an edge without icons', () {
      // Split screen, app on the left: no inset on its right edge.
      expect(
        columnPlacementFromRegion(
          region: const Rect.fromLTWH(377, 16, 88, 619),
          onRight: true,
          width: 88,
          size: const Size(469, 669),
          padding: const EdgeInsets.only(bottom: 34),
        ),
        isNull,
      );
    });

    test('keeps the safe area when the column is too wide for the icons', () {
      // 120 wide: iOS falls back to a region inside the safe area.
      expect(
        columnPlacementFromRegion(
          region: const Rect.fromLTWH(262, 17.3, 120, 626.7),
          onRight: true,
          width: 120,
          size: folded,
          padding: icons,
        ),
        isNull,
      );
    });
  });

  group('titleBarPaddingFromRegion', () {
    test('portrait: up into the band, ending before the icons', () {
      final padding = titleBarPaddingFromRegion(
        region: const Rect.fromLTWH(16, 20, 519, 56),
        origin: Offset.zero,
        bodyWidth: 669 - 72,
        size: const Size(669, 951),
        padding: const EdgeInsets.only(top: 82, bottom: 34),
      );
      expect(padding.top, 20);
      expect(padding.left, 0);
      expect(padding.right, 597 - 535);
    });

    test('landscape: stays on the top edge, ends before the icon column', () {
      final padding = titleBarPaddingFromRegion(
        region: const Rect.fromLTWH(16, 20, 851, 56),
        origin: Offset.zero,
        bodyWidth: 951 - 72,
        // The body's padding: the column covers 72 of the 84.
        size: const Size(951, 669),
        padding: const EdgeInsets.only(right: 12, bottom: 34),
      );
      expect(padding.top, 0);
      expect(padding.right, 879 - 867);
    });

    test('symmetric margins: no icons on the top edge, no side padding', () {
      final padding = titleBarPaddingFromRegion(
        region: const Rect.fromLTWH(16, 20, 637, 56),
        origin: Offset.zero,
        bodyWidth: 669,
        size: const Size(669, 951),
        padding: const EdgeInsets.only(top: 24),
      );
      expect(padding, const EdgeInsets.only(top: 20));
    });
  });

  testWidgets('unfolded portrait: the title bar sits in the band beside the '
      'icons', (tester) async {
    tester.view.physicalSize = const Size(669, 951);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final source = _FakeRegions({
      DuoScreenEdge.top: (e) => Rect.fromLTWH(16, 48 - e / 2, 519, e),
      DuoScreenEdge.right: (e) => Rect.fromLTWH(669 - 48 - e / 2, 82, e, 835),
    });
    await tester.pumpWidget(
      _app(padding: const EdgeInsets.only(top: 82, bottom: 34), source: source),
    );
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(DuoBarLayout));
    expect(bar.top, 48 - kToolbarHeight / 2);
    expect(bar.right, lessThanOrEqualTo(535));
    expect(tester.getRect(find.text('Title')).bottom, lessThan(82));
  });

  testWidgets('folded: the column starts below the icon column', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(466, 678);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final source = _FakeRegions({
      DuoScreenEdge.top: (e) => Rect.fromLTWH(2.3, 48 - e / 2, 379.7, e),
      DuoScreenEdge.right: (e) => Rect.fromLTWH(466 - 48 - e / 2, 170, e, 474),
    });
    await tester.pumpWidget(
      _app(
        padding: const EdgeInsets.only(right: 84, bottom: 34),
        source: source,
      ),
    );
    await tester.pumpAndSettle();

    final column = find.byKey(DuoKeys.column);
    final safeArea = find.descendant(
      of: column,
      matching: find.byType(SafeArea),
    );
    // The column is centred on the icons' centre line, 48 from the edge,
    // and the body ends where it starts.
    final columnRect = tester.getRect(column);
    expect(columnRect.top, 0);
    expect(columnRect.center.dx, 466 - 48);
    expect(
      tester.getRect(find.byType(DuoBarLayout)).right,
      lessThanOrEqualTo(columnRect.left),
    );
    // The column's content starts below the icons.
    final content = find.descendant(
      of: safeArea.first,
      matching: find.byType(DuoSideColumnLayout),
    );
    expect(tester.getRect(content).top, greaterThanOrEqualTo(170));
    // The title bar keeps the top edge and ends before the icon column.
    final bar = tester.getRect(find.byType(DuoBarLayout));
    expect(bar.top, lessThan(56));
    expect(bar.right, lessThanOrEqualTo(466 - 84));
  });

  testWidgets('without answers the safe area applies', (tester) async {
    tester.view.physicalSize = const Size(669, 951);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        padding: const EdgeInsets.only(top: 82, bottom: 34),
        source: _FakeRegions({}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(DuoBarLayout)).top, 82);
  });

  testWidgets('a page with its own Scaffold moves up with DuoTitleBarPadding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(669, 951);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final source = _FakeRegions({
      DuoScreenEdge.top: (e) => Rect.fromLTWH(16, 48 - e / 2, 519, e),
    });
    await tester.pumpWidget(
      _app(
        padding: const EdgeInsets.only(top: 82, bottom: 34),
        source: source,
        page: DuoPageScope<Object?, Object?>(
          title: const Text('Own'),
          trailing: [
            DuoAction<Object?>(id: 'edit', label: 'Edit', onPressed: () {}),
          ],
          child: const DuoTitleBarPadding(
            child: Scaffold(appBar: DuoAppBar(), body: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(DuoBarLayout));
    expect(bar.top, 48 - kToolbarHeight / 2);
    expect(bar.right, lessThanOrEqualTo(535));
    expect(tester.getRect(find.text('Edit')).right, lessThanOrEqualTo(535));
  });
}
