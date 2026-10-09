import 'package:flutter/widgets.dart';

import 'tab_stack.dart';

/// A [Navigator] for one tab of a `DuoShell`: it doesn't clip, and the
/// system back gesture pops its pages while its tab is shown.
///
/// ```dart
/// DuoShell(
///   tabs: tabs,
///   currentIndex: index,
///   onTabSelected: (i) => setState(() => index = i),
///   child: DuoTabStack(
///     index: index,
///     children: [
///       DuoTabNavigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const HomePage())),
///       DuoTabNavigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const MePage())),
///     ],
///   ),
/// )
/// ```
///
/// * **System back** (Android's back button and gesture, and the predictive
///   back animation) pops the shown tab's pages first; on a tab's first page
///   it goes to the navigator above, as without tabs. Tabs that aren't shown
///   (`DuoTabStack.isActiveOf`) neither handle back nor tell the app they
///   could, so a pushed page in another tab doesn't keep the app from
///   closing.
/// * **No clip** (`Clip.none`, a plain [Navigator] clips to its bounds), so a
///   `DuoBleed` in a page reaches under the bar and the column.
///
/// The arguments are the [Navigator]'s, except that the navigator's key is
/// [navigatorKey]: `key` keys this widget. Apps with a routing package (such as
/// go_router's `StatefulShellRoute`) get system back from it and use their
/// own navigators.
class DuoTabNavigator extends StatefulWidget {
  /// A tab's navigator; see [Navigator] for the arguments.
  const DuoTabNavigator({
    super.key,
    this.navigatorKey,
    this.initialRoute,
    this.onGenerateInitialRoutes = Navigator.defaultGenerateInitialRoutes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.observers = const [],
    this.restorationScopeId,
    this.handlesSystemBack = true,
  }) : assert(
         key is! GlobalKey<NavigatorState>,
         'DuoTabNavigator(key:) keys the DuoTabNavigator, not its Navigator, '
         'so a GlobalKey<NavigatorState> passed as key has no currentState. '
         'Pass it as navigatorKey instead.',
       );

  /// The key of the [Navigator], to push from outside the tab or pop it to
  /// its root (`navigatorKey.currentState`). Null: an internal one. Not
  /// `key`, which keys this widget.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// See [Navigator.initialRoute].
  final String? initialRoute;

  /// See [Navigator.onGenerateInitialRoutes].
  final RouteListFactory onGenerateInitialRoutes;

  /// See [Navigator.onGenerateRoute].
  final RouteFactory? onGenerateRoute;

  /// See [Navigator.onUnknownRoute].
  final RouteFactory? onUnknownRoute;

  /// See [Navigator.observers].
  final List<NavigatorObserver> observers;

  /// See [Navigator.restorationScopeId].
  final String? restorationScopeId;

  /// Whether the system back gesture pops this navigator's pages while its
  /// tab is shown.
  final bool handlesSystemBack;

  @override
  State<DuoTabNavigator> createState() => _DuoTabNavigatorState();
}

class _DuoTabNavigatorState extends State<DuoTabNavigator> {
  GlobalKey<NavigatorState>? _ownKey;
  bool? _active;

  GlobalKey<NavigatorState> get _key =>
      widget.navigatorKey ?? (_ownKey ??= GlobalKey<NavigatorState>());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = DuoTabStack.isActiveOf(context);
    final becameActive = _active == false && active;
    _active = active;
    if (becameActive) {
      // While hidden, this tab kept its navigation state to itself; tell the
      // app again whether back can pop something here.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _active != true) return;
        NavigationNotification(
          canHandlePop: _key.currentState?.canPop() ?? false,
        ).dispatch(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active ?? true;
    return NotificationListener<NavigationNotification>(
      // A hidden tab must not tell the app that back can pop something.
      onNotification: (_) => !active,
      child: NavigatorPopHandler<Object?>(
        enabled: active && widget.handlesSystemBack,
        onPopWithResult: (_) => _key.currentState?.maybePop(),
        child: Navigator(
          key: _key,
          clipBehavior: Clip.none,
          initialRoute: widget.initialRoute,
          onGenerateInitialRoutes: widget.onGenerateInitialRoutes,
          onGenerateRoute: widget.onGenerateRoute,
          onUnknownRoute: widget.onUnknownRoute,
          observers: widget.observers,
          restorationScopeId: widget.restorationScopeId,
        ),
      ),
    );
  }
}
