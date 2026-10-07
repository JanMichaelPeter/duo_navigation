import 'package:flutter/widgets.dart';

import 'actions/action_host.dart';
import 'builders/builders.dart';
import 'frame/frame.dart';
import 'frame/modal_scope.dart';
import 'geometry/layout_mode.dart';
import 'keys.dart';
import 'models/action.dart';
import 'models/bar_data.dart';

/// Builds a whole page from [DockBarData] (see [DockPage.custom]).
typedef DockPageBuilder<A> =
    Widget Function(BuildContext context, DockBarData<A> bar);

/// A tab root, subpage or modal page. Declare actions once; the page puts them
/// in the app bar (compact) or hands icon actions to the side column (wide).
///
/// [A] is the actions' payload type; the action and page builders get it
/// typed.
///
/// Use [DockPage.custom] to build the whole page yourself (slivers, large
/// titles, floating bars...) from [DockBarData].
class DockPage<A> extends StatelessWidget {
  /// A page whose title bar and body are built by the `page` builder
  /// (`DockBuilders.page`).
  const DockPage({
    super.key,
    this.title,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    required Widget this.body,
  }) : builder = null;

  /// A page you build yourself from [DockBarData] in [builder].
  const DockPage.custom({
    super.key,
    this.title,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    required DockPageBuilder<A> this.builder,
  }) : body = null;

  /// Title shown in the title bar.
  final Widget? title;

  /// The leading action. Defaults to [DockAction.back] for pages that can pop,
  /// or [DockAction.close] for full-screen dialogs. In wide mode it moves into
  /// the column when it has an icon; a text-only one ("Cancel") stays in the
  /// bar.
  final DockAction<A>? leading;

  /// In wide mode icon actions move to the side column (ordered by
  /// [DockAction.order], above the leading action); label-only actions and
  /// those with `hoist: DockHoist.never` stay in the bar.
  final List<DockAction<A>> trailing;

  /// Add a back/close action when the route can pop and [leading] is null.
  final bool automaticallyImplyLeading;

  /// Page content below the title bar (default constructor).
  final Widget? body;

  /// Builds the whole page ([DockPage.custom]).
  final DockPageBuilder<A>? builder;

  @override
  Widget build(BuildContext context) {
    final content = _DockPageContent<A>(page: this);
    // No shell or modal scope above: this page was presented modally on the
    // root navigator, so it brings its own frame.
    if (context.getInheritedWidgetOfExactType<DockScope>() != null) {
      return content;
    }
    return DockModalScope<A>(child: content);
  }
}

class _DockPageContent<A> extends StatefulWidget {
  const _DockPageContent({required this.page});

  final DockPage<A> page;

  @override
  State<_DockPageContent<A>> createState() => _DockPageContentState<A>();
}

class _DockPageContentState<A> extends State<_DockPageContent<A>> {
  DockActionRegistration? _registration;

  @override
  void dispose() {
    _registration?.dispose();
    super.dispose();
  }

  DockAction<A>? _resolveLeading(ModalRoute<Object?>? route) {
    final page = widget.page;
    void pop() => Navigator.maybePop(context);

    final explicit = page.leading;
    if (explicit != null) {
      return explicit.isBack && explicit.onPressed == null
          ? explicit.copyWith(onPressed: pop)
          : explicit;
    }
    if (!page.automaticallyImplyLeading || route == null || !route.canPop) {
      return null;
    }
    // Back and close share one identity, so they morph instead of flickering.
    final isDialog = route is PageRoute && route.fullscreenDialog;
    return isDialog
        ? DockAction<A>.close(onPressed: pop)
        : DockAction<A>.back(onPressed: pop);
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
    final scope = DockScope.maybeOf(context)!;
    final builders = DockBuilders.of<Object?, A>(context);
    final page = widget.page;

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
    final leading = _resolveLeading(route);
    final leadingInColumn = leading != null && leading.canHoist;

    final hoisted = <DockAction<A>>[
      ..._hoisted(page.trailing),
      if (leadingInColumn) leading,
    ];
    registration.update(
      actions: hoisted,
      // TickerMode.valuesOf needs Flutter 3.41; keep .of while supporting 3.38.
      // ignore: deprecated_member_use
      active: _shows(route) && TickerMode.of(context),
      route: route,
    );

    final wide = scope.mode == DockLayoutMode.wide;
    final bar = DockBarData<A>(
      mode: scope.mode,
      title: page.title,
      leading: leading == null || (wide && leadingInColumn)
          ? null
          : registration.guarded(leading),
      trailing: [
        for (final a in page.trailing)
          if (!wide || !a.canHoist) registration.guarded(a),
      ],
      hoisted: wide ? hoisted.map(registration.guarded).toList() : const [],
      sideColumnSide: wide ? scope.side : null,
      buildAction: (a, placement) {
        final key = a.key;
        final built = builders.buildAction(context, a, placement);
        return KeyedSubtree(
          key: DockKeys.action(a.id),
          child: key == null ? built : KeyedSubtree(key: key, child: built),
        );
      },
    );

    final builder = page.builder;
    if (builder != null) return builder(context, bar);
    return builders.buildPage(context, bar, page.body!);
  }
}
