// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../a11y/focus.dart';
import '../actions/action_host.dart';
import '../builders/builders.dart';
import '../config/navigation.dart';
import '../config/keyboard.dart';
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
    required this.route,
    required this.impliedLeading,
    required this.leadingAtEnd,
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

  /// The route the modal frame is on; null in a shell. Its first page
  /// dismisses the modal by popping this route.
  final ModalRoute<Object?>? route;

  /// The leading action the modal's first page implies; null: from [route]
  /// (close for a full-screen dialog, else back).
  final DockImpliedLeading? impliedLeading;

  /// Whether the modal's first page has its leading action at the end.
  final bool leadingAtEnd;

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
      hoisting != oldWidget.hoisting ||
      route != oldWidget.route ||
      impliedLeading != oldWidget.impliedLeading ||
      leadingAtEnd != oldWidget.leadingAtEnd;
}

/// Decides whether a tab may be selected; see `DockShell.canSelectTab`.
typedef DockTabVeto = FutureOr<bool> Function(int index);

/// Shared implementation of the shell and modal frames. Not exported.
class DockFrame<T, A, B> extends StatefulWidget {
  const DockFrame({
    super.key,
    required this.isModal,
    this.implicitModal = false,
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
    this.backdrop,
    this.impliedLeading,
    this.leadingAtEnd,
    this.keyboard,
  });

  final bool isModal;

  /// A frame that a page without a scope above creates around itself. Every
  /// page on the root navigator gets one, so it is a modal start only if its
  /// route presents as one (see [_isModalStart]).
  final bool implicitModal;
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

  /// Painted across the whole frame under everything, unless the active page
  /// has its own.
  final Widget? backdrop;
  final DockImpliedLeading? impliedLeading;
  final bool? leadingAtEnd;
  final DockKeyboard? keyboard;

  @override
  State<DockFrame<T, A, B>> createState() => _DockFrameState<T, A, B>();
}

class _DockFrameState<T, A, B> extends State<DockFrame<T, A, B>>
    with TickerProviderStateMixin {
  final DockActionHost _host = DockActionHost();

  /// How far the bar and column are shown. Only ticks while they animate.
  /// Created in [initState], not lazily: [dispose] must not be the first to
  /// touch it (it would look up TickerMode on a deactivated element).
  late final AnimationController _visibility;
  late final CurvedAnimation _curved;

  /// Hides the chrome while the keyboard is open, for
  /// [DockKeyboardBehavior.hide]. Combined with [_visibility] by product.
  late final AnimationController _keyboardShown;
  late final CurvedAnimation _keyboardCurved;
  late final Animation<double> _shown;
  bool _keyboardHides = false;

  /// Moves focus to the same tab or action when the layout mode changes.
  final DockFocusRegistry _focus = DockFocusRegistry();
  DockLayoutMode? _lastMode;
  Duration _visibilityDuration = Duration.zero;

  /// The shell's and the active page's wish together.
  bool get _wantsNavigation =>
      widget.navigationVisible && (_host.active?.navigationVisible ?? true);

  @override
  void initState() {
    super.initState();
    _visibility = AnimationController(
      vsync: this,
      value: widget.navigationVisible ? 1 : 0,
    );
    _curved = CurvedAnimation(parent: _visibility, curve: Curves.linear);
    _keyboardShown = AnimationController(vsync: this, value: 1);
    _keyboardCurved = CurvedAnimation(
      parent: _keyboardShown,
      curve: Curves.linear,
    );
    _shown = _Product(_curved, _keyboardCurved);
    _host.addListener(_syncVisibility);
  }

  @override
  void didUpdateWidget(DockFrame<T, A, B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationVisible != oldWidget.navigationVisible) {
      _syncVisibility();
    }
  }

  /// The active page's backdrop, else the frame's, else the builders'
  /// default; a change of owner cross-fades.
  Widget _backdrop(BuildContext context, DockNavigationData config) {
    final page = _host.active;
    final pageBackdrop = page?.backdrop;
    final Object owner = pageBackdrop != null ? page! : 'frame';
    final child =
        pageBackdrop ??
        widget.backdrop ??
        DockBuilders.of<T, A, B>(context).backdrop?.call(context);
    return AnimatedSwitcher(
      duration: _visibilityDuration == Duration.zero
          ? Duration.zero
          : config.actionAnimationDuration,
      // Backdrops fill the frame, also while two of them cross-fade.
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: KeyedSubtree(
        key: ValueKey<Object>(child == null ? 'none' : owner),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }

  /// Starts hiding or showing the chrome for the keyboard. Called during
  /// layout, where the mode is known; the render object follows the
  /// animation without a rebuild.
  void _hideForKeyboard(bool hide) {
    if (hide == _keyboardHides) return;
    _keyboardHides = hide;
    _keyboardShown.animateTo(hide ? 0 : 1, duration: _visibilityDuration);
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
    _keyboardCurved.dispose();
    _keyboardShown.dispose();
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
      child: DockFocusRegistryScope(
        registry: _focus,
        child: Builder(builder: _build),
      ),
    );
  }

  /// Whether this frame starts a modal, so the app-wide
  /// `DockNavigationData.modalLeading` applies to its first page: an explicit
  /// `DockModalScope`, or an implicit frame on a full-screen dialog or a modal
  /// route that isn't a page (a sheet, a dialog). A plain page pushed on the
  /// root navigator is not one.
  bool _isModalStart(ModalRoute<Object?>? route) {
    if (!widget.isModal) return false;
    if (!widget.implicitModal) return true;
    return switch (route) {
      PageRoute(:final fullscreenDialog) => fullscreenDialog,
      null => false,
      _ => true,
    };
  }

  List<Widget> _items(
    BuildContext context,
    DockBuilders<T, A, B> builders,
    DockTabsData<T> data,
  ) {
    return [
      for (var i = 0; i < data.tabs.length; i++)
        Builder(
          builder: (context) {
            final item = data.itemData(i);
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
    _keyboardCurved.curve = config.visibilityCurve;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardConfig = widget.keyboard ?? config.keyboard;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = config.layoutPolicy.resolve(
          window: window,
          frame: constraints.biggest,
        );
        // Before the old chrome goes: remember which tab or action has focus,
        // and give it to the same one in the new layout.
        if (_lastMode != null && mode != _lastMode) {
          final focused = _focus.focusedId();
          if (focused != null) _focus.restoreAfterFrame(focused);
        }
        _lastMode = mode;
        final behavior = mode == DockLayoutMode.compact
            ? keyboardConfig.bar
            : keyboardConfig.column;
        _hideForKeyboard(keyboard > 0 && behavior == DockKeyboardBehavior.hide);
        final hidden = !_wantsNavigation || _keyboardHides;
        final tabs = widget.tabs == null
            ? null
            : DockTabsData<T>(
                tabs: widget.tabs!,
                currentIndex: widget.currentIndex,
                onSelected: _select,
                mode: mode,
              );

        // Only modal frames need their route; a shell doesn't rebuild when
        // routes change above it.
        final route = widget.isModal ? ModalRoute.of(context) : null;
        final modalStart = _isModalStart(route);
        return DockScope._(
          mode: mode,
          host: _host,
          isModal: widget.isModal,
          side: side,
          hoisting: widget.hoisting ?? config.hoisting,
          route: route,
          impliedLeading:
              widget.impliedLeading ??
              (modalStart ? config.modalLeading.implied : null),
          leadingAtEnd:
              widget.leadingAtEnd ?? (modalStart && config.modalLeading.atEnd),
          // Focus and semantics order, the same in both modes: the page
          // first, then the chrome (the column's actions above its rail, or
          // the tab bar).
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: DockFrameLayout(
              mode: mode,
              side: side,
              columnOnRight: columnOnRight,
              columnWidth:
                  config.sideColumnWidth *
                  textScale.clamp(1.0, config.columnTextScaleLimit),
              columnInset: config.columnInset,
              bodyMode: widget.bodyMode ?? config.bodyMode,
              systemPadding: padding,
              visibility: _shown,
              keyboard: keyboard,
              liftColumn: keyboardConfig.column == DockKeyboardBehavior.lift,
              liftBar: keyboardConfig.bar == DockKeyboardBehavior.lift,
              liftBody: keyboardConfig.body == DockBodyKeyboardBehavior.lift,
              // The body keeps its slot in every mode, so switching modes
              // (rotation, split view) keeps its State.
              body: _Ordered(
                order: 1,
                child: DockBodyScope(child: widget.child),
              ),
              backdrop: ListenableBuilder(
                listenable: _host,
                builder: (context, _) => _backdrop(context, config),
              ),
              bar: tabs == null || mode != DockLayoutMode.compact
                  ? null
                  : _Ordered(
                      order: 2,
                      child: KeyedSubtree(
                        key: DockKeys.bar,
                        child: _Inert(
                          inert: hidden,
                          // The bar sits at the bottom, so the status bar is
                          // not its concern (as with Scaffold's bottom bar);
                          // it owns the bottom padding.
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: Builder(
                              builder: (context) => builders.buildTabBar(
                                context,
                                tabs,
                                _items(context, builders, tabs),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              column: _Ordered(
                order: 2,
                child: _Inert(
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
                    columnInset: config.columnInset,
                    buildChip: (context, action) =>
                        _chip(context, builders, action),
                  ),
                ),
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

/// The product of two animations: shown only while both are.
class _Product extends CompoundAnimation<double> {
  _Product(Animation<double> first, Animation<double> next)
    : super(first: first, next: next);

  @override
  double get value => first.value * next.value;
}

/// Puts a frame part at [order] in focus traversal and in the semantics
/// order.
class _Ordered extends StatelessWidget {
  const _Ordered({required this.order, required this.child});

  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: FocusTraversalGroup(
      child: Semantics(
        container: true,
        sortKey: OrdinalSortKey(order),
        child: child,
      ),
    ),
  );
}
