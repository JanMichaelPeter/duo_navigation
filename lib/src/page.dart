import 'package:flutter/widgets.dart';

import 'builders/builders.dart';
import 'models/action.dart';
import 'models/bar_data.dart';
import 'page/page_scope.dart';

/// Builds a whole page from [DockBarData] (see [DockPage.custom]).
typedef DockPageBuilder<A, B> =
    Widget Function(BuildContext context, DockBarData<A, B> bar);

/// A tab root, subpage or modal page: a [DockPageScope] plus the `page`
/// builder. Declare actions once; the page puts them in the app bar (compact)
/// or hands icon actions to the side column (wide).
///
/// [A] is the actions' payload type and [B] the bar payload's; the action
/// and page builders get them typed.
///
/// For a page with its own `Scaffold`, use [DockPageScope] with `DockAppBar`
/// instead. Use [DockPage.custom] to build the whole page yourself (slivers,
/// large titles, floating bars...) from [DockBarData].
class DockPage<A, B> extends StatelessWidget {
  /// A page whose title bar and body are built by the `page` builder
  /// (`DockBuilders.page`).
  const DockPage({
    super.key,
    this.title,
    this.barPayload,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.impliedLeading,
    this.leadingAtEnd = false,
    this.hoisting,
    this.visible = true,
    this.backdrop,
    required Widget this.body,
  }) : builder = null;

  /// A page you build yourself from [DockBarData] in [builder].
  const DockPage.custom({
    super.key,
    this.title,
    this.barPayload,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.impliedLeading,
    this.leadingAtEnd = false,
    this.hoisting,
    this.visible = true,
    this.backdrop,
    required DockPageBuilder<A, B> this.builder,
  }) : body = null;

  /// See [DockPageScope.title].
  final Widget? title;

  /// See [DockPageScope.barPayload].
  final B? barPayload;

  /// See [DockPageScope.leading].
  final DockAction<A>? leading;

  /// See [DockPageScope.trailing].
  final List<DockAction<A>> trailing;

  /// See [DockPageScope.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// See [DockPageScope.impliedLeading].
  final DockImpliedLeading? impliedLeading;

  /// See [DockPageScope.leadingAtEnd].
  final bool leadingAtEnd;

  /// See [DockPageScope.hoisting].
  final DockHoisting? hoisting;

  /// See [DockPageScope.visible].
  final bool visible;

  /// See [DockPageScope.backdrop].
  final Widget? backdrop;

  /// Page content below the title bar (default constructor).
  final Widget? body;

  /// Builds the whole page ([DockPage.custom]).
  final DockPageBuilder<A, B>? builder;

  @override
  Widget build(BuildContext context) {
    return DockPageScope<A, B>(
      title: title,
      barPayload: barPayload,
      leading: leading,
      trailing: trailing,
      automaticallyImplyLeading: automaticallyImplyLeading,
      impliedLeading: impliedLeading,
      leadingAtEnd: leadingAtEnd,
      hoisting: hoisting,
      visible: visible,
      backdrop: backdrop,
      child: Builder(
        builder: (context) {
          final bar = DockBarData.of<A, B>(context);
          final builder = this.builder;
          if (builder != null) return builder(context, bar);
          return DockBuilders.of<Object?, A, B>(
            context,
          ).buildPage(context, bar, body!);
        },
      ),
    );
  }
}
