import 'package:flutter/widgets.dart';

import '../geometry/layout_mode.dart';
import '../geometry/side.dart';
import 'action.dart';
import 'enums.dart';

/// Renders an action at a placement with the configured action builder.
typedef DuoActionWidgetBuilder<A> =
    Widget Function(DuoAction<A> action, DuoActionPlacement placement);

/// What a page's title bar should show in the current mode.
///
/// In wide mode the actions that moved into the side column are in [hoisted]
/// and already rendered there; [leading] and [trailing] hold what stays in the
/// bar: label-only actions and actions with `hoist: DuoHoist.never`. With
/// hoisting off (`DuoHoisting.none`), nothing moves and the data is the same
/// in both modes.
///
/// [A] is the actions' payload type and [B] the type of [payload], the
/// page's data for the bar (a structured title, a bar style). Read it below a
/// `DuoPageScope` with [DuoBarData.of].
@immutable
class DuoBarData<A, B> {
  /// Built by `DuoPageScope`; you receive it in page builders.
  const DuoBarData({
    required this.mode,
    required this.title,
    this.payload,
    required this.leading,
    required this.trailing,
    required this.hoisted,
    this.sideColumnSide,
    this.leadingAtEnd = false,
    required DuoActionWidgetBuilder<A> buildAction,
  }) : _buildAction = buildAction;

  /// The current layout mode.
  final DuoLayoutMode mode;

  /// The page title.
  final Widget? title;

  /// The page's data for the bar, from `DuoPageScope.barPayload`.
  final B? payload;

  /// The back or close action for the bar. Null in wide mode when it moved
  /// into the column; a text-only leading action ("Cancel") stays here in
  /// every mode.
  final DuoAction<A>? leading;

  /// Actions for the bar. In wide mode only the ones that stay in the bar;
  /// the rest are in [hoisted].
  final List<DuoAction<A>> trailing;

  /// Actions shown as side-column chips (wide mode only). Already rendered
  /// by the column; for information.
  final List<DuoAction<A>> hoisted;

  /// Edge the side column is on when actions move into it; null otherwise
  /// (compact mode, or hoisting off).
  final DuoSide? sideColumnSide;

  /// Whether [leading] belongs at the end of the bar, after the actions (a
  /// close action at the top right, as in iOS sheets), from
  /// `DuoPageScope.leadingAtEnd`. `DuoBarLayout` handles it.
  final bool leadingAtEnd;

  final DuoActionWidgetBuilder<A> _buildAction;

  /// Whether the layout is [DuoLayoutMode.wide].
  bool get isWide => mode == DuoLayoutMode.wide;

  /// Whether [trailing] belongs at the start of the bar: the column is at the
  /// start edge, so bar actions follow it to the same side. `DuoBarLayout`
  /// handles it.
  bool get trailingAtStart => sideColumnSide == DuoSide.start;

  /// Renders an action with the configured action builder, with its keys.
  Widget buildAction(DuoAction<A> action, DuoActionPlacement placement) =>
      _buildAction(action, placement);

  /// The bar data of the nearest `DuoPageScope`. Throws a [FlutterError]
  /// when there is none or its types don't match [A] and [B]; builders for
  /// any types use `DuoBarData.of<Object?, Object?>`.
  static DuoBarData<A, B> of<A, B>(BuildContext context) {
    final bar = context
        .dependOnInheritedWidgetOfExactType<DuoBarDataScope>()
        ?.data;
    if (bar is DuoBarData<A, B>) return bar;
    throw FlutterError.fromParts([
      if (bar == null)
        ErrorSummary('No DuoPageScope found.')
      else
        ErrorSummary('The page\'s bar data does not match.'),
      if (bar == null)
        ErrorDescription(
          '${context.widget.runtimeType} reads the title bar of its page, and '
          'is not below a DuoPageScope or DuoPage.',
        )
      else
        ErrorDescription(
          'The page provides a ${bar.runtimeType}, and '
          '${context.widget.runtimeType} asked for DuoBarData<$A, $B>.',
        ),
      ErrorHint(
        'Put a DuoPageScope around the page (DuoPage does it for you), and '
        'read it with the page\'s payload types, or with <Object?, Object?>.',
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Like [of], but null when there is no matching `DuoPageScope`.
  static DuoBarData<A, B>? maybeOf<A, B>(BuildContext context) {
    final bar = context
        .dependOnInheritedWidgetOfExactType<DuoBarDataScope>()
        ?.data;
    return bar is DuoBarData<A, B> ? bar : null;
  }
}

/// Provides a page's [DuoBarData] to its subtree. Inserted by
/// `DuoPageScope`; not exported.
class DuoBarDataScope extends InheritedWidget {
  /// Provides [data] to [child].
  const DuoBarDataScope({super.key, required this.data, required super.child});

  /// The bar data, stored untyped so readers check its types themselves.
  final Object data;

  @override
  bool updateShouldNotify(DuoBarDataScope oldWidget) =>
      !identical(data, oldWidget.data);
}
