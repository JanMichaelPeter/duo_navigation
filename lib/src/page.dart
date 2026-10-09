import 'package:flutter/widgets.dart';

import 'builders/builders.dart';
import 'models/action.dart';
import 'models/bar_data.dart';
import 'page/page_scope.dart';

/// Builds a whole page from [DuoBarData] (see [DuoPage.custom]).
typedef DuoPageBuilder<A, B> =
    Widget Function(BuildContext context, DuoBarData<A, B> bar);

/// A tab root, subpage or modal page: a [DuoPageScope] plus the `page`
/// builder. Declare actions once; the page puts them in the app bar (compact)
/// or hands icon actions to the side column (wide).
///
/// [A] is the actions' payload type and [B] the bar payload's; the action
/// and page builders get them typed.
///
/// For a page with its own `Scaffold`, use [DuoPageScope] with `DuoAppBar`
/// instead. Use [DuoPage.custom] to build the whole page yourself (slivers,
/// large titles, floating bars...) from [DuoBarData].
class DuoPage<A, B> extends StatelessWidget {
  /// A page whose title bar and body are built by the `page` builder
  /// (`DuoBuilders.page`).
  const DuoPage({
    super.key,
    this.title,
    this.barPayload,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.impliedLeading,
    this.leadingAtEnd,
    this.hoisting,
    this.visible = true,
    this.backdrop,
    required Widget this.body,
  }) : builder = null;

  /// A page you build yourself from [DuoBarData] in [builder].
  const DuoPage.custom({
    super.key,
    this.title,
    this.barPayload,
    this.leading,
    this.trailing = const [],
    this.automaticallyImplyLeading = true,
    this.impliedLeading,
    this.leadingAtEnd,
    this.hoisting,
    this.visible = true,
    this.backdrop,
    required DuoPageBuilder<A, B> this.builder,
  }) : body = null;

  /// See [DuoPageScope.title].
  final Widget? title;

  /// See [DuoPageScope.barPayload].
  final B? barPayload;

  /// See [DuoPageScope.leading].
  final DuoAction<A>? leading;

  /// See [DuoPageScope.trailing].
  final List<DuoAction<A>> trailing;

  /// See [DuoPageScope.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// See [DuoPageScope.impliedLeading].
  final DuoImpliedLeading? impliedLeading;

  /// See [DuoPageScope.leadingAtEnd].
  final bool? leadingAtEnd;

  /// See [DuoPageScope.hoisting].
  final DuoHoisting? hoisting;

  /// See [DuoPageScope.visible].
  final bool visible;

  /// See [DuoPageScope.backdrop].
  final Widget? backdrop;

  /// Page content below the title bar (default constructor).
  final Widget? body;

  /// Builds the whole page ([DuoPage.custom]).
  final DuoPageBuilder<A, B>? builder;

  @override
  Widget build(BuildContext context) {
    return DuoPageScope<A, B>(
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
          final bar = DuoBarData.of<A, B>(context);
          final builder = this.builder;
          if (builder != null) return builder(context, bar);
          return DuoBuilders.of<Object?, A, B>(
            context,
          ).buildPage(context, bar, body!);
        },
      ),
    );
  }
}
