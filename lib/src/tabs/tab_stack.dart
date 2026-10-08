import 'package:flutter/widgets.dart';

/// Shows the child at [index] and keeps the others alive but inert.
///
/// Use it as the child of a `DockShell`, one child per tab (often a
/// `Navigator` each):
///
/// ```dart
/// DockShell(
///   tabs: tabs,
///   currentIndex: index,
///   onTabSelected: (i) => setState(() => index = i),
///   child: DockTabStack(index: index, children: [homeNavigator, meNavigator]),
/// )
/// ```
///
/// Inactive tabs keep their state (routes, scroll positions, text) and are
/// inert: not painted, not hit-tested, out of the semantics tree
/// ([Offstage]), not ticking ([TickerMode], unless [maintainTickers]), out of
/// focus traversal ([ExcludeFocus]) and without hero flights ([HeroMode]).
/// Their pages don't claim the side column. Tabs are built the first time
/// they are shown, unless [lazy] is false.
///
/// It does not clip, so content can bleed under the bar and column. Any other
/// container works with `DockShell` too, as long as it wraps inactive tabs in
/// `TickerMode(enabled: false)`.
///
/// Coming from an [IndexedStack] (inactive children not painted, hit-tested,
/// focused or in semantics, like here), the differences are: [IndexedStack]
/// builds every child at once (here: [lazy]), keeps the tickers of inactive
/// children running (here: [maintainTickers]) and lets their heroes fly.
/// In an [IndexedStack], the pages of inactive tabs also claim the side
/// column unless each tab is wrapped in `TickerMode(enabled: false)`.
class DockTabStack extends StatefulWidget {
  /// Shows `children[index]`.
  const DockTabStack({
    super.key,
    required this.index,
    required this.children,
    this.lazy = true,
    this.maintainTickers = false,
  }) : assert(index >= 0 && index < children.length);

  /// The visible child.
  final int index;

  /// One child per tab, in tab order.
  final List<Widget> children;

  /// Whether a tab is built only once it has been shown. False builds all
  /// tabs right away (for example to preload them).
  final bool lazy;

  /// Whether inactive tabs keep ticking, as in an [IndexedStack]: for a tab
  /// whose long-running animation (a video, a map camera) must go on while
  /// another tab is shown. Their pages still don't claim the side column.
  /// Costs frames while anything in an inactive tab animates.
  final bool maintainTickers;

  /// Whether the tab around [context] is the shown one: false inside an
  /// inactive tab of a [DockTabStack], true everywhere else.
  static bool isActiveOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TabActivity>()?.active ??
      true;

  @override
  State<DockTabStack> createState() => _DockTabStackState();
}

class _DockTabStackState extends State<DockTabStack> {
  final Set<int> _built = {};

  @override
  Widget build(BuildContext context) {
    _built.add(widget.index);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _TabSlot(
            key: ValueKey<int>(i),
            active: i == widget.index,
            maintainTickers: widget.maintainTickers,
            child: !widget.lazy || _built.contains(i)
                ? widget.children[i]
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _TabSlot extends StatelessWidget {
  const _TabSlot({
    super.key,
    required this.active,
    required this.maintainTickers,
    required this.child,
  });

  final bool active;
  final bool maintainTickers;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active || maintainTickers,
        child: _TabActivity(
          active: active,
          child: ExcludeFocus(
            excluding: !active,
            child: HeroMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}

/// Tells pages whether their tab is the shown one, also when inactive tabs
/// keep ticking.
class _TabActivity extends InheritedWidget {
  const _TabActivity({required this.active, required super.child});

  final bool active;

  @override
  bool updateShouldNotify(_TabActivity oldWidget) => active != oldWidget.active;
}
