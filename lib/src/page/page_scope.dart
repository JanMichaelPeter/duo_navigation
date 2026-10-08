import 'package:flutter/widgets.dart';

import '../actions/action_host.dart';
import '../actions/action_item.dart';
import '../builders/builders.dart';
import '../frame/frame.dart';
import '../frame/modal_scope.dart';
import '../geometry/layout_mode.dart';
import '../keys.dart';
import '../models/action.dart';
import '../models/bar_data.dart';
import '../tabs/tab_stack.dart';

/// Declares a page's title bar and actions, and provides them to the page as
/// [DockBarData] (`DockBarData.of(context)`).
///
/// It is the page layer as a piece: put it around any page, including one
/// with its own `Scaffold`, keys, bottom bar or floating action button, and
/// read the bar with `DockAppBar` (`package:nav_dock/material.dart`) or your
/// own bar:
///
/// ```dart
/// DockPageScope(
///   title: const Text('Items'),
///   trailing: [DockAction(id: 'add', icon: const DockIcon(Icons.add), onPressed: add)],
///   child: Scaffold(
///     key: const Key('items'),
///     appBar: const DockAppBar(),
///     bottomNavigationBar: const ItemsToolbar(),
///     body: const ItemsList(),
///   ),
/// )
/// ```
///
/// In wide mode, icon actions move into the side column (see [hoisting]);
/// the rest stay in the bar. `DockPage` is this scope plus the `page`
/// builder.
///
/// [A] is the actions' payload type and [B] the type of [barPayload].
class DockPageScope<A, B> extends StatefulWidget {
  /// A page with the given bar and actions around [child].
  const DockPageScope({
    super.key,
    this.title,
    this.barPayload,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.impliedLeading,
    this.hoisting,
    this.visible = true,
    this.backdrop,
    required this.child,
  });

  /// The title shown in the title bar.
  final Widget? title;

  /// Data for the bar builder, for example a design system's title spec or bar
  /// style: `DockBarData.payload`, typed.
  final B? barPayload;

  /// The leading action. Defaults to [DockAction.back] for pages that can pop,
  /// or [DockAction.close] for full-screen dialogs (see [impliedLeading]). In
  /// wide mode it moves into the column when it has an icon; a text-only one
  /// ("Cancel") stays in the bar.
  ///
  /// A [DockAction.back] or [DockAction.close] without `onPressed` pops the
  /// page's route, or dismisses the modal on a modal's first page.
  final DockAction<A>? leading;

  /// The page's other actions. In wide mode icon actions move to the side
  /// column (ordered by [DockAction.order], above the leading action);
  /// label-only actions and those with `hoist: DockHoist.never` stay in the
  /// bar.
  final List<DockAction<A>> trailing;

  /// Add a back or close action when the route can pop and [leading] is
  /// null.
  final bool automaticallyImplyLeading;

  /// The leading action implied when [leading] is null. Null: the modal's
  /// choice on its first page (`DockModalScope.impliedLeading`), otherwise
  /// [DockImpliedLeading.close] for a full-screen dialog and
  /// [DockImpliedLeading.back] for anything else.
  ///
  /// The first page of a modal (the page on the modal's route, or the first
  /// page of a Navigator inside a `DockModalScope`) gets one too, and it
  /// dismisses the modal.
  final DockImpliedLeading? impliedLeading;

  /// Whether this page's icon actions move into the column in wide mode.
  /// Null: the frame's (`DockShell.hoisting`, `DockModalScope.hoisting`,
  /// `DockNavigationData.hoisting`).
  final DockHoisting? hoisting;

  /// Whether the navigation (tab bar or side column) shows while this page is
  /// on top. False hides it with an animation, for example for a camera, a
  /// video or reading. The shell can hide it too (`navigationVisible`).
  final bool visible;

  /// Painted across the whole frame, under the body, the bar and the column,
  /// while this page is shown: a gradient or picture behind the page that is
  /// not affected by clips. It replaces the shell's backdrop and cross-fades
  /// when the page changes (not during an interactive back swipe).
  final Widget? backdrop;

  /// The page.
  final Widget child;

  @override
  State<DockPageScope<A, B>> createState() => _DockPageScopeState<A, B>();
}

class _DockPageScopeState<A, B> extends State<DockPageScope<A, B>> {
  DockActionRegistration? _registration;

  @override
  void dispose() {
    _registration?.dispose();
    super.dispose();
  }

  DockAction<A>? _resolveLeading(DockScope scope, ModalRoute<Object?>? route) {
    final page = widget;
    // The modal's first page: on the modal's own route, or the first page of
    // a Navigator inside the modal. It dismisses the modal when it can't pop
    // its own route.
    final modal = scope.route;
    final first =
        modal != null &&
        route != null &&
        (route == modal ||
            (route.isFirst && route.navigator != modal.navigator));
    final ModalRoute<Object?>? popped = route == null
        ? null
        : route.canPop
        ? route
        : first && modal.canPop
        ? modal
        : null;
    void pop() {
      if (popped != null && popped != route) {
        popped.navigator?.maybePop();
      } else {
        Navigator.maybePop(context);
      }
    }

    final explicit = page.leading;
    if (explicit != null) {
      return explicit.isBack && explicit.onPressed == null
          ? explicit.copyWith(onPressed: pop)
          : explicit;
    }
    if (!page.automaticallyImplyLeading || popped == null) return null;
    final kind =
        page.impliedLeading ??
        (first ? scope.impliedLeading : null) ??
        (popped is PageRoute && popped.fullscreenDialog
            ? DockImpliedLeading.close
            : DockImpliedLeading.back);
    // Back and close share one identity, so they morph instead of flickering.
    return switch (kind) {
      DockImpliedLeading.close => DockAction<A>.close(onPressed: pop),
      DockImpliedLeading.back => DockAction<A>.back(onPressed: pop),
    };
  }

  /// Whether the page shows: its route is current, or only popups (dialogs,
  /// sheets, menus) are above it. Page routes animate the routes below them
  /// out of the way; popups leave them as they are, so a route below only
  /// popups is not current but its secondary animation stays dismissed.
  static bool _shows(ModalRoute<Object?>? route) {
    if (route == null || route.isCurrent) return true;
    return route.isActive && (route.secondaryAnimation?.isDismissed ?? false);
  }

  /// The trailing actions that move into the column, top to bottom: higher
  /// [DockAction.order] first, equal orders in declaration order.
  static List<DockAction<A>> _hoisted<A>(List<DockAction<A>> trailing) {
    final indexed = [
      for (var i = 0; i < trailing.length; i++)
        if (trailing[i].canHoist) (i, trailing[i]),
    ];
    indexed.sort((a, b) {
      final byOrder = b.$2.order.compareTo(a.$2.order);
      return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
    });
    return [for (final (_, action) in indexed) action];
  }

  @override
  Widget build(BuildContext context) {
    final scope = DockScope.maybeOf(context);
    // No shell or modal scope above: this page was presented modally on the
    // root navigator, so it brings its own frame.
    if (scope == null) {
      // A copy without the key, so a GlobalKey is not used twice.
      return DockModalScope<A, B>(
        child: DockPageScope<A, B>(
          title: widget.title,
          barPayload: widget.barPayload,
          leading: widget.leading,
          trailing: widget.trailing,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          impliedLeading: widget.impliedLeading,
          hoisting: widget.hoisting,
          visible: widget.visible,
          backdrop: widget.backdrop,
          child: widget.child,
        ),
      );
    }
    final builders = DockBuilders.of<Object?, A, B>(context);
    final page = widget;

    if (_registration?.host != scope.host) {
      _registration?.dispose();
      _registration = scope.host.register();
    }
    final registration = _registration!;

    assert(() {
      final ids = page.trailing.map((a) => a.id).toList();
      return ids.toSet().length == ids.length;
    }(), 'Trailing actions of one page need unique ids.');

    // Depending on ModalRoute and TickerMode rebuilds this page whenever it
    // becomes / stops being the visible top page.
    final route = ModalRoute.of(context);
    final leading = _resolveLeading(scope, route);
    final hoisting = page.hoisting ?? scope.hoisting;
    final hoists = hoisting == DockHoisting.iconActions;
    final leadingInColumn = hoists && leading != null && leading.canHoist;

    final hoisted = <DockAction<A>>[
      if (hoists) ..._hoisted(page.trailing),
      if (leadingInColumn) leading,
    ];
    registration.update(
      actions: hoisted,
      // TickerMode.valuesOf needs Flutter 3.41; keep .of while supporting 3.35.
      // DockTabStack.isActiveOf covers tabs that keep ticking.
      active:
          _shows(route) &&
          // ignore: deprecated_member_use
          TickerMode.of(context) &&
          DockTabStack.isActiveOf(context),
      route: route,
      navigationVisible: page.visible,
      backdrop: page.backdrop,
    );

    final wide = scope.mode == DockLayoutMode.wide;
    final moves = wide && hoists;
    final bar = DockBarData<A, B>(
      mode: scope.mode,
      title: page.title,
      payload: page.barPayload,
      leading: leading == null || (wide && leadingInColumn)
          ? null
          : registration.guarded(leading),
      trailing: [
        for (final a in page.trailing)
          if (!moves || !a.canHoist) registration.guarded(a),
      ],
      hoisted: wide ? hoisted.map(registration.guarded).toList() : const [],
      sideColumnSide: moves ? scope.side : null,
      buildAction: (a, placement) => KeyedSubtree(
        key: DockKeys.action(a.id),
        child: DockActionItem(
          action: a,
          child: builders.buildAction(context, a, placement),
        ),
      ),
    );
    return DockBarDataScope(data: bar, child: page.child);
  }
}
