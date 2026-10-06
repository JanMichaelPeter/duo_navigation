import 'package:flutter/material.dart';

import 'actions/action_host.dart';
import 'config/navigation.dart';
import 'frame/frame.dart';
import 'frame/modal_scope.dart';
import 'models/action.dart';
import 'models/bar_data.dart';
import 'models/enums.dart';

/// Builds a whole page from [DockBarData] (see [DockPage.custom]).
typedef DockPageBuilder =
    Widget Function(BuildContext context, DockBarData bar);

/// A tab root, subpage or modal page. Declare actions once; the page puts them
/// in the app bar (compact) or hands icon actions to the side column (wide).
///
/// Use [DockPage.custom] to build the whole page yourself (slivers, large
/// titles, floating bars...) from [DockBarData].
class DockPage extends StatelessWidget {
  /// A page whose title bar and body are built by the configured
  /// `pageBuilder`.
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
    required DockPageBuilder this.builder,
  }) : body = null;

  /// Title shown in the title bar.
  final Widget? title;

  /// Must have an icon (it moves to the side column in wide mode). Defaults
  /// to a back button, or a close button for fullscreen dialogs.
  final DockAction? leading;

  /// In wide mode icon actions move to the side column (in this order, above
  /// the leading action); label-only and pinned actions stay in the bar.
  final List<DockAction> trailing;

  /// Add a back/close action when the route can pop and [leading] is null.
  final bool automaticallyImplyLeading;

  /// Page content below the title bar (default constructor).
  final Widget? body;

  /// Builds the whole page ([DockPage.custom]).
  final DockPageBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final content = _DockPageContent(page: this);
    // No shell or modal scope above: this page was presented modally on the
    // root navigator, so it brings its own frame.
    if (context.getInheritedWidgetOfExactType<DockScope>() != null) {
      return content;
    }
    return DockModalScope(child: content);
  }
}

class _DockPageContent extends StatefulWidget {
  const _DockPageContent({required this.page});

  final DockPage page;

  @override
  State<_DockPageContent> createState() => _DockPageContentState();
}

class _DockPageContentState extends State<_DockPageContent> {
  DockActionRegistration? _registration;

  @override
  void dispose() {
    _registration?.dispose();
    super.dispose();
  }

  DockAction? _resolveLeading(ModalRoute<Object?>? route) {
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
    final l10n = MaterialLocalizations.of(context);
    final isDialog = route is PageRoute && route.fullscreenDialog;
    // Same id either way, so back <-> close morphs instead of flickering.
    return DockAction.back(
      icon: isDialog ? const Icon(Icons.close) : const BackButtonIcon(),
      tooltip: isDialog ? l10n.closeButtonTooltip : l10n.backButtonTooltip,
      onPressed: pop,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = DockScope.maybeOf(context)!;
    final config = DockNavigation.of(context);
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
    assert(
      leading == null || leading.icon != null,
      'Leading actions need an icon: they move to the side column when wide.',
    );

    final hoisted = <DockAction>[
      for (final a in page.trailing)
        if (a.canHoist) a,
      ?leading,
    ];
    registration.update(
      actions: hoisted,
      active:
          (route?.isCurrent ?? true) && TickerMode.valuesOf(context).enabled,
      route: route,
    );

    final wide = scope.mode == DockLayoutMode.wide;
    final bar = DockBarData(
      mode: scope.mode,
      title: page.title,
      leading: wide || leading == null ? null : registration.guarded(leading),
      trailing: [
        for (final a in page.trailing)
          if (!wide || !a.canHoist) registration.guarded(a),
      ],
      hoisted: wide ? hoisted.map(registration.guarded).toList() : const [],
      sideColumnSide: wide ? scope.side : null,
      buildAction: (a, placement) =>
          config.actionBuilder(context, a, placement),
    );

    final builder = page.builder;
    if (builder != null) return builder(context, bar);
    return config.pageBuilder(context, bar, page.body!);
  }
}
