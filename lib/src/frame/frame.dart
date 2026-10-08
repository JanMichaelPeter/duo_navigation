// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../actions/action_host.dart';
import '../builders/builders.dart';
import '../config/navigation.dart';
import '../config/navigation_data.dart';
import '../geometry/body_mode.dart';
import '../geometry/layout_mode.dart';
import '../geometry/side.dart';
import '../keys.dart';
import '../models/action.dart';
import '../models/enums.dart';
import '../models/tab.dart';
import '../models/tabs_data.dart';
import '../tabs/tab_item.dart';
import 'body_scope.dart';
import 'render_frame.dart';
import 'side_column.dart';

/// Exposes the current layout mode and action host to pages.
class DockScope extends InheritedWidget {
  const DockScope._({
    required this.mode,
    required this.host,
    required this.isModal,
    required this.side,
    required this.hoisting,
    required super.child,
  });

  /// Compact or wide, decided by the layout policy.
  final DockLayoutMode mode;

  /// Edge the side column is on (after window-edge resolution), relative to
  /// [Directionality]. Only meaningful in wide mode.
  final DockSide side;

  /// Collects the actions of the pages in this frame.
  final DockActionHost host;

  /// True for an [DockModalScope] (no tabs), false inside an DockShell.
  final bool isModal;

  /// Whether icon actions move into the column, for pages that don't decide
  /// themselves.
  final DockHoisting hoisting;

  /// The nearest scope, or null outside any shell or modal frame.
  static DockScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DockScope>();

  /// Current mode; outside any scope it is [DockNavigation.modeOf].
  static DockLayoutMode modeOf(BuildContext context) =>
      maybeOf(context)?.mode ?? DockNavigation.modeOf(context);

  @override
  bool updateShouldNotify(DockScope oldWidget) =>
      mode != oldWidget.mode ||
      host != oldWidget.host ||
      isModal != oldWidget.isModal ||
      side != oldWidget.side ||
      hoisting != oldWidget.hoisting;
}

/// Decides whether a tab may be selected; see `DockShell.canSelectTab`.
typedef DockTabVeto = FutureOr<bool> Function(int index);

/// Shared implementation of the shell and modal frames. Not exported.
class DockFrame<T, A, B> extends StatefulWidget {
  const DockFrame({
    super.key,
    required this.isModal,
    required this.child,
    this.tabs,
    this.currentIndex = 0,
    this.onTabSelected,
    this.onTabReselected,
    this.canSelectTab,
    this.bodyMode,
    this.hoisting,
    this.builders,
    this.navigationVisible = true,
  });

  final bool isModal;
  final Widget child;
  final List<DockTab<T>>? tabs;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final ValueChanged<int>? onTabReselected;
  final DockTabVeto? canSelectTab;

  /// Null: [DockNavigationData.bodyMode].
  final DockBodyMode? bodyMode;

  /// Null: [DockNavigationData.hoisting].
  final DockHoisting? hoisting;

  /// Overrides on top of the builders above; null fields fall back to them.
  final DockBuilders<T, A, B>? builders;

  /// Whether the bar and column show; pages can hide them too.
  final bool navigationVisible;

  @override
  State<DockFrame<T, A, B>> createState() => _DockFrameState<T, A, B>();
}

class _DockFrameState<T, A, B> extends State<DockFrame<T, A, B>>
    with SingleTickerProviderStateMixin {
  final DockActionHost _host = DockActionHost();

  /// How far the bar and column are shown. Only ticks while they animate.
  late final AnimationController _visibility = AnimationController(
    vsync: this,
    value: _wantsNavigation ? 1 : 0,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _visibility,
    curve: Curves.linear,
  );
  Duration _visibilityDuration = Duration.zero;

  /// The shell's and the active page's wish together.
  bool get _wantsNavigation =>
      widget.navigationVisible && (_host.active?.navigationVisible ?? true);

  @override
  void initState() {
    super.initState();
    _host.addListener(_syncVisibility);
  }

  @override
  void didUpdateWidget(DockFrame<T, A, B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationVisible != oldWidget.navigationVisible) {
      _syncVisibility();
    }
  }

  void _syncVisibility() {
    if (!mounted) return;
    final target = _wantsNavigation ? 1.0 : 0.0;
    if (_visibility.value == target && !_visibility.isAnimating) return;
    // Rebuild so the chrome leaves (or joins) hit testing, focus and
    // semantics right away, not when the animation ends.
    setState(() {});
    _visibility.animateTo(target, duration: _visibilityDuration);
  }

  @override
  void dispose() {
    _host.removeListener(_syncVisibility);
    _curved.dispose();
    _visibility.dispose();
    _host.dispose();
    super.dispose();
  }

  /// Applies the shell's rules: a tap on the current tab re-selects it, a
  /// tap on another tab asks the veto first.
  void _select(int index) {
    final widget = this.widget;
    if (index == widget.currentIndex) {
      (widget.onTabReselected ?? widget.onTabSelected)?.call(index);
      return;
    }
    final veto = widget.canSelectTab;
    if (veto == null) {
      widget.onTabSelected?.call(index);
      return;
    }
    final allowed = veto(index);
    if (allowed is bool) {
      if (allowed) widget.onTabSelected?.call(index);
      return;
    }
    allowed.then((ok) {
      if (ok && mounted) this.widget.onTabSelected?.call(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The scope sits above everything the frame builds, so the bar, the
    // column and the pages all see the shell's builders.
    return DockBuildersScope(
      builders: widget.builders,
      child: Builder(builder: _build),
    );
  }

  List<Widget> _items(
    BuildContext context,
    DockBuilders<T, A, B> builders,
    DockTabsData<T> data,
  ) {
    final count = data.tabs.length;
    return [
      for (var i = 0; i < count; i++)
        Builder(
          builder: (context) {
            final item = DockTabItemData<T>(
              tab: data.tabs[i],
              index: i,
              count: count,
              selected: i == data.currentIndex,
              placement: data.placement,
              onTap: () => _select(i),
            );
            return DockTabItem<T>(
              data: item,
              child: builders.buildTabItem(context, item),
            );
          },
        ),
    ];
  }

  /// Hands a chip's action to the typed action builder.
  Widget _chip(
    BuildContext context,
    DockBuilders<T, A, B> builders,
    DockAction<Object?> action,
  ) {
    if (action is! DockAction<A>) {
      throw FlutterError.fromParts([
        ErrorSummary('A page action does not match this frame.'),
        ErrorDescription(
          'The action ${action.id} is a ${action.runtimeType}, and this '
          'frame draws DockAction<$A>.',
        ),
        ErrorHint(
          'Give the shell or modal scope the action payload type its pages '
          'use, for example DockShell<MyTab, MyAction>.',
        ),
      ]);
    }
    return builders.buildAction(
      context,
      action,
      DockActionPlacement.sideColumn,
    );
  }

  Widget _build(BuildContext context) {
    final config = DockNavigation.of(context);
    _host.tapGuard = config.tapGuard;
    final padding = MediaQuery.paddingOf(context);
    final window = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final columnOnRight = DockNavigation.sideOnRight(context);
    final side = columnOnRight == ltr ? DockSide.end : DockSide.start;
    final builders = DockBuilders.of<T, A, B>(context);
    _visibilityDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : config.visibilityDuration;
    _curved.curve = config.visibilityCurve;
    final hidden = !_wantsNavigation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = config.layoutPolicy.resolve(
          window: window,
          frame: constraints.biggest,
        );
        final tabs = widget.tabs == null
            ? null
            : DockTabsData<T>(
                tabs: widget.tabs!,
                currentIndex: widget.currentIndex,
                onSelected: _select,
                mode: mode,
              );

        return DockScope._(
          mode: mode,
          host: _host,
          isModal: widget.isModal,
          side: side,
          hoisting: widget.hoisting ?? config.hoisting,
          child: DockFrameLayout(
            mode: mode,
            side: side,
            columnOnRight: columnOnRight,
            columnWidth:
                config.sideColumnWidth *
                textScale.clamp(1.0, config.columnTextScaleLimit),
            bodyMode: widget.bodyMode ?? config.bodyMode,
            systemPadding: padding,
            visibility: _curved,
            // The body keeps its slot in every mode, so switching modes
            // (rotation, split view) keeps its State.
            body: DockBodyScope(child: widget.child),
            bar: tabs == null || mode != DockLayoutMode.compact
                ? null
                : KeyedSubtree(
                    key: DockKeys.bar,
                    child: _Inert(
                      inert: hidden,
                      child: builders.buildTabBar(
                        context,
                        tabs,
                        _items(context, builders, tabs),
                      ),
                    ),
                  ),
            column: _Inert(
              inert: hidden,
              child: SideColumn(
                key: DockKeys.column,
                host: _host,
                rail: tabs == null || mode != DockLayoutMode.wide
                    ? null
                    : KeyedSubtree(
                        key: DockKeys.rail,
                        // Scrolls when the tabs don't fit the column.
                        child: SingleChildScrollView(
                          child: builders.buildRail(
                            context,
                            tabs,
                            _items(context, builders, tabs),
                          ),
                        ),
                      ),
                columnOnRight: columnOnRight,
                buildChip: (context, action) =>
                    _chip(context, builders, action),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Takes hidden chrome out of hit testing, focus and semantics. Inserted
/// always, so the chrome keeps its state across hiding and showing.
class _Inert extends StatelessWidget {
  const _Inert({required this.inert, required this.child});

  final bool inert;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: inert,
    child: ExcludeFocus(
      excluding: inert,
      child: ExcludeSemantics(excluding: inert, child: child),
    ),
  );
}
